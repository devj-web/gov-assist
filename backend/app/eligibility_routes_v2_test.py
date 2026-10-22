"""Eligibility matching API for citizens.

Matches a citizen's stored profile against the scheme catalogue. A scheme is
hidden when any configured criterion definitely fails; otherwise it is
reported as either a potential match or as needing verification.
"""

from dataclasses import dataclass, field
from datetime import date, datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.auth import decode_access_token
from app.database import get_db
from app.models import User


router = APIRouter(prefix="/api/v1/eligibility", tags=["Eligibility"])
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")

POTENTIAL_MATCH = "potential_match"
NEEDS_VERIFICATION = "needs_verification"


# ---------------------------------------------------------
# AUTHENTICATION
# ---------------------------------------------------------

def get_authenticated_citizen(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
) -> User:
    unauthorized = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid or expired access token.",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        payload = decode_access_token(token)
        user_id = int(payload["sub"])
    except Exception:
        raise unauthorized

    user = db.query(User).filter(User.id == user_id).first()

    if user is None or not user.is_active or payload.get("role") != user.role:
        raise unauthorized

    if user.role != "CITIZEN":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only citizen accounts can use this endpoint.",
        )

    return user


# ---------------------------------------------------------
# NORMALIZATION HELPERS
# ---------------------------------------------------------

UNRESTRICTED_VALUES = frozenset({
    "", "any", "all", "all categories", "none", "not required",
    "not applicable", "n/a",
})
NATIONWIDE_VALUES = frozenset({
    "all", "india", "all india", "pan india", "central", "national",
    "nationwide", "all states",
})
TRUE_VALUES = frozenset({"yes", "true", "required", "eligible", "farmer", "bpl"})
FALSE_VALUES = frozenset({
    "no", "false", "not required", "not eligible", "not a farmer",
    "non farmer", "non-farmer", "not bpl", "above poverty line", "apl",
})


def normalize(value) -> Optional[str]:
    """Lower-case, trim and collapse whitespace. Returns None when empty."""
    if value is None:
        return None
    return " ".join(str(value).split()).casefold() or None


def split_values(value) -> list[str]:
    if not value:
        return []
    return [
        item.strip().casefold()
        for item in str(value).replace(",", "|").split("|")
        if item.strip()
    ]


def calculate_age(dob) -> Optional[int]:
    if not dob:
        return None
    if isinstance(dob, datetime):
        dob = dob.date()
    today = date.today()
    age = today.year - dob.year - ((today.month, today.day) < (dob.month, dob.day))
    return age if age >= 0 else None  # a future date of birth is invalid data


def is_unrestricted(value) -> bool:
    normalized = normalize(value)
    return normalized is None or normalized in UNRESTRICTED_VALUES


def parse_yes_no(value) -> Optional[bool]:
    """True / False for recognised values, None when unknown."""
    if isinstance(value, bool):
        return value
    normalized = normalize(value)
    if normalized in TRUE_VALUES:
        return True
    if normalized in FALSE_VALUES:
        return False
    return None


# ---------------------------------------------------------
# CRITERION CHECKS  (each returns True / False / None=unknown)
# ---------------------------------------------------------

EDUCATION_LEVELS = {
    "no formal education": 0,
    "primary": 1, "below 10th": 1, "below 10th standard": 1,
    "8th": 1, "8th pass": 1,
    "10th": 2, "10th pass": 2, "sslc": 2, "matriculation": 2,
    "12th": 3, "12th pass": 3, "higher secondary": 3, "plus two": 3,
    "diploma": 4, "iti": 4,
    "graduate": 5, "graduation": 5, "degree": 5, "bachelor": 5, "bachelors": 5,
    "postgraduate": 6, "post graduation": 6, "master": 6, "masters": 6,
    "phd": 7, "doctorate": 7,
}


def education_check(required, citizen) -> Optional[bool]:
    if is_unrestricted(required):
        return True
    required_rank = EDUCATION_LEVELS.get(normalize(required))
    citizen_rank = EDUCATION_LEVELS.get(normalize(citizen))
    if required_rank is None or citizen_rank is None:
        return None
    return citizen_rank >= required_rank


EMPLOYMENT_ALIASES = {
    "employed": {"employed", "working", "salaried", "employee"},
    "unemployed": {"unemployed", "not employed", "job seeker", "jobseeker"},
    "student": {"student", "studying", "college student"},
    "self-employed": {"self-employed", "self employed", "business owner"},
    "farmer": {
        "farmer", "agricultural worker",
        "agricultural labourer", "agricultural laborer",
    },
    "unorganised worker": {"unorganised worker", "unorganized worker"},
}
RECOGNIZED_EMPLOYMENT = set(EMPLOYMENT_ALIASES).union(*EMPLOYMENT_ALIASES.values())

