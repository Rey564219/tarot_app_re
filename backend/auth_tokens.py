from datetime import datetime, timedelta, timezone

import jwt

from .config import JWT_AUDIENCE, JWT_EXP_SECONDS, JWT_ISSUER, JWT_SECRET


def create_access_token(user_id: str) -> str:
    now = datetime.now(timezone.utc)
    payload = {
        'sub': user_id,
        'iss': JWT_ISSUER,
        'aud': JWT_AUDIENCE,
        'iat': int(now.timestamp()),
        'exp': int((now + timedelta(seconds=JWT_EXP_SECONDS)).timestamp()),
    }
    return jwt.encode(payload, JWT_SECRET, algorithm='HS256')


def decode_access_token(token: str) -> dict:
    return jwt.decode(
        token,
        JWT_SECRET,
        algorithms=['HS256'],
        issuer=JWT_ISSUER,
        audience=JWT_AUDIENCE,
    )
