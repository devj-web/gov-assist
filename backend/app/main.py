
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from datetime import datetime, timezone
from app.routes import router as schemes_router
from app.auth_routes import router as auth_router
from app.eligibility_routes import router as eligibility_router
from app.admin_ward_routes import router as admin_ward_router
from app.citizen_profile_routes import router as citizen_profile_router
app = FastAPI(
    title="GovAssist AI API",
    description="API for government scheme discovery and assistance tracking",
    version="1.0.0",
)
app.include_router(eligibility_router)
app.include_router(auth_router)
app.include_router(schemes_router)  
app.include_router(admin_ward_router)    
app.include_router(citizen_profile_router)    
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Restrict this before production deployment.
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
def root():
    return {
        "message": "GovAssist AI API is running",
        "status": "success",
    }


@app.get("/health")
def health():
    return {
        "status": "healthy",
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


@app.get("/api/v1")
def api_info():
    return {
        "name": "GovAssist AI",
        "version": "1.0.0",
        "modules": [
            "authentication",
            "citizen profiles",
            "scheme discovery",
            "eligibility",
            "ward assistance",
            "administration",
        ],
        "database": "Not connected yet",
    }
