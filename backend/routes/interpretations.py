from fastapi import APIRouter, Depends, HTTPException
from datetime import datetime, timedelta, timezone
from pydantic import BaseModel
from psycopg.types.json import Json

from ..db import get_conn
from ..services.claude import ClaudeClient
from ..config import DISABLE_INTERPRETATION_LIMITS
from ..services.card_meanings import get_card_meaning
from ..services.interpretation_prompt import build_prompt
from .security import get_user_id

router = APIRouter(prefix='/interpretations', tags=['interpretations'])


class InterpretationInputRequest(BaseModel):
    reading_id: str
    input_json: dict


class InterpretationOutputRequest(BaseModel):
    reading_id: str
    output_text: str


@router.post('/input')
def save_interpretation_input(payload: InterpretationInputRequest, user_id: str = Depends(get_user_id)):
    if not payload.reading_id:
        raise HTTPException(status_code=400, detail='Missing reading_id')

    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                'SELECT id FROM readings WHERE id = %s AND user_id = %s',
                (payload.reading_id, user_id),
            )
            if not cur.fetchone():
                raise HTTPException(status_code=404, detail='Reading not found')
            enriched = _enrich_input(cur, payload.input_json)
            cur.execute(
                'INSERT INTO reading_interpretations (reading_id, input_json) VALUES (%s, %s) ON CONFLICT (reading_id) DO UPDATE SET input_json = EXCLUDED.input_json',
                (payload.reading_id, Json(enriched)),
            )
            conn.commit()

    return {'ok': True}


@router.post('/output')
def save_interpretation_output(payload: InterpretationOutputRequest, user_id: str = Depends(get_user_id)):
    if not payload.reading_id:
        raise HTTPException(status_code=400, detail='Missing reading_id')

    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                'SELECT id FROM readings WHERE id = %s AND user_id = %s',
                (payload.reading_id, user_id),
            )
            if not cur.fetchone():
                raise HTTPException(status_code=404, detail='Reading not found')
            cur.execute(
                'INSERT INTO reading_interpretations (reading_id, input_json, output_text) VALUES (%s, %s, %s) ON CONFLICT (reading_id) DO UPDATE SET output_text = EXCLUDED.output_text',
                (payload.reading_id, Json({}), payload.output_text),
            )
            conn.commit()

    return {'ok': True}


@router.post('/generate')
def generate_interpretation(reading_id: str, user_id: str = Depends(get_user_id)):
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                'SELECT ri.input_json, r.access_type, ft.key '
                'FROM reading_interpretations ri '
                'JOIN readings r ON r.id = ri.reading_id '
                'JOIN fortune_types ft ON ft.id = r.fortune_type_id '
                'WHERE ri.reading_id = %s AND r.user_id = %s',
                (reading_id, user_id),
            )
            row = cur.fetchone()
            if not row:
                raise HTTPException(status_code=404, detail='Interpretation input not found')
            input_json, access_type, fortune_key = row[0], row[1], row[2]

            if not DISABLE_INTERPRETATION_LIMITS:
                if access_type == 'one_time':
                    cur.execute(
                        'SELECT 1 FROM interpretation_versions WHERE reading_id = %s LIMIT 1',
                        (reading_id,),
                    )
                    if cur.fetchone():
                        raise HTTPException(status_code=409, detail='Interpretation already generated')

                if fortune_key and fortune_key.startswith('today_'):
                    window_start = _daily_window_start_utc()
                    cur.execute(
                        'SELECT 1 '
                        'FROM interpretation_versions iv '
                        'JOIN readings r ON r.id = iv.reading_id '
                        'JOIN fortune_types ft ON ft.id = r.fortune_type_id '
                        'WHERE r.user_id = %s AND ft.key = %s AND iv.created_at >= %s '
                        'LIMIT 1',
                        (user_id, fortune_key, window_start),
                    )
                    if cur.fetchone():
                        raise HTTPException(status_code=409, detail='Daily interpretation limit reached')

    client = ClaudeClient()
    prompt, output_text = client.generate(input_json)

    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                'SELECT COALESCE(MAX(version), 0) FROM interpretation_versions WHERE reading_id = %s',
                (reading_id,),
            )
            next_version = (cur.fetchone()[0] or 0) + 1
            cur.execute(
                'UPDATE reading_interpretations SET output_text = %s, updated_at = now() WHERE reading_id = %s',
                (output_text, reading_id),
            )
            cur.execute(
                'INSERT INTO interpretation_versions (reading_id, version, prompt, output_text, model) VALUES (%s, %s, %s, %s, %s)',
                (reading_id, next_version, prompt, output_text, client.model),
            )
            conn.commit()

    return {
        'reading_id': reading_id,
        'prompt': prompt,
        'output_text': output_text,
        'version': next_version,
        'model': client.model,
    }


