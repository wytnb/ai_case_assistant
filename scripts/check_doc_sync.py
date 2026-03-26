#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
文档同步检查脚本

用途：
1. 检查本次 Git 改动中是否同时包含代码 / 脚本文件与文档 / 契约文件；
2. 根据改动路径给出建议至少检查的文档；
3. 在严格模式下，当改了代码却没有同步任何文档时返回非 0。
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path
from typing import Iterable, List, Set

APP_ROOT = "apps/ai_case_assistant/"
SERVICE_ROOT = "services/ai_gateway/"

ROOT_DOC_FILES = {
    "README.md",
    "AGENTS.md",
    "scripts/verify/README.md",
    "tests/regression/README.md",
}

ROOT_RULE_FILES = {
    ".cursor/rules/00-core.mdc",
    ".cursor/rules/10-docs-and-tests.mdc",
}

SERVICE_RULE_FILES = {
    "services/ai_gateway/.cursor/rules/00-core.mdc",
}

DOC_FILES = {
    "docs/00-index.md",
    "docs/docs-policy.md",
    "docs/01-overview.md",
    "docs/02-scope-and-nongoals.md",
    "docs/03-business-flows.md",
    "docs/04-domain-model.md",
    "docs/05-system-architecture.md",
    "docs/06-api-contracts.md",
    "docs/07-data-model.md",
    "docs/08-rules-and-edge-cases.md",
    "docs/09-env-and-runbook.md",
    "docs/10-testing-strategy.md",
    "docs/11-regression-matrix.md",
    "docs/12-release-smoke-checklist.md",
    "docs/13-requirement-deltas.md",
    "docs/14-android-real-device-testing-sop.md",
    "docs/15-monorepo-workspace.md",
}

CONTRACT_FILES = {
    "contracts/health-record-ai.openapi.json",
}

CODE_EXTENSIONS = {
    ".dart",
    ".kt",
    ".kts",
    ".java",
    ".swift",
    ".m",
    ".mm",
    ".xml",
    ".json",
    ".yaml",
    ".yml",
    ".gradle",
    ".properties",
    ".toml",
    ".ts",
    ".mts",
    ".js",
    ".cjs",
    ".mjs",
}

SCRIPT_EXTENSIONS = {
    ".py",
    ".bat",
    ".ps1",
    ".sh",
}

IGNORED_PREFIXES = (
    ".git/",
    f"{APP_ROOT}.dart_tool/",
    f"{APP_ROOT}build/",
    f"{SERVICE_ROOT}.wrangler/",
    f"{SERVICE_ROOT}node_modules/",
)

