BEGIN;

INSERT INTO card_catalog (name, arcana, suit, rank)
VALUES
  ('The Fool', 'major', NULL, NULL),
  ('The Magician', 'major', NULL, NULL),
  ('The High Priestess', 'major', NULL, NULL),
  ('The Empress', 'major', NULL, NULL),
  ('The Emperor', 'major', NULL, NULL),
  ('The Hierophant', 'major', NULL, NULL),
  ('The Lovers', 'major', NULL, NULL),
  ('The Chariot', 'major', NULL, NULL),
  ('Strength', 'major', NULL, NULL),
  ('The Hermit', 'major', NULL, NULL),
  ('Wheel of Fortune', 'major', NULL, NULL),
  ('Justice', 'major', NULL, NULL),
  ('The Hanged Man', 'major', NULL, NULL),
  ('Death', 'major', NULL, NULL),
  ('Temperance', 'major', NULL, NULL),
  ('The Devil', 'major', NULL, NULL),
  ('The Tower', 'major', NULL, NULL),
  ('The Star', 'major', NULL, NULL),
  ('The Moon', 'major', NULL, NULL),
  ('The Sun', 'major', NULL, NULL),
  ('Judgement', 'major', NULL, NULL),
  ('The World', 'major', NULL, NULL),
  ('Ace of Wands', 'minor', 'Wands', 'Ace'),
  ('Two of Wands', 'minor', 'Wands', 'Two'),
  ('Three of Wands', 'minor', 'Wands', 'Three'),
  ('Four of Wands', 'minor', 'Wands', 'Four'),
  ('Five of Wands', 'minor', 'Wands', 'Five'),
  ('Six of Wands', 'minor', 'Wands', 'Six'),
  ('Seven of Wands', 'minor', 'Wands', 'Seven'),
  ('Eight of Wands', 'minor', 'Wands', 'Eight'),
  ('Nine of Wands', 'minor', 'Wands', 'Nine'),
  ('Ten of Wands', 'minor', 'Wands', 'Ten'),
  ('Page of Wands', 'minor', 'Wands', 'Page'),
  ('Knight of Wands', 'minor', 'Wands', 'Knight'),
  ('Queen of Wands', 'minor', 'Wands', 'Queen'),
  ('King of Wands', 'minor', 'Wands', 'King'),
  ('Ace of Cups', 'minor', 'Cups', 'Ace'),
  ('Two of Cups', 'minor', 'Cups', 'Two'),
  ('Three of Cups', 'minor', 'Cups', 'Three'),
  ('Four of Cups', 'minor', 'Cups', 'Four'),
  ('Five of Cups', 'minor', 'Cups', 'Five'),
  ('Six of Cups', 'minor', 'Cups', 'Six'),
  ('Seven of Cups', 'minor', 'Cups', 'Seven'),
  ('Eight of Cups', 'minor', 'Cups', 'Eight'),
  ('Nine of Cups', 'minor', 'Cups', 'Nine'),
  ('Ten of Cups', 'minor', 'Cups', 'Ten'),
  ('Page of Cups', 'minor', 'Cups', 'Page'),
  ('Knight of Cups', 'minor', 'Cups', 'Knight'),
  ('Queen of Cups', 'minor', 'Cups', 'Queen'),
  ('King of Cups', 'minor', 'Cups', 'King'),
  ('Ace of Swords', 'minor', 'Swords', 'Ace'),
  ('Two of Swords', 'minor', 'Swords', 'Two'),
  ('Three of Swords', 'minor', 'Swords', 'Three'),
  ('Four of Swords', 'minor', 'Swords', 'Four'),
  ('Five of Swords', 'minor', 'Swords', 'Five'),
  ('Six of Swords', 'minor', 'Swords', 'Six'),
  ('Seven of Swords', 'minor', 'Swords', 'Seven'),
  ('Eight of Swords', 'minor', 'Swords', 'Eight'),
  ('Nine of Swords', 'minor', 'Swords', 'Nine'),
  ('Ten of Swords', 'minor', 'Swords', 'Ten'),
  ('Page of Swords', 'minor', 'Swords', 'Page'),
  ('Knight of Swords', 'minor', 'Swords', 'Knight'),
  ('Queen of Swords', 'minor', 'Swords', 'Queen'),
  ('King of Swords', 'minor', 'Swords', 'King'),
  ('Ace of Pentacles', 'minor', 'Pentacles', 'Ace'),
  ('Two of Pentacles', 'minor', 'Pentacles', 'Two'),
  ('Three of Pentacles', 'minor', 'Pentacles', 'Three'),
  ('Four of Pentacles', 'minor', 'Pentacles', 'Four'),
  ('Five of Pentacles', 'minor', 'Pentacles', 'Five'),
  ('Six of Pentacles', 'minor', 'Pentacles', 'Six'),
  ('Seven of Pentacles', 'minor', 'Pentacles', 'Seven'),
  ('Eight of Pentacles', 'minor', 'Pentacles', 'Eight'),
  ('Nine of Pentacles', 'minor', 'Pentacles', 'Nine'),
  ('Ten of Pentacles', 'minor', 'Pentacles', 'Ten'),
  ('Page of Pentacles', 'minor', 'Pentacles', 'Page'),
  ('Knight of Pentacles', 'minor', 'Pentacles', 'Knight'),
  ('Queen of Pentacles', 'minor', 'Pentacles', 'Queen'),
  ('King of Pentacles', 'minor', 'Pentacles', 'King')
