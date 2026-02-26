import json

from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
import requests

from .security import get_user_id
from ..config import (
    DISCORD_WEBHOOK_URL,
    PAYPAY_PAYMENT_LINKS_JSON,
    STRIPE_CANCEL_URL,
    STRIPE_PAYMENT_LINKS_JSON,
    STRIPE_SECRET_KEY,
    STRIPE_SUCCESS_URL,
)

router = APIRouter(prefix='/shop', tags=['shop'])

_SHOP_ITEMS = [
    {
        'id': 'love_stone_set',
        'name': '恋愛運：アメジスト、ローズクォーツ',
        'price_cents': 7800,
        'currency': 'JPY',
    },
    {
        'id': 'work_stone_set',
        'name': '仕事運：タイガーアイ、アンバー',
        'price_cents': 7800,
        'currency': 'JPY',
    },
    {
        'id': 'health_stone_set',
        'name': '健康運：トルマリン、ブラックルチル、スモーキークォーツ',
        'price_cents': 7800,
        'currency': 'JPY',
    },
    {
        'id': 'money_stone_set',
        'name': '金運：ヘマタイト、ルチルクォーツ',
        'price_cents': 10800,
        'currency': 'JPY',
    },
    {
        'id': 'amulet_stone_set',
        'name': 'お守り：ラピスラズリ、クリスタル',
        'price_cents': 10800,
        'currency': 'JPY',
    },
    {
        'id': 'custom_consulting',
        'name': '職人との相談で決めるメニュー',
        'price_cents': 15800,
        'currency': 'JPY',
    },
    {
        'id': 'kink_trump',
        'name': '性癖トランプ',
        'price_cents': 3800,
        'currency': 'JPY',
    },
]


class ShopCheckoutRequest(BaseModel):
    item_id: str
    payment_method: str


def _shop_items() -> dict[str, dict]:
    return {item['id']: item for item in _SHOP_ITEMS}


def _load_link_map(raw_json: str, setting_name: str) -> dict[str, str]:
    if not raw_json:
        return {}
    try:
        parsed = json.loads(raw_json)
    except json.JSONDecodeError as exc:
        raise RuntimeError(f'Invalid JSON in {setting_name}') from exc
    if not isinstance(parsed, dict):
        raise RuntimeError(f'{setting_name} must be a JSON object')
    return {str(k): str(v) for k, v in parsed.items() if str(v).strip()}


def _resolve_paypay_url(item_id: str) -> str:
    mapping = _load_link_map(PAYPAY_PAYMENT_LINKS_JSON, 'PAYPAY_PAYMENT_LINKS_JSON')
    url = mapping.get(item_id) or mapping.get('default')
    if not url:
        raise HTTPException(status_code=503, detail='PayPay決済URLが未設定です')
    return url


def _resolve_stripe_url(item: dict, user_id: str) -> str:
    mapping = _load_link_map(STRIPE_PAYMENT_LINKS_JSON, 'STRIPE_PAYMENT_LINKS_JSON')
    linked_url = mapping.get(item['id']) or mapping.get('default')
    if linked_url:
        return linked_url

    if not STRIPE_SECRET_KEY:
        raise HTTPException(status_code=503, detail='Stripe秘密鍵が未設定です')
    if not STRIPE_SUCCESS_URL or not STRIPE_CANCEL_URL:
        raise HTTPException(status_code=503, detail='Stripe遷移URLが未設定です')

    try:
        import stripe
    except ModuleNotFoundError as exc:
        raise HTTPException(status_code=503, detail='Stripe SDKが未インストールです') from exc

    stripe.api_key = STRIPE_SECRET_KEY
    session = stripe.checkout.Session.create(
        mode='payment',
        success_url=STRIPE_SUCCESS_URL,
        cancel_url=STRIPE_CANCEL_URL,
        line_items=[
            {
                'quantity': 1,
                'price_data': {
                    'currency': item['currency'].lower(),
                    'unit_amount': item['price_cents'],
                    'product_data': {
                        'name': item['name'],
                    },
                },
            }
        ],
        metadata={
            'user_id': user_id,
            'item_id': item['id'],
            'payment_method': 'stripe',
        },
    )
    checkout_url = session.get('url')
    if not checkout_url:
        raise HTTPException(status_code=502, detail='StripeセッションURLの取得に失敗しました')
    return checkout_url


def _notify_discord(lines: list[str]):
    if not DISCORD_WEBHOOK_URL:
        return
    content = '\n'.join(lines)
    try:
        requests.post(DISCORD_WEBHOOK_URL, json={'content': content}, timeout=10)
    except requests.RequestException:
        pass


@router.get('/items')
def list_shop_items(user_id: str = Depends(get_user_id)):
    del user_id
    return {
        'items': [
            {
                **item,
                'payment_methods': ['paypay', 'stripe'],
            }
            for item in _SHOP_ITEMS
        ]
    }


@router.post('/checkout/start')
def start_checkout(payload: ShopCheckoutRequest, user_id: str = Depends(get_user_id)):
    method = payload.payment_method.lower().strip()
    if method not in {'paypay', 'stripe'}:
        raise HTTPException(status_code=400, detail='Unsupported payment_method')

    item = _shop_items().get(payload.item_id)
    if not item:
        raise HTTPException(status_code=404, detail='Shop item not found')

    if method == 'paypay':
        checkout_url = _resolve_paypay_url(payload.item_id)
    else:
        checkout_url = _resolve_stripe_url(item, user_id)

    _notify_discord(
        [
            '🛒 物販決済開始',
            f'ユーザーID: {user_id}',
            f'商品ID: {item["id"]}',
            f'商品名: {item["name"]}',
            f'決済手段: {method}',
            f'URL: {checkout_url}',
        ]
    )

    return {
        'ok': True,
        'payment_method': method,
        'checkout_url': checkout_url,
        'item': item,
    }


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
