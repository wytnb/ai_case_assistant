# 验证脚本说明

本目录用于放置稳定、可重复执行的验证脚本。

当前已落地的稳定脚本：

- `python scripts/check_doc_sync.py --working-tree --no-strict`
- `python scripts/verify/check_ai_contract_sync.py`

app 自动化仍在 `apps/ai_case_assistant/` 下执行：

- `cd apps/ai_case_assistant && fvm flutter analyze`
- `cd apps/ai_case_assistant && fvm flutter test`

## 设计原则

- 脚本名稳定
- 输出明确
- 能本地重复执行
- 后续若引入 CI，也应能直接复用
