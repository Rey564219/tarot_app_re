import logging
import os
import re
import time

from dotenv import load_dotenv

import requests
from requests import Response
from requests.exceptions import HTTPError, RequestException

from .interpretation_prompt import build_prompt

load_dotenv()

logger = logging.getLogger(__name__)

_MODEL_ID_PATTERN = re.compile(
    r'^claude-(?:\d(?:-\d)?-(?:opus|sonnet|haiku)|(?:opus|sonnet|haiku)-\d(?:-\d)?)-(?:\d{8}|latest)$'
)
_DEFAULT_MODEL = 'claude-3-5-sonnet-20241022'


class ClaudeClient:
    def __init__(self):
        self.api_key = os.environ.get('ANTHROPIC_API_KEY', '')
        self.model = os.environ.get('ANTHROPIC_MODEL', _DEFAULT_MODEL)
        self.api_url = os.environ.get('ANTHROPIC_API_URL', 'https://api.anthropic.com/v1/messages')
        self.max_retries = int(os.environ.get('ANTHROPIC_MAX_RETRIES', '3'))
        self.retry_backoff = float(os.environ.get('ANTHROPIC_RETRY_BACKOFF', '1.5'))
        self.allow_fallback = os.environ.get('ALLOW_AI_FALLBACK', 'true').lower() == 'true'
        self.skip_model_validation = os.environ.get('ANTHROPIC_SKIP_MODEL_VALIDATION', 'false').lower() == 'true'

    def validate_model_name(self) -> None:
        if self.skip_model_validation:
            return
        if not self.api_key and self.allow_fallback:
            return

        model = (self.model or '').strip()
        if not model:
            raise RuntimeError(
                'ANTHROPIC_MODEL is empty. Set a valid model id like '
                '"claude-3-5-sonnet-20241022" or set ANTHROPIC_SKIP_MODEL_VALIDATION=true.'
            )

        allowed_raw = os.environ.get('ANTHROPIC_ALLOWED_MODELS', '').strip()
        if allowed_raw:
            allowed = {item.strip() for item in allowed_raw.split(',') if item.strip()}
            if model not in allowed:
                raise RuntimeError(
                    f"ANTHROPIC_MODEL '{model}' is not in ANTHROPIC_ALLOWED_MODELS. "
                    "Update the allowlist or set ANTHROPIC_SKIP_MODEL_VALIDATION=true."
                )
            return

        if not _MODEL_ID_PATTERN.match(model):
            raise RuntimeError(
                f"ANTHROPIC_MODEL '{model}' does not look like a valid Anthropic model id. "
                'Use a date-stamped id like "claude-3-5-sonnet-20241022" or '
                '"claude-haiku-4-5-20251001", a latest id like "claude-4-5-sonnet-latest", '
                'or set ANTHROPIC_SKIP_MODEL_VALIDATION=true.'
            )

    def generate(self, input_json: dict) -> tuple[str, str]:
        if not self.api_key:
            if self.allow_fallback:
                logger.warning('ANTHROPIC_API_KEY not set; using fallback interpretation.')
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
        tried_default_model = False
        while True:
            attempt += 1
            try:
                response = requests.post(self.api_url, json=payload, headers=headers, timeout=30)
                if self._should_retry(response, attempt):
                    self._sleep(attempt)
                    continue
                if not response.ok:
                    logger.error(
                        'Anthropic API error status=%s body=%s',
                        response.status_code,
                        (response.text or '')[:500],
                    )
                response.raise_for_status()
                data = response.json()
                text = ''
                for block in data.get('content', []):
                    if block.get('type') == 'text':
                        text += block.get('text', '')
                if not text.strip():
                    logger.warning('Anthropic API returned empty text content.')
                return prompt, text.strip()
            except RequestException as exc:
                response = getattr(exc, 'response', None)
                if isinstance(exc, HTTPError) and response is not None:
                    if response.status_code == 404:
                        logger.error(
                            'Anthropic model not found. Check ANTHROPIC_MODEL. status=%s body=%s',
                            response.status_code,
                            (response.text or '')[:500],
                        )
                        if (
                            not tried_default_model
                            and isinstance(payload.get('model'), str)
                            and payload.get('model', '').endswith('-latest')
                        ):
                            tried_default_model = True
                            payload['model'] = _DEFAULT_MODEL
                            logger.warning(
                                'Retrying Anthropic request with default model %s after 404.',
                                _DEFAULT_MODEL,
                            )
                            continue
                    if not self._should_retry(response, attempt):
                        if self.allow_fallback:
                            logger.warning('Falling back after Anthropic API failures.')
                            return prompt, self._fallback_text(input_json)
                        raise
                logger.exception('Anthropic API request failed: %s', exc)
                if attempt >= self.max_retries:
                    if self.allow_fallback:
                        logger.warning('Falling back after Anthropic API failures.')
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
