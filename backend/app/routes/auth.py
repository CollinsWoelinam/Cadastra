from fastapi import APIRouter, HTTPException, Request, Response

from .. import auth
from ..auth import Conn, CurrentUser
from ..schemas import LoginRequest, PasswordChange, RefreshRequest, TokenPair, User

router = APIRouter(prefix="/auth")


@router.post("/login", response_model=TokenPair)
def login(body: LoginRequest, conn: Conn, request: Request):
    # Behind a proxy this is the forwarded client address, as long as uvicorn is told
    # to trust that proxy (FORWARDED_ALLOW_IPS).
    ip = request.client.host if request.client else None
    retry_after = auth.login_retry_after(conn, body.email, ip)
    if retry_after is not None:
        raise HTTPException(429, "too many sign-in attempts; try again later",
                            headers={"Retry-After": str(retry_after)})
    user = auth.authenticate(conn, body.email, body.password)
    auth.record_login_attempt(conn, body.email, ip, succeeded=user is not None)
    if user is None:
        # Commit the failed attempt, which the error response would otherwise roll back.
        conn.commit()
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


@router.post("/password", response_model=TokenPair)
def change_password(body: PasswordChange, conn: Conn, user: CurrentUser, request: Request):
    """Changes the caller's password, ends all their sessions and starts a fresh one."""
    ip = request.client.host if request.client else None
    # Throttled like sign-in, so a stolen session can't be used to guess the password.
    retry_after = auth.login_retry_after(conn, user["email"], ip)
    if retry_after is not None:
        raise HTTPException(429, "too many attempts; try again later", headers={"Retry-After": str(retry_after)})
    if auth.authenticate(conn, user["email"], body.current_password) is None:
        auth.record_login_attempt(conn, user["email"], ip, succeeded=False)
        conn.commit()
        # 400, not 401: the session itself is fine.
        raise HTTPException(400, "current password is incorrect")
    if body.new_password == body.current_password:
        raise HTTPException(422, "the new password must differ from the current one")
    auth.set_password(conn, user["id"], body.new_password)
    auth.revoke_all(conn, user["id"])
    return auth.issue_tokens(conn, user)
