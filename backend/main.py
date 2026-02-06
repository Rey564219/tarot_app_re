from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .routes import auth, master, life, readings, warnings, billing, affiliate, consultation, interpretations, shop
from .services.claude import ClaudeClient


def create_app() -> FastAPI:
    ClaudeClient().validate_model_name()
    app = FastAPI(title='Tarot App API')
    app.add_middleware(
        CORSMiddleware,
        allow_origins=['*'],
        allow_credentials=False,
        allow_methods=['*'],
        allow_headers=['*'],
    )
    app.include_router(auth.router)
    app.include_router(master.router)
    app.include_router(life.router)
    app.include_router(readings.router)
    app.include_router(warnings.router)
    app.include_router(billing.router)
    app.include_router(affiliate.router)
    app.include_router(consultation.router)
    app.include_router(interpretations.router)
    app.include_router(shop.router)
    return app


app = create_app()
