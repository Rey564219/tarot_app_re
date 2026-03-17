from __future__ import annotations

from dataclasses import dataclass


SM_RATIO_TABLE: dict[tuple[int, int], tuple[int, int, str]] = {
    (7, 0): (100, 0, '完全S'),
    (6, 1): (86, 14, 'かなりS'),
    (5, 2): (71, 29, 'ややS'),
    (4, 3): (57, 43, 'S寄りバランス'),
    (3, 4): (43, 57, 'M寄りバランス'),
    (2, 5): (29, 71, 'ややM'),
    (1, 6): (14, 86, 'かなりM'),
    (0, 7): (0, 100, '完全M'),
}

RANK_ORDER = {
    '1': 1,
    '2': 2,
    '3': 3,
    '4': 4,
    '5': 5,
    '6': 6,
    '7': 7,
    '8': 8,
    '9': 9,
    '10': 10,
    'J': 11,
    'Q': 12,
    'K': 13,
    'Joker': 99,
}

CARD_MAP: dict[tuple[str, str], dict[str, str]] = {
    ('Spade', 'K'): {'category': '拘束', 'theme': '緊縛(吊り)'},
    ('Club', 'K'): {'category': '拘束', 'theme': '緊縛(床縄)'},
    ('Diamond', 'K'): {'category': '拘束', 'theme': '磔・固定'},
    ('Harts', 'K'): {'category': '拘束', 'theme': '拘束具'},
    ('Spade', 'Q'): {'category': '鞭', 'theme': '一本鞭'},
    ('Club', 'Q'): {'category': '鞭', 'theme': 'パドル・打具'},
    ('Diamond', 'Q'): {'category': '鞭', 'theme': 'ケイン'},
    ('Harts', 'Q'): {'category': '鞭', 'theme': 'バラ鞭'},
    ('Spade', 'J'): {'category': '蝋燭・武器', 'theme': '針・刃物'},
    ('Club', 'J'): {'category': '蝋燭・武器', 'theme': '電気'},
    ('Diamond', 'J'): {'category': '蝋燭・武器', 'theme': '蝋燭'},
    ('Harts', 'J'): {'category': '蝋燭・武器', 'theme': '洗濯ばさみ'},
    ('Spade', '10'): {'category': '殴打・暴力', 'theme': '噛みつき'},
    ('Club', '10'): {'category': '殴打・暴力', 'theme': 'ビンタ'},
    ('Diamond', '10'): {'category': '殴打・暴力', 'theme': '腹パン'},
    ('Harts', '10'): {'category': '殴打・暴力', 'theme': 'スパンキング'},
    ('Spade', '9'): {'category': '窒息系', 'theme': '呼吸管理'},
    ('Club', '9'): {'category': '窒息系', 'theme': '全頭マスク'},
    ('Diamond', '9'): {'category': '窒息系', 'theme': '首絞め'},
    ('Harts', '9'): {'category': '窒息系', 'theme': '顔面騎乗'},
    ('Spade', '8'): {'category': '拷問系', 'theme': '拷問'},
    ('Club', '8'): {'category': '拷問系', 'theme': '三角木馬'},
    ('Diamond', '8'): {'category': '拷問系', 'theme': '股間蹴り'},
    ('Harts', '8'): {'category': '拷問系', 'theme': '水責め'},
    ('Spade', '7'): {'category': '排泄系', 'theme': '塗糞食糞'},
    ('Club', '7'): {'category': '排泄系', 'theme': '浣腸'},
    ('Diamond', '7'): {'category': '排泄系', 'theme': '浴尿飲尿'},
    ('Harts', '7'): {'category': '排泄系', 'theme': '尿抑制(おしがま)'},
    ('Spade', '6'): {'category': 'フェチ', 'theme': 'バキューム・ラバー'},
    ('Club', '6'): {'category': 'フェチ', 'theme': 'ウェット&メッシー'},
    ('Diamond', '6'): {'category': 'フェチ', 'theme': '幼児'},
    ('Harts', '6'): {'category': 'フェチ', 'theme': '異性装'},
    ('Spade', '5'): {'category': 'アブノーマル', 'theme': '尿道'},
    ('Club', '5'): {'category': 'アブノーマル', 'theme': '喉姦・嘔吐'},
    ('Diamond', '5'): {'category': 'アブノーマル', 'theme': 'アナル'},
    ('Harts', '5'): {'category': 'アブノーマル', 'theme': '脳イキ・連続イキ'},
    ('Spade', '4'): {'category': 'くすぐり・言葉', 'theme': 'くすぐり'},
    ('Club', '4'): {'category': 'くすぐり・言葉', 'theme': '愛撫'},
    ('Diamond', '4'): {'category': 'くすぐり・言葉', 'theme': '言葉責め'},
    ('Harts', '4'): {'category': 'くすぐり・言葉', 'theme': '催眠'},
    ('Spade', '3'): {'category': '羞恥系', 'theme': '露出'},
    ('Club', '3'): {'category': '羞恥系', 'theme': 'CMNF・CFNM'},
    ('Diamond', '3'): {'category': '羞恥系', 'theme': '落書き'},
    ('Harts', '3'): {'category': '羞恥系', 'theme': '鼻フック'},
    ('Spade', '2'): {'category': '屈辱系', 'theme': '足舐め・靴舐め'},
    ('Club', '2'): {'category': '屈辱系', 'theme': '顔踏み'},
    ('Diamond', '2'): {'category': '屈辱系', 'theme': '人間家具'},
    ('Harts', '2'): {'category': '屈辱系', 'theme': 'ヒトイス'},
    ('Spade', '1'): {'category': '主従関係', 'theme': '奴隷'},
    ('Club', '1'): {'category': '主従関係', 'theme': '玩具'},
    ('Diamond', '1'): {'category': '主従関係', 'theme': '主従'},
    ('Harts', '1'): {'category': '主従関係', 'theme': 'ペット'},
    ('Joker', 'Joker'): {'category': 'Joker', 'theme': '規格外・増幅'},
}