ON CONFLICT (name) DO NOTHING;

INSERT INTO fortune_spreads (fortune_type_id, name)
SELECT id, name
FROM fortune_types
WHERE key IN (
  'today_free',
  'today_deep_love',
  'today_deep_work',
  'today_deep_money',
  'today_deep_trouble',
  'week_one',
  'compatibility',
  'no_desc_draw',
  'hexagram_love',
  'hexagram_reunion',
  'hexagram_unreq',
  'hexagram_marriage',
  'celtic_work',
  'celtic_startup',
  'celtic_job',
  'flower_timing',
  'triangle_crime',
  'partner_sexual'
)
ON CONFLICT DO NOTHING;

WITH spreads AS (
  SELECT fs.id, ft.key
  FROM fortune_spreads fs
  JOIN fortune_types ft ON ft.id = fs.fortune_type_id
)
INSERT INTO fortune_spread_slots (spread_id, slot_index, position_label)
SELECT id, slot_index, position_label
FROM (
  SELECT id, 1 AS slot_index, '今日' AS position_label FROM spreads WHERE key = 'today_free'
  UNION ALL SELECT id, 1, '恋愛' FROM spreads WHERE key = 'today_deep_love'
  UNION ALL SELECT id, 1, '仕事' FROM spreads WHERE key = 'today_deep_work'
  UNION ALL SELECT id, 1, '金運' FROM spreads WHERE key = 'today_deep_money'
  UNION ALL SELECT id, 1, 'トラブル' FROM spreads WHERE key = 'today_deep_trouble'
  UNION ALL SELECT id, 1, '総合' FROM spreads WHERE key = 'week_one'
  UNION ALL SELECT id, 2, '恋愛' FROM spreads WHERE key = 'week_one'
  UNION ALL SELECT id, 3, '仕事' FROM spreads WHERE key = 'week_one'
  UNION ALL SELECT id, 4, '金運' FROM spreads WHERE key = 'week_one'
  UNION ALL SELECT id, 5, 'トラブル' FROM spreads WHERE key = 'week_one'
  UNION ALL SELECT id, 1, 'あなた' FROM spreads WHERE key = 'compatibility'
  UNION ALL SELECT id, 2, '相手' FROM spreads WHERE key = 'compatibility'
  UNION ALL SELECT id, 3, '二人の未来' FROM spreads WHERE key = 'compatibility'
  UNION ALL SELECT id, 1, 'カード1' FROM spreads WHERE key = 'no_desc_draw'
  UNION ALL SELECT id, 2, 'カード2' FROM spreads WHERE key = 'no_desc_draw'
  UNION ALL SELECT id, 1, '1' FROM spreads WHERE key IN ('hexagram_love','hexagram_reunion','hexagram_unreq','hexagram_marriage')
  UNION ALL SELECT id, 2, '2' FROM spreads WHERE key IN ('hexagram_love','hexagram_reunion','hexagram_unreq','hexagram_marriage')
  UNION ALL SELECT id, 3, '3' FROM spreads WHERE key IN ('hexagram_love','hexagram_reunion','hexagram_unreq','hexagram_marriage')
  UNION ALL SELECT id, 4, '4' FROM spreads WHERE key IN ('hexagram_love','hexagram_reunion','hexagram_unreq','hexagram_marriage')
  UNION ALL SELECT id, 5, '5' FROM spreads WHERE key IN ('hexagram_love','hexagram_reunion','hexagram_unreq','hexagram_marriage')
  UNION ALL SELECT id, 6, '6' FROM spreads WHERE key IN ('hexagram_love','hexagram_reunion','hexagram_unreq','hexagram_marriage')
  UNION ALL SELECT id, 7, '7' FROM spreads WHERE key IN ('hexagram_love','hexagram_reunion','hexagram_unreq','hexagram_marriage')
  UNION ALL SELECT id, 1, '現在' FROM spreads WHERE key IN ('celtic_work','celtic_startup','celtic_job')
  UNION ALL SELECT id, 2, '課題' FROM spreads WHERE key IN ('celtic_work','celtic_startup','celtic_job')
  UNION ALL SELECT id, 3, '過去' FROM spreads WHERE key IN ('celtic_work','celtic_startup','celtic_job')
  UNION ALL SELECT id, 4, '未来' FROM spreads WHERE key IN ('celtic_work','celtic_startup','celtic_job')
  UNION ALL SELECT id, 5, '顕在意識' FROM spreads WHERE key IN ('celtic_work','celtic_startup','celtic_job')
  UNION ALL SELECT id, 6, '潜在意識' FROM spreads WHERE key IN ('celtic_work','celtic_startup','celtic_job')
  UNION ALL SELECT id, 7, '自分' FROM spreads WHERE key IN ('celtic_work','celtic_startup','celtic_job')
  UNION ALL SELECT id, 8, '周囲' FROM spreads WHERE key IN ('celtic_work','celtic_startup','celtic_job')
  UNION ALL SELECT id, 9, '願望' FROM spreads WHERE key IN ('celtic_work','celtic_startup','celtic_job')
  UNION ALL SELECT id, 10, '結果' FROM spreads WHERE key IN ('celtic_work','celtic_startup','celtic_job')
  UNION ALL SELECT id, 1, '1' FROM spreads WHERE key = 'flower_timing'
  UNION ALL SELECT id, 2, '2' FROM spreads WHERE key = 'flower_timing'
  UNION ALL SELECT id, 3, '3' FROM spreads WHERE key = 'flower_timing'
  UNION ALL SELECT id, 4, '4' FROM spreads WHERE key = 'flower_timing'
  UNION ALL SELECT id, 5, '5' FROM spreads WHERE key = 'flower_timing'
  UNION ALL SELECT id, 6, '6' FROM spreads WHERE key = 'flower_timing'
  UNION ALL SELECT id, 7, '7' FROM spreads WHERE key = 'flower_timing'
  UNION ALL SELECT id, 8, '8' FROM spreads WHERE key = 'flower_timing'
  UNION ALL SELECT id, 9, '9' FROM spreads WHERE key = 'flower_timing'
  UNION ALL SELECT id, 10, '10' FROM spreads WHERE key = 'flower_timing'
  UNION ALL SELECT id, 11, '11' FROM spreads WHERE key = 'flower_timing'
  UNION ALL SELECT id, 12, '12' FROM spreads WHERE key = 'flower_timing'
  UNION ALL SELECT id, 1, '状況' FROM spreads WHERE key = 'triangle_crime'
  UNION ALL SELECT id, 2, '関係性' FROM spreads WHERE key = 'triangle_crime'
  UNION ALL SELECT id, 3, '注意点' FROM spreads WHERE key = 'triangle_crime'
  UNION ALL SELECT id, 1, '表面' FROM spreads WHERE key = 'partner_sexual'
  UNION ALL SELECT id, 2, '深層' FROM spreads WHERE key = 'partner_sexual'
  UNION ALL SELECT id, 3, '相性' FROM spreads WHERE key = 'partner_sexual'
) AS rows
ON CONFLICT DO NOTHING;

COMMIT;
