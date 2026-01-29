from fastapi import Header, HTTPException
from jwt import ExpiredSignatureError, InvalidTokenError

from ..auth_tokens import decode_access_token
from ..config import ADMIN_USER_IDS, ALLOW_X_USER_ID_FALLBACK


def is_admin_user(user_id: str) -> bool:
    return user_id in ADMIN_USER_IDS


def get_user_id(
    authorization: str | None = Header(default=None),
    x_user_id: str | None = Header(default=None),
) -> str:
    if authorization:
        if not authorization.lower().startswith('bearer '):
            raise HTTPException(status_code=401, detail='Invalid auth header')
        token = authorization.split(' ', 1)[1].strip()
        if not token:
            raise HTTPException(status_code=401, detail='Missing token')
        try:
            payload = decode_access_token(token)
        except ExpiredSignatureError as exc:
            raise HTTPException(status_code=401, detail='Token expired') from exc
        except InvalidTokenError as exc:
            raise HTTPException(status_code=401, detail='Invalid token') from exc
        user_id = payload.get('sub')
        if not user_id:
            raise HTTPException(status_code=401, detail='Invalid token')
        return user_id

    if ALLOW_X_USER_ID_FALLBACK and x_user_id:
        return x_user_id

    raise HTTPException(status_code=401, detail='Missing auth')
