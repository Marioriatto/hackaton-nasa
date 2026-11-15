from fastapi import FastAPI, HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.routers import alertas, aplicaciones, parcelas, predictions

app = FastAPI()

# cambiar CORS al sacar a produccion
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def error_response(status_code: int, error: str, message: str, details: list | dict | None = None) -> JSONResponse:
    return JSONResponse(
        status_code=status_code,
        content={
            "error": error,
            "message": message,
            "details": details,
        },
    )


@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException) -> JSONResponse:
    detail = exc.detail
    if isinstance(detail, dict):
        message = detail.get("message") or detail.get("detail") or str(detail)
        details = detail.get("details")
    elif isinstance(detail, list):
        message = "HTTP error"
        details = detail
    else:
        message = str(detail)
        details = None
    return error_response(
        status_code=exc.status_code,
        error=exc.__class__.__name__,
        message=message,
        details=details,
    )


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError) -> JSONResponse:
    return error_response(
        status_code=422,
        error="ValidationError",
        message="Request validation failed.",
        details=exc.errors(),
    )


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    return error_response(
        status_code=500,
        error="InternalServerError",
        message="An unexpected error occurred.",
        details=None,
    )

app.include_router(parcelas.router, prefix="/api/v1")
app.include_router(aplicaciones.router, prefix="/api/v1")
app.include_router(alertas.router, prefix="/api/v1")
app.include_router(predictions.router, prefix="/api/v1")


@app.get("/api/v1/health", tags=["health"], status_code=200)
async def health_check() -> dict[str, str]:
    return {"status": "ok"}
