#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CONTRACT_PATH = ROOT / "contracts" / "health-record-ai.openapi.json"
APP_ROOT = ROOT / "apps" / "ai_case_assistant"
GATEWAY_ROOT = ROOT / "services" / "ai_gateway"

CURRENT_DOCS = [
    ROOT / "README.md",
    ROOT / "AGENTS.md",
    ROOT / "docs" / "00-index.md",
    ROOT / "docs" / "02-scope-and-nongoals.md",
    ROOT / "docs" / "05-system-architecture.md",
    ROOT / "docs" / "06-api-contracts.md",
    ROOT / "docs" / "08-rules-and-edge-cases.md",
    ROOT / "docs" / "09-env-and-runbook.md",
    ROOT / "docs" / "10-testing-strategy.md",
    ROOT / "docs" / "11-regression-matrix.md",
    ROOT / "docs" / "12-release-smoke-checklist.md",
    ROOT / "docs" / "15-monorepo-workspace.md",
    GATEWAY_ROOT / "README.md",
    GATEWAY_ROOT / "AGENTS.md",
    GATEWAY_ROOT / ".cursor" / "rules" / "00-core.mdc",
    GATEWAY_ROOT / "docs" / "00-index.md",
    GATEWAY_ROOT / "docs" / "06-api-contracts.md",
    GATEWAY_ROOT / "docs" / "09-env-and-runbook.md",
    GATEWAY_ROOT / "docs" / "10-testing-strategy.md",
]

ALLOWED_EXTRACT_MARKERS = (
    "退场",
    "已退场",
    "retired",
    "下线",
    "adr",
    "404",
    "历史",
    "旧",
    "兼容",
    "回归",
)


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def fail(message: str) -> None:
    print(f"[FAIL] {message}")


def ok(message: str) -> None:
    print(f"[OK] {message}")


def check_contract() -> list[str]:
    issues: list[str] = []
    payload = json.loads(read_text(CONTRACT_PATH))
    paths = payload.get("paths")
    if not isinstance(paths, dict):
        return ["共享契约缺少 paths 对象。"]

    actual_paths = set(paths.keys())
    expected_paths = {"/ai/intake", "/ai/report"}
    if actual_paths != expected_paths:
        issues.append(
            f"共享契约当前 paths={sorted(actual_paths)}，期望仅为 {sorted(expected_paths)}。"
        )

    info = payload.get("info")
    if not isinstance(info, dict) or not info.get("version"):
        issues.append("共享契约缺少 info.version。")

    return issues


def check_app_runtime() -> list[str]:
    issues: list[str] = []
    app_lib = APP_ROOT / "lib"
    texts = [path.read_text(encoding="utf-8") for path in app_lib.rglob("*.dart")]
    merged = "\n".join(texts)
    if "/ai/extract" in merged:
        issues.append("app 运行时代码中仍存在 /ai/extract 引用。")
    if "USE_MOCK_AI_EXTRACT" in merged:
        issues.append("app 运行时代码中仍存在 USE_MOCK_AI_EXTRACT。")
    return issues


def check_gateway_runtime() -> list[str]:
    issues: list[str] = []
    index_text = read_text(GATEWAY_ROOT / "src" / "index.ts")
    if "url.pathname === '/ai/intake'" not in index_text:
        issues.append("gateway 路由实现缺少 /ai/intake。")
    if "url.pathname === '/ai/report'" not in index_text:
        issues.append("gateway 路由实现缺少 /ai/report。")
    if "url.pathname === '/ai/extract'" in index_text:
        issues.append("gateway 路由实现仍显式分发 /ai/extract。")
    return issues


def check_current_docs() -> list[str]:
    issues: list[str] = []
    for path in CURRENT_DOCS:
        text = read_text(path)
        for line_no, line in enumerate(text.splitlines(), start=1):
            if "/ai/extract" not in line:
                continue
            lowered = line.lower()
            if any(marker.lower() in lowered for marker in ALLOWED_EXTRACT_MARKERS):
                continue
            issues.append(f"{path.relative_to(ROOT)}:{line_no} 把 /ai/extract 写成了当前态内容。")
    return issues


def main() -> int:
    issues: list[str] = []
    issues.extend(check_contract())
    issues.extend(check_app_runtime())
    issues.extend(check_gateway_runtime())
    issues.extend(check_current_docs())

    if issues:
        for item in issues:
            fail(item)
        return 1

    ok("共享契约只包含 /ai/intake 与 /ai/report。")
    ok("app 当前运行时代码不再引用 /ai/extract。")
    ok("gateway 当前公开路由与共享契约一致。")
    ok("关键当前态文档未把 /ai/extract 写成现行公开能力。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
