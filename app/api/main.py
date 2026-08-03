"""Sample API for portfolio-cloud-platform."""

from __future__ import annotations

import os
import time

from flask import Flask, jsonify

app = Flask(__name__)


@app.get("/healthz")
def healthz():
    return jsonify(status="ok"), 200


@app.get("/work")
def work():
    """Simulate a unit of work; optional redis enqueue when REDIS_URL set."""
    started = time.time()
    redis_url = os.environ.get("REDIS_URL")
    queued = False
    if redis_url:
        try:
            import redis

            r = redis.from_url(redis_url)
            r.lpush("jobs", f"job-{int(started)}")
            queued = True
        except Exception as exc:  # noqa: BLE001 — demo resilience
            return jsonify(error=str(exc), queued=False), 503
    duration_ms = int((time.time() - started) * 1000)
    return jsonify(ok=True, queued=queued, duration_ms=duration_ms), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", "8080")))
