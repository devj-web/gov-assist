
from app.database import Base, engine
from app import models


def main():
    print("Checking database models...")

    print("Tables to create:")
    for table_name in Base.metadata.tables:
        print(f"- {table_name}")

    Base.metadata.create_all(bind=engine)

    print("Database table initialization completed.")


if __name__ == "__main__":
    main()
