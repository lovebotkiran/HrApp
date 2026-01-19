from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from contextlib import asynccontextmanager
import time
import logging

from core.config import settings
from infrastructure.database.connection import init_db
from api.routers import auth, job_requisitions, job_postings, candidates, applications, interviews, offers, dashboard, ai, onboarding

# Configure logging
logging.basicConfig(
    level=logging.INFO if settings.DEBUG else logging.WARNING,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Application lifespan events.
    Runs on startup and shutdown.
    """
    # Startup
    logger.info("Starting AgenticHR application...")
    try:
        init_db()
        logger.info("Database initialized successfully")
    except Exception as e:
        logger.error(f"Failed to initialize database: {e}")
    
    yield
    
    # Shutdown
    logger.info("Shutting down AgenticHR application...")


# Create FastAPI application
app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="AI-Powered Recruitment Management System",
    docs_url=f"{settings.API_PREFIX}/docs",
    redoc_url=f"{settings.API_PREFIX}/redoc",
    openapi_url=f"{settings.API_PREFIX}/openapi.json",
    lifespan=lifespan
)

# CORS Middleware
if settings.DEBUG:
    # In development, allow all local origins to support credentials
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["http://localhost:8080", "http://127.0.0.1:8080", "http://0.0.0.0:8080"],
        allow_origin_regex=r"https?://(localhost|127\.0\.0\.1|0\.0\.0\.0)(:\d+)?",
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
else:
    # In production, use specific origins
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins_list,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )


# Request timing middleware
@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    """Add processing time to response headers."""
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    response.headers["X-Process-Time"] = str(process_time)
    return response


# Global exception handler
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Handle all unhandled exceptions."""
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={
            "message": "Internal server error",
            "detail": str(exc) if settings.DEBUG else "An error occurred"
        }
    )


# Health check endpoint
@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "app_name": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "environment": settings.ENVIRONMENT
    }


# Root endpoint
@app.get("/")
async def root():
    """Root endpoint with API information."""
    return {
        "message": "Welcome to AgenticHR API",
        "version": settings.APP_VERSION,
        "docs": f"{settings.API_PREFIX}/docs",
        "health": "/health"
    }


# Include routers
app.include_router(
    auth.router,
    prefix=f"{settings.API_PREFIX}/auth",
    tags=["Authentication"]
)

app.include_router(
    job_requisitions.router,
    prefix=f"{settings.API_PREFIX}/job-requisitions",
    tags=["Job Requisitions"]
)

app.include_router(
    job_postings.router,
    prefix=f"{settings.API_PREFIX}/job-postings",
    tags=["Job Postings"]
)

app.include_router(
    candidates.router,
    prefix=f"{settings.API_PREFIX}/candidates",
    tags=["Candidates"]
)

app.include_router(
    applications.router,
    prefix=f"{settings.API_PREFIX}/applications",
    tags=["Applications"]
)

app.include_router(
    interviews.router,
    prefix=f"{settings.API_PREFIX}/interviews",
    tags=["Interviews"]
)

app.include_router(
    offers.router,
    prefix=f"{settings.API_PREFIX}/offers",
    tags=["Offers"]
)

app.include_router(
    dashboard.router,
    prefix=f"{settings.API_PREFIX}/dashboard",
    tags=["Dashboard & Analytics"]
)

app.include_router(
    ai.router,
    prefix=f"{settings.API_PREFIX}/ai",
    tags=["AI Services"]
)

app.include_router(
    onboarding.router,
    prefix=f"{settings.API_PREFIX}/onboarding",
    tags=["Onboarding"]
)


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.DEBUG
    )
