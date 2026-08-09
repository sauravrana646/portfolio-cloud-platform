#!/usr/bin/env python3
"""Validate ApplicationSet discovery files under charts/."""
from __future__ import annotations

import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
REQUIRED = {"name", "layer", "chart", "chartPath", "namespace", "syncWave"}


def load(path: Path) -> dict:
    data = yaml.safe_load(path.read_text())
    if not isinstance(data, dict):
        raise ValueError(f"{path}: expected mapping")
    return data


def check_app(path: Path) -> None:
    app = load(path)
    missing = REQUIRED - set(app)
    if missing:
        raise SystemExit(f"{path}: missing fields {sorted(missing)}")

    chart_path = ROOT / app["chartPath"]
    if not chart_path.is_dir():
        raise SystemExit(f"{path}: chartPath does not exist: {app['chartPath']}")

    source_type = app.get("sourceType", "helm")
    if source_type == "helm":
        if "valuesPath" not in app:
            raise SystemExit(f"{path}: valuesPath required for sourceType=helm")
        values_base = ROOT / "helm-values" / app["valuesPath"]
        values_file = values_base / "values.yaml"
        if not values_file.is_file():
            raise SystemExit(f"{path}: missing {values_file.relative_to(ROOT)}")
        env = app.get("env")
        if env:
            env_values = values_base / "environments" / env / "values.yaml"
            if not env_values.is_file():
                raise SystemExit(f"{path}: missing {env_values.relative_to(ROOT)}")
            if str(app.get("imagePin", "false")) == "true":
                images = values_base / "environments" / env / "images.yaml"
                if not images.is_file():
                    raise SystemExit(f"{path}: missing {images.relative_to(ROOT)}")
    elif source_type == "directory":
        if not (chart_path / "kustomization.yaml").is_file() and not any(
            chart_path.glob("*.yaml")
        ):
            raise SystemExit(f"{path}: directory source has no manifests under {chart_path}")
    else:
        raise SystemExit(f"{path}: unknown sourceType {source_type!r}")

    expected_layer = path.parts[path.parts.index("charts") + 1]
    if app["layer"] != expected_layer:
        raise SystemExit(f"{path}: layer {app['layer']!r} != path layer {expected_layer!r}")

    print(f"OK  {path.relative_to(ROOT)} -> {app['name']}")


def main() -> int:
    files = sorted(ROOT.glob("charts/bootstrap-layer/*/app.yaml"))
    files += sorted(ROOT.glob("charts/applications/*/apps/*.yaml"))
    if not files:
        raise SystemExit("no discovery files found under charts/")
    for path in files:
        check_app(path)
    print(f"Validated {len(files)} chart Application discovery files")
    return 0


if __name__ == "__main__":
    sys.exit(main())