DOC_SUGGESTION_RULES = [
    (
        "monorepo 结构、入口或协作边界变化",
        lambda p: p in {"README.md", "AGENTS.md"}
        or p.startswith("contracts/")
        or p.startswith("scripts/")
        or p.startswith(".cursor/"),
        {
            "README.md",
            "AGENTS.md",
            "docs/00-index.md",
            "docs/docs-policy.md",
            "docs/05-system-architecture.md",
            "docs/06-api-contracts.md",
            "docs/09-env-and-runbook.md",
            "docs/10-testing-strategy.md",
            "docs/15-monorepo-workspace.md",
        },
    ),
    (
        "用户可见页面、主链路或范围变化",
        lambda p: (
            p.startswith(f"{APP_ROOT}lib/features/") and "/presentation/" in p
        )
        or p.startswith(f"{APP_ROOT}lib/app/router/")
        or p.startswith(f"{APP_ROOT}lib/app/presentation/"),
        {
            "README.md",
            "docs/02-scope-and-nongoals.md",
            "docs/03-business-flows.md",
            "docs/08-rules-and-edge-cases.md",
            "docs/10-testing-strategy.md",
            "docs/11-regression-matrix.md",
            "docs/12-release-smoke-checklist.md",
            "docs/13-requirement-deltas.md",
            "docs/14-android-real-device-testing-sop.md",
        },
    ),
    (
        "AI 契约、网络路径、错误映射或环境变量变化",
        lambda p: p.startswith(f"{APP_ROOT}lib/features/ai/")
        or p.startswith(f"{APP_ROOT}lib/features/intake/")
        or p.startswith(f"{APP_ROOT}lib/core/network/")
        or p.startswith(f"{APP_ROOT}lib/core/config/")
        or p.startswith(f"{SERVICE_ROOT}src/"),
        {
            "contracts/health-record-ai.openapi.json",
            "docs/06-api-contracts.md",
            "docs/08-rules-and-edge-cases.md",
            "docs/09-env-and-runbook.md",
            "docs/10-testing-strategy.md",
            "docs/12-release-smoke-checklist.md",
            "docs/15-monorepo-workspace.md",
            "services/ai_gateway/docs/06-api-contracts.md",
            "services/ai_gateway/docs/09-env-and-runbook.md",
            "services/ai_gateway/docs/10-testing-strategy.md",
        },
    ),
    (
        "领域对象、数据口径或迁移变化",
        lambda p: p.startswith(f"{APP_ROOT}lib/core/database/")
        or "/tables/" in p
        or "schema" in p,
        {
            "docs/04-domain-model.md",
            "docs/07-data-model.md",
            "docs/10-testing-strategy.md",
            "docs/11-regression-matrix.md",
        },
    ),
    (
        "环境配置、构建方式或平台元数据变化",
        lambda p: p
        in {
            f"{APP_ROOT}pubspec.yaml",
            f"{APP_ROOT}pubspec.lock",
            f"{APP_ROOT}.fvmrc",
            f"{APP_ROOT}analysis_options.yaml",
            ".vscode/settings.json",
            ".gitignore",
        }
        or p.startswith(f"{APP_ROOT}android/")
        or p.startswith(f"{APP_ROOT}ios/")
        or p.startswith(f"{APP_ROOT}macos/")
        or p.startswith(f"{APP_ROOT}linux/")
        or p.startswith(f"{APP_ROOT}windows/")
        or p.startswith(f"{APP_ROOT}web/")
        or p.startswith(f"{SERVICE_ROOT}wrangler"),
        {
            "README.md",
            "docs/09-env-and-runbook.md",
            "docs/12-release-smoke-checklist.md",
            "docs/14-android-real-device-testing-sop.md",
            "docs/15-monorepo-workspace.md",
            "services/ai_gateway/docs/09-env-and-runbook.md",
        },
    ),
    (
        "测试口径或测试布局变化",
        lambda p: p.startswith(f"{APP_ROOT}test/")
        or p.startswith(f"{APP_ROOT}integration_test/")
        or p.startswith(f"{SERVICE_ROOT}test/")
        or p.startswith("tests/"),
        {
            "docs/10-testing-strategy.md",
            "docs/11-regression-matrix.md",
            "docs/12-release-smoke-checklist.md",
            "services/ai_gateway/docs/10-testing-strategy.md",
            "services/ai_gateway/docs/11-regression-matrix.md",
        },
    ),
]

EXTRA_REMINDER_RULES = [
    (
        "如本次改动改变了范围边界、阶段目标或需求理解，请追加检查 docs/13-requirement-deltas.md。",
        lambda files: any(
            (
                p.startswith(f"{APP_ROOT}lib/features/")
                and "/presentation/" in p
            )
            or p.startswith(f"{APP_ROOT}lib/app/router/")
            for p in files
        ),
    ),
    (
        "如本次改动涉及共享契约、app AI 主链路或 gateway 路由，请评估真实接口验证。",
        lambda files: any(
            p.startswith("contracts/")
            or p.startswith(f"{APP_ROOT}lib/features/intake/")
            or p.startswith(f"{APP_ROOT}lib/features/ai/")
            or p.startswith(f"{APP_ROOT}lib/core/network/")
            or p.startswith(f"{APP_ROOT}lib/core/config/")
            or p.startswith(f"{SERVICE_ROOT}src/")
            for p in files
        ),
    ),
    (
        "如本次改动涉及 Android 安装、图片、附件或设备文件，请按 docs/14-android-real-device-testing-sop.md 评估真机 smoke。",
        lambda files: any(
            p.startswith(f"{APP_ROOT}android/")
            or "image_picker" in p
            or "attachment" in p
            or "Image.file" in p
            for p in files
        ),
    ),
]


def run_git_command(args: List[str]) -> str:
    result = subprocess.run(
        ["git", *args],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        encoding="utf-8",
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or "Git 命令执行失败。")
    return result.stdout


def get_changed_files(staged: bool, against: str | None) -> List[str]:
    if staged:
        output = run_git_command(["diff", "--name-only", "--cached"])
        extra_output = ""
    elif against:
        output = run_git_command(["diff", "--name-only", against])
        extra_output = run_git_command(["ls-files", "--others", "--exclude-standard"])
    else:
        output = run_git_command(["diff", "--name-only"])
        extra_output = run_git_command(["ls-files", "--others", "--exclude-standard"])

    combined_output = "\n".join(part for part in [output, extra_output] if part.strip())
    files = [
        line.strip().replace("\\", "/")
        for line in combined_output.splitlines()
        if line.strip()
    ]
    return [f for f in files if not any(f.startswith(prefix) for prefix in IGNORED_PREFIXES)]


