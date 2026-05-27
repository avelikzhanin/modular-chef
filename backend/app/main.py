"""FastAPI приложение. Stage 5 наполнит роутами."""
from fastapi import FastAPI

app = FastAPI(
    title="Modular Chef API",
    version="0.1.0",
    description="Backend для мил-преп приложения с двумя ролями (Шеф/Гость).",
)


@app.get("/health")
async def health() -> dict[str, str]:
    """Лёгкий probe для Railway healthcheck и smoke-теста."""
    return {"status": "ok"}