def _daily_window_start_utc() -> datetime:
    # Daily reset at 05:00 JST
    now_utc = datetime.now(timezone.utc)
    now_jst = now_utc + timedelta(hours=9)
    if now_jst.hour < 5:
        base_date = (now_jst - timedelta(days=1)).date()
    else:
        base_date = now_jst.date()
    window_start_jst = datetime.combine(base_date, datetime.min.time()) + timedelta(hours=5)
    return (window_start_jst - timedelta(hours=9)).replace(tzinfo=timezone.utc)


@router.get('/{reading_id}')
def get_interpretation(reading_id: str, user_id: str = Depends(get_user_id)):
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                'SELECT input_json, output_text, created_at, updated_at FROM reading_interpretations WHERE reading_id = %s',
                (reading_id,),
            )
            row = cur.fetchone()

    if not row:
        raise HTTPException(status_code=404, detail='Interpretation not found')

    return {'input_json': row[0], 'output_text': row[1], 'created_at': row[2], 'updated_at': row[3]}


@router.get('/{reading_id}/history')
def get_interpretation_history(reading_id: str, user_id: str = Depends(get_user_id)):
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                'SELECT r.id FROM readings r WHERE r.id = %s AND r.user_id = %s',
                (reading_id, user_id),
            )
            if not cur.fetchone():
                raise HTTPException(status_code=404, detail='Reading not found')
            cur.execute(
                'SELECT version, prompt, output_text, model, created_at FROM interpretation_versions WHERE reading_id = %s ORDER BY version DESC',
                (reading_id,),
            )
            rows = cur.fetchall()

    items = [
        {
            'version': r[0],
            'prompt': r[1],
            'output_text': r[2],
            'model': r[3],
            'created_at': r[4],
        }
        for r in rows
    ]
    return {'items': items}


def _enrich_input(cur, input_json: dict) -> dict:
    if not isinstance(input_json, dict):
        return input_json
    cards = input_json.get('cards')
    if not isinstance(cards, list) or not cards:
        return input_json

    names = [card.get('card_name') for card in cards if isinstance(card, dict) and card.get('card_name')]
    if not names:
        return input_json

    cur.execute(
        'SELECT c.name, m.orientation, m.short_meaning, m.keywords FROM card_catalog c LEFT JOIN card_meanings m ON m.card_id = c.id WHERE c.name = ANY(%s)',
        (names,),
    )
    rows = cur.fetchall()
    meaning_map: dict[str, dict[str, dict]] = {}
    for name, orientation, short_meaning, keywords in rows:
        if name not in meaning_map:
            meaning_map[name] = {}
        if orientation:
            meaning_map[name][orientation] = {
                'short_meaning': short_meaning,
                'keywords': keywords or [],
            }

    def orientation_key(card: dict) -> str:
        upright = card.get('upright')
        if upright is None:
            return 'none'
        return 'upright' if upright else 'reversed'

    enriched_cards = []
    for card in cards:
        if not isinstance(card, dict):
            enriched_cards.append(card)
            continue
        name = card.get('card_name')
        if not name or name not in meaning_map:
            enriched_cards.append(card)
            continue
        orient = orientation_key(card)
        meaning = meaning_map.get(name, {}).get(orient)
        if not meaning:
            fallback = get_card_meaning(name, card.get('upright'))
            if not fallback:
                enriched_cards.append(card)
                continue
            updated = dict(card)
            if not updated.get('meaning_short'):
                updated['meaning_short'] = fallback.get('short_meaning')
            if not updated.get('keywords'):
                updated['keywords'] = fallback.get('keywords') or []
            enriched_cards.append(updated)
            continue
        updated = dict(card)
        if not updated.get('meaning_short'):
            updated['meaning_short'] = meaning.get('short_meaning')
        if not updated.get('keywords'):
            updated['keywords'] = meaning.get('keywords') or []
        enriched_cards.append(updated)

    return {**input_json, 'cards': enriched_cards}


def _build_prompt(input_json: dict) -> str:
    return build_prompt(input_json)
