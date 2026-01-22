from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from uuid import uuid4

from ..auth_tokens import create_access_token
from ..db import get_conn
from ..services import oauth as oauth_service

router = APIRouter(prefix='/auth', tags=['auth'])


class OAuthRequest(BaseModel):
    provider: str
    id_token: str


@router.post('/anonymous')
def create_anonymous():
    user_id = str(uuid4())
    auth_id = str(uuid4())

    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute('INSERT INTO users (id) VALUES (%s)', (user_id,))
            cur.execute(
                'INSERT INTO user_auth_providers (id, user_id, provider, provider_user_id) VALUES (%s, %s, %s, %s)',
                (auth_id, user_id, 'anonymous', user_id),
            )
            cur.execute(
                'INSERT INTO user_lives (user_id, current_life, max_life) VALUES (%s, %s, %s)',
                (user_id, 5, 5),
            )
            conn.commit()

    token = create_access_token(user_id)
    return {'token': token, 'user_id': user_id}


@router.post('/oauth')
def oauth_sign_in(payload: OAuthRequest):
    provider = payload.provider
    id_token = payload.id_token

    if provider not in ('google',):
        raise HTTPException(status_code=400, detail='Invalid provider')
    try:
        provider_user_id = oauth_service.verify_google_id_token(id_token)
    except Exception as exc:
        raise HTTPException(status_code=401, detail='Invalid id_token') from exc

    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                'SELECT user_id FROM user_auth_providers WHERE provider = %s AND provider_user_id = %s',
                (provider, provider_user_id),
            )
            row = cur.fetchone()
            if row:
                user_id = row[0]
            else:
                user_id = str(uuid4())
                cur.execute('INSERT INTO users (id) VALUES (%s)', (user_id,))
                cur.execute(
                    'INSERT INTO user_auth_providers (id, user_id, provider, provider_user_id) VALUES (%s, %s, %s, %s)',
                    (str(uuid4()), user_id, provider, provider_user_id),
                )
                cur.execute(
                    'INSERT INTO user_lives (user_id, current_life, max_life) VALUES (%s, %s, %s)',
                    (user_id, 5, 5),
                )
                conn.commit()

    if not user_id:
        raise HTTPException(status_code=403, detail='Auth failed')

    token = create_access_token(user_id)
    return {'token': token, 'user_id': user_id}
