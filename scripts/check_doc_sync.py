#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
文档同步检查脚本

用途：
1. 检查本次 Git 改动中是否同时包含代码文件和文档文件；
2. 根据改动路径给出建议检查的文档；
3. 在严格模式下，当改了代码但没有改任何文档时返回非 0，便于本地或 CI 使用。

默认行为：
- 默认检查 staged 改动；
- 默认开启严格模式；
- 若只是查看工作区改动，可传入 --working-tree；
- 若只是提示而不阻止流程，可传入 --no-strict。
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path
from typing import Iterable, List, Set

DOC_FILES = {
    "AGENTS.md",
    "README.md",
    "docs/product_facts.md",
    "docs/product_notes.md",
    "docs/architecture.md",
    "docs/architecture_notes.md",
    "docs/conventions.md",
    "docs/workflow.md",
    "docs/contracts.md",
    "docs/acceptance.md",
    "docs/doc_sync_matrix.md",
    "docs/project_overview.md",
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
        "用户可见页面或当前阶段范围变化",
        lambda p: (p.startswith("lib/features/") and "/presentation/" in p)
        or p.startswith("lib/app/router/"),
        {"docs/product_notes.md", "docs/acceptance.md", "README.md", "docs/project_overview.md"},
    ),
    (
        "数据模型、字段、DTO、实体、枚举、JSON 或解析规则变化",
        lambda p: any(key in p for key in [
            "/models/",
            "/entities/",
            "/dto",
            "_dto.dart",
            "_entity.dart",
            "_vo.dart",
            "_mapper.dart",
            "drift",
            "table",
            "schema",
            "json",
        ]),
        {"docs/contracts.md", "docs/acceptance.md"},
    ),
    (
        "架构边界、模块职责、依赖方向、路由组织变化",
        lambda p: p.startswith("lib/app/")
        or p.startswith("lib/core/")
        or p.startswith("lib/shared/")
        or "/datasources/" in p
        or "/repositories/" in p
        or "_repository.dart" in p
        or "_repository_impl.dart" in p,
        {"docs/architecture.md", "docs/architecture_notes.md"},
    ),
    (
        "命名、错误处理、日志或通用实现方式变化",
        lambda p: any(key in p for key in [
            "logger",
            "log",
            "error",
            "exception",
            "util",
            "utils",
            "constant",
            "constants",
            "_provider.dart",
        ]),
        {"docs/conventions.md"},
    ),
    (
        "AI 协作方式或流程规则变化",
        lambda p: p.startswith("scripts/"),
        {"AGENTS.md", "docs/workflow.md", "docs/doc_sync_matrix.md"},
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
    elif against:
        output = run_git_command(["diff", "--name-only", against])
    else:
        output = run_git_command(["diff", "--name-only"])
    files = [line.strip().replace("\\", "/") for line in output.splitlines() if line.strip()]
    return [f for f in files if not any(f.startswith(prefix) for prefix in IGNORED_PREFIXES)]


def is_doc_file(path: str) -> bool:
    return path in DOC_FILES or (path.endswith(".md") and path.startswith("docs/"))


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

    print("=== 文档同步检查结果 ===")
    print(f"改动文件总数：{len(changed_files)}")
    print(f"代码/脚本文件数：{len(code_files)}")
    print(f"文档文件数：{len(doc_files)}")
    print(f"其他文件数：{len(other_files)}")
    print()

    if code_files:
        print("【代码/脚本改动】")
        for path in code_files:
            print(f"- {path}")
        print()

    if doc_files:
        print("【已改动文档】")
        for path in doc_files:
            print(f"- {path}")
        print()
    else:
        print("【已改动文档】")
        print("- 无")
        print()

    if suggestions:
        print("【建议至少检查的文档】")
        for path in suggestions:
            print(f"- {path}")
        print()

    if other_files:
        print("【其他改动】")
        for path in other_files:
            print(f"- {path}")
        print()

    if code_files and not doc_files:
        print("[结论] 检测到代码改动，但未检测到任何文档改动。")
        print("请检查 docs/doc_sync_matrix.md，并更新受影响文档。")
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