@dataclass
class SideCounts:
    s: int = 0
    m: int = 0

    @property
    def dominant(self) -> str:
        if self.s > self.m:
            return 'S'
        if self.m > self.s:
            return 'M'
        return 'balanced'


def build_partner_sexual_deck() -> list[dict]:
    deck: list[dict] = []
    for suit in ['Spade', 'Club', 'Diamond', 'Harts']:
        for rank in ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K']:
            asset = f'{suit.lower()}_{rank}' if suit == 'Spade' else f'{suit}_{rank}'
            deck.append(
                {
                    'name': f'{suit} {rank}',
                    'arcana': 'trump',
                    'suit': suit,
                    'rank': rank,
                    'asset_name': asset,
                }
            )
    deck.append(
        {
            'name': 'Joker 1',
            'arcana': 'trump',
            'suit': 'Joker',
            'rank': 'Joker',
            'asset_name': 'Joker_1',
        }
    )
    deck.append(
        {
            'name': 'Joker 2',
            'arcana': 'trump',
            'suit': 'Joker',
            'rank': 'Joker',
            'asset_name': 'Joker_2',
        }
    )
    return deck


def get_partner_card_meaning(card: dict) -> dict:
    suit = card.get('suit')
    rank = str(card.get('rank') or '')
    mapped = CARD_MAP.get((suit, rank))
    if not mapped:
        return {'short_meaning': '分類外', 'keywords': []}
    return {
        'short_meaning': f"{mapped['category']} / {mapped['theme']}",
        'keywords': [mapped['category'], mapped['theme']],
    }


