import os

from dotenv import load_dotenv

load_dotenv()


def env(name, default=None):
    return os.environ.get(name, default)


def env_list(name, default=''):
    raw = env(name, default) or ''
    return [value.strip() for value in raw.split(',') if value.strip()]


DATABASE_URL = env('DATABASE_URL', 'postgresql://tarot_user:admin1234@localhost:5432/tarot_db')

# Auth/JWT
JWT_SECRET = env('JWT_SECRET', 'dev-secret')
JWT_ISSUER = env('JWT_ISSUER', 'tarot-app')
JWT_AUDIENCE = env('JWT_AUDIENCE', 'tarot-app')
JWT_EXP_SECONDS = int(env('JWT_EXP_SECONDS', '2592000'))  # 30 days

# Google Play verification
GOOGLE_SERVICE_ACCOUNT_JSON = env('GOOGLE_SERVICE_ACCOUNT_JSON')
GOOGLE_PACKAGE_NAME = env('GOOGLE_PACKAGE_NAME')
GOOGLE_CLIENT_ID = env('GOOGLE_CLIENT_ID')

# Ads throttling
AD_REWARD_MAX_PER_HOUR = int(env('AD_REWARD_MAX_PER_HOUR', '5'))
AD_REWARD_MAX_PER_DAY = int(env('AD_REWARD_MAX_PER_DAY', '20'))

# Dev fallback
ALLOW_X_USER_ID_FALLBACK = env('ALLOW_X_USER_ID_FALLBACK', 'true').lower() == 'true'

# Admin testing helpers
ADMIN_USER_IDS = set(env_list('ADMIN_USER_IDS', 'e154d397-dff7-4780-b5c4-5aa3a3889a7d'))
ADMIN_LIFE_OVERRIDE = int(env('ADMIN_LIFE_OVERRIDE', '99'))

# Testing helpers
DISABLE_INTERPRETATION_LIMITS = env('DISABLE_INTERPRETATION_LIMITS', 'false').lower() == 'true'

# Dev-only auth
ENABLE_DEV_AUTH = env('ENABLE_DEV_AUTH', 'false').lower() == 'true'
DEV_AUTH_TOKEN = env('DEV_AUTH_TOKEN', '')
