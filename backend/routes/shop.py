from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
import requests

from .security import get_user_id
from ..config import DISCORD_WEBHOOK_URL

router = APIRouter(prefix='/shop', tags=['shop'])


class ShopNotifyPayload(BaseModel):
    product_name: str
    price: str | None = None
    url: str | None = None


@router.post('/notify')
def notify_purchase(payload: ShopNotifyPayload, user_id: str = Depends(get_user_id)):
    if not DISCORD_WEBHOOK_URL:
        raise HTTPException(status_code=400, detail='Discord webhook not configured')
    content_lines = [
        '🛒 物販の購入通知',
        f'ユーザーID: {user_id}',
        f'商品名: {payload.product_name}',
    ]
    if payload.price:
        content_lines.append(f'価格: {payload.price}')
    if payload.url:
        content_lines.append(f'URL: {payload.url}')
    content = '\n'.join(content_lines)
    resp = requests.post(DISCORD_WEBHOOK_URL, json={'content': content}, timeout=10)
    if resp.status_code >= 400:
        raise HTTPException(status_code=502, detail='Discord webhook failed')
    return {'ok': True}
