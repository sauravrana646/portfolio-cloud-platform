from main import app


def test_healthz():
    c = app.test_client()
    r = c.get("/healthz")
    assert r.status_code == 200
    assert r.get_json()["status"] == "ok"


def test_work():
    c = app.test_client()
    r = c.get("/work")
    assert r.status_code == 200
    assert r.get_json()["ok"] is True
