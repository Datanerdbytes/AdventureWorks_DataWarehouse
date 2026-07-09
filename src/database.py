from dotenv import load_dotenv
from sqlalchemy import create_engine
import os

load_dotenv()

def get_engine():
    server = os.getenv("DB_SERVER")
    port = os.getenv("DB_PORT", "1433")
    database = os.getenv("DB_DATABASE")
    username = os.getenv("DB_USERNAME")
    password = os.getenv("DB_PASSWORD")
    driver = os.getenv("DB_DRIVER").replace(" ", "+")

    connection_string = (
        f"mssql+pyodbc://{username}:{password}@{server}:{port}/{database}"
        f"?driver={driver}"
        "&TrustServerCertificate=yes"
    )

    return create_engine(connection_string)