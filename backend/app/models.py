from sqlalchemy import Enum
from datetime import datetime
from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    ForeignKey,
    Integer,
    String,
    Text,
    func,
)
from sqlalchemy.orm import relationship

from app.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(150), nullable=False)
    email = Column(String(255), unique=True, index=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    
    role = Column(
    Enum(
        "CITIZEN",
        "WARD_MEMBER",
        "PANCHAYAT_OFFICIAL",
        "MUNICIPALITY_OFFICIAL",
        "CORPORATION_OFFICIAL",
        "ADMIN",
        name="userrole",
    ),
    nullable=False,
    index=True,
)

    is_active = Column(Boolean, default=True, nullable=False)
    


# Inside the User class:
    created_at = Column(
    DateTime,
    nullable=False,
    default=datetime.utcnow,
)
 


class WardAssignment(Base):
    __tablename__ = "ward_assignments"

    id = Column(Integer, primary_key=True, index=True)
    ward_member_id = Column(
        Integer, ForeignKey("users.id"), nullable=False, index=True
    )
    state = Column(String(100), nullable=False)
    district = Column(String(100), nullable=False)
    local_body = Column(String(150), nullable=False)
    ward_name = Column(String(100), nullable=False)


class CitizenProfile(Base):
    __tablename__ = "citizen_profiles"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(
        Integer, ForeignKey("users.id"), unique=True, nullable=False
    )
    date_of_birth = Column(DateTime(timezone=True), nullable=True)
    gender = Column(String(30), nullable=True)
    state = Column(String(100), nullable=True)
    district = Column(String(100), nullable=True)
    annual_income = Column(Integer, nullable=True)
    category = Column(String(50), nullable=True)
    disability = Column(Boolean, default=False, nullable=False)
    bpl_status = Column(String(30), nullable=True)
    education_level = Column(String(50), nullable=True)
    employment_status = Column(String(50), nullable=True)
    farmer_status = Column(String(30), nullable=True)


class Scheme(Base):
    __tablename__ = "schemes"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(250), nullable=False, index=True)
    scheme_type = Column(String(30), nullable=False)
    category = Column(String(100), nullable=False)
    state = Column(String(100), nullable=True)
    description = Column(Text, nullable=False)
    official_url = Column(String(500), nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class CitizenConsent(Base):
    __tablename__ = "citizen_consents"

    id = Column(Integer, primary_key=True, index=True)
    citizen_id = Column(
        Integer, ForeignKey("users.id"), nullable=False, index=True
    )
    ward_member_id = Column(
        Integer, ForeignKey("users.id"), nullable=False, index=True
    )
    purpose = Column(String(250), nullable=False)
    granted = Column(Boolean, nullable=False)
    recorded_at = Column(DateTime(timezone=True), server_default=func.now())


class AssistanceCase(Base):
    __tablename__ = "assistance_cases"

    id = Column(Integer, primary_key=True, index=True)
    citizen_id = Column(
        Integer, ForeignKey("users.id"), nullable=False, index=True
    )
    ward_member_id = Column(
        Integer, ForeignKey("users.id"), nullable=False, index=True
    )
    scheme_id = Column(Integer, ForeignKey("schemes.id"), nullable=True)
    status = Column(String(40), default="Open", nullable=False)
    missing_documents = Column(Text, nullable=True)
    notes = Column(Text, nullable=True)
    follow_up_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
    )
