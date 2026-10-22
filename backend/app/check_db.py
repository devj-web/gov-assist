
from sqlalchemy import text
from app.database import engine

try:
    with engine.connect() as connection:
        result = connection.execute(
            text("SELECT current_database(), version()")
        )
        database_name, version = result.fetchone()

        print("Database connection successful!")
        print("Database:", database_name)
        print("PostgreSQL:", version.split(",")[0])

except Exception as error:
    print("Database connection failed.")
    print(type(error).__name__ + ":", error)
