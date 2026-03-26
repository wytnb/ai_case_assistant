# AI Gateway

本目录是 monorepo 中的 AI gateway 服务目录，不是独立 git 仓库。

当前负责：

- 整理健康记录 intake 草稿
- 基于事件列表生成结构化健康报告
- 对 retired `/ai/extract` 维持 `404` 路由回归

## 当前能力

- 当前公开业务端点只有 `POST /ai/intake` 与 `POST /ai/report`
- 共享 HTTP 契约以根级 [contracts/health-record-ai.openapi.json](../../contracts/health-record-ai.openapi.json) 为准
- Worker 实现细节、错误结构、时间锚点和兼容性要求见 [docs/06-api-contracts.md](./docs/06-api-contracts.md)
- 业务流程、领域对象、规则边界分别见 [docs/03-business-flows.md](./docs/03-business-flows.md)、[docs/04-domain-model.md](./docs/04-domain-model.md)、[docs/08-rules-and-edge-cases.md](./docs/08-rules-and-edge-cases.md)

## 技术栈

- Cloudflare Workers
- TypeScript
- Wrangler 4
- Vitest + `@cloudflare/vitest-pool-workers`
- DeepSeek `chat/completions`

## 快速开始

以下命令都在 `services/ai_gateway/` 下执行：

1. 安装依赖：`npm install`
2. 按 [docs/09-env-and-runbook.md](./docs/09-env-and-runbook.md) 配置 `.dev.vars`
3. 本地启动：`npm run dev`
4. 自动化验证与部署闭环规则见 [docs/10-testing-strategy.md](./docs/10-testing-strategy.md) 和 [docs/12-release-smoke-checklist.md](./docs/12-release-smoke-checklist.md)

## 新同学上手路径

1. 先读 [docs/00-index.md](./docs/00-index.md) 了解文档地图
2. 再读 [docs/01-overview.md](./docs/01-overview.md)、[docs/02-scope-and-nongoals.md](./docs/02-scope-and-nongoals.md)、[docs/05-system-architecture.md](./docs/05-system-architecture.md)
3. 接口对接时重点看 [docs/06-api-contracts.md](./docs/06-api-contracts.md)
4. 环境、测试、发布相关操作统一看 [docs/09-env-and-runbook.md](./docs/09-env-and-runbook.md)、[docs/10-testing-strategy.md](./docs/10-testing-strategy.md)、[docs/12-release-smoke-checklist.md](./docs/12-release-smoke-checklist.md)
5. 使用 Codex / Cursor 维护仓库时，先读根级 `README.md` / `AGENTS.md`，再补读本目录的 `AGENTS.md` 与 [docs/docs-policy.md](./docs/docs-policy.md)

## 常用命令

- `npm run dev` / `npm run start`：本地运行 Worker
- `npm test`：运行默认自动化测试
- `npm run test:live`：运行依赖真实 DeepSeek 凭据的 live 测试
- `npm run deploy`：部署到 Cloudflare
- `npm run cf-typegen`：在 `wrangler` 绑定配置变动后更新类型定义

## 文档入口

- [docs/00-index.md](./docs/00-index.md)：完整文档索引
- [../../contracts/health-record-ai.openapi.json](../../contracts/health-record-ai.openapi.json)：根级共享契约
- [docs/06-api-contracts.md](./docs/06-api-contracts.md)：接口契约与提示词展示
- [docs/09-env-and-runbook.md](./docs/09-env-and-runbook.md)：环境配置、运行、发布、排障
- [docs/10-testing-strategy.md](./docs/10-testing-strategy.md)：测试策略与验证规则
- [docs/12-release-smoke-checklist.md](./docs/12-release-smoke-checklist.md)：部署后 smoke 清单

## 目录说明

- `src/`：Worker 实现，当前核心逻辑集中在 `src/index.ts`
- `test/`：自动化测试与 live 集成测试
- `docs/`：项目事实文档与 ADR
- `.cursor/rules/`：给 Cursor Agent 的规则
- `scripts/verify/`：建议放稳定的验证脚本

## 当前约束

- 当前范围与非目标以 [docs/02-scope-and-nongoals.md](./docs/02-scope-and-nongoals.md) 为准
- 公开端点、错误结构、字段语义、兼容性要求以根级共享契约 + [docs/06-api-contracts.md](./docs/06-api-contracts.md) 为准
- 环境变量、运行方式、强制测试与部署闭环以 [docs/09-env-and-runbook.md](./docs/09-env-and-runbook.md) 和 [docs/10-testing-strategy.md](./docs/10-testing-strategy.md) 为准
- 文档事实统一以 `docs/` 为 source of truth
