#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
文档同步检查脚本

用途：
1. 检查本次 Git 改动中是否同时包含代码 / 脚本文件与文档文件；
2. 根据改动路径给出建议至少检查的文档；
3. 在严格模式下，当改了代码却没有同步任何文档时返回非 0，便于本地或 CI 使用。

默认行为：
- 默认检查 staged 改动；
- 默认开启严格模式；
- 若只是查看工作区改动，可传入 --working-tree；
- 若只想查看建议而不阻止流程，可传入 --no-strict。
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path
from typing import Iterable, List, Set

ROOT_DOC_FILES = {
    "README.md",
    "AGENTS.md",
    "scripts/verify/README.md",
    "tests/regression/README.md",
}

RULE_FILES = {
    ".cursor/rules/00-core.mdc",
    ".cursor/rules/10-docs-and-tests.mdc",
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
}

SCRIPT_EXTENSIONS = {
    ".py",
    ".bat",
    ".ps1",
    ".sh",
}

IGNORED_PREFIXES = (
    ".git/",
    "build/",
    ".dart_tool/",
)

DOC_SUGGESTION_RULES = [
    (
        "用户可见页面、主链路或范围变化",
        lambda p: (p.startswith("lib/features/") and "/presentation/" in p)
        or p.startswith("lib/app/router/")
        or p.startswith("lib/app/presentation/"),
        {
            "README.md",
            "docs/02-scope-and-nongoals.md",
            "docs/03-business-flows.md",
            "docs/08-rules-and-edge-cases.md",
            "docs/11-regression-matrix.md",
            "docs/13-requirement-deltas.md",
        },
    ),
    (
        "AI 接口、网络路径、错误映射或环境变量变化",
        lambda p: p.startswith("lib/features/ai/")
        or p.startswith("lib/core/network/")
        or p.startswith("lib/core/config/"),
        {
            "docs/06-api-contracts.md",
            "docs/08-rules-and-edge-cases.md",
            "docs/09-env-and-runbook.md",
            "docs/10-testing-strategy.md",
            "docs/12-release-smoke-checklist.md",
            "docs/13-requirement-deltas.md",
        },
    ),
    (
        "领域对象、接口字段、JSON 或数据口径变化",
        lambda p: any(
            key in p
            for key in [
                "/models/",
                "/entities/",
                "/dto",
                "_dto.dart",
                "_entity.dart",
                "_vo.dart",
                "_mapper.dart",
                "/tables/",
                "schema",
                "json",
            ]
        ),
        {
            "docs/04-domain-model.md",
            "docs/06-api-contracts.md",
            "docs/07-data-model.md",
            "docs/08-rules-and-edge-cases.md",
            "docs/10-testing-strategy.md",
        },
    ),
    (
        "架构边界、模块职责或依赖方向变化",
        lambda p: p.startswith("lib/app/")
        or p.startswith("lib/core/")
        or p.startswith("lib/shared/")
        or "/datasources/" in p
        or "/repositories/" in p
        or "/presentation/providers/" in p
        or "_repository.dart" in p
        or "_repository_impl.dart" in p,
        {
            "docs/05-system-architecture.md",
            "docs/11-regression-matrix.md",
        },
    ),
    (
        "环境配置、构建方式或平台元数据变化",
        lambda p: p in {"pubspec.yaml", "pubspec.lock", ".fvmrc", "analysis_options.yaml"}
        or p.startswith("android/")
        or p.startswith("ios/")
        or p.startswith("macos/")
        or p.startswith("linux/")
        or p.startswith("windows/")
        or p.startswith("web/"),
        {
            "README.md",
            "docs/09-env-and-runbook.md",
            "docs/12-release-smoke-checklist.md",
        },
    ),
    (
        "测试口径或测试布局变化",
        lambda p: p.startswith("test/") or p.startswith("tests/"),
        {
            "docs/10-testing-strategy.md",
            "docs/11-regression-matrix.md",
            "docs/12-release-smoke-checklist.md",
        },
    ),
    (
        "AI 协作规则、文档同步流程或脚本变化",
        lambda p: p.startswith("scripts/")
        or p.startswith(".cursor/")
        or p == "AGENTS.md",
        {
            "AGENTS.md",
            "docs/docs-policy.md",
            ".cursor/rules/00-core.mdc",
            ".cursor/rules/10-docs-and-tests.mdc",
        },
    ),
]

EXTRA_REMINDER_RULES = [
    (
        "如本次改动改变了范围边界、阶段目标或需求理解，请追加检查 docs/13-requirement-deltas.md。",
        lambda files: any(
            (p.startswith("lib/features/") and "/presentation/" in p)
            or p.startswith("lib/app/router/")
            or p.startswith("lib/app/presentation/")
            for p in files
        ),
    ),
    (
        "如本次改动形成了新的长期架构取舍，请考虑新增或更新 docs/adr/*.md。",
        lambda files: any(
            p.startswith("lib/app/")
            or p.startswith("lib/core/")
            or p.startswith("lib/shared/")
            or "/datasources/" in p
            or "/repositories/" in p
            or "/presentation/providers/" in p
            or "_repository.dart" in p
            or "_repository_impl.dart" in p
            for p in files
        ),
    ),
    (
        "如本次改动涉及 AI 接口、真实网络路径、环境变量或发布步骤，请评估真实接口验证或手工 smoke。",
        lambda files: any(
            p.startswith("lib/features/ai/")
            or p.startswith("lib/core/network/")
            or p.startswith("lib/core/config/")
            or p.startswith("android/")
            or p.startswith("ios/")
            or p.startswith("macos/")
            or p.startswith("web/")
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
    if path in ROOT_DOC_FILES or path in DOC_FILES or path in RULE_FILES:
        return True
    if path.startswith("docs/adr/") and path.endswith(".md"):
        return True
    return path.startswith("docs/") and path.endswith(".md")


def is_code_like_file(path: str) -> bool:
    suffix = Path(path).suffix.lower()
    if suffix in CODE_EXTENSIONS:
        return True
    if suffix in SCRIPT_EXTENSIONS and path.startswith("scripts/"):
        return True
    return path.startswith("lib/")


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
    print(f"文档 / 规则文件数：{len(doc_files)}")
    print(f"其他文件数：{len(other_files)}")
    print()

    if code_files:
        print("【代码/脚本改动】")
        for path in code_files:
            print(f"- {path}")
        print()

    print("【已改动文档】")
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
        print("[结论] 检测到代码 / 脚本改动，但未检测到任何文档改动。")
        print("请检查 docs/docs-policy.md，并更新受影响的编号文档。")
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
