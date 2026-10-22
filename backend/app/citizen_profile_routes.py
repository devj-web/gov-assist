
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from pydantic import BaseModel, Field, ConfigDict
from sqlalchemy.orm import Session

from app.auth import decode_access_token
from app.database import get_db
from app.models import User, CitizenProfile

router = APIRouter(
    prefix="/api/v1/citizen/profile",
    tags=["Citizen Profile"],
)

oauth2_scheme = OAuth2PasswordBearer(
    tokenUrl="/api/v1/auth/login"
)


class ProfileUpdate(BaseModel):
    date_of_birth: Optional[datetime] = None
    gender: Optional[str] = Field(default=None, max_length=30)
    state: Optional[str] = Field(default=None, max_length=100)
    district: Optional[str] = Field(default=None, max_length=100)
    annual_income: Optional[int] = Field(default=None, ge=0)
    category: Optional[str] = Field(default=None, max_length=50)
    disability: Optional[bool] = None

    bpl_status: Optional[str] = Field(default=None, max_length=30)
    education_level: Optional[str] = Field(default=None, max_length=50)
    employment_status: Optional[str] = Field(default=None, max_length=50)
    farmer_status: Optional[str] = Field(default=None, max_length=30)


class ProfileResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    user_id: int
    date_of_birth: Optional[datetime] = None
    gender: Optional[str] = None
    state: Optional[str] = None
    district: Optional[str] = None
    annual_income: Optional[int] = None
    category: Optional[str] = None
    disability: bool = False

    bpl_status: Optional[str] = None
    education_level: Optional[str] = None
    employment_status: Optional[str] = None
    farmer_status: Optional[str] = None


def current_citizen(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
) -> User:
    try:
        payload = decode_access_token(token)
        user_id = int(payload["sub"])
    except Exception:
        raise HTTPException(
            status_code=401,
            detail="Invalid or expired token",
        )

    user = db.query(User).filter(User.id == user_id).first()

    if (
        user is None
        or not user.is_active
        or user.role != "CITIZEN"
        or payload.get("role") != user.role
    ):
        raise HTTPException(
            status_code=403,
            detail="Citizen access required",
        )

    return user


@router.get("/", response_model=ProfileResponse)
def get_profile(
    user: User = Depends(current_citizen),
    db: Session = Depends(get_db),
):
    profile = (
        db.query(CitizenProfile)
        .filter(CitizenProfile.user_id == user.id)
        .first()
    )

    if profile is None:
        profile = CitizenProfile(
            user_id=user.id,
            disability=False,
        )
        db.add(profile)
        db.commit()
        db.refresh(profile)

    return profile


@router.put("/", response_model=ProfileResponse)
def update_profile(
    payload: ProfileUpdate,
    user: User = Depends(current_citizen),
    db: Session = Depends(get_db),
):
    profile = (
        db.query(CitizenProfile)
        .filter(CitizenProfile.user_id == user.id)
        .first()
    )

    if profile is None:
        profile = CitizenProfile(
            user_id=user.id,
            disability=False,
        )
        db.add(profile)
        db.flush()

    values = payload.model_dump(exclude_unset=True)

    for field, value in values.items():
        setattr(profile, field, value)

    db.commit()
    db.refresh(profile)

    return profile
