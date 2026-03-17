# 验证脚本说明

本目录用于放置稳定、可重复执行的验证脚本。

当前仓库还没有正式落地以下脚本，因此这里只保留目录说明，不把不存在的脚本写成既成事实：

- `verify-local.*`
- `verify-fast.*`
- `verify-release.*`
- `smoke-test.*`

## 当前建议做法

在固定验证脚本补齐前，优先使用以下命令：

- `fvm flutter analyze`
- `fvm flutter test`
- `python scripts/check_doc_sync.py --working-tree --no-strict`

## 设计原则

- 脚本名稳定
- 输出明确
- 能本地重复执行
- 后续若引入 CI，也应能直接复用

