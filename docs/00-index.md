# 文档索引

本目录存放项目的事实文档。
`README.md` 负责仓库入口，`AGENTS.md` 与 `.cursor/rules/` 负责 AI 执行规则，这里的编号文档负责记录项目本身的产品、系统、接口、数据、测试与发布事实。

## 使用规则

1. 先更新已有文档，不默认新建。
2. 需要判断“改哪份文档”或“是否新建文档”时，先看 `docs/docs-policy.md`。
3. 新增、删除、重命名文档后，必须同步更新本索引。
4. 文档内容必须区分：
   - 当前已实现
   - 当前未实现但方向明确
   - 待确认

## 当前文档清单

### 基础文档

- `docs/docs-policy.md`：文档策略、完整清单、模板、示例、命名与放置规则
- `docs/01-overview.md`：项目概览、目标用户、目标问题、成功标准
- `docs/02-scope-and-nongoals.md`：当前范围、明确不做、版本边界、延期项
- `docs/03-business-flows.md`：主流程、异常流程、状态流转、前后置条件

### 设计文档

- `docs/04-domain-model.md`：核心对象、关系、字段语义、不变量
- `docs/05-system-architecture.md`：模块划分、依赖边界、工程组织、技术约束
- `docs/06-api-contracts.md`：`/ai/extract` 与 `/ai/report` 的契约、错误语义、兼容要求
- `docs/07-data-model.md`：Drift 表结构、迁移策略、本地文件存储规则
- `docs/08-rules-and-edge-cases.md`：业务规则、边界条件、降级与兜底

### 运行与测试文档

- `docs/09-env-and-runbook.md`：环境要求、dart-define、启动与排障
- `docs/10-testing-strategy.md`：测试分层、现状、覆盖缺口、通过标准
- `docs/11-regression-matrix.md`：高风险模块与回归矩阵
- `docs/12-release-smoke-checklist.md`：本地 / 演示版 smoke 检查清单
- `docs/13-requirement-deltas.md`：需求与文档体系变更记录

### ADR

- `docs/adr/ADR-0000-template.md`：ADR 模板
- `docs/adr/ADR-0001-local-first-flutter-client-with-thin-ai-proxy.md`：本地优先 Flutter 客户端 + 薄 AI 代理
- `docs/adr/ADR-0002-keep-orchestration-in-provider-service-layer-during-mvp.md`：MVP 阶段维持 Provider / 轻服务编排

## 相关配套入口

这些文件不在 `docs/` 内，但与文档体系一起维护：

- `README.md`：仓库入口说明
- `AGENTS.md`：AI 执行规则
- `.cursor/rules/00-core.mdc`：Cursor 核心规则
- `.cursor/rules/10-docs-and-tests.mdc`：Cursor 文档与测试规则
- `scripts/check_doc_sync.py`：文档同步检查脚本
- `scripts/verify/README.md`：固定验证脚本目录说明
- `tests/regression/README.md`：专项回归目录说明

## 推荐阅读顺序

### 初次进入仓库

1. `README.md`
2. `AGENTS.md`
3. `docs/01-overview.md`
4. `docs/02-scope-and-nongoals.md`
5. `docs/05-system-architecture.md`
6. `docs/09-env-and-runbook.md`
7. `docs/10-testing-strategy.md`

### 处理页面或流程任务

1. `docs/02-scope-and-nongoals.md`
2. `docs/03-business-flows.md`
3. `docs/08-rules-and-edge-cases.md`
4. 相关代码与测试

### 处理接口、数据或迁移任务

1. `docs/04-domain-model.md`
2. `docs/06-api-contracts.md`
3. `docs/07-data-model.md`
4. `docs/10-testing-strategy.md`

### 处理架构或重构任务

1. `docs/05-system-architecture.md`
2. 相关 ADR
3. `docs/11-regression-matrix.md`
