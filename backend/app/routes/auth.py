from fastapi import APIRouter, HTTPException, Response

from .. import auth
from ..auth import Conn, CurrentUser
from ..schemas import LoginRequest, RefreshRequest, TokenPair, User

router = APIRouter(prefix="/auth")


@router.post("/login", response_model=TokenPair)
def login(body: LoginRequest, conn: Conn):
    user = auth.authenticate(conn, body.email, body.password)
    if user is None:
        raise HTTPException(401, "incorrect email or password")
    return auth.issue_tokens(conn, user)


@router.post("/refresh", response_model=TokenPair)
def refresh(body: RefreshRequest, conn: Conn, response: Response):
    pair = auth.rotate_refresh_token(conn, body.refresh_token)
    if pair is None:
        # Commit the revocations rotate_refresh_token may have made before failing.
        conn.commit()
        raise HTTPException(401, "invalid or expired refresh token")
    return pair


@router.post("/logout", status_code=204)
def logout(body: RefreshRequest, conn: Conn):
    auth.revoke_refresh_token(conn, body.refresh_token)


@router.get("/me", response_model=User)
def me(user: CurrentUser):
    return user
