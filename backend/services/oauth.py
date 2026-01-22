from google.auth.transport import requests as google_requests
from google.oauth2 import id_token as google_id_token

from ..config import GOOGLE_CLIENT_ID


def verify_google_id_token(token: str) -> str:
    if not GOOGLE_CLIENT_ID:
        raise RuntimeError('GOOGLE_CLIENT_ID is not set')

    payload = google_id_token.verify_oauth2_token(token, google_requests.Request(), GOOGLE_CLIENT_ID)
    subject = payload.get('sub')
    if not subject:
        raise ValueError('Missing subject')
    return subject

