
from pydantic import BaseModel, ConfigDict, Field


class SchemeCreate(BaseModel):
    name: str = Field(min_length=2, max_length=250)
    scheme_type: str = Field(pattern=r"^(Central|State)$")
    category: str = Field(min_length=2, max_length=100)
    state: str | None = Field(default=None, max_length=100)
    description: str = Field(min_length=2)
    official_url: str | None = Field(default=None, max_length=500)


class SchemeResponse(BaseModel):
    id: int
    name: str
    scheme_type: str
    category: str
    state: str | None
    description: str
    official_url: str | None
    is_active: bool

    model_config = ConfigDict(from_attributes=True)