# Phrases that describe more than a simple employment status.
COMPLEX_EMPLOYMENT_TERMS = (
    "experience", "registered", "years", "household", "enterprise",
    "apprentice", "landless", "job card", "self help group", "self-help group",
)


def employment_labels(value) -> set[str]:
    value = normalize(value)
    if not value:
        return set()
    labels = {value}
    for canonical, aliases in EMPLOYMENT_ALIASES.items():
        if value == canonical or value in aliases:
            labels |= {canonical} | aliases
    return labels


def employment_check(required, citizen) -> Optional[bool]:
    required_values = split_values(required)
    if not required_values or "any" in required_values:
        return True

    citizen_value = normalize(citizen)
    if not citizen_value:
        return None

    if any(term in item for item in required_values for term in COMPLEX_EMPLOYMENT_TERMS):
        return None

    citizen_labels = employment_labels(citizen_value)
    if any(citizen_labels & employment_labels(item) for item in required_values):
        return True

    if all(item in RECOGNIZED_EMPLOYMENT for item in required_values):
        return False
    return None


GENDER_ALIASES = {
    "male": {"male", "man", "men"},
    "female": {"female", "woman", "women"},
    "transgender": {"transgender", "trans"},
}


def _canonical(value: str, aliases: dict[str, set[str]]) -> Optional[str]:
    return next(
        (key for key, values in aliases.items() if value == key or value in values),
        None,
    )


def gender_check(required, citizen) -> Optional[bool]:
    if is_unrestricted(required):
        return True
    citizen = normalize(citizen)
    if not citizen or is_unrestricted(citizen):
        return None
    required_group = _canonical(normalize(required), GENDER_ALIASES)
    citizen_group = _canonical(citizen, GENDER_ALIASES)
    # Unknown labels must be verified, not assumed to match.
    if required_group is None or citizen_group is None:
        return None
    return required_group == citizen_group


CATEGORY_ALIASES = {
    "general": {"general", "unreserved", "ur"},
    "obc": {"obc", "other backward class", "other backward classes"},
    "sc": {"sc", "scheduled caste"},
    "st": {"st", "scheduled tribe"},
    "ews": {"ews", "economically weaker section"},
}


def category_check(required, citizen) -> Optional[bool]:
    allowed = split_values(required)
    if not allowed or any(item in UNRESTRICTED_VALUES for item in allowed):
        return True
    citizen_value = normalize(citizen)
    if not citizen_value:
        return None

    def canonical(value):
        return _canonical(value, CATEGORY_ALIASES) or value

    return canonical(citizen_value) in {canonical(item) for item in allowed}


def age_check(age, min_age, max_age) -> Optional[bool]:
    if min_age is None and max_age is None:
        return True  # no age limit: a missing date of birth is irrelevant
    if age is None:
        return None
    if min_age is not None and age < min_age:
        return False
    if max_age is not None and age > max_age:
        return False
    return True


# ---------------------------------------------------------
# EVALUATION ACCUMULATOR
# ---------------------------------------------------------

@dataclass
class Evaluation:
    reasons: list[str] = field(default_factory=list)
    missing: list[tuple[str, str]] = field(default_factory=list)  # (code, message)
    excluded: bool = False

    def record(self, result, code, satisfied_msg, missing_msg, *, applicable=True):
        """Record a tri-state result. `applicable=False` suppresses the
        'satisfied' reason for criteria the scheme does not actually restrict."""
        if result is False:
            self.excluded = True
        elif result is None:
            self.missing.append((code, missing_msg))
        elif applicable:
            self.reasons.append(satisfied_msg)

    def record_flag(self, required_raw, profile_value, code, label, noun):
        """Handle yes/no requirements such as BPL, disability and farmer status."""
        required = parse_yes_no(required_raw)
        if required is True:
            self.record(
                parse_yes_no(profile_value), code,
                f"{label} requirement satisfied",
                f"{label} status needs verification",
            )
        elif required is None and not is_unrestricted(required_raw):
            self.missing.append((f"{code}_scheme", f"Scheme {noun} requirement needs review"))


# ---------------------------------------------------------
# SCHEME-SPECIFIC REVIEW FLAGS
# ---------------------------------------------------------

FARMER_KEYWORDS = (
    "farmer", "agriculture", "agricultural", "crop insurance", "kisan credit",
)

