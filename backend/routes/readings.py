from fastapi import APIRouter, Depends, HTTPException
from datetime import datetime, timedelta, timezone
from pydantic import BaseModel
from uuid import uuid4

from psycopg.types.json import Json

from ..db import get_conn
from ..services.readings import generate_reading, build_seed
from .security import get_user_id, is_admin_user

router = APIRouter(prefix='/readings', tags=['readings'])


class ExecuteRequest(BaseModel):
    fortune_type_key: str
    input_json: dict | None = None


@router.post('/execute')
def execute_reading(payload: ExecuteRequest, user_id: str = Depends(get_user_id)):
    with get_conn() as conn:
        with conn.cursor() as cur:
            reading_id, result_json = _execute_one(cur, user_id, payload.fortune_type_key, payload.input_json)
            conn.commit()

    return {'reading_id': reading_id, 'result_json': result_json}


class BatchExecuteRequest(BaseModel):
    fortune_type_keys: list[str]
    input_json: dict | None = None


@router.post('/execute-batch')
def execute_batch(payload: BatchExecuteRequest, user_id: str = Depends(get_user_id)):
    if not payload.fortune_type_keys:
        raise HTTPException(status_code=400, detail='Missing fortune_type_keys')

    with get_conn() as conn:
        with conn.cursor() as cur:
            results = []
            for key in payload.fortune_type_keys:
                reading_id, result_json = _execute_one(cur, user_id, key, payload.input_json)
                results.append({'fortune_type_key': key, 'reading_id': reading_id, 'result_json': result_json})
            conn.commit()

    return {'items': results}


def _execute_one(cur, user_id: str, fortune_type_key: str, input_json: dict | None):
    cur.execute(
        'SELECT id, access_type_default, requires_warning FROM fortune_types WHERE key = %s',
        (fortune_type_key,),
    )
    ft = cur.fetchone()
    if not ft:
        raise HTTPException(status_code=404, detail='Fortune type not found')

    admin_user = is_admin_user(user_id)
    fortune_type_id, access_type_default, requires_warning = ft
    if access_type_default == 'free':
        access_type_default = 'life'
    access_type_used = access_type_default
    consumed_purchase_id = None

    if requires_warning and not admin_user:
        cur.execute(
            "SELECT id FROM warnings_acceptance WHERE user_id = %s AND fortune_type_id = %s AND accepted_at > now() - interval '5 minutes' ORDER BY accepted_at DESC LIMIT 1",
            (user_id, fortune_type_id),
        )
        if not cur.fetchone():
            raise HTTPException(status_code=409, detail='Warning acceptance required')

    if access_type_default == 'subscription' and not admin_user:
        cur.execute(
            'SELECT id FROM subscriptions WHERE user_id = %s AND status = %s AND current_period_end > now() LIMIT 1',
            (user_id, 'active'),
        )
        if not cur.fetchone():
            raise HTTPException(status_code=403, detail='Subscription required')

    if access_type_default == 'one_time' and not admin_user:
        cur.execute(
            'SELECT p.id FROM purchases p JOIN products pr ON p.product_id = pr.id WHERE p.user_id = %s AND p.status = %s AND pr.fortune_type_id = %s ORDER BY p.verified_at ASC NULLS LAST, p.id ASC LIMIT 1 FOR UPDATE',
            (user_id, 'verified', fortune_type_id),
        )
        row = cur.fetchone()
        if not row:
            raise HTTPException(status_code=403, detail='Purchase required')
        consumed_purchase_id = row[0]

    if access_type_default == 'life' and not admin_user:
        cur.execute(
            'SELECT id FROM subscriptions WHERE user_id = %s AND status = %s AND current_period_end > now() LIMIT 1',
            (user_id, 'active'),
        )
        if cur.fetchone():
            access_type_used = 'subscription'
        else:
            cur.execute(
                'SELECT current_life FROM user_lives WHERE user_id = %s FOR UPDATE',
                (user_id,),
            )
            row = cur.fetchone()
            if not row or row[0] <= 0:
                raise HTTPException(status_code=409, detail='Life is empty')
            cur.execute(
                'UPDATE user_lives SET current_life = current_life - 1, updated_at = now() WHERE user_id = %s',
                (user_id,),
            )
            cur.execute(
                'INSERT INTO life_events (id, user_id, event_type, amount, reason) VALUES (%s, %s, %s, %s, %s)',
                (str(uuid4()), user_id, 'consume', -1, f'execute:{fortune_type_key}'),
            )

    if fortune_type_key.startswith('today_') or fortune_type_key == 'week_one':
        existing = _get_today_reading(cur, user_id, fortune_type_id)
        if existing:
            return existing

    seed = build_seed(user_id, fortune_type_key)
    result_json = generate_reading(user_id, fortune_type_key, input_json)

    reading_id = str(uuid4())
    cur.execute(
        'INSERT INTO readings (id, user_id, fortune_type_id, access_type, input_json, result_json, seed) VALUES (%s, %s, %s, %s, %s, %s, %s)',
        (
            reading_id,
            user_id,
            fortune_type_id,
            access_type_used,
            Json(input_json or {}),
            Json(result_json),
            seed,
        ),
    )
    if consumed_purchase_id:
        cur.execute(
            'UPDATE purchases SET status = %s WHERE id = %s',
            ('consumed', consumed_purchase_id),
        )
    return reading_id, result_json


