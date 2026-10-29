"""Create an account, e.g. the first admin:

    docker compose run --rm api python -m scripts.create_user admin@lands.gov.gh "Ama Owusu" ADMIN

The password is read from CADASTRA_PASSWORD or prompted for.
"""

import argparse
import getpass
import os

import psycopg
from psycopg.rows import dict_row

from app.auth import ROLES, create_user
from app.config import settings
from app.db import migrate


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("email")
    parser.add_argument("full_name")
    parser.add_argument("role", choices=ROLES)
    args = parser.parse_args()
    password = os.environ.get("CADASTRA_PASSWORD") or getpass.getpass("Password (min 12 chars): ")
    if len(password) < 12:
        raise SystemExit("password must be at least 12 characters")
    migrate(settings.database_url)
    with psycopg.connect(settings.database_url, row_factory=dict_row) as conn:
        user = create_user(conn, args.email, args.full_name, password, args.role)
    print(f"created {user['role']} {user['email']} ({user['id']})")


if __name__ == "__main__":
    main()
