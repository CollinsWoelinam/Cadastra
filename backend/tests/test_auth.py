import psycopg
import pytest

from .conftest import PASSWORD, TEST_URL, As, login_as, square


def test_login_rejects_bad_credentials(app_client, accounts):
    bad = app_client.post("/auth/login", json={"email": "surveyor@test.gh", "password": "nope-nope-nope"})
    unknown = app_client.post("/auth/login", json={"email": "ghost@test.gh", "password": PASSWORD})
    assert bad.status_code == unknown.status_code == 401
    assert bad.json() == unknown.json()  # no hint whether the account exists


def test_email_is_case_insensitive(app_client, accounts):
    r = app_client.post("/auth/login", json={"email": "SURVEYOR@Test.GH", "password": PASSWORD})
    assert r.status_code == 200
    assert r.json()["user"]["role"] == "SURVEYOR"


def test_everything_but_health_requires_a_token(app_client):
    assert app_client.get("/health").status_code == 200
    for path in ["/parcels", "/parcels/extent", "/tiles/14/0/0.mvt", "/auth/me", "/users"]:
        r = app_client.get(path)
        assert r.status_code == 401, path
        assert r.headers["www-authenticate"] == "Bearer"
    assert app_client.get("/parcels", headers={"Authorization": "Bearer junk"}).status_code == 401


def test_me(client):
    me = client.get("/auth/me").json()
    assert (me["email"], me["role"]) == ("surveyor@test.gh", "SURVEYOR")


def test_refresh_rotates_and_detects_reuse(app_client, accounts):
    pair = app_client.post("/auth/login", json={"email": "surveyor2@test.gh", "password": PASSWORD}).json()
    first = pair["refresh_token"]
    rotated = app_client.post("/auth/refresh", json={"refresh_token": first})
    assert rotated.status_code == 200
    second = rotated.json()["refresh_token"]
    assert second != first
    assert As(app_client, rotated.json()["access_token"], {}).get("/auth/me").status_code == 200

    # Replaying the rotated token is treated as theft: all sessions are revoked.
    assert app_client.post("/auth/refresh", json={"refresh_token": first}).status_code == 401
    assert app_client.post("/auth/refresh", json={"refresh_token": second}).status_code == 401


def test_logout_revokes_refresh_token(app_client, accounts):
    pair = app_client.post("/auth/login", json={"email": "surveyor2@test.gh", "password": PASSWORD}).json()
    assert app_client.post("/auth/logout", json={"refresh_token": pair["refresh_token"]}).status_code == 204
    assert app_client.post("/auth/refresh", json={"refresh_token": pair["refresh_token"]}).status_code == 401


def test_roles_gate_submission_and_review(client, reviewer, submit):
    body = {"title_deed_no": "GA-R1", "owner_name": "X", "boundary": square(0, 0, 10)}
    assert reviewer.post("/parcels", json=body).status_code == 403
    pid = submit(square(0, 0, 10)).json()["parcel"]["id"]
    assert client.post(f"/parcels/{pid}/approve", json={}).status_code == 403
    assert client.post(f"/parcels/{pid}/reject", json={}).status_code == 403
    assert reviewer.post(f"/parcels/{pid}/approve", json={}).status_code == 200


def test_submitter_and_reviewer_are_recorded(client, reviewer, submit):
    parcel = submit(square(0, 0, 10)).json()["parcel"]
    assert parcel["submitted_by"] == client.user["id"]
    approved = reviewer.post(f"/parcels/{parcel['id']}/approve", json={}).json()
    assert approved["reviewed_by"] == reviewer.user["id"]
    assert approved["reviewed_by_name"] == "Reviewer"


def test_nobody_reviews_their_own_submission(admin):
    # ADMIN may both submit and review, but never the same parcel.
    r = admin.post("/parcels", json={"title_deed_no": "GA-SELF", "owner_name": "X", "boundary": square(0, 0, 10)})
    pid = r.json()["parcel"]["id"]
    assert admin.post(f"/parcels/{pid}/approve", json={}).status_code == 403
    assert admin.post(f"/parcels/{pid}/reject", json={}).status_code == 403


def test_client_ref_cannot_be_reused_by_another_surveyor(app_client, accounts, submit):
    ref = "5c2f8a1e-0000-4000-8000-00000000abcd"
    assert submit(square(0, 0, 10), client_ref=ref).status_code == 201
    other = login_as(app_client, accounts, "surveyor2")
    r = other.post("/parcels", json={"client_ref": ref, "title_deed_no": "GA-OTHER", "owner_name": "X",
                                     "boundary": square(0, 0, 10)})
    assert r.status_code == 409


