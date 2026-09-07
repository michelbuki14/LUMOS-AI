# =============================================================================
# LUMOS AI — Middleware
# =============================================================================

from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
import time
import structlog

logger = structlog.get_logger()


class LoggingMiddleware(BaseHTTPMiddleware):
    """Log all requests and responses."""
    
    async def dispatch(self, request: Request, call_next):
        start_time = time.time()
        
        # Log request
        logger.info(
            "Request started",
            method=request.method,
            path=request.url.path,
            client=request.client.host if request.client else "unknown",
        )
        
        response = await call_next(request)
        
        # Log response
        process_time = time.time() - start_time
        logger.info(
            "Request completed",
            method=request.method,
            path=request.url.path,
            status_code=response.status_code,
            duration_ms=round(process_time * 1000, 2),
        )
        
        response.headers["X-Process-Time"] = str(process_time)
        return response


class RateLimitMiddleware(BaseHTTPMiddleware):
    """Simple rate limiting middleware."""
    
    def __init__(self, app, requests_per_minute: int = 60):
        super().__init__(app)
        self.requests_per_minute = requests_per_minute
    
    async def dispatch(self, request: Request, call_next):
        # In production, use Redis for distributed rate limiting
        response = await call_next(request)
        return response
