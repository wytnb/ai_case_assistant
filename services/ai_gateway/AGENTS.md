# AGENTS.md

本文件定义当前仓库对 Codex / Cursor / 其他 coding agent 的项目级执行规则。

本规则只作用于 `services/ai_gateway/**`。
当前目录是 monorepo 内的服务目录，不是独立 git 仓库。

## 1. 必读顺序

开始规划或修改前，按以下顺序阅读：

1. `README.md`
2. `AGENTS.md`
3. `docs/00-index.md`
4. `docs/docs-policy.md`
5. 与当前任务最相关的 `docs/` 文档
6. 对应代码、配置、测试文件

## 1.1 Plan 语言

- 默认使用简体中文输出 Plan、实现拆解与方案说明
- 只有需求明确要求其他语言时，才切换输出语言

## 2. 先查官方文档

涉及 Cloudflare Workers 运行时、Wrangler 配置、Secrets、平台限制时，先查最新官方文档：

- https://developers.cloudflare.com/workers/
- https://developers.cloudflare.com/workers/wrangler/configuration/
- https://developers.cloudflare.com/workers/configuration/secrets/
- https://developers.cloudflare.com/workers/platform/limits/

不要只凭旧经验修改 Worker 配置或运行方式。

## 3. Source Of Truth

- 项目事实、业务约束、接口契约写在 `docs/`
- 根级共享 HTTP 契约写在 `../../contracts/health-record-ai.openapi.json`
- `AGENTS.md` 只放执行规则和少量项目级硬约束
- 如果代码与文档冲突，不要静默选择其一
  - 若意图明确：在同一任务里同步修正文档和/或代码
  - 若意图不明确：保持改动最小，并在最终汇报中明确指出冲突

## 4. 当前项目硬约束

- 当前公开端点只有：
  - `POST /ai/intake`
  - `POST /ai/report`
- 支持 `OPTIONS` 预检；未知路径或非 `POST` 请求统一返回 `404 NOT_FOUND`
- 错误响应结构统一为：
  - `{ "error": { "code": "string", "message": "string" } }`
- 不要新增无关端点，例如 `/ai/followup`，除非需求明确要求
- `POST /ai/extract` 已退场；除非需求明确要求恢复，否则不要重新引入
- 密钥不要写入 `wrangler.jsonc`
  - 本地开发用 `.dev.vars`
  - 必需绑定：`DEEPSEEK_API_KEY`
  - 可选绑定：`DEEPSEEK_MODEL`
- 如果修改 `wrangler.jsonc` 中的绑定配置，务必运行 `npx wrangler types`

## 5. 文档决策规则

### Rule A: 优先更新已有文档

默认先更新已有文档，不要先新建。

### Rule B: 只有在以下条件都满足时才新建

- 信息形成独立主题
- 后续会被反复引用
- 不能合理放进现有文档
- 单独成文能降低长期维护成本

### Rule C: 以 `docs/docs-policy.md` 为准

如果创建、删除、重命名文档，必须同步更新 `docs/00-index.md`。
如果改动影响共享 HTTP 契约，也要同步检查根级 `docs/06-api-contracts.md` 与 `../../contracts/health-record-ai.openapi.json`。

## 6. 文档同步要求

以下变动必须在同一任务里同步更新文档：

- 接口契约变化
- 业务流程变化
- 领域对象或字段语义变化
- 模块边界或架构决策变化
- 环境变量、运行方式、部署步骤变化
- 测试策略、回归口径、发布检查变化
- 需求理解、假设或权衡变化

若形成新的重要架构取舍，新增或更新 `docs/adr/` 下的 ADR。
若需求理解、假设或权衡发生变化，更新 `docs/13-requirement-deltas.md`。

## 7. 测试同步要求

每次代码任务都要显式判断需要哪些测试层，而不是默认只跑一套测试。

### 强制测试与部署触发规则（硬约束）

- 若本轮改动集合包含以下任一项，触发“强制测试 + 部署闭环”：
  - `src/**` 下任意文件
  - 会影响线上运行行为的配置改动（至少包括 `wrangler.jsonc`、环境绑定相关配置）
- 触发后必须按固定顺序执行：
  - `npm test`
  - `npm run test:live`
  - `npm run deploy`
  - 按 `docs/12-release-smoke-checklist.md` 执行线上 smoke
- 若本轮仅改人类阅读文档（如 `docs/**`、`README.md`、`scripts/verify/README.md`），不触发上述强制部署闭环
- 触发后任一环节无法执行时，不得标记“完成”；必须在最终汇报中明确未执行项与阻塞原因

### 新功能

至少补：

- happy path
- 1 个边界场景
- 1 个失败场景

### Bug 修复

补或更新回归测试，确保修复前会失败。

### 契约变化

补或更新集成测试。

### 每次代码任务都要判断的测试层

- 本地自动化测试
  - 默认命令：`npm test`
- live 测试
  - 默认命令：`npm run test:live`
  - 当触发“强制测试 + 部署闭环”时为必跑项
- 线上 smoke
  - 默认参考：`docs/12-release-smoke-checklist.md`
  - 当触发“强制测试 + 部署闭环”时为必跑项

如果某一层测试本应执行，但因凭据、环境或发布条件缺失无法执行，必须在最终汇报中明确说明阻塞原因。

### 发布影响变更

检查 `docs/12-release-smoke-checklist.md` 是否需要同步更新。

### 当前仓库的部署规则

- 对当前仓库，触发“强制测试 + 部署闭环”后，`npm run deploy` 为必做步骤，不是可选步骤
- “必做部署”用于每一轮逻辑完整、测试与文档已同步的业务/运行时配置改动，不是每保存一次文件都立即部署

## 8. 完成定义

任务只有同时满足以下条件才算完成：

1. 代码或文档改动完成
2. 相关文档已同步
3. 必要测试已新增或更新
4. 若触发“强制测试 + 部署闭环”，已按顺序执行 `npm test`、`npm run test:live`、`npm run deploy` 与线上 smoke；若未执行，已明确说明阻塞原因
5. 已明确说明本次是否需要新增文档，以及原因
6. 最终汇报列出改动文件、测试、命令与剩余风险

不要在未说明验证情况时声称“完成”。

## 9. 执行策略

推荐顺序：

1. 理解当前文档和代码事实
2. 先补齐或修正文档
3. 再改代码
4. 更新测试
5. 运行验证
6. 汇报结果

需求模糊时，优先收敛文档，而不是直接做大范围推测性改动。

## 10. Final Task Report Format

每次任务结束时，至少汇报以下内容：

- 代码改动
- 文档改动
- 是否新建文档，以及为什么
- 如果没有更新文档，也要说明为什么现有文档足够承接
- 新增或更新了哪些测试
- 本地验证命令
- live 测试命令
- 线上 smoke 执行情况
- 未执行项与阻塞原因
- 结果摘要
- 剩余风险 / follow-up

## 11. 禁止事项

不要：

- 编造仓库中不存在的业务规则
- 把模板内容直接当成项目事实
- 在有现有文档可承接时大量新建文档
- 在行为变化后跳过文档更新
- 在 bug 修复后跳过回归测试
- 在本应判断 live/线上验证时静默跳过
- 在未说明验证结果时声称任务已完成
