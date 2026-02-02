BEGIN;

INSERT INTO fortune_types (id, key, name, access_type_default, requires_warning, description)
VALUES
  ('ccadbb01-cacb-4cce-9376-405e07f93216', 'today_free', '今日の運勢 1枚引き', 'free', false, NULL),
  ('514f3999-2a0d-46b1-a083-18186f63a868', 'today_deep_love', '今日の運勢 深掘り(恋�E)', 'subscription', false, NULL),
  ('9ee6bbdb-d864-4115-9a30-4dbc3be8ee84', 'today_deep_work', '今日の運勢 深掘り(仕亁E', 'subscription', false, NULL),
  ('38037bd0-e462-4e6a-b102-eb651dee5a60', 'today_deep_money', '今日の運勢 深掘り(金運)', 'subscription', false, NULL),
  ('1adc5555-4a7f-44f0-9475-7f8dc19f5ba8', 'today_deep_trouble', '今日の運勢 深掘り(トラブル)', 'subscription', false, NULL),
  ('171de1cc-b127-496d-9830-fae2c2cf506d', 'week_one', '今週の運勢 1枚引き', 'subscription', false, NULL),
  ('8f6330fd-1189-4730-8d34-1846f9f86e33', 'no_desc_draw', '説明なしカード引き', 'life', false, NULL),
  ('d72aebe4-5723-4621-b5c1-42fb4637903d', 'compatibility', '相手との相性占ぁE, 'free', false, NULL),
  ('ea3fc9e9-fac9-40b4-8699-e82f6511f8b4', 'hexagram_love', '悩み別ヘキサグラム(恋�E)', 'one_time', false, NULL),
  ('e2a86513-3c69-4a03-9e7d-8a81a90f0b3e', 'hexagram_reunion', '悩み別ヘキサグラム(復縁E', 'one_time', false, NULL),
  ('04e7dfcb-fdc9-435f-ae37-5012161bbf7b', 'hexagram_unreq', '悩み別ヘキサグラム(牁E��い)', 'one_time', false, NULL),
  ('a88e7f10-9afc-4d43-a15a-9d01beee2987', 'hexagram_marriage', '悩み別ヘキサグラム(結婁E', 'one_time', false, NULL),
  ('ca4a1218-d4a5-4c64-8a6d-e47f2f3a7152', 'celtic_work', '悩み別ケルト十孁E仕亁E', 'one_time', false, NULL),
  ('803fb304-fcbc-4c64-82d3-b783bdd8909b', 'celtic_startup', '悩み別ケルト十孁E起業)', 'one_time', false, NULL),
  ('35f0bac0-8aa0-46bc-9828-f06d7c3206ea', 'celtic_job', '悩み別ケルト十孁E転職)', 'one_time', false, NULL),
  ('c16ddcc1-6de2-4fe2-a4da-515638517652', 'flower_timing', '行動の時期読み(花占ぁE', 'one_time', false, NULL),
  ('99b953f1-a9c2-4c0c-9bf0-47b2fcc398d0', 'triangle_crime', '犯罪の不正のトライアングル', 'one_time', true, NULL),
  ('a01ffd76-7a5a-415a-b596-b2c8b0c5bfa5', 'partner_sexual', '相手�E性癖占ぁE, 'one_time', false, NULL)
ON CONFLICT (key) DO UPDATE SET
  name = EXCLUDED.name,
  access_type_default = EXCLUDED.access_type_default,
  requires_warning = EXCLUDED.requires_warning,
  description = EXCLUDED.description;

INSERT INTO products (id, product_key, fortune_type_id, name, price_cents, currency, platform, active)
VALUES
  ('e3561581-b4a9-4b69-89ca-d99741641931', 'p_hex_love_android', (SELECT id FROM fortune_types WHERE key = 'hexagram_love'), '悩み別ヘキサグラム(恋�E)', 980, 'JPY', 'android', true),
  ('dc0da8ed-9f25-48c7-9203-4c3a2131d6a4', 'p_hex_reunion_android', (SELECT id FROM fortune_types WHERE key = 'hexagram_reunion'), '悩み別ヘキサグラム(復縁E', 980, 'JPY', 'android', true),
  ('7a592417-29bb-4e78-bdf7-aaa3ceadadc8', 'p_hex_unreq_android', (SELECT id FROM fortune_types WHERE key = 'hexagram_unreq'), '悩み別ヘキサグラム(牁E��い)', 980, 'JPY', 'android', true),
  ('2f285447-666a-44c8-9a66-064181bf4927', 'p_hex_marriage_android', (SELECT id FROM fortune_types WHERE key = 'hexagram_marriage'), '悩み別ヘキサグラム(結婁E', 980, 'JPY', 'android', true),
  ('b6bcc43c-45ae-46dc-9c7d-56b7fc42c14a', 'p_celtic_work_android', (SELECT id FROM fortune_types WHERE key = 'celtic_work'), '悩み別ケルト十孁E仕亁E', 1200, 'JPY', 'android', true),
  ('3b60237d-48c2-4f1a-a8e1-82df363d79aa', 'p_celtic_startup_android', (SELECT id FROM fortune_types WHERE key = 'celtic_startup'), '悩み別ケルト十孁E起業)', 1200, 'JPY', 'android', true),
  ('08a4d7bb-9b9c-4667-881c-fa8791386775', 'p_celtic_job_android', (SELECT id FROM fortune_types WHERE key = 'celtic_job'), '悩み別ケルト十孁E転職)', 1200, 'JPY', 'android', true),
  ('dce445b3-8dc4-496d-8eab-64f4fa8977a8', 'p_flower_timing_android', (SELECT id FROM fortune_types WHERE key = 'flower_timing'), '行動の時期読み(花占ぁE', 800, 'JPY', 'android', true),
  ('a59b5ec0-1722-48e0-8d66-ea2dccf6f4a2', 'p_triangle_crime_android', (SELECT id FROM fortune_types WHERE key = 'triangle_crime'), '犯罪の不正のトライアングル', 1500, 'JPY', 'android', true),
  ('41b25928-e0ea-4edd-a476-7e0c8ec9743a', 'p_partner_sexual_android', (SELECT id FROM fortune_types WHERE key = 'partner_sexual'), '相手�E性癖占ぁE, 900, 'JPY', 'android', true)
ON CONFLICT (product_key) DO UPDATE SET
  fortune_type_id = EXCLUDED.fortune_type_id,
  name = EXCLUDED.name,
  price_cents = EXCLUDED.price_cents,
  currency = EXCLUDED.currency,
  platform = EXCLUDED.platform,
  active = EXCLUDED.active;

COMMIT;
