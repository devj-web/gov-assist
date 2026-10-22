
import csv
import sys
from pathlib import Path
from decimal import Decimal, InvalidOperation

from sqlalchemy import text

from app.database import engine


CSV_PATH = Path(__file__).parent / "government_schemes.csv"


def clean(value):
    if value is None:
        return None
    value = value.strip()
    return value if value else None


def to_int(value):
    value = clean(value)
    if value is None:
        return None
    try:
        return int(value)
    except ValueError:
        return None


def to_decimal(value):
    value = clean(value)
    if value is None:
        return None
    try:
        return Decimal(value.replace(",", ""))
    except InvalidOperation:
        return None


def import_schemes():
    if not CSV_PATH.exists():
        print(f"ERROR: CSV file not found: {CSV_PATH}")
        sys.exit(1)

    required_columns = {
        "schemeName", "category", "minAge", "maxAge", "gender",
        "casteEligible", "incomeLimit", "bplRequired", "purpose",
        "minEducation", "employmentStatus", "disabilityRequired",
        "schemeType", "state", "description"
    }

    with CSV_PATH.open("r", encoding="utf-8-sig", newline="") as file:
        reader = csv.DictReader(file)

        if not reader.fieldnames:
            print("ERROR: CSV has no header row.")
            sys.exit(1)

        missing = required_columns - set(reader.fieldnames)
        if missing:
            print("ERROR: Missing CSV columns:", ", ".join(sorted(missing)))
            sys.exit(1)

        rows = list(reader)

    prepared = []
    seen = set()

    for line_number, row in enumerate(rows, start=2):
        name = clean(row.get("schemeName"))
        if not name:
            print(f"Skipping row {line_number}: scheme name is empty.")
            continue

        key = name.casefold()
        if key in seen:
            print(f"Skipping duplicate scheme in CSV: {name}")
            continue
        seen.add(key)

        scheme_type = (clean(row.get("schemeType")) or "").title()
        if scheme_type not in {"Central", "State"}:
            print(f"Skipping {name}: unexpected schemeType.")
            continue

        prepared.append({
            "name": name,
            "scheme_type": scheme_type,
            "category": clean(row.get("category")) or "Other",
            "state": clean(row.get("state")) or "All",
            "description": clean(row.get("description")),
            "min_age": to_int(row.get("minAge")),
            "max_age": to_int(row.get("maxAge")),
            "gender": clean(row.get("gender")),
            "caste_eligible": clean(row.get("casteEligible")),
            "income_limit": to_decimal(row.get("incomeLimit")),
            "bpl_required": clean(row.get("bplRequired")),
            "purpose": clean(row.get("purpose")),
            "min_education": clean(row.get("minEducation")),
            "employment_status": clean(row.get("employmentStatus")),
            "disability_required": clean(row.get("disabilityRequired")),
        })

    if not prepared:
        print("ERROR: No valid schemes found. Nothing imported.")
        sys.exit(1)

    # Preview and validate before changing the database.
    print(f"Valid schemes prepared: {len(prepared)}")
    print("First three schemes:")
    for item in prepared[:3]:
        print(f"- {item['name']} ({item['scheme_type']})")

    answer = input(
        "\nImport these schemes into govassist_fresh_db? Type YES to continue: "
    ).strip()

    if answer != "YES":
        print("Import cancelled. No database changes made.")
        return

    with engine.begin() as connection:
        database_name = connection.execute(
            text("SELECT current_database()")
        ).scalar_one()

        if database_name != "govassist_fresh_db":
            raise RuntimeError(
                f"Safety check failed: connected to {database_name}, "
                "not govassist_fresh_db. Nothing imported."
            )

        for item in prepared:
            existing = connection.execute(
                text("""
                    SELECT id FROM schemes
                    WHERE lower(name) = lower(:name)
                    LIMIT 1
                """),
                {"name": item["name"]},
            ).first()

            if existing:
                scheme_id = existing[0]
                connection.execute(
                    text("""
                        UPDATE schemes
                        SET scheme_type = :scheme_type,
                            category = :category,
                            state = :state,
                            description = :description,
                            is_active = TRUE
                        WHERE id = :scheme_id
                    """),
                    {
                        "scheme_id": scheme_id,
                        "scheme_type": item["scheme_type"],
                        "category": item["category"],
                        "state": item["state"],
                        "description": item["description"],
                    },
                )
            else:
                scheme_id = connection.execute(
                    text("""
                        INSERT INTO schemes
                            (name, scheme_type, category, state, description, is_active)
                        VALUES
                            (:name, :scheme_type, :category, :state, :description, TRUE)
                        RETURNING id
                    """),
                    {
                        "name": item["name"],
                        "scheme_type": item["scheme_type"],
                        "category": item["category"],
                        "state": item["state"],
                        "description": item["description"],
                    },
                ).scalar_one()

            connection.execute(
                text("""
                    INSERT INTO scheme_eligibility (
                        scheme_id, min_age, max_age, gender, caste_eligible,
                        income_limit, bpl_required, purpose, min_education,
                        employment_status, disability_required
                    )
                    VALUES (
                        :scheme_id, :min_age, :max_age, :gender, :caste_eligible,
                        :income_limit, :bpl_required, :purpose, :min_education,
                        :employment_status, :disability_required
                    )
                    ON CONFLICT (scheme_id) DO UPDATE SET
                        min_age = EXCLUDED.min_age,
                        max_age = EXCLUDED.max_age,
                        gender = EXCLUDED.gender,
                        caste_eligible = EXCLUDED.caste_eligible,
                        income_limit = EXCLUDED.income_limit,
                        bpl_required = EXCLUDED.bpl_required,
                        purpose = EXCLUDED.purpose,
                        min_education = EXCLUDED.min_education,
                        employment_status = EXCLUDED.employment_status,
                        disability_required = EXCLUDED.disability_required
                """),
                item | {"scheme_id": scheme_id},
            )

    print(f"\nImport completed successfully: {len(prepared)} schemes processed.")


if __name__ == "__main__":
    import_schemes()
