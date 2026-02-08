URLが決まったら、shop_screen.dart の url: '' を差し替える
.env に Discord の Webhook URL を追加してください。
DISCORD_WEBHOOK_URL=あなたのWebhookURL


画像置き場所: frontend/assets/cards/
ファイル名はカード名のスラッグ（英字小文字 + _）
例:
The Fool → the_fool.png
Four of Swords → four_of_swords.png


プロダクトの取得
SELECT p.id, p.product_key
FROM products p
JOIN fortune_types ft ON ft.id = p.fortune_type_id
WHERE p.platform = 'android'
LIMIT 20;

ユーザーの取得
SELECT id FROM users ORDER BY created_at DESC LIMIT 1;


買い切りのテスト
INSERT INTO purchases (id, user_id, product_id, platform, store_transaction_id, status)
VALUES (
  gen_random_uuid(),
  'd7316201-5303-42f2-8857-b63d10135c82', -- user_id 
  'e3561581-b4a9-4b69-89ca-d99741641931', -- product_id 
  'android',
  'test_txn_001',
  'verified'
);

サブスクのテスト

INSERT INTO subscriptions (
  id, user_id, platform, store_subscription_id, status,
  current_period_start, current_period_end, auto_renew
)
VALUES (
  gen_random_uuid(),
  'd7316201-5303-42f2-8857-b63d10135c82',
  'android',
  'test_sub_001',
  'active',
  now(),
  now() + interval '30 days',
  true
);

frontend
flutter run -d chrome --dart-define=DEV_USER_ID=e154d397-dff7-4780-b5c4-5aa3a3889a7d --dart-define=DEV_AUTH_TOKEN=test

backend
python -m uvicorn backend.main:app --reload --host 0.0.0.0 --port
 8000


データクリア
BEGIN;

WITH win AS (
  SELECT
    CASE
      WHEN (now() AT TIME ZONE 'Asia/Tokyo')::time < time '05:00'
      THEN (date_trunc('day', (now() AT TIME ZONE 'Asia/Tokyo') - interval '1 day')
            + interval '5 hours') AT TIME ZONE 'Asia/Tokyo'
      ELSE (date_trunc('day', (now() AT TIME ZONE 'Asia/Tokyo'))
            + interval '5 hours') AT TIME ZONE 'Asia/Tokyo'
    END AS window_start_fixed
)
DELETE FROM interpretation_versions
WHERE reading_id IN (
  SELECT r.id
  FROM readings r
  JOIN fortune_types ft ON ft.id = r.fortune_type_id
  JOIN reading_interpretations ri ON ri.reading_id = r.id
  CROSS JOIN win w
  WHERE r.user_id = 'e154d397-dff7-4780-b5c4-5aa3a3889a7d'
    AND ft.key LIKE 'today_%'
    AND ri.updated_at >= w.window_start_fixed
);

WITH win AS (
  SELECT
    CASE
      WHEN (now() AT TIME ZONE 'Asia/Tokyo')::time < time '05:00'
      THEN (date_trunc('day', (now() AT TIME ZONE 'Asia/Tokyo') - interval '1 day')
            + interval '5 hours') AT TIME ZONE 'Asia/Tokyo'
      ELSE (date_trunc('day', (now() AT TIME ZONE 'Asia/Tokyo'))
            + interval '5 hours') AT TIME ZONE 'Asia/Tokyo'
    END AS window_start_fixed
)
UPDATE reading_interpretations
SET output_text = NULL, updated_at = now()
WHERE reading_id IN (
  SELECT r.id
  FROM readings r
  JOIN fortune_types ft ON ft.id = r.fortune_type_id
  JOIN reading_interpretations ri ON ri.reading_id = r.id
  CROSS JOIN win w
  WHERE r.user_id = 'e154d397-dff7-4780-b5c4-5aa3a3889a7d'
    AND ft.key LIKE 'today_%'
    AND ri.updated_at >= w.window_start_fixed
);

COMMIT;

広告
実サービスで広告を使う際は ad_manager.dart 内のテスト用ユニットIDを本番IDに置き換えてからビルドしてください。