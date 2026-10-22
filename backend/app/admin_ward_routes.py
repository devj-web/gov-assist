from datetime import datetime, timezone
from typing import Optional
from app.models import User, Scheme, AssistanceCase
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from pydantic import BaseModel, EmailStr, Field
from sqlalchemy.orm import Session

from app.auth import decode_access_token, hash_password
from app.database import get_db
from app.models import (
    User,
    WardAssignment,
    CitizenProfile,
    CitizenConsent,
    AssistanceCase,
    Scheme,
)

router = APIRouter(prefix="/api/v1", tags=["Admin & Ward Member"])

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")


# ---------------- AUTHORIZATION ----------------

def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
):
    unauthorized = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid or expired authentication token",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        payload = decode_access_token(token)
        user_id = int(payload["sub"])
    except Exception:
        raise unauthorized

    user = db.query(User).filter(
        User.id == user_id,
        User.is_active.is_(True),
    ).first()

    if not user:
        raise unauthorized

    return user


def require_admin(user: User = Depends(get_current_user)):
    if user.role != "ADMIN":
        raise HTTPException(status_code=403, detail="Admin access required")
    return user


def require_ward_member(user: User = Depends(get_current_user)):
    if user.role != "WARD_MEMBER":
        raise HTTPException(
            status_code=403,
            detail="Ward Member access required",
        )
    return user


def has_current_consent(
    db: Session,
    citizen_id: int,
    ward_member_id: int,
) -> bool:
    consent = (
        db.query(CitizenConsent)
        .filter(
            CitizenConsent.citizen_id == citizen_id,
            CitizenConsent.ward_member_id == ward_member_id,
            CitizenConsent.purpose == "ASSISTANCE_CASE",
        )
        .order_by(CitizenConsent.recorded_at.desc(), CitizenConsent.id.desc())
        .first()
    )
    return bool(consent and consent.granted)


def require_assigned_ward(
    db: Session,
    ward_member_id: int,
) -> WardAssignment:
    assignment = (
        db.query(WardAssignment)
        .filter(WardAssignment.ward_member_id == ward_member_id)
        .first()
    )
    if not assignment:
        raise HTTPException(
            status_code=403,
            detail="No ward has been assigned to this account",
        )
    return assignment


def require_case_access(
    db: Session,
    case_id: int,
    ward_member_id: int,
) -> AssistanceCase:
    case = (
        db.query(AssistanceCase)
        .filter(
            AssistanceCase.id == case_id,
            AssistanceCase.ward_member_id == ward_member_id,
        )
        .first()
    )
    if not case:
        raise HTTPException(
            status_code=404,
            detail="Case not found in your assigned cases",
        )

    if not has_current_consent(
        db, case.citizen_id, ward_member_id
    ):
        raise HTTPException(
            status_code=403,
            detail="Citizen consent is required or has been withdrawn",
        )

    return case


# ---------------- REQUEST SCHEMAS ----------------

class WardMemberCreate(BaseModel):
    name: str = Field(min_length=2, max_length=150)
    email: EmailStr
    password: str = Field(min_length=8)
    state: str = Field(min_length=1, max_length=100)
    district: str = Field(min_length=1, max_length=100)
    local_body: str = Field(min_length=1, max_length=150)
    ward_name: str = Field(min_length=1, max_length=100)


class WardAssignmentUpdate(BaseModel):
    state: str
    district: str
    local_body: str
    ward_name: str


class ConsentRequest(BaseModel):
    ward_member_id: int
    granted: bool


class CaseCreate(BaseModel):
    citizen_id: int
    scheme_id: Optional[int] = None
    status: str = "Open"
    missing_documents: Optional[str] = None
    notes: Optional[str] = None
    follow_up_at: Optional[datetime] = None


class CaseUpdate(BaseModel):
    status: Optional[str] = None
    missing_documents: Optional[str] = None
    notes: Optional[str] = None
    follow_up_at: Optional[datetime] = None


class SchemeCreate(BaseModel):
    name: str = Field(min_length=1, max_length=250)
    scheme_type: str = Field(min_length=1, max_length=30)
    category: str = Field(min_length=1, max_length=100)
    state: Optional[str] = None
    description: str
    official_url: Optional[str] = None


