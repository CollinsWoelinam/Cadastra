import psycopg
import pytest

from app import certificates as certs

from .conftest import TEST_URL, square


@pytest.fixture
def issued(approved, reviewer):
    def _issued(boundary=None):
        parcel = approved(boundary or square(0, 0, 30))
        r = reviewer.post(f"/parcels/{parcel['id']}/certificates")
        assert r.status_code == 201, r.text
        return parcel, r.json()
    return _issued


def test_reviewers_issue_numbered_certificates_for_approved_parcels(client, reviewer, submit, issued):
    pending = submit(square(200, 0, 20)).json()["parcel"]["id"]
    assert reviewer.post(f"/parcels/{pending}/certificates").status_code == 409
    parcel, cert = issued()
    assert client.post(f"/parcels/{parcel['id']}/certificates").status_code == 403  # surveyors cannot
    assert cert["number"].startswith("C-20") and len(cert["number"]) == 13
    assert cert["code"].startswith("CDX-") and len(cert["code"]) == 13
    assert cert["issued_by_name"] == "Reviewer"
    listed = client.get(f"/parcels/{parcel['id']}/certificates").json()
    assert [(c["number"], c["current"]) for c in listed] == [(cert["number"], True)]
    events = client.get(f"/parcels/{parcel['id']}/events").json()
    assert events[-1]["event_type"] == "CERTIFICATE_ISSUED"


def test_anyone_can_verify_a_genuine_certificate(app_client, issued):
    parcel, cert = issued()
    for typed in (cert["code"], cert["code"].lower(), cert["code"].replace("-", "")[3:]):
        r = app_client.get(f"/verify/{typed}")  # no bearer token
        assert r.status_code == 200, typed
    body = r.json()
    assert body["verdict"] == "genuine"
    assert body["changes"] == []
    assert body["certificate"]["number"] == cert["number"]
    assert body["current"]["title_deed_no"] == parcel["title_deed_no"]
    assert body["current"]["corners"] == 4
    assert body["current"]["boundary"]["type"] == "Polygon"


def test_a_changed_record_makes_the_certificate_out_of_date(app_client, client, issued):
    parcel, cert = issued()
    with psycopg.connect(TEST_URL, autocommit=True) as conn:
        # A transfer and a ~1 m boundary correction after the certificate was issued.
        conn.execute("UPDATE parcels SET owner_name = 'Kwesi Mensah', boundary = ST_Translate(boundary, 0.00001, 0) "
                     "WHERE id = %s", (parcel["id"],))
    body = app_client.get(f"/verify/{cert['code']}").json()
    assert body["verdict"] == "outdated"
    assert body["changes"] == [
        {"field": "owner_name", "certified": "Ama Mensah", "current": "Kwesi Mensah"},
        {"field": "boundary", "certified": "as certified", "current": "changed"},
    ]
    assert client.get(f"/parcels/{parcel['id']}/certificates").json()[0]["current"] is False


def test_unknown_codes_are_throttled(app_client, monkeypatch):
    monkeypatch.setattr(certs, "MAX_MISSES", 3)
    for _ in range(3):
        assert app_client.get("/verify/CDX-AAAA-BBBB").status_code == 404
    assert app_client.get("/verify/CDX-AAAA-BBBB").status_code == 429
