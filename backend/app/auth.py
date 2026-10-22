
import os
from datetime import datetime, timedelta, timezone

import jwt
from dotenv import load_dotenv
from pwdlib import PasswordHash

# Load environment variables from backend/.env
load_dotenv()

SECRET_KEY = os.getenv("JWT_SECRET_KEY")

if not SECRET_KEY:
    raise RuntimeError(
        "JWT_SECRET_KEY is missing. Add a secure random secret "
        "to backend/.env before starting the API."
    )

ALGORITHM = "HS256"
ACCESS_TOKEN_MINUTES = 30

password_hash = PasswordHash.recommended()


def hash_password(password: str) -> str:
    """Return a secure hash of a password."""
    if not password or len(password) < 8:
        raise ValueError("Password must contain at least 8 characters.")

    return password_hash.hash(password)


def verify_password(password: str, hashed_password: str) -> bool:
    """Check a password against its stored hash."""
    return password_hash.verify(password, hashed_password)


def create_access_token(user_id: int, role: str) -> str:
    """Create a signed JWT access token."""
    if role not in {
    "CITIZEN",
    "WARD_MEMBER",
    "PANCHAYAT_OFFICIAL",
    "MUNICIPALITY_OFFICIAL",
    "CORPORATION_OFFICIAL",
    "ADMIN",
}:
   
        raise ValueError("Invalid user role.")

    expires_at = datetime.now(timezone.utc) + timedelta(
        minutes=ACCESS_TOKEN_MINUTES
    )

    payload = {
        "sub": str(user_id),
        "role": role,
        "exp": expires_at,
        "iat": datetime.now(timezone.utc),
    }

    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


def decode_access_token(token: str) -> dict:
    """Validate a JWT and return its payload."""
    return jwt.decode(
        token,
        SECRET_KEY,
        algorithms=[ALGORITHM],
        options={"require": ["sub", "exp", "iat"]},
    )