# (keywords searched in name/category/description/purpose, review prompt)
OFFICIAL_CHECK_RULES = (
    (FARMER_KEYWORDS,
     "Verify landholding, cultivation, tenancy or other scheme-specific farmer conditions"),
    (("scholarship", "merit-based", "merit based", "academic performance"),
     "Verify academic marks, course, institution and other scholarship conditions"),
    (("ex-servicemen", "ex-serviceman", "coast guard", "warb", "armed forces"),
     "Verify the required service-family relationship"),
    (("startup", "micro enterprise", "micro-enterprise", "mudra", "msme",
      "pmegp", "business loan"),
     "Verify business ownership, project, registration and scheme-specific conditions"),
    (("housing", "awas yojana", "housing loan", "house ownership"),
     "Verify household income, existing house ownership and applicable housing conditions"),
    (("ration card", "food security", "family per year", "household"),
     "Verify household, ration-card and beneficiary records"),
    (("mgnrega", "100 days guaranteed wage employment"),
     "Verify rural household, job-card and registration conditions"),
    (("pension", "insurance", "pmjjby", "pmsby", "jan dhan", "pm-jay", "ayushman bharat"),
     "Verify official beneficiary conditions, enrollment and any applicable age or account requirements"),
)


@dataclass(frozen=True)
class SchemeText:
    """Normalised searchable text of a scheme, computed once."""
    category: str
    combined: str

    @classmethod
    def from_row(cls, scheme) -> "SchemeText":
        parts = [
            normalize(scheme[key]) or ""
            for key in ("name", "scheme_category", "description", "purpose")
        ]
        return cls(category=parts[1], combined=" ".join(parts))

    def mentions(self, keywords) -> bool:
        return any(word in self.combined for word in keywords)

    @property
    def is_farmer_category(self) -> bool:
        """Reliable signal: the catalogue itself files it under farmers."""
        return self.category == "farmer support"

    @property
    def mentions_farmers(self) -> bool:
        """Weak signal: keywords can appear in unrelated descriptions."""
        return self.mentions(FARMER_KEYWORDS)


def scheme_specific_checks(text_info: SchemeText) -> list[str]:
    """Review prompts only; they are not proof of eligibility."""
    return list(dict.fromkeys(
        message
        for keywords, message in OFFICIAL_CHECK_RULES
        if text_info.mentions(keywords)
    ))


# ---------------------------------------------------------
# NEXT ACTIONS
# ---------------------------------------------------------

NEXT_ACTIONS = {
    "dob": "Add or verify your date of birth in your profile.",
    "gender": "Complete or verify your gender information in your citizen profile.",
    "state": "Complete your state information in your profile.",
    "income": "Complete or verify your annual household income.",
    "category": "Complete or verify your social category information.",
    "bpl": "Verify your BPL status using your official household or ration-card records.",
    "disability": "Complete or verify your disability information.",
    "education": "Complete your education details and check the scheme's education requirements.",
    "employment": "Complete your employment details and check the scheme's employment requirements.",
    "farmer": "Verify your farmer status and any relevant landholding or cultivation details.",
}


def build_next_actions(missing, official_checks) -> list[str]:
    actions = [
        NEXT_ACTIONS.get(code, f"Resolve this profile check: {message}")
        for code, message in missing
    ]
    actions += [
        f"Before applying, check with the relevant scheme authority: {check}"
        for check in official_checks
    ]
    if not actions:
        actions.append("Review the current official scheme guidelines before applying.")
    return list(dict.fromkeys(actions))


# ---------------------------------------------------------
# DATA ACCESS
# ---------------------------------------------------------

PROFILE_SQL = text("""
    SELECT date_of_birth, gender, state, district, annual_income, category,
           disability, bpl_status, education_level, employment_status,
           farmer_status
    FROM citizen_profiles
    WHERE user_id = :user_id
""")

SCHEMES_SQL = text("""
    SELECT s.id AS scheme_id, s.name, s.scheme_type,
           s.category AS scheme_category, s.state AS scheme_state,
           s.description,
           e.min_age, e.max_age, e.gender AS required_gender,
           e.caste_eligible, e.income_limit, e.bpl_required, e.purpose,
           e.min_education, e.employment_status, e.disability_required
    FROM schemes s
    JOIN scheme_eligibility e ON e.scheme_id = s.id
    WHERE s.is_active = TRUE
    ORDER BY s.name
""")


# ---------------------------------------------------------
# MATCHING
# ---------------------------------------------------------

