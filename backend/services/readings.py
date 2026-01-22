import hashlib
import random
from datetime import datetime, timezone

MAJOR_ARCANA = [
    'The Fool',
    'The Magician',
    'The High Priestess',
    'The Empress',
    'The Emperor',
    'The Hierophant',
    'The Lovers',
    'The Chariot',
    'Strength',
    'The Hermit',
    'Wheel of Fortune',
    'Justice',
    'The Hanged Man',
    'Death',
    'Temperance',
    'The Devil',
    'The Tower',
    'The Star',
    'The Moon',
    'The Sun',
    'Judgement',
    'The World',
]

MINOR_SUITS = ['Wands', 'Cups', 'Swords', 'Pentacles']
MINOR_RANKS = [
    'Ace',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
    'Ten',
    'Page',
    'Knight',
    'Queen',
    'King',
]

MAJOR_DECK = [{'name': name, 'arcana': 'major'} for name in MAJOR_ARCANA]
MINOR_DECK = [
    {'name': f'{rank} of {suit}', 'arcana': 'minor', 'suit': suit, 'rank': rank}
    for suit in MINOR_SUITS
    for rank in MINOR_RANKS
]
FULL_DECK = MAJOR_DECK + MINOR_DECK


def _seed_to_int(seed: str) -> int:
    digest = hashlib.sha256(seed.encode('utf-8')).hexdigest()
    return int(digest[:16], 16)


def build_seed(user_id: str, fortune_type_key: str, date_str: str | None = None) -> str:
    if date_str is None:
        date_str = datetime.now(timezone.utc).strftime('%Y-%m-%d')

    base_key = fortune_type_key
    if fortune_type_key.startswith('today_deep_'):
        base_key = 'today_free'
    return f'{user_id}:{date_str}:{base_key}'


def generate_reading(user_id: str, fortune_type_key: str, input_json: dict | None = None) -> dict:
    base_seed = build_seed(user_id, fortune_type_key)
    base_rng = random.Random(_seed_to_int(base_seed))

    if fortune_type_key.startswith('hexagram_'):
        cards = _draw_cards(base_rng, 7, major_only=False)
        return {
            'type': 'hexagram',
            'cards': cards,
            'seed': base_seed,
        }

    if fortune_type_key.startswith('celtic_'):
        cards = _draw_cards(base_rng, 10, major_only=False)
        return {
            'type': 'celtic_cross',
            'cards': cards,
            'seed': base_seed,
        }

    if fortune_type_key == 'flower_timing':
        cards = _draw_cards(base_rng, 12, major_only=True)
        return {
            'type': 'flower_timing',
            'cards': cards,
            'seed': base_seed,
        }

    if fortune_type_key == 'triangle_crime':
        cards = _draw_cards(base_rng, 3, major_only=False)
        return {
            'type': 'triangle_warning',
            'cards': cards,
            'seed': base_seed,
        }

    if fortune_type_key == 'no_desc_draw':
        cards = _draw_cards(base_rng, 2, major_only=False)
        return {
            'type': 'no_desc_draw',
            'cards': cards,
            'seed': base_seed,
        }

    if fortune_type_key == 'compatibility':
        cards = _draw_cards(base_rng, 3, major_only=False)
        return {
            'type': 'compatibility',
            'cards': cards,
            'seed': base_seed,
            'input': input_json or {},
        }

    if fortune_type_key.startswith('today_deep_'):
        deep_seed = f'{base_seed}:{fortune_type_key}'
        deep_rng = random.Random(_seed_to_int(deep_seed))
        base_card = _draw_cards(base_rng, 1, major_only=False)[0]
        extra_cards = _draw_cards(deep_rng, 4, major_only=False, exclude_names={base_card['name']})
        return {
            'type': 'today_deep',
            'base_card': base_card,
            'extra_cards': extra_cards,
            'seed': base_seed,
            'deep_seed': deep_seed,
        }

    if fortune_type_key == 'today_free':
        cards = _draw_cards(base_rng, 1, major_only=False)
        return {
            'type': 'today_free',
            'cards': cards,
            'seed': base_seed,
        }

    if fortune_type_key == 'week_one':
        cards = _draw_cards(base_rng, 5, major_only=False)
        return {
            'type': 'week_one',
            'cards': cards,
            'seed': base_seed,
        }

    if fortune_type_key == 'partner_sexual':
        cards = _draw_cards(base_rng, 3, major_only=False)
        return {
            'type': 'partner_sexual',
            'cards': cards,
            'seed': base_seed,
        }

    cards = _draw_cards(base_rng, 1, major_only=False)
    return {
        'type': 'single_draw',
        'cards': cards,
        'seed': base_seed,
    }


def _draw_cards(
    rng: random.Random,
    count: int,
    major_only: bool,
    exclude_names: set[str] | None = None,
) -> list[dict]:
    deck = MAJOR_DECK if major_only else FULL_DECK
    if exclude_names:
        available = [card for card in deck if card['name'] not in exclude_names]
    else:
        available = deck

    if count > len(available):
        raise ValueError('Requested more cards than available in deck')

    indices = rng.sample(range(len(available)), count)
    cards = []
    for idx in indices:
        base = available[idx]
        cards.append(
            {
                'name': base['name'],
                'arcana': base['arcana'],
                'suit': base.get('suit'),
                'rank': base.get('rank'),
                'upright': rng.choice([True, False]),
            }
        )
    return cards
