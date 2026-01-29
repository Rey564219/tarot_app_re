FORTUNE_PROMPT_HINTS = {
    'today_free': '今日の運勢として、全体の流れと1日の過ごし方に焦点を当てる。',
    'today_deep_love': '今日の恋愛運として、相手との距離感や行動のヒントに焦点を当てる。',
    'today_deep_work': '今日の仕事運として、仕事の進め方や注意点に焦点を当てる。',
    'today_deep_money': '今日の金運として、支出・収入のバランスと行動の指針に焦点を当てる。',
    'today_deep_trouble': '今日のトラブル運として、回避策と心構えに焦点を当てる。',
    'week_one': '今週の運勢として、序盤から終盤の流れと対策に焦点を当てる。',
    'no_desc_draw': 'カードから読み取れるテーマのみを簡潔に示す。',
    'compatibility': '相性占いとして、関係性の強みと改善点に焦点を当てる。',
    'hexagram_love': '恋愛の悩みに対する指針と注意点に焦点を当てる。',
    'hexagram_reunion': '復縁の可能性や取るべき行動に焦点を当てる。',
    'hexagram_unreq': '片思いの進め方と距離の取り方に焦点を当てる。',
    'hexagram_marriage': '結婚に向けた現実的な視点と心構えに焦点を当てる。',
    'celtic_work': '仕事の現状・障害・結果の流れを明確にする。',
    'celtic_startup': '起業のリスクとチャンス、具体的な一歩に焦点を当てる。',
    'celtic_job': '転職のタイミングと準備、選択の軸に焦点を当てる。',
    'flower_timing': '行動の最適な時期と注意点に焦点を当てる。',
    'triangle_crime': '警戒すべき点と回避のための行動に焦点を当てる。',
    'partner_sexual': '相手の性的傾向の見立てと、関係性への影響に焦点を当てる。',
}

FORTUNE_QUESTION_TEXT = {
    'today_free': '今日の運勢',
    'today_deep_love': '今日の恋愛運',
    'today_deep_work': '今日の仕事運',
    'today_deep_money': '今日の金運',
    'today_deep_trouble': '今日のトラブル運',
    'week_one': '今週の運勢',
    'no_desc_draw': 'カードの示すテーマ',
    'compatibility': '相性占い',
    'hexagram_love': '恋愛の悩み',
    'hexagram_reunion': '復縁の悩み',
    'hexagram_unreq': '片思いの悩み',
    'hexagram_marriage': '結婚の悩み',
    'celtic_work': '仕事の悩み',
    'celtic_startup': '起業の悩み',
    'celtic_job': '転職の悩み',
    'flower_timing': '行動の時期',
    'triangle_crime': '警戒すべき点',
    'partner_sexual': '相手の性的傾向',
}

TYPE_FALLBACK_HINTS = {
    'today_deep': '今日の運勢の深掘りとして、具体的な行動のヒントに焦点を当てる。',
    'today_free': '今日の運勢として、全体の流れと1日の過ごし方に焦点を当てる。',
    'week_one': '今週の運勢として、序盤から終盤の流れと対策に焦点を当てる。',
    'compatibility': '相性占いとして、関係性の強みと改善点に焦点を当てる。',
    'hexagram': '悩みに対する指針と注意点に焦点を当てる。',
    'celtic_cross': '現状・障害・結果の流れを明確にする。',
    'flower_timing': '行動の最適な時期と注意点に焦点を当てる。',
    'triangle_warning': '警戒すべき点と回避のための行動に焦点を当てる。',
    'partner_sexual': '相手の性的傾向の見立てと、関係性への影響に焦点を当てる。',
}


def build_prompt(input_json: dict) -> str:
    if not isinstance(input_json, dict):
        return 'No input provided.'

    kind = input_json.get('type', 'reading')
    fortune_key = input_json.get('fortune_type_key') or ''
    cards = input_json.get('cards', [])
    question = input_json.get('question') or ''
    context = input_json.get('context') or ''
    hint = FORTUNE_PROMPT_HINTS.get(fortune_key) or TYPE_FALLBACK_HINTS.get(kind) or 'カードの配置に沿って簡潔に解釈する。'
    default_question = FORTUNE_QUESTION_TEXT.get(fortune_key) or ''

    lines = [
        'You are a professional tarot reader.',
        'Write a concise Japanese interpretation.',
        'Tone: warm, honest, and practical.',
        'Output: 6-10 sentences, no bullet points.',
        '',
        f'Fortune type: {kind}',
        f'Fortune key: {fortune_key}' if fortune_key else 'Fortune key: -',
        f'Focus: {hint}',
        'Cards:',
    ]

    for card in cards:
        if not isinstance(card, dict):
            continue
        pos = card.get('position', '')
        name = card.get('card_name', '')
        meaning = card.get('meaning_short') or ''
        keywords = card.get('keywords') or []
        upright = card.get('upright')
        orient = 'upright' if upright is True else 'reversed' if upright is False else 'neutral'
        keyword_text = ', '.join(keywords)
        lines.append(f'- {pos}: {name} ({orient}) | {meaning} | {keyword_text}')

    if question or context or default_question:
        lines.append('')
        if question:
            lines.append(f'Question: {question}')
        elif default_question:
            lines.append(f'Question: {default_question}')
        if context:
            lines.append(f'Context: {context}')
    lines.append('')
    lines.append('Focus on the positions (past/present/future or given labels).')
    lines.append('Avoid claiming certainty; offer guidance.')
    return '\n'.join(lines)
