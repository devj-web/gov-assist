
from app.eligibility_routes_v2_test import (
    age_check,
    gender_check,
    category_check,
    education_check,
    employment_check,
    evaluate_scheme,
)


def check(label, actual, expected):
    assert actual == expected, (
        f"FAIL: {label}: expected {expected!r}, got {actual!r}"
    )
    print(f"PASS: {label}")


def make_scheme(**overrides):
    scheme = {
        "scheme_id": 1,
        "name": "General Test Scheme",
        "scheme_type": "State",
        "scheme_category": "General Welfare",
        "scheme_state": "Kerala",
        "description": "General assistance",
        "min_age": None,
        "max_age": None,
        "required_gender": "Any",
        "caste_eligible": "All",
        "income_limit": None,
        "bpl_required": "No",
        "purpose": "General assistance",
        "min_education": "Any",
        "employment_status": "Any",
        "disability_required": "No",
    }
    scheme.update(overrides)
    return scheme


profile = {
    "date_of_birth": None,
    "gender": "Male",
    "state": "Kerala",
    "district": "Alappuzha",
    "annual_income": 100000,
    "category": "General",
    "disability": False,
    "bpl_status": "No",
    "education_level": "12th",
    "employment_status": "Student",
    "farmer_status": "No",
}


if __name__ == "__main__":
    print("=== Individual criterion tests ===")

    check("No age limit accepts missing age",
          age_check(None, None, None), True)

    check("Age requirement with missing age needs verification",
          age_check(None, 18, None), None)

    check("Underage applicant fails minimum age",
          age_check(16, 18, None), False)

    check("Male matches male requirement",
          gender_check("Male", "Male"), True)

    check("Male does not match female requirement",
          gender_check("Female", "Male"), False)

    check("Unknown gender requires verification",
          gender_check("Female", "Any"), None)

    check("General category matches General",
          category_check("General", "General"), True)

    check("SC category does not match General",
          category_check("SC", "General"), False)

    check("12th education meets 10th requirement",
          education_check("10th", "12th"), True)

    check("12th education does not meet graduate requirement",
          education_check("Graduate", "12th"), False)

    check("Student matches student requirement",
          employment_check("Student", "Student"), True)

    check("Student does not match unemployed requirement",
          employment_check("Unemployed", "Student"), False)

    print("\n=== Complete scheme evaluation tests ===")

    kerala_scheme = make_scheme()
    result = evaluate_scheme(kerala_scheme, profile, age=None)

    check("Kerala scheme is not excluded",
          result.excluded, False)

    west_bengal_scheme = make_scheme(scheme_state="West Bengal")
    result = evaluate_scheme(west_bengal_scheme, profile, age=None)

    check("West Bengal scheme is excluded",
          result.excluded, True)

    income_scheme = make_scheme(income_limit=50000)
    result = evaluate_scheme(income_scheme, profile, age=None)

    check("Income above limit excludes applicant",
          result.excluded, True)

    print("\nAll eligibility tests passed.")
