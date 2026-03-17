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
    'triangle_crime': '犯罪者である相手について、意図・機会・自己正当化の傾向を見たい',
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
    unit = input_json.get('unit')
    sexual_profile = input_json.get('sexual_profile') if isinstance(input_json.get('sexual_profile'), dict) else None
    hint = FORTUNE_PROMPT_HINTS.get(fortune_key) or TYPE_FALLBACK_HINTS.get(kind) or 'カードの配置に沿って簡潔に解釈する。'
    default_question = FORTUNE_QUESTION_TEXT.get(fortune_key) or ''

    is_today = fortune_key.startswith('today_')
    is_today_deep = fortune_key.startswith('today_deep_') or kind == 'today_deep'
    lines = [
        'You are a professional tarot reader.',
        'Write a concrete and direct Japanese interpretation.',
        'Tone: warm, honest, and practical.',
        'Avoid vague language; be specific and actionable.',
        'Use consistent sentence style (desu/masu).',
        'When mentioning any tarot card, copy the exact English card name shown in the Cards section (e.g., "Knight of Cups"). Do not translate or alter card names.',
    ]

    if fortune_key == 'flower_timing':
        unit_label = {
            'day': '1日',
            'week': '1週間',
            'month': '1か月',
            'year': '1年',
        }.get(unit or 'month', '1か月')
        lines.extend(
            [
                'This is a flower timing reading with 12 positions.',
                f'Time unit: {unit_label}.',
                'Interpret as N units from now (e.g., 3 months later), not calendar months or specific dates.',
                'Rule: The Fool indicates the lucky timing. If The Fool does not appear, there is no timing.',
                'Output format (exact labels, no bullets):',
                f'ラッキータイミング: 〇{unit_label}後',
                '理由: ...',
                '結論: ...',
                'If no The Fool, set ラッキータイミング to "該当なし" and explain that there is no timing.',
            ]
        )
    elif is_today_deep:
        lines.extend(
            [
                'Output format (exact labels, no bullets):',
                '# 今日の総合運',
                '結果: ...',
                'アドバイス: ...',
                '結論: ...',
                '# 今日の恋愛運',
                '結果: ...',
                'アドバイス: ...',
                '結論: ...',
                '# 今日の仕事運',
                '結果: ...',
                'アドバイス: ...',
                '結論: ...',
                '# 今日の金運',
                '結果: ...',
                'アドバイス: ...',
                '結論: ...',
                '# 今日のトラブル運',
                '結果: ...',
                'アドバイス: ...',
                '結論: ...',
                'Each line should be 1-3 sentences.',
                'Use the base card for 総合運, and the labeled positions for the other categories.',
            ]
        )
    elif is_today:
        lines.extend(
            [
                'Output format (exact labels, no bullets):',
                '結果: ...',
                'アドバイス: ...',
                '結論: ...',
                'Each line should be 1-3 sentences.',
            ]
        )
    elif fortune_key == 'partner_sexual':
        lines.extend(
            [
                'This is a trump-card based sexual tendency spread.',
                'Important fixed rule: upright = S, reversed = M.',
                'Card meanings are symbolic nuance, not literal facts or fixed labels.',
                'Infer tendencies from aggregate patterns and numeric metrics, not from a single card.',
                'Output format (exact labels, no bullets):',
                '判定: ...',
                'S度: ...%',
                'M度: ...%',
                '傾向: ...',
                'スイッチャー傾向: ...',
                '補足: ...',
                'Reflect the given percentages and the tendency card directly in the text.',
            ]
        )
    else:
        lines.append('Output: 6-10 sentences, no bullet points.')

    if fortune_key == 'triangle_crime':
        lines.extend(
            [
                'Interpretation perspective: analyze a potentially harmful counterpart (the offender side), not the querent as perpetrator.',
                'Never provide suggestions that enable, justify, or optimize criminal acts.',
                'Focus on warning signs, boundary setting, evidence preservation, and safety-oriented actions for the querent.',
                'Output format (exact labels, no bullets):',
                '危険度: 低 / 中 / 高 / 緊急 のいずれか1つ',
                '根拠: カード配置から危険度を判断した理由を簡潔に述べる。',
                '対策: 相談者が今日から取るべき安全行動を具体的に述べる。',
            ]
        )

    lines.extend(
        [
            '',
            f'Fortune type: {kind}',
            f'Fortune key: {fortune_key}' if fortune_key else 'Fortune key: -',
            f'Focus: {hint}',
            'Cards:',
            'Use the following card names verbatim whenever you mention them.',
        ]
    )

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
    if sexual_profile:
        lines.extend(
            [
                '',
                'Partner Sexual Metrics:',
                f"- Upright(S) count: {sexual_profile.get('s_count')}",
                f"- Reversed(M) count: {sexual_profile.get('m_count')}",
                f"- S degree: {sexual_profile.get('s_percent')}%",
                f"- M degree: {sexual_profile.get('m_percent')}%",
                f"- Balance label: {sexual_profile.get('balance_label')}",
                f"- Dominant attribute: {sexual_profile.get('dominant_attribute')}",
            ]
        )
        tendency = sexual_profile.get('tendency')
        if isinstance(tendency, dict):
            lines.append(
                f"- Tendency card: {tendency.get('card', {}).get('name')} ({tendency.get('attribute')}) | {tendency.get('category')} | {tendency.get('theme')}"
            )
        switcher = sexual_profile.get('switcher')
        if isinstance(switcher, dict):
            left = switcher.get('left') or {}
            right = switcher.get('right') or {}
            lines.append(
                f"- Switcher: detected={switcher.get('detected')} left(S/M)={left.get('s')}/{left.get('m')} right(S/M)={right.get('s')}/{right.get('m')}"
            )
        numeric_traits = sexual_profile.get('numeric_traits')
        if isinstance(numeric_traits, dict):
            lines.append(f"- Polarity index (S%-M%): {numeric_traits.get('polarity_index')}")
            lines.append(f"- Imbalance count |S-M|: {numeric_traits.get('imbalance_count')}")
            suit_counts = numeric_traits.get('suit_counts') or {}
            if isinstance(suit_counts, dict):
                lines.append(
                    '- Suit counts: '
                    f"Spade={suit_counts.get('Spade', 0)} "
                    f"Club={suit_counts.get('Club', 0)} "
                    f"Diamond={suit_counts.get('Diamond', 0)} "
                    f"Harts={suit_counts.get('Harts', 0)} "
                    f"Joker={suit_counts.get('Joker', 0)}"
                )
            rank_band_counts = numeric_traits.get('rank_band_counts') or {}
            if isinstance(rank_band_counts, dict):
                lines.append(
                    '- Rank bands: '
                    f"low(1-6)={rank_band_counts.get('low', 0)} "
                    f"mid(7-10)={rank_band_counts.get('mid', 0)} "
                    f"high(J-Q-K)={rank_band_counts.get('high', 0)} "
                    f"joker={rank_band_counts.get('joker', 0)}"
                )
        lines.append(
            f"- Joker boost: applied={sexual_profile.get('joker_boost_applied')} target={sexual_profile.get('joker_boost_target')}"
        )
    lines.append('')
    lines.append('Focus on the positions (past/present/future or given labels).')
    lines.append('Treat card meanings as nuance and metaphor; avoid one-to-one deterministic claims.')
    lines.append('Avoid claiming certainty; offer guidance.')
    return '\n'.join(lines)
