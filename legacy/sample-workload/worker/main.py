"""Optional worker that drains Redis jobs list."""

from __future__ import annotations

import os
import time

import redis


def main() -> None:
    url = os.environ.get("REDIS_URL", "redis://redis:6379/0")
    r = redis.from_url(url)
    print("worker started", flush=True)
    while True:
        item = r.brpop("jobs", timeout=5)
        if item:
            _, payload = item
            print(f"processed {payload!r}", flush=True)
        else:
            time.sleep(0.5)


if __name__ == "__main__":
    main()