# ---------------- ADMIN: WARD MEMBERS ----------------

@router.post("/admin/ward-members", status_code=201)
def create_ward_member(
    data: WardMemberCreate,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    if db.query(User).filter(User.email == data.email).first():
        raise HTTPException(status_code=409, detail="Email already registered")

    member = User(
        name=data.name,
        email=str(data.email),
        password_hash=hash_password(data.password),
        role="WARD_MEMBER",
        is_active=True,
    )
    db.add(member)
    db.flush()

    assignment = WardAssignment(
        ward_member_id=member.id,
        state=data.state.strip(),
        district=data.district.strip(),
        local_body=data.local_body.strip(),
        ward_name=data.ward_name.strip(),
    )
    db.add(assignment)

    try:
        db.commit()
        db.refresh(member)
        db.refresh(assignment)
    except Exception:
        db.rollback()
        raise HTTPException(status_code=500, detail="Could not create ward member")

    return {
        "message": "Ward Member created and assigned",
        "user_id": member.id,
        "name": member.name,
        "email": member.email,
        "role": member.role,
        "assignment": {
            "id": assignment.id,
            "state": assignment.state,
            "district": assignment.district,
            "local_body": assignment.local_body,
            "ward_name": assignment.ward_name,
        },
    }


@router.get("/admin/ward-members")
def list_ward_members(
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    members = (
        db.query(User, WardAssignment)
        .outerjoin(
            WardAssignment,
            WardAssignment.ward_member_id == User.id,
        )
        .filter(User.role == "WARD_MEMBER")
        .order_by(User.id.desc())
        .all()
    )

    return [
        {
            "user_id": user.id,
            "name": user.name,
            "email": user.email,
            "is_active": user.is_active,
            "assignment": (
                {
                    "id": assignment.id,
                    "state": assignment.state,
                    "district": assignment.district,
                    "local_body": assignment.local_body,
                    "ward_name": assignment.ward_name,
                }
                if assignment else None
            ),
        }
        for user, assignment in members
    ]


@router.put("/admin/ward-members/{member_id}/assignment")
def update_ward_assignment(
    member_id: int,
    data: WardAssignmentUpdate,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    member = db.query(User).filter(
        User.id == member_id,
        User.role == "WARD_MEMBER",
    ).first()

    if not member:
        raise HTTPException(status_code=404, detail="Ward Member not found")

    assignment = db.query(WardAssignment).filter(
        WardAssignment.ward_member_id == member_id
    ).first()

    if not assignment:
        assignment = WardAssignment(ward_member_id=member_id)
        db.add(assignment)

    assignment.state = data.state.strip()
    assignment.district = data.district.strip()
    assignment.local_body = data.local_body.strip()
    assignment.ward_name = data.ward_name.strip()

    db.commit()
    db.refresh(assignment)

    return {"message": "Ward assignment updated", "assignment_id": assignment.id}


@router.patch("/admin/ward-members/{member_id}/active")
def set_ward_member_active(
    member_id: int,
    active: bool,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    member = db.query(User).filter(
        User.id == member_id,
        User.role == "WARD_MEMBER",
    ).first()

    if not member:
        raise HTTPException(status_code=404, detail="Ward Member not found")

    member.is_active = active
    db.commit()

    return {"user_id": member.id, "is_active": member.is_active}


# ---------------- ADMIN: SCHEME MANAGEMENT ----------------

@router.post("/admin/schemes", status_code=201)
def create_scheme(
    data: SchemeCreate,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    scheme = Scheme(**data.model_dump())
    db.add(scheme)
    db.commit()
    db.refresh(scheme)

    return {
        "message": "Scheme created",
        "scheme_id": scheme.id,
        "name": scheme.name,
    }


@router.patch("/admin/schemes/{scheme_id}/active")
def set_scheme_active(
    scheme_id: int,
    active: bool,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    scheme = db.query(Scheme).filter(Scheme.id == scheme_id).first()
    if not scheme:
        raise HTTPException(status_code=404, detail="Scheme not found")

    scheme.is_active = active
    db.commit()

    return {"scheme_id": scheme.id, "is_active": scheme.is_active}


# ---------------- CITIZEN: CONSENT CONTROL ----------------

@router.post("/citizen/consent")
def set_citizen_consent(
    data: ConsentRequest,
    db: Session = Depends(get_db),
    citizen: User = Depends(get_current_user),
):
    if citizen.role != "CITIZEN":
        raise HTTPException(
            status_code=403,
            detail="Only citizens can manage their consent",
        )

    member = db.query(User).filter(
        User.id == data.ward_member_id,
        User.role == "WARD_MEMBER",
        User.is_active.is_(True),
    ).first()

    if not member:
        raise HTTPException(status_code=404, detail="Ward Member not found")

    # Consent is permitted only for the ward to which the citizen belongs.
    # The current CitizenProfile schema has no ward/local-body fields, so
    # this endpoint requires a matching ward assignment by state/district.
    profile = db.query(CitizenProfile).filter(
        CitizenProfile.user_id == citizen.id
    ).first()

    assignment = require_assigned_ward(db, member.id)

    if (
        not profile
        or not profile.state
        or not profile.district
        or profile.state.strip().casefold() != assignment.state.strip().casefold()
        or profile.district.strip().casefold() != assignment.district.strip().casefold()
    ):
        raise HTTPException(
            status_code=403,
            detail=(
                "Your profile must match the Ward Member's state and district. "
                "Ward-level matching needs ward details in the citizen profile."
            ),
        )

    consent = CitizenConsent(
        citizen_id=citizen.id,
        ward_member_id=member.id,
        purpose="ASSISTANCE_CASE",
        granted=data.granted,
    )
    db.add(consent)
    db.commit()
    db.refresh(consent)

    return {
        "message": "Consent granted" if data.granted else "Consent withdrawn",
        "consent_id": consent.id,
        "granted": consent.granted,
    }


@router.get("/citizen/consent")
def get_my_consents(
    db: Session = Depends(get_db),
    citizen: User = Depends(get_current_user),
):
    if citizen.role != "CITIZEN":
        raise HTTPException(status_code=403, detail="Citizen access required")

    records = (
        db.query(CitizenConsent)
        .filter(CitizenConsent.citizen_id == citizen.id)
        .order_by(CitizenConsent.recorded_at.desc(), CitizenConsent.id.desc())
        .all()
    )

    latest = {}
    for record in records:
        latest.setdefault(record.ward_member_id, record)

    return [
        {
            "ward_member_id": record.ward_member_id,
            "purpose": record.purpose,
            "granted": record.granted,
            "recorded_at": record.recorded_at,
        }
        for record in latest.values()
    ]


# ---------------- WARD MEMBER: ASSIGNED DATA ----------------

@router.get("/ward/me")
def ward_member_dashboard(
    db: Session = Depends(get_db),
    member: User = Depends(require_ward_member),
):
    assignment = require_assigned_ward(db, member.id)

    cases = db.query(AssistanceCase).filter(
        AssistanceCase.ward_member_id == member.id
    ).all()

    consented_citizen_ids = {
        case.citizen_id
        for case in cases
        if has_current_consent(db, case.citizen_id, member.id)
    }

    return {
        "ward_member": {
            "id": member.id,
            "name": member.name,
        },
        "assignment": {
            "state": assignment.state,
            "district": assignment.district,
            "local_body": assignment.local_body,
            "ward_name": assignment.ward_name,
        },
        "consented_citizens_with_cases": len(consented_citizen_ids),
        "open_cases": sum(
            1 for case in cases
            if case.status.casefold() == "open"
            and case.citizen_id in consented_citizen_ids
        ),
    }


@router.get("/ward/citizens")
def list_consented_citizens(
    db: Session = Depends(get_db),
    member: User = Depends(require_ward_member),
):
    require_assigned_ward(db, member.id)

    # Only citizens with a case assigned to this member and current consent
    # are returned. CitizenProfile currently has no ward field.
    cases = db.query(AssistanceCase).filter(
        AssistanceCase.ward_member_id == member.id
    ).all()

    citizen_ids = {
        case.citizen_id
        for case in cases
        if has_current_consent(db, case.citizen_id, member.id)
    }

    if not citizen_ids:
        return []

    citizens = db.query(User).filter(
        User.id.in_(citizen_ids),
        User.role == "CITIZEN",
        User.is_active.is_(True),
    ).all()

    profiles = {
        profile.user_id: profile
        for profile in db.query(CitizenProfile).filter(
            CitizenProfile.user_id.in_(citizen_ids)
        ).all()
    }

    return [
        {
            "citizen_id": citizen.id,
            "name": citizen.name,
            "email": citizen.email,
            "state": profiles[citizen.id].state if citizen.id in profiles else None,
            "district": profiles[citizen.id].district if citizen.id in profiles else None,
        }
        for citizen in citizens
    ]

@router.get("/ward/cases")
def list_ward_cases(
    db: Session = Depends(get_db),
    member: User = Depends(require_ward_member),
):
    require_assigned_ward(db, member.id)

    cases = (
        db.query(AssistanceCase, User.name, Scheme.name)
        .join(User, User.id == AssistanceCase.citizen_id)
        .outerjoin(Scheme, Scheme.id == AssistanceCase.scheme_id)
        .filter(AssistanceCase.ward_member_id == member.id)
        .order_by(AssistanceCase.updated_at.desc())
        .all()
    )

    results = []

    for case, citizen_name, scheme_name in cases:
        if not has_current_consent(db, case.citizen_id, member.id):
            continue

        results.append({
            "case_id": case.id,
            "citizen_id": case.citizen_id,
            "citizen_name": citizen_name,
            "scheme_id": case.scheme_id,
            "scheme_name": scheme_name or "Assistance request",
            "status": case.status,
            "missing_documents": case.missing_documents,
            "notes": case.notes,
            "follow_up_at": case.follow_up_at,
            "created_at": case.created_at,
            "updated_at": case.updated_at,
        })

    return results

@router.post("/ward/cases", status_code=201)
def create_assistance_case(
    data: CaseCreate,
    db: Session = Depends(get_db),
    member: User = Depends(require_ward_member),
):
    require_assigned_ward(db, member.id)

    citizen = db.query(User).filter(
        User.id == data.citizen_id,
        User.role == "CITIZEN",
        User.is_active.is_(True),
    ).first()

    if not citizen:
        raise HTTPException(status_code=404, detail="Citizen not found")

    if not has_current_consent(db, citizen.id, member.id):
        raise HTTPException(status_code=403, detail="Citizen consent is required")

    if data.scheme_id is not None:
        scheme = db.query(Scheme).filter(
            Scheme.id == data.scheme_id,
            Scheme.is_active.is_(True),
        ).first()
        if not scheme:
            raise HTTPException(status_code=404, detail="Active scheme not found")

    allowed_statuses = {"Open", "In Progress", "Pending", "Resolved", "Closed"}
    if data.status not in allowed_statuses:
        raise HTTPException(status_code=422, detail="Invalid case status")

    case = AssistanceCase(
        citizen_id=citizen.id,
        ward_member_id=member.id,
        scheme_id=data.scheme_id,
        status=data.status,
        missing_documents=data.missing_documents,
        notes=data.notes,
        follow_up_at=data.follow_up_at,
    )
    db.add(case)
    db.commit()
    db.refresh(case)

    return {"message": "Assistance case created", "case_id": case.id}


@router.patch("/ward/cases/{case_id}")
def update_assistance_case(
    case_id: int,
    data: CaseUpdate,
    db: Session = Depends(get_db),
    member: User = Depends(require_ward_member),
):
    case = require_case_access(db, case_id, member.id)

    changes = data.model_dump(exclude_unset=True)

    allowed_statuses = {"Open", "In Progress", "Pending", "Resolved", "Closed"}
    if "status" in changes and changes["status"] not in allowed_statuses:
        raise HTTPException(status_code=422, detail="Invalid case status")

    for key, value in changes.items():
        setattr(case, key, value)

    db.commit()
    db.refresh(case)

    return {
        "message": "Case updated",
        "case_id": case.id,
        "status": case.status,
        "follow_up_at": case.follow_up_at,
    }