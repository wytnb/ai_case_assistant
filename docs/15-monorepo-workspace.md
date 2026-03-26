# Monorepo Workspace

## 当前结构

当前仓库采用单仓 monorepo 结构：

- `apps/ai_case_assistant/`：Flutter 客户端
- `services/ai_gateway/`：AI gateway
- `contracts/`：共享机器可读契约
- `docs/`：workspace 与业务本体文档
- `scripts/`：workspace 级校验脚本

根目录是唯一 git 边界。

## 职责边界

### app

- 页面、路由、Provider、Drift、本地附件
- `/ai/intake` 与 `/ai/report` 的调用与结果消费
- 正式记录、草稿记录、报告展示

### gateway

- 当前公开能力：`POST /ai/intake`、`POST /ai/report`
- retired `/ai/extract` 的 `404` 路由回归
- DeepSeek 调用、提示词、本地格式化与错误结构

### 共享契约

- `contracts/health-record-ai.openapi.json` 是 app 与 gateway 的 HTTP 契约 source of truth
- 根级 `docs/06-api-contracts.md` 解释契约语义
- 服务侧 `docs/06-api-contracts.md` 解释 Worker 实现细节

## 新增 AI 功能时的默认顺序

1. 先改共享契约
2. 再改 gateway 实现
3. 再改 app 调用与解析
4. 同步根级 / 服务级文档
5. 补测试与一致性校验

## 什么时候必须一起改

以下情况默认需要同时检查 app、gateway、文档、测试：

- 请求体 / 响应体变化
- 错误码或错误结构变化
- 路由新增、退场或兼容策略变化
- 环境变量、运行命令、验证命令变化
- 当前公开能力列表变化

## 运行方式

### 根目录

- 用于阅读文档、运行 Python 校验脚本、管理整仓改动

### app

在 `apps/ai_case_assistant/` 下执行 Flutter 命令。

### gateway

在 `services/ai_gateway/` 下执行 Node / Wrangler 命令。

## 如何避免接口对不齐

- 先更新 `contracts/health-record-ai.openapi.json`
- 运行 `python scripts/verify/check_ai_contract_sync.py`
- 若修改 gateway 运行时，再补服务侧自动化 / live / smoke
- 若修改 app 调用链，再补 app 自动化与真实 AI 评估
