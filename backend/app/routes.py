
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Scheme
from app.schemas import SchemeCreate, SchemeResponse

router = APIRouter(prefix="/api/v1/schemes", tags=["Schemes"])


@router.get("/", response_model=list[SchemeResponse])
def list_schemes(
    search: str | None = Query(default=None, max_length=200),
    category: str | None = Query(default=None, max_length=100),
    scheme_type: str | None = Query(
        default=None, pattern=r"^(Central|State)$"
    ),
    state: str | None = Query(default=None, max_length=100),
    db: Session = Depends(get_db),
):
    query = db.query(Scheme).filter(Scheme.is_active.is_(True))

    if search:
        query = query.filter(Scheme.name.ilike(f"%{search}%"))

    if category:
        query = query.filter(Scheme.category.ilike(category))

    if scheme_type:
        query = query.filter(Scheme.scheme_type == scheme_type)

    if state:
        query = query.filter(
            (Scheme.state.is_(None)) | (Scheme.state.ilike(state))
        )

    return query.order_by(Scheme.name).all()


@router.get("/{scheme_id}", response_model=SchemeResponse)
def get_scheme(scheme_id: int, db: Session = Depends(get_db)):
    scheme = (
        db.query(Scheme)
        .filter(Scheme.id == scheme_id, Scheme.is_active.is_(True))
        .first()
    )

    if scheme is None:
        raise HTTPException(status_code=404, detail="Scheme not found")

    return scheme


@router.post("/", response_model=SchemeResponse, status_code=201)
def create_scheme(
    payload: SchemeCreate,
    db: Session = Depends(get_db),
):
    scheme = Scheme(**payload.model_dump())
    db.add(scheme)
    db.commit()
    db.refresh(scheme)
    return scheme
