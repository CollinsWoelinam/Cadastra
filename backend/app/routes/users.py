from uuid import UUID

from fastapi import APIRouter, HTTPException
from psycopg import errors

from .. import auth
from ..auth import USER_COLUMNS, Conn, require_role
from ..schemas import User, UserCreate, UserUpdate

router = APIRouter(prefix="/users")
Admin = require_role("ADMIN")


@router.get("", response_model=list[User])
def list_users(conn: Conn, _=Admin):
    return conn.execute(f"""
        SELECT {USER_COLUMNS},
               (SELECT max(created_at) FROM refresh_tokens t WHERE t.user_id = users.id) AS last_active_at
        FROM users ORDER BY full_name
    """).fetchall()


@router.post("", response_model=User, status_code=201)
def create_user(body: UserCreate, conn: Conn, _=Admin):
    try:
        return auth.create_user(conn, body.email, body.full_name, body.password, body.role)
    except errors.UniqueViolation as e:
        raise HTTPException(409, "a user with that email already exists") from e


@router.patch("/{user_id}", response_model=User)
def update_user(user_id: UUID, body: UserUpdate, conn: Conn, admin=Admin):
    if user_id == admin["id"] and (body.is_active is False or body.role not in (None, "ADMIN")):
        raise HTTPException(409, "admins cannot deactivate or demote themselves")
    sets, params = [], []
    for column in ("full_name", "role", "is_active"):
        value = getattr(body, column)
        if value is not None:
            sets.append(f"{column} = %s")
            params.append(value)
    if body.password is not None:
        sets.append("password_hash = %s")
        params.append(auth.hash_password(body.password))
    if not sets:
        raise HTTPException(422, "nothing to update")
    user = conn.execute(f"UPDATE users SET {', '.join(sets)} WHERE id = %s RETURNING {USER_COLUMNS}",
                        (*params, user_id)).fetchone()
    if user is None:
        raise HTTPException(404, "user not found")
    if body.is_active is False or body.password is not None:
        auth.revoke_all(conn, user_id)
    if body.password is not None:
        # A reset is how a locked-out user gets back in, so lift the sign-in throttle too.
        auth.clear_login_failures(conn, user["email"])
    return user
