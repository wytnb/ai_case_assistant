# 需求变更记录

## 维护说明

本文档从 2026-03-17 的文档体系迁移开始维护。更早的需求变更、阶段取舍和历史时间线没有在当前仓库中形成完整可追溯记录，因此不回填未证实历史，只在后续任务中继续追加。

## 变更记录

### 2026-03-18 - 真实 AI 验证收口与无毫秒 eventTime

- 原需求：
  - `eventTime` 只要求带 `+08:00`，未明确是否保留毫秒
  - mock 验证完成后是否必须立即执行真实 AI 集成测试，文档中未固定
- 新需求：
  - 出站 `eventTime` 统一改为不带毫秒、带 `+08:00` 的 ISO 8601 字符串
  - 完成 mock 验证后，下一步必须执行一次带 `RUN_REAL_AI_API_TESTS=true` 的真实 AI 集成测试
  - Android 真机手工 smoke 若依赖 Clash 等代理访问真实 AI，上述代理应保留，不把关闭代理作为默认排障步骤
  - 真机在保留代理的前提下仍无法跑通时，可补一条 Web Chrome 备用 smoke，但只能覆盖 UI 与真实 AI 主链路
- 变更原因：
  - 真实上游 `/ai/extract` 实测会拒绝 `.000+08:00`，只接受 `2026-03-15T08:00:00+08:00` 这类无毫秒格式
  - 需要把 mock 验证后的真实接口验证流程固定下来，避免只验证本地 mock 就结束
- 影响范围：
  - `README.md`
  - `docs/02-scope-and-nongoals.md`
  - `docs/06-api-contracts.md`
  - `docs/08-10`
  - `docs/11-regression-matrix.md`
  - `docs/12-release-smoke-checklist.md`
  - `lib/features/ai/data/remote/event_time_formatter.dart`
  - 真实 AI 集成测试与远程服务契约测试
- 需要更新的文档：
  - 上述受影响文档
- 需要补的测试：
  - `/ai/extract` 与 `/ai/report` 的 `eventTime` 无毫秒序列化断言
  - 真实 AI 集成测试中 `/ai/extract` success case 回归
- 风险：
  - 若上游 `/ai/report` 对无毫秒格式的接受度与 `/ai/extract` 不一致，仍可能出现真实环境差异
- 后续动作：
  - 用真实 AI 上游重跑集成测试
  - 在 Android 真机上补记录创建、详情查看、报告生成的 smoke；若真机仍受设备网络条件限制，再补 Web Chrome 备用 smoke

### 2026-03-18 - 记录时间收敛为单一 eventTime

- 原需求：
  - 记录创建链路中同时维护 `eventStartTime`、`eventEndTime`、`createdAt`、`updatedAt`
  - 列表排序、报告筛选和详情展示依赖 `eventEndTime`
  - `/ai/extract` 不发送 `eventTime`
  - 原始描述长度上限未在当前实现中固定到 1000 字
- 新需求：
  - 新增记录时先取一次客户端本地时间，并同时作为 `eventTime`、`createdAt`、`updatedAt`
  - 列表排序、报告筛选和详情展示统一改为基于 `createdAt`
  - `/ai/extract` 请求体改为发送 `rawText` 与 `eventTime`
  - `eventTime` 必须是带 `+08:00` 的 ISO 8601 字符串
  - `rawText.trim()` 必须非空且不能超过 1000 字
- 变更原因：
  - 收敛时间语义，减少客户端和数据库中的重复时间字段
  - 让 AI 提取与报告载荷使用统一时间口径
  - 在提交前就阻止超长输入，降低无效请求和上游契约歧义
- 影响范围：
  - `README.md`
  - `docs/03-business-flows.md`
  - `docs/04-domain-model.md`
  - `docs/06-api-contracts.md`
  - `docs/07-data-model.md`
  - `docs/08-rules-and-edge-cases.md`
  - `docs/10-testing-strategy.md`
  - `docs/11-regression-matrix.md`
  - `docs/12-release-smoke-checklist.md`
  - `lib/features/ai/`
  - `lib/features/health_record/`
  - `lib/features/report/`
  - `lib/core/database/`
  - 相关测试与 Drift 生成代码
- 需要更新的文档：
  - 上述所有受影响文档
- 需要补的测试：
  - `/ai/extract` 的 `eventTime` 与 1000 字限制契约测试
  - `/ai/report` 单一 `eventTime` 契约测试
  - 新增记录页 1000 字 happy path、边界值、失败路径
  - 列表 / 详情页单一时间展示测试
  - schema 2 / 3 升级到 schema 4 的迁移测试
- 风险：
  - 真实上游若尚未切换到新 `/ai/extract` 或 `/ai/report` 契约，真实接口调用会失败
  - 本次仍需额外真实接口验证和手工 smoke 才能覆盖 UI 与上游协同风险
- 后续动作：
  - 在可访问真实 AI 代理时执行真实接口验证
  - 在设备或模拟器上执行新增记录、详情查看、报告生成的手工 smoke

### 2026-03-17 - 文档体系迁移与补齐

- 原需求：
  - 仓库使用按“产品事实 / 阶段说明 / 架构 / 契约 / 验收 / 流程 / 约定”拆分的旧文档体系。
- 新需求：
  - 将项目迁移到 starter 模板的编号文档体系，并让文档真实反映当前代码、配置、脚本、测试与运行方式。
- 变更原因：
  - 统一仓库与模板包的文档结构，降低后续任务中的事实分散和引用漂移。
- 影响范围：
  - `README.md`
  - `AGENTS.md`
  - `docs/00-index.md`
  - `docs/docs-policy.md`
  - `docs/01-13`
  - `docs/adr/`
  - `.cursor/rules/`
  - `scripts/check_doc_sync.py`
- 需要更新的文档：
  - 本次迁移涉及的全部新文档。
- 需要补的测试：
  - 不涉及业务功能变更；沿用现有 `analyze`、`test` 与脚本文档检查。
- 风险：
  - 旧文档删除后，任何残留引用都会变成断链
  - 历史需求变更未回填，后续若需追溯更早决策只能标记为待确认
- 后续动作：
  - 后续凡是发生范围、接口、架构或测试口径变化，都继续在本文件追加记录