def is_doc_file(path: str) -> bool:
    if path in ROOT_DOC_FILES or path in ROOT_RULE_FILES or path in SERVICE_RULE_FILES:
        return True
    if path in DOC_FILES or path in CONTRACT_FILES:
        return True
    if path in {f"{SERVICE_ROOT}README.md", f"{SERVICE_ROOT}AGENTS.md"}:
        return True
    if path.startswith("docs/adr/") and path.endswith(".md"):
        return True
    if path.startswith(f"{SERVICE_ROOT}docs/") and path.endswith(".md"):
        return True
    return path.startswith("docs/") and path.endswith(".md")


def is_code_like_file(path: str) -> bool:
    suffix = Path(path).suffix.lower()
    if suffix in CODE_EXTENSIONS:
        return True
    if suffix in SCRIPT_EXTENSIONS and path.startswith("scripts/"):
        return True
    return path.startswith(f"{APP_ROOT}lib/") or path.startswith(f"{SERVICE_ROOT}src/")


def suggest_docs(changed_files: Iterable[str]) -> Set[str]:
    suggestions: Set[str] = set()
    for path in changed_files:
        for _, matcher, docs in DOC_SUGGESTION_RULES:
            try:
                if matcher(path):
                    suggestions.update(docs)
            except Exception:
                continue
    return suggestions


def collect_extra_reminders(changed_files: Iterable[str]) -> List[str]:
    file_list = list(changed_files)
    reminders: List[str] = []
    for message, matcher in EXTRA_REMINDER_RULES:
        try:
            if matcher(file_list):
                reminders.append(message)
        except Exception:
            continue
    return reminders


def main() -> int:
    parser = argparse.ArgumentParser(description="检查本次改动是否同步更新了项目文档。")
    parser.add_argument(
        "--working-tree",
        action="store_true",
        help="检查工作区未暂存改动。默认检查 staged 改动。",
    )
    parser.add_argument(
        "--against",
        help="与指定 Git 引用比较，例如 HEAD~1。仅在非 staged 模式下生效。",
    )
    parser.add_argument(
        "--no-strict",
        action="store_true",
        help="仅输出提示，不因缺少文档改动返回非 0。",
    )
    args = parser.parse_args()

    staged = not args.working_tree and args.against is None
    strict = not args.no_strict

    try:
        changed_files = get_changed_files(staged=staged, against=args.against)
    except RuntimeError as exc:
        print(f"[错误] {exc}")
        return 2

    if not changed_files:
        print("[信息] 未检测到改动文件。")
        return 0

    doc_files = sorted([f for f in changed_files if is_doc_file(f)])
    code_files = sorted([f for f in changed_files if is_code_like_file(f) and not is_doc_file(f)])
    other_files = sorted([f for f in changed_files if f not in doc_files and f not in code_files])
    suggestions = sorted(suggest_docs(code_files))
    extra_reminders = collect_extra_reminders(code_files)

    print("=== 文档同步检查结果 ===")
    print(f"改动文件总数：{len(changed_files)}")
    print(f"代码/脚本文件数：{len(code_files)}")
    print(f"文档 / 契约 / 规则文件数：{len(doc_files)}")
    print(f"其他文件数：{len(other_files)}")
    print()

    if code_files:
        print("【代码/脚本改动】")
        for path in code_files:
            print(f"- {path}")
        print()

    print("【已改动文档 / 契约】")
    if doc_files:
        for path in doc_files:
            print(f"- {path}")
    else:
        print("- 无")
    print()

    if suggestions:
        print("【建议至少检查的文档】")
        for path in suggestions:
            print(f"- {path}")
        print()

    if extra_reminders:
        print("【额外提醒】")
        for reminder in extra_reminders:
            print(f"- {reminder}")
        print()

    if other_files:
        print("【其他改动】")
        for path in other_files:
            print(f"- {path}")
        print()

    if code_files and not doc_files:
        print("[结论] 检测到代码 / 脚本改动，但未检测到任何文档或契约改动。")
        print("请检查 docs/docs-policy.md，并更新受影响的根级或服务级文档。")
        return 1 if strict else 0

    missing_suggestions = [path for path in suggestions if path not in doc_files]
    if code_files and missing_suggestions:
        print("[提醒] 以下文档根据路径规则看起来可能需要检查，但当前没有出现在改动列表中：")
        for path in missing_suggestions:
            print(f"- {path}")
        print("若你已确认无需更新，请在任务说明中明确写出原因。")
        print()

    print("[结论] 文档同步检查已执行。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