def evaluate_scheme(scheme, profile, age) -> Evaluation:
    ev = Evaluation()

    # Age
    has_age_rule = scheme["min_age"] is not None or scheme["max_age"] is not None
    ev.record(
        age_check(age, scheme["min_age"], scheme["max_age"]),
        "dob", "Age requirement satisfied", "Date of birth needs verification",
        applicable=has_age_rule,
    )

    # Gender
    ev.record(
        gender_check(scheme["required_gender"], profile["gender"]),
        "gender", "Gender requirement satisfied",
        "Gender requirement needs verification",
        applicable=not is_unrestricted(scheme["required_gender"]),
    )

    # State
    scheme_states = split_values(scheme["scheme_state"])
    if scheme_states and not any(s in NATIONWIDE_VALUES for s in scheme_states):
        citizen_state = normalize(profile["state"])
        # Known citizen state that is not among the scheme's states -> excluded.
        ev.record(
            None if not citizen_state else citizen_state in scheme_states,
            "state", "State requirement satisfied", "State needs verification",
        )

    # Income
    income_limit = scheme["income_limit"]
    if income_limit is not None:
        income = profile["annual_income"]
        ev.record(
            None if income is None else income <= income_limit,
            "income", "Income is within the stored limit",
            "Annual income needs verification",
        )

    # Caste / category
    ev.record(
        category_check(scheme["caste_eligible"], profile["category"]),
        "category", "Category requirement satisfied",
        "Caste/category needs verification",
        applicable=not is_unrestricted(scheme["caste_eligible"]),
    )

    # BPL and disability
    ev.record_flag(scheme["bpl_required"], profile["bpl_status"], "bpl", "BPL", "BPL")
    ev.record_flag(
        scheme["disability_required"], profile["disability"],
        "disability", "Disability", "disability",
    )

    # Education
    ev.record(
        education_check(scheme["min_education"], profile["education_level"]),
        "education", "Minimum education requirement satisfied",
        "Education requirement needs verification",
        applicable=not is_unrestricted(scheme["min_education"]),
    )
    # (unrestricted + unknown cannot happen: education_check returns True)

    # Employment
    ev.record(
        employment_check(scheme["employment_status"], profile["employment_status"]),
        "employment", "Employment requirement satisfied",
        "Employment requirement needs verification",
        applicable=not is_unrestricted(scheme["employment_status"]),
    )

    # Farmer status
    scheme_text = SchemeText.from_row(scheme)
    if scheme_text.is_farmer_category:
        ev.record(
            parse_yes_no(profile["farmer_status"]),
            "farmer", "Farmer status recorded as affirmative",
            "Farmer status needs verification",
        )
    elif scheme_text.mentions_farmers:
        # Keyword-only detection must never exclude a scheme: a non-farmer
        # may still qualify for a scheme that merely mentions farmers.
        if parse_yes_no(profile["farmer_status"]) is not True:
            ev.missing.append(("farmer", "Farmer status needs verification"))

    return ev


def build_match(scheme, ev: Evaluation) -> dict:
    official_checks = scheme_specific_checks(SchemeText.from_row(scheme))
    missing = list(dict.fromkeys(ev.missing))
    return {
        "scheme_id": scheme["scheme_id"],
        "name": scheme["name"],
        "scheme_type": scheme["scheme_type"],
        "category": scheme["scheme_category"],
        "state": scheme["scheme_state"],
        "description": scheme["description"],
        "match_status": (
            NEEDS_VERIFICATION if missing or official_checks else POTENTIAL_MATCH
        ),
        "reasons": list(dict.fromkeys(ev.reasons)),
        "needs_verification": [message for _, message in missing],
        "official_checks": official_checks,
        "next_actions": build_next_actions(missing, official_checks),
    }


# ---------------------------------------------------------
# API
# ---------------------------------------------------------

@router.get("/matches")
def get_eligibility_matches(
    user: User = Depends(get_authenticated_citizen),
    db: Session = Depends(get_db),
):
    profile = db.execute(PROFILE_SQL, {"user_id": user.id}).mappings().first()

    if profile is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Citizen profile not found. Complete your profile first.",
        )

    age = calculate_age(profile["date_of_birth"])
    schemes = db.execute(SCHEMES_SQL).mappings().all()

    matches = []
    for scheme in schemes:
        ev = evaluate_scheme(scheme, profile, age)
        # Do not show a scheme when a configured criterion fails.
        if not ev.excluded:
            matches.append(build_match(scheme, ev))

    potential = sum(m["match_status"] == POTENTIAL_MATCH for m in matches)

    return {
        "citizen_id": user.id,
        "age_calculated": age,
        "total_potential_schemes": len(matches),
        "potential_matches": potential,
        "schemes_needing_verification": len(matches) - potential,
        "matches": matches,
        "notice": (
            "Potential matches are based on the stored catalogue and "
            "configured rules. They are not confirmed legal eligibility "
            "or a guarantee of approval. Review official_checks and "
            "verify the latest official scheme rules before applying."
        ),
    }