def test_admin_manages_users(app_client, admin, client):
    assert client.get("/users").status_code == 403
    new = admin.post("/users", json={"email": "new.surveyor@test.gh", "full_name": "New Surveyor",
                                     "password": "a-long-enough-password", "role": "SURVEYOR"})
    assert new.status_code == 201
    assert admin.post("/users", json={"email": "NEW.surveyor@test.gh", "full_name": "Dup",
                                      "password": "a-long-enough-password", "role": "SURVEYOR"}).status_code == 409
    assert admin.post("/users", json={"email": "short@test.gh", "full_name": "S",
                                      "password": "short", "role": "SURVEYOR"}).status_code == 422

    session = app_client.post("/auth/login", json={"email": "new.surveyor@test.gh",
                                                   "password": "a-long-enough-password"}).json()
    user = As(app_client, session["access_token"], session["user"])
    assert user.get("/auth/me").status_code == 200

    # Deactivation takes effect immediately and kills refresh tokens.
    uid = new.json()["id"]
    assert admin.patch(f"/users/{uid}", json={"is_active": False}).status_code == 200
    assert user.get("/auth/me").status_code == 401
    assert app_client.post("/auth/refresh", json={"refresh_token": session["refresh_token"]}).status_code == 401
    assert app_client.post("/auth/login", json={"email": "new.surveyor@test.gh",
                                                "password": "a-long-enough-password"}).status_code == 401


def test_role_change_applies_to_existing_tokens(app_client, admin, accounts):
    s2 = login_as(app_client, accounts, "surveyor2")
    assert s2.get("/users").status_code == 403
    admin.patch(f"/users/{accounts['surveyor2']['id']}", json={"role": "ADMIN"})
    try:
        assert s2.get("/users").status_code == 200
    finally:
        admin.patch(f"/users/{accounts['surveyor2']['id']}", json={"role": "SURVEYOR"})


def test_admin_cannot_lock_themselves_out(admin):
    assert admin.patch(f"/users/{admin.user['id']}", json={"is_active": False}).status_code == 409
    assert admin.patch(f"/users/{admin.user['id']}", json={"role": "REVIEWER"}).status_code == 409


def test_passwords_are_hashed(accounts):
    with psycopg.connect(TEST_URL) as conn:
        stored = conn.execute("SELECT password_hash FROM users WHERE email = 'surveyor@test.gh'").fetchone()[0]
    assert stored.startswith("$argon2id$") and PASSWORD not in stored


# --- Sign-in throttling ------------------------------------------------------------

@pytest.fixture
def limits(monkeypatch):
    from app.config import settings
    monkeypatch.setattr(settings, "login_max_failures_per_email", 3)
    monkeypatch.setattr(settings, "login_max_failures_per_ip", 6)
    return settings


def _login(app_client, email, password=PASSWORD):
    return app_client.post("/auth/login", json={"email": email, "password": password})


def test_repeated_failures_lock_the_email(app_client, accounts, limits):
    for _ in range(3):
        assert _login(app_client, "surveyor2@test.gh", "wrong-password-0").status_code == 401
    # Even the right password is refused until the window passes, so guessing can't continue.
    r = _login(app_client, "SURVEYOR2@test.gh")
    assert r.status_code == 429
    assert 0 < int(r.headers["retry-after"]) <= limits.login_window_minutes * 60
    assert _login(app_client, "reviewer@test.gh").status_code == 200  # other accounts unaffected


def test_unknown_emails_are_throttled_too(app_client, accounts, limits):
    for _ in range(3):
        _login(app_client, "ghost@test.gh", "wrong-password-0")
    assert _login(app_client, "ghost@test.gh", "wrong-password-0").status_code == 429


def test_success_resets_the_email_count(app_client, accounts, limits):
    for _ in range(2):
        _login(app_client, "surveyor2@test.gh", "wrong-password-0")
    assert _login(app_client, "surveyor2@test.gh").status_code == 200
    for _ in range(2):
        _login(app_client, "surveyor2@test.gh", "wrong-password-0")
    assert _login(app_client, "surveyor2@test.gh").status_code == 200


def test_failures_age_out_of_the_window(app_client, accounts, limits):
    for _ in range(3):
        _login(app_client, "surveyor2@test.gh", "wrong-password-0")
    with psycopg.connect(TEST_URL, autocommit=True) as conn:
        conn.execute("UPDATE login_attempts SET attempted_at = attempted_at - interval '16 minutes'")
    assert _login(app_client, "surveyor2@test.gh").status_code == 200


def test_one_address_guessing_many_accounts_is_throttled(app_client, accounts, limits):
    # TestClient requests all come from the same address.
    for i in range(6):
        assert _login(app_client, f"user{i}@test.gh", "wrong-password-0").status_code == 401
    assert _login(app_client, "reviewer@test.gh").status_code == 429