def _get_today_reading(cur, user_id: str, fortune_type_id: str):
    window_start = _daily_window_start_utc()
    cur.execute(
        'SELECT id, result_json FROM readings '
        'WHERE user_id = %s AND fortune_type_id = %s AND created_at >= %s '
        'ORDER BY created_at DESC LIMIT 1',
        (user_id, fortune_type_id, window_start),
    )
    row = cur.fetchone()
    if not row:
        return None
    return row[0], row[1]


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


@router.get('')
def list_readings(limit: int = 20, user_id: str = Depends(get_user_id)):
    limit = min(limit, 100)
    admin_user = is_admin_user(user_id)
    with get_conn() as conn:
        with conn.cursor() as cur:
            if admin_user:
                cur.execute(
                    'SELECT id, fortune_type_id, access_type, input_json, result_json, seed, created_at FROM readings ORDER BY created_at DESC LIMIT %s',
                    (limit,),
                )
            else:
                cur.execute(
                    'SELECT id, fortune_type_id, access_type, input_json, result_json, seed, created_at FROM readings WHERE user_id = %s ORDER BY created_at DESC LIMIT %s',
                    (user_id, limit),
                )
            rows = cur.fetchall()

    items = [
        {
            'id': r[0],
            'fortune_type_id': r[1],
            'access_type': r[2],
            'input_json': r[3],
            'result_json': r[4],
            'seed': r[5],
            'created_at': r[6],
        }
        for r in rows
    ]

    return {'items': items, 'next_cursor': None}


@router.get('/{reading_id}')
def get_reading(reading_id: str, user_id: str = Depends(get_user_id)):
    admin_user = is_admin_user(user_id)
    with get_conn() as conn:
        with conn.cursor() as cur:
            if admin_user:
                cur.execute(
                    'SELECT id, fortune_type_id, access_type, input_json, result_json, seed, created_at FROM readings WHERE id = %s',
                    (reading_id,),
                )
            else:
                cur.execute(
                    'SELECT id, fortune_type_id, access_type, input_json, result_json, seed, created_at FROM readings WHERE user_id = %s AND id = %s',
                    (user_id, reading_id),
                )
            row = cur.fetchone()

    if not row:
        raise HTTPException(status_code=404, detail='Reading not found')

    return {
        'id': row[0],
        'fortune_type_id': row[1],
        'access_type': row[2],
        'input_json': row[3],
        'result_json': row[4],
        'seed': row[5],
        'created_at': row[6],
    }
