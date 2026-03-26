# 文档索引

本目录存放 `services/ai_gateway/` 子树的项目事实文档。  
它属于 monorepo 下的服务文档，不是另一个仓库的根文档。  
`AGENTS.md` 和 `.cursor/rules/` 负责执行规则；`docs/` 负责记录服务事实、架构、测试与变更。

## 使用规则

1. 默认先更新已有文档，不默认新建
2. 判断是否新建文档时，以 `docs/docs-policy.md` 为准
3. 新增、删除、重命名文档后，必须同步更新本索引
4. 当代码、契约、流程、环境或测试口径变化时，相关文档要在同一任务中同步更新

## 当前文档清单

### 基础文档

- `docs-policy.md`：文档策略、适用条件、模板与新建文档判定规则
- `01-overview.md`：项目目标、定位、成功标准
- `02-scope-and-nongoals.md`：当前范围、边界、不做什么
- `03-business-flows.md`：主流程、异常流程、请求生命周期

### 设计文档

- `04-domain-model.md`：核心请求/响应对象、字段语义与内部结构
- `05-system-architecture.md`：模块边界、依赖、关键时序、技术约束
- `06-api-contracts.md`：HTTP 契约、字段、错误码、兼容说明
  - 其中当前公开 HTTP source of truth 见根级 `../../contracts/health-record-ai.openapi.json`
- `07-data-model.md`：当前无持久化前提下的运行时数据模型与约束
- `08-rules-and-edge-cases.md`：时间规则、格式规则、边界与异常处理

### 运维与测试文档

- `09-env-and-runbook.md`：环境变量、本地运行、live 测试、部署与排障
- `10-testing-strategy.md`：按任务类型规定应补哪些测试、应跑哪些验证
- `11-regression-matrix.md`：按改动类型映射必须补的测试和必须跑的命令
- `12-release-smoke-checklist.md`：部署后可直接执行的 smoke 清单与最小断言
- `13-requirement-deltas.md`：需求或口径变化记录

### ADR

- `adr/ADR-0000-template.md`：ADR 模板
- `adr/ADR-0001-single-worker-sync-deepseek.md`：单 Worker + 同步 DeepSeek 的初始架构决策
- `adr/ADR-0002-stateless-intake-history-and-summary-reuse.md`：新增 `/ai/intake` 时的历史决策，现已被后续 ADR 部分覆盖
- `adr/ADR-0003-retire-public-extract-endpoint.md`：下线公开 `/ai/extract`，将症状结构化能力收敛为内部实现

## 推荐阅读顺序

1. `README.md`
2. `docs/01-overview.md`
3. `docs/02-scope-and-nongoals.md`
4. `docs/05-system-architecture.md`
5. `docs/06-api-contracts.md`
6. `docs/09-env-and-runbook.md`
7. `docs/10-testing-strategy.md`
8. `docs/11-regression-matrix.md`
9. `docs/12-release-smoke-checklist.md`
