
from app.database import SessionLocal
from app.models import User
from app.eligibility_routes import (
    get_eligibility_matches as run_v1,
)
from app.eligibility_routes_v2_test import (
    PROFILE_SQL,
    SCHEMES_SQL,
    calculate_age,
    evaluate_scheme,
    build_match,
)


def main():
    db = SessionLocal()

    try:
        user_id = 1
        user = db.query(User).filter(User.id == user_id).first()

        if user is None:
            print(f"User {user_id} was not found.")
            return

        # Run Version 1's actual endpoint function directly.
        v1_response = run_v1(user=user, db=db)
        v1_matches = {
            item["scheme_id"]: item
            for item in v1_response["matches"]
        }

        # Run Version 2 against the same profile and scheme data.
        profile = db.execute(
            PROFILE_SQL, {"user_id": user_id}
        ).mappings().first()

        if profile is None:
            print("Citizen profile was not found.")
            return

        age = calculate_age(profile["date_of_birth"])
        schemes = db.execute(SCHEMES_SQL).mappings().all()

        v2_matches = {}

        for scheme in schemes:
            evaluation = evaluate_scheme(scheme, profile, age)

            if not evaluation.excluded:
                match = build_match(scheme, evaluation)
                v2_matches[match["scheme_id"]] = match

        ids_v1 = set(v1_matches)
        ids_v2 = set(v2_matches)

        only_v1 = sorted(ids_v1 - ids_v2)
        only_v2 = sorted(ids_v2 - ids_v1)
        common = ids_v1 & ids_v2

        status_changes = [
            (
                scheme_id,
                v1_matches[scheme_id]["name"],
                v1_matches[scheme_id]["match_status"],
                v2_matches[scheme_id]["match_status"],
            )
            for scheme_id in sorted(common)
            if v1_matches[scheme_id]["match_status"]
            != v2_matches[scheme_id]["match_status"]
        ]

        print("=== SIDE-BY-SIDE RESULTS ===")
        print("Citizen ID:", user_id)
        print("Citizen state:", profile["state"])
        print("Version 1 returned:", len(v1_matches))
        print("Version 2 returned:", len(v2_matches))
        print("Returned by both:", len(common))

        print("\n=== ONLY IN VERSION 1 ===")
        if only_v1:
            for scheme_id in only_v1:
                item = v1_matches[scheme_id]
                print(
                    scheme_id, "|", item["name"],
                    "|", item["state"],
                    "|", item["match_status"],
                )
        else:
            print("None")

        print("\n=== ONLY IN VERSION 2 ===")
        if only_v2:
            for scheme_id in only_v2:
                item = v2_matches[scheme_id]
                print(
                    scheme_id, "|", item["name"],
                    "|", item["state"],
                    "|", item["match_status"],
                )
        else:
            print("None")

        print("\n=== STATUS DIFFERENCES ===")
        if status_changes:
            for row in status_changes:
                print(
                    f"ID {row[0]} | {row[1]} | "
                    f"V1={row[2]} | V2={row[3]}"
                )
        else:
            print("No status differences among common schemes.")

        print("\n=== WEST BENGAL SCHEME ID 87 ===")
        print("Version 1 returned it:", 87 in v1_matches)
        print("Version 2 returned it:", 87 in v2_matches)

        print("\nComparison complete. No database records were changed.")

    finally:
        db.close()


if __name__ == "__main__":
    main()
