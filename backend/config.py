import os


def env(name, default=None):
    return os.environ.get(name, default)


DATABASE_URL = env('DATABASE_URL')

# Auth/JWT
JWT_SECRET = env('JWT_SECRET', 'dev-secret')
JWT_ISSUER = env('JWT_ISSUER', 'tarot-app')
JWT_AUDIENCE = env('JWT_AUDIENCE', 'tarot-app')
JWT_EXP_SECONDS = int(env('JWT_EXP_SECONDS', '2592000'))  # 30 days

# Apple receipt verification (disabled)
APPLE_VERIFY_URL = env('APPLE_VERIFY_URL', 'https://buy.itunes.apple.com/verifyReceipt')
APPLE_VERIFY_SANDBOX_URL = env('APPLE_VERIFY_SANDBOX_URL', 'https://sandbox.itunes.apple.com/verifyReceipt')
APPLE_SHARED_SECRET = env('APPLE_SHARED_SECRET')

# Google Play verification
GOOGLE_SERVICE_ACCOUNT_JSON = env('GOOGLE_SERVICE_ACCOUNT_JSON')
GOOGLE_PACKAGE_NAME = env('GOOGLE_PACKAGE_NAME')
GOOGLE_CLIENT_ID = env('GOOGLE_CLIENT_ID')

# Ads throttling
AD_REWARD_MAX_PER_HOUR = int(env('AD_REWARD_MAX_PER_HOUR', '5'))
AD_REWARD_MAX_PER_DAY = int(env('AD_REWARD_MAX_PER_DAY', '20'))

# Dev fallback
ALLOW_X_USER_ID_FALLBACK = env('ALLOW_X_USER_ID_FALLBACK', 'true').lower() == 'true'
