"""Neon PostgreSQL URL from .env (DB_PASSWORD)."""

from __future__ import annotations

import os
from pathlib import Path
from urllib.parse import quote_plus

from dotenv import load_dotenv

_REPO_ROOT = Path(__file__).resolve().parent
load_dotenv(_REPO_ROOT / ".env")


def get_database_url() -> str:
    """Build the Neon connection string; password from DB_PASSWORD in .env."""
    password = os.environ.get("DB_PASSWORD")
    if not password:
        raise KeyError(
            "DB_PASSWORD is not set. Add it to your .env file in the repo root."
        )
    user = "neondb_owner"
    host = "ep-little-pine-am5l89vj-pooler.c-5.us-east-1.aws.neon.tech"
    dbname = "neondb"
    safe_pw = quote_plus(password)
    return (
        f"postgresql://{user}:{safe_pw}@{host}/{dbname}"
        "?sslmode=require&channel_binding=require"
    )


def connect():
    """Return a new psycopg connection using get_database_url()."""
    import psycopg

    return psycopg.connect(get_database_url())


if __name__ == "__main__":
    with connect() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT 1")
            assert cur.fetchone()[0] == 1
    print("Database connection OK.")
