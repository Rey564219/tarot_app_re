from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from uuid import uuid4

from ..db import get_conn
from ..services import billing as billing_service
from .security import get_user_id, is_admin_user

router = APIRouter(prefix='/billing', tags=['billing'])


class PurchaseVerifyRequest(BaseModel):
    platform: str
    receipt: str
    product_key: str


class SubscriptionVerifyRequest(BaseModel):
    platform: str
    receipt: str
    subscription_id: str | None = None


class MockPurchaseRequest(BaseModel):
    fortune_type_key: str


@router.post('/verify/purchase')
def verify_purchase(payload: PurchaseVerifyRequest, user_id: str = Depends(get_user_id)):
    platform = payload.platform
    if platform != 'android':
        raise HTTPException(status_code=400, detail='Invalid platform')

    package_name = billing_service.resolve_google_package()
    purchase = billing_service.verify_google_product(package_name, payload.product_key, payload.receipt)
    store_transaction_id = purchase.get('transaction_id')

    if not store_transaction_id:
        raise HTTPException(status_code=409, detail='Missing transaction id')
    if purchase.get('status') != 'verified':
        raise HTTPException(status_code=409, detail='Purchase not verified')

    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute('SELECT id FROM products WHERE product_key = %s AND platform = %s', (payload.product_key, platform))
            row = cur.fetchone()
            if not row:
                raise HTTPException(status_code=404, detail='Product not found')
            product_id = row[0]

            cur.execute(
                'INSERT INTO purchases (id, user_id, product_id, platform, store_transaction_id, status, verified_at) VALUES (%s, %s, %s, %s, %s, %s, now()) ON CONFLICT (platform, store_transaction_id) DO UPDATE SET status = EXCLUDED.status, verified_at = EXCLUDED.verified_at',
                (str(uuid4()), user_id, product_id, platform, store_transaction_id, 'verified'),
            )
            conn.commit()

    return {'ok': True}


@router.post('/mock/purchase')
def mock_purchase(payload: MockPurchaseRequest, user_id: str = Depends(get_user_id)):
    fortune_type_key = payload.fortune_type_key
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                'SELECT id FROM fortune_types WHERE key = %s AND access_type_default = %s',
                (fortune_type_key, 'one_time'),
            )
            row = cur.fetchone()
            if not row:
                raise HTTPException(status_code=400, detail='Fortune type not purchasable')
            fortune_type_id = row[0]

            cur.execute(
                'SELECT id FROM products WHERE fortune_type_id = %s AND active = true ORDER BY id LIMIT 1',
                (fortune_type_id,),
            )
            product = cur.fetchone()
            if not product:
                raise HTTPException(status_code=404, detail='Product not found')
            product_id = product[0]

            purchase_id = str(uuid4())
            store_transaction_id = f'mock-{purchase_id}'
            cur.execute(
                'INSERT INTO purchases (id, user_id, product_id, platform, store_transaction_id, status, verified_at) VALUES (%s, %s, %s, %s, %s, %s, now())',
                (purchase_id, user_id, product_id, 'mock', store_transaction_id, 'verified'),
            )
            conn.commit()

    return {'ok': True, 'purchase_id': purchase_id}


@router.post('/verify/subscription')
def verify_subscription(payload: SubscriptionVerifyRequest, user_id: str = Depends(get_user_id)):
    platform = payload.platform
    if platform != 'android':
        raise HTTPException(status_code=400, detail='Invalid platform')

    if not payload.subscription_id:
        raise HTTPException(status_code=400, detail='Missing subscription_id')
    package_name = billing_service.resolve_google_package()
    sub = billing_service.verify_google_subscription(package_name, payload.subscription_id, payload.receipt)
    store_subscription_id = sub.get('product_id')
    period_start = sub.get('period_start')
    period_end = sub.get('period_end')
    status = sub.get('status')
    auto_renew = sub.get('auto_renewing', False)

    if not store_subscription_id or not period_start or not period_end:
        raise HTTPException(status_code=409, detail='Invalid subscription data')

    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                'INSERT INTO subscriptions (id, user_id, platform, store_subscription_id, status, current_period_start, current_period_end, auto_renew, verified_at) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, now()) ON CONFLICT (platform, store_subscription_id) DO UPDATE SET status = EXCLUDED.status, current_period_start = EXCLUDED.current_period_start, current_period_end = EXCLUDED.current_period_end, auto_renew = EXCLUDED.auto_renew, verified_at = EXCLUDED.verified_at',
                (
                    str(uuid4()),
                    user_id,
                    platform,
                    store_subscription_id,
                    status,
                    period_start,
                    period_end,
                    auto_renew,
                ),
            )
            conn.commit()

    return {'ok': True}


@router.get('/status')
def billing_status(user_id: str = Depends(get_user_id)):
    if is_admin_user(user_id):
        return {
            'subscription_active': True,
            'subscription_expires_at': None,
            'ads_disabled': True,
        }

    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                'SELECT status, current_period_end FROM subscriptions WHERE user_id = %s AND status = %s AND current_period_end > now() ORDER BY current_period_end DESC LIMIT 1',
                (user_id, 'active'),
            )
            row = cur.fetchone()

    subscription_active = bool(row)
    subscription_expires_at = row[1] if row else None

    return {
        'subscription_active': subscription_active,
        'subscription_expires_at': subscription_expires_at,
        'ads_disabled': subscription_active,
    }
