"""Accounts, tokens and the request dependencies that enforce them."""

import hashlib
import secrets
from datetime import datetime, timedelta, timezone
from typing import Annotated, Iterator
from uuid import UUID

import jwt
from argon2 import PasswordHasher
from argon2.exceptions import VerificationError
from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from psycopg import Connection

from .config import settings
from .db import pool

ROLES = ("SURVEYOR", "REVIEWER", "ADMIN")
USER_COLUMNS = "id, email, full_name, role, is_active, created_at"

_hasher = PasswordHasher()
# Verified against when the email is unknown, so response time doesn't reveal which
# emails have accounts.
_DUMMY_HASH = _hasher.hash("not-a-real-password")


def hash_password(password: str) -> str:
    return _hasher.hash(password)


def verify_password(password_hash: str | None, password: str) -> bool:
    try:
        return _hasher.verify(password_hash or _DUMMY_HASH, password) and password_hash is not None
    except VerificationError:
        return False


def _token_hash(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


def create_user(conn: Connection, email: str, full_name: str, password: str, role: str) -> dict:
    return conn.execute(f"""
        INSERT INTO users (email, full_name, password_hash, role) VALUES (%s, %s, %s, %s)
        RETURNING {USER_COLUMNS}
    """, (email.strip(), full_name.strip(), hash_password(password), role)).fetchone()


def authenticate(conn: Connection, email: str, password: str) -> dict | None:
    row = conn.execute(f"SELECT {USER_COLUMNS}, password_hash FROM users WHERE lower(email) = lower(%s)",
                       (email.strip(),)).fetchone()
    if not verify_password(row["password_hash"] if row else None, password) or not row["is_active"]:
        return None
    row.pop("password_hash")
    return row


def _nth_recent_failure(conn: Connection, where: str, params: tuple, limit: int) -> datetime | None:
    """The limit-th most recent failure in the window, if there are that many."""
    row = conn.execute(f"""
        SELECT attempted_at FROM login_attempts
        WHERE NOT succeeded AND attempted_at > now() - make_interval(mins => %s) AND {where}
        ORDER BY attempted_at DESC OFFSET %s LIMIT 1
    """, (settings.login_window_minutes, *params, limit - 1)).fetchone()
    return row["attempted_at"] if row else None


def login_retry_after(conn: Connection, email: str, ip: str | None) -> int | None:
    """Seconds until sign-in may be tried again for this email and IP, or None if allowed.

    Takes a per-email transaction lock, so concurrent guesses at one account are
    counted one at a time; hold the transaction until the attempt is recorded.
    """
    email = email.strip().lower()
    conn.execute("SELECT pg_advisory_xact_lock(727003, hashtext(%s))", (email,))
    blocked = [
        _nth_recent_failure(conn, """email = %s AND attempted_at > coalesce(
            (SELECT max(attempted_at) FROM login_attempts WHERE email = %s AND succeeded), '-infinity')""",
                            (email, email), settings.login_max_failures_per_email),
    ]
    if ip:
        blocked.append(_nth_recent_failure(conn, "ip = %s", (ip,), settings.login_max_failures_per_ip))
    blocked = [t for t in blocked if t is not None]
    if not blocked:
        return None
    # Allowed again once the failure that reached the limit leaves the window.
    until = max(blocked) + timedelta(minutes=settings.login_window_minutes)
    return max(1, int((until - datetime.now(timezone.utc)).total_seconds()) + 1)


def record_login_attempt(conn: Connection, email: str, ip: str | None, succeeded: bool) -> None:
    conn.execute("INSERT INTO login_attempts (email, ip, succeeded) VALUES (%s, %s, %s)",
                 (email.strip().lower(), ip, succeeded))
    conn.execute("DELETE FROM login_attempts WHERE attempted_at < now() - interval '1 day'")


def issue_tokens(conn: Connection, user: dict) -> dict:
    now = datetime.now(timezone.utc)
    access_exp = now + timedelta(minutes=settings.access_token_ttl_minutes)
    access = jwt.encode({"sub": str(user["id"]), "role": user["role"], "iat": now, "exp": access_exp},
                        settings.jwt_secret, algorithm="HS256")
    refresh = secrets.token_urlsafe(48)
    refresh_exp = now + timedelta(days=settings.refresh_token_ttl_days)
    conn.execute("INSERT INTO refresh_tokens (user_id, token_hash, expires_at) VALUES (%s, %s, %s)",
                 (user["id"], _token_hash(refresh), refresh_exp))
    return {
        "access_token": access,
        "access_expires_at": access_exp,
        "refresh_token": refresh,
        "refresh_expires_at": refresh_exp,
        "user": user,
    }


def rotate_refresh_token(conn: Connection, token: str) -> dict | None:
    """Exchanges a refresh token for a new token pair, or returns None if it is invalid."""
    row = conn.execute("""
        SELECT id, user_id, expires_at, revoked_at FROM refresh_tokens WHERE token_hash = %s FOR UPDATE
    """, (_token_hash(token),)).fetchone()
    if row is None:
        return None
    if row["revoked_at"] is not None:
        # A rotated token being replayed means it leaked: end every session for the user.
        revoke_all(conn, row["user_id"])
        return None
    if row["expires_at"] <= datetime.now(timezone.utc):
        return None
    conn.execute("UPDATE refresh_tokens SET revoked_at = now() WHERE id = %s", (row["id"],))
    user = conn.execute(f"SELECT {USER_COLUMNS} FROM users WHERE id = %s", (row["user_id"],)).fetchone()
    if user is None or not user["is_active"]:
        return None
    return issue_tokens(conn, user)


def revoke_refresh_token(conn: Connection, token: str) -> None:
    conn.execute("UPDATE refresh_tokens SET revoked_at = now() WHERE token_hash = %s AND revoked_at IS NULL",
                 (_token_hash(token),))


def revoke_all(conn: Connection, user_id: UUID) -> None:
    conn.execute("UPDATE refresh_tokens SET revoked_at = now() WHERE user_id = %s AND revoked_at IS NULL",
                 (user_id,))


# --- Request dependencies -------------------------------------------------------

def get_conn() -> Iterator[Connection]:
    with pool.connection() as conn:
        yield conn


Conn = Annotated[Connection, Depends(get_conn)]
_bearer = HTTPBearer(auto_error=False)


def _unauthorized(detail: str) -> HTTPException:
    return HTTPException(401, detail, headers={"WWW-Authenticate": "Bearer"})


def current_user(conn: Conn,
                 creds: Annotated[HTTPAuthorizationCredentials | None, Depends(_bearer)]) -> dict:
    if creds is None:
        raise _unauthorized("not authenticated")
    try:
        claims = jwt.decode(creds.credentials, settings.jwt_secret, algorithms=["HS256"],
                            options={"require": ["sub", "exp"]})
    except jwt.ExpiredSignatureError:
        raise _unauthorized("token expired")
    except jwt.InvalidTokenError:
        raise _unauthorized("invalid token")
    # Re-read the account so deactivation and role changes apply immediately.
    user = conn.execute(f"SELECT {USER_COLUMNS} FROM users WHERE id = %s", (claims["sub"],)).fetchone()
    if user is None or not user["is_active"]:
        raise _unauthorized("account disabled")
    return user


CurrentUser = Annotated[dict, Depends(current_user)]


def require_role(*roles: str):
    def check(user: CurrentUser) -> dict:
        if user["role"] not in roles:
            raise HTTPException(403, f"requires role {' or '.join(roles)}")
        return user
    return Depends(check)