def build_partner_profile(cards: list[dict]) -> dict:
    s_count = sum(1 for card in cards if card.get('upright') is True)
    m_count = sum(1 for card in cards if card.get('upright') is False)

    base_s, base_m, balance_label = SM_RATIO_TABLE[(s_count, m_count)]
    dominant_attr = 'S' if s_count >= m_count else 'M'
    dominant_cards = [card for card in cards if _to_attr(card) == dominant_attr]
    tendency_card = dominant_cards[len(dominant_cards) // 2] if dominant_cards else None

    center_card = cards[len(cards) // 2] if cards else None
    joker_boost_target = None
    if tendency_card and _is_joker(tendency_card):
        joker_boost_target = dominant_attr
    elif center_card and _is_joker(center_card):
        joker_boost_target = _to_attr(center_card)

    s_percent, m_percent = _apply_joker_boost(base_s, base_m, joker_boost_target)
    left_counts = _count_sides(cards[:3])
    right_counts = _count_sides(cards[4:7])
    switcher = left_counts.dominant in ('S', 'M') and right_counts.dominant in ('S', 'M') and left_counts.dominant != right_counts.dominant
    tendency = _build_tendency(tendency_card)
    numeric_traits = _build_numeric_traits(cards, s_count, m_count, s_percent, m_percent)

    return {
        's_count': s_count,
        'm_count': m_count,
        's_percent': s_percent,
        'm_percent': m_percent,
        'balance_label': balance_label,
        'dominant_attribute': dominant_attr,
        'tendency': tendency,
        'tendency_card': _card_summary(tendency_card),
        'center_card': _card_summary(center_card),
        'joker_boost_applied': joker_boost_target is not None,
        'joker_boost_target': joker_boost_target,
        'numeric_traits': numeric_traits,
        'switcher': {
            'detected': switcher,
            'left': {'s': left_counts.s, 'm': left_counts.m, 'dominant': left_counts.dominant},
            'right': {'s': right_counts.s, 'm': right_counts.m, 'dominant': right_counts.dominant},
        },
    }


def _build_numeric_traits(
    cards: list[dict],
    s_count: int,
    m_count: int,
    s_percent: int,
    m_percent: int,
) -> dict:
    total = len(cards) if cards else 0
    suit_counts = {key: 0 for key in ['Spade', 'Club', 'Diamond', 'Harts', 'Joker']}
    rank_band_counts = {'low': 0, 'mid': 0, 'high': 0, 'joker': 0}

    for card in cards:
        suit = str(card.get('suit') or '')
        rank = str(card.get('rank') or '')
        if suit in suit_counts:
            suit_counts[suit] += 1
        if rank == 'Joker':
            rank_band_counts['joker'] += 1
            continue
        rank_num = RANK_ORDER.get(rank, 0)
        if 1 <= rank_num <= 6:
            rank_band_counts['low'] += 1
        elif 7 <= rank_num <= 10:
            rank_band_counts['mid'] += 1
        elif 11 <= rank_num <= 13:
            rank_band_counts['high'] += 1

    return {
        'total_cards': total,
        'polarity_index': s_percent - m_percent,
        'imbalance_count': abs(s_count - m_count),
        'suit_counts': suit_counts,
        'rank_band_counts': rank_band_counts,
    }


def _to_attr(card: dict) -> str:
    return 'S' if card.get('upright') is True else 'M'


def _is_joker(card: dict | None) -> bool:
    if not card:
        return False
    return card.get('suit') == 'Joker' or str(card.get('rank') or '').lower() == 'joker'


def _apply_joker_boost(s_percent: int, m_percent: int, target: str | None) -> tuple[int, int]:
    if target == 'S':
        return min(100, s_percent + 5), max(0, m_percent - 5)
    if target == 'M':
        return max(0, s_percent - 5), min(100, m_percent + 5)
    return s_percent, m_percent


def _count_sides(side_cards: list[dict]) -> SideCounts:
    counts = SideCounts()
    for card in side_cards:
        if card.get('upright') is True:
            counts.s += 1
        elif card.get('upright') is False:
            counts.m += 1
    return counts


def _build_tendency(card: dict | None) -> dict | None:
    if not card:
        return None
    suit = card.get('suit')
    rank = str(card.get('rank') or '')
    mapped = CARD_MAP.get((suit, rank))
    if not mapped:
        return None
    return {
        'category': mapped['category'],
        'theme': mapped['theme'],
        'attribute': _to_attr(card),
        'card': _card_summary(card),
    }


def _card_summary(card: dict | None) -> dict | None:
    if not card:
        return None
    return {
        'name': card.get('name'),
        'suit': card.get('suit'),
        'rank': card.get('rank'),
        'upright': card.get('upright'),
        'attribute': _to_attr(card),
        'index_rank': RANK_ORDER.get(str(card.get('rank') or ''), 0),
    }
