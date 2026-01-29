import os
import time

import requests
from requests import Response
from requests.exceptions import RequestException

from .interpretation_prompt import build_prompt


class ClaudeClient:
    def __init__(self):
        self.api_key = os.environ.get('ANTHROPIC_API_KEY', '')
        self.model = os.environ.get('ANTHROPIC_MODEL', 'claude-3-5-sonnet-20241022')
        self.api_url = os.environ.get('ANTHROPIC_API_URL', 'https://api.anthropic.com/v1/messages')
        self.max_retries = int(os.environ.get('ANTHROPIC_MAX_RETRIES', '3'))
        self.retry_backoff = float(os.environ.get('ANTHROPIC_RETRY_BACKOFF', '1.5'))
        self.allow_fallback = os.environ.get('ALLOW_AI_FALLBACK', 'true').lower() == 'true'

    def generate(self, input_json: dict) -> tuple[str, str]:
        if not self.api_key:
            if self.allow_fallback:
                return build_prompt(input_json), self._fallback_text(input_json)
            raise RuntimeError('ANTHROPIC_API_KEY is not set')

        prompt = build_prompt(input_json)
        payload = {
            'model': self.model,
            'max_tokens': 800,
            'temperature': 0.7,
            'messages': [
                {'role': 'user', 'content': prompt},
            ],
        }
        headers = {
            'x-api-key': self.api_key,
            'anthropic-version': '2023-06-01',
            'content-type': 'application/json',
        }

        attempt = 0
        while True:
            attempt += 1
            try:
                response = requests.post(self.api_url, json=payload, headers=headers, timeout=30)
                if self._should_retry(response, attempt):
                    self._sleep(attempt)
                    continue
                response.raise_for_status()
                data = response.json()
                text = ''
                for block in data.get('content', []):
                    if block.get('type') == 'text':
                        text += block.get('text', '')
                return prompt, text.strip()
            except RequestException as exc:
                if attempt >= self.max_retries:
                    if self.allow_fallback:
                        return prompt, self._fallback_text(input_json)
                    raise
                self._sleep(attempt)
                continue

    def _should_retry(self, response: Response, attempt: int) -> bool:
        if attempt >= self.max_retries:
            return False
        return response.status_code in (408, 409, 429, 500, 502, 503, 504)

    def _sleep(self, attempt: int) -> None:
        time.sleep(self.retry_backoff * attempt)

    def _fallback_text(self, input_json: dict) -> str:
        card_names = []
        cards = input_json.get('cards') if isinstance(input_json, dict) else None
        if isinstance(cards, list):
            for card in cards:
                if isinstance(card, dict) and card.get('card_name'):
                    card_names.append(card.get('card_name'))
        if card_names:
            joined = ' / '.join(card_names[:3])
            return f'AI解釈は未設定です。カード: {joined}'
        return 'AI解釈は未設定です。'
