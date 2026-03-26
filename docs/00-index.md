# 文档索引

本目录存放 monorepo 根级事实文档。`README.md` 负责仓库入口，`AGENTS.md` 与 `.cursor/rules/` 负责执行规则，这里的编号文档负责记录 workspace、Flutter 客户端与跨 app/gateway 的共享事实。

## 使用规则

1. 默认先更新已有文档，不默认新建。
2. 需要判断“改哪份文档”或“是否新增文档”时，先看 `docs/docs-policy.md`。
3. 新增、删除或重命名根级文档、共享契约后，必须同步更新本索引与 `README.md`。
4. 当前 HTTP 共享契约以 `contracts/health-record-ai.openapi.json` 为准。
5. `services/ai_gateway/docs/` 是服务子树文档，不是第二个仓库的根文档。

## 当前文档清单

### 基础文档

- `docs/docs-policy.md`：文档策略、模板、命名与放置规则
- `docs/01-overview.md`：monorepo 与业务目标概览
- `docs/02-scope-and-nongoals.md`：当前范围、明确不做、版本边界
- `docs/03-business-flows.md`：新增记录、追问、删除、报告等主流程

### 设计文档

- `docs/04-domain-model.md`：核心对象、关系、字段语义、不变量
- `docs/05-system-architecture.md`：monorepo 结构、模块职责、依赖边界
- `docs/06-api-contracts.md`：共享契约解释与客户端消费规则
- `docs/07-data-model.md`：Drift 表结构、迁移策略、本地文件路径与存储规则
- `docs/08-rules-and-edge-cases.md`：业务规则、边界条件、默认兜底与历史兼容
- `docs/15-monorepo-workspace.md`：workspace 结构、职责边界、跨 app/gateway 协作顺序

### 运行与测试文档

- `docs/09-env-and-runbook.md`：环境要求、运行入口、验证命令与排障总览
- `docs/10-testing-strategy.md`：测试分层、覆盖目标、真实验证触发条件
- `docs/11-regression-matrix.md`：高风险模块与回归矩阵
- `docs/12-release-smoke-checklist.md`：本地演示 / 阶段发布 smoke 清单
- `docs/13-requirement-deltas.md`：需求理解、范围边界与阶段性取舍变更记录
- `docs/14-android-real-device-testing-sop.md`：Android 真机连接、安装、运行、日志与排障 SOP

### 共享契约

- `contracts/health-record-ai.openapi.json`：app 与 gateway 的共享 HTTP 契约 source of truth

### ADR

- `docs/adr/ADR-0000-template.md`：ADR 模板
- `docs/adr/ADR-0001-local-first-flutter-client-with-thin-ai-proxy.md`：本地优先 Flutter 客户端 + 薄 AI 代理
- `docs/adr/ADR-0002-keep-orchestration-in-provider-service-layer-during-mvp.md`：MVP 阶段继续使用 Provider / Service 编排
- `docs/adr/ADR-0003-client-owned-intake-sessions-and-separated-draft-storage.md`：追问会话由客户端持有，未完成草稿与正式记录分离

## 推荐阅读顺序

### 初次进入仓库

1. `README.md`
2. `AGENTS.md`
3. `docs/01-overview.md`
4. `docs/15-monorepo-workspace.md`
5. `docs/05-system-architecture.md`
6. `docs/06-api-contracts.md`
7. `docs/09-env-and-runbook.md`
8. `docs/10-testing-strategy.md`

### 处理 app 主链路任务

1. `docs/02-scope-and-nongoals.md`
2. `docs/03-business-flows.md`
3. `docs/08-rules-and-edge-cases.md`
4. `apps/ai_case_assistant/lib/**` 与对应测试

### 处理跨 app + gateway 接口任务

1. `docs/15-monorepo-workspace.md`
2. `contracts/health-record-ai.openapi.json`
3. `docs/06-api-contracts.md`
4. `services/ai_gateway/docs/06-api-contracts.md`

### 处理 gateway 任务

1. `services/ai_gateway/README.md`
2. `services/ai_gateway/AGENTS.md`
3. `services/ai_gateway/docs/00-index.md`
4. `services/ai_gateway/docs/06-api-contracts.md`
