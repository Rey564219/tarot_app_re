def build_prompt(input_json: dict) -> str:
    if not isinstance(input_json, dict):
        return 'No input provided.'

    kind = input_json.get('type', 'reading')
    cards = input_json.get('cards', [])
    question = input_json.get('question') or ''
    context = input_json.get('context') or ''

    lines = [
        'You are a professional tarot reader.',
        'Write a concise Japanese interpretation.',
        'Tone: warm, honest, and practical.',
        'Output: 6-10 sentences, no bullet points.',
        '',
        f'Fortune type: {kind}',
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

    if question or context:
        lines.append('')
        if question:
            lines.append(f'Question: {question}')
        if context:
            lines.append(f'Context: {context}')
    lines.append('')
    lines.append('Focus on the positions (past/present/future or given labels).')
    lines.append('Avoid claiming certainty; offer guidance.')
    return '\n'.join(lines)
