# 需求变更记录

## 维护说明

本文档用于记录需求理解、范围边界和阶段性取舍的变更。无法从仓库直接确认的历史事实不做编造，只记录当前任务中可确认的变化。

## 变更记录

### 2026-03-19 - 客户端本地追问会话与 `/ai/intake` 主链路落地

- 原需求：
  - 新增记录主链路基于 `/ai/extract`
  - 没有本地追问会话、消息历史与恢复能力
  - 没有正式记录 `actionAdvice`
  - `symptomSummary` 允许客户端用 `rawText` 首句 fallback
- 新需求：
  - 新增记录默认切到 `POST /ai/intake`
  - 追问会话状态保存在客户端 Drift，不放到 worker
  - 正式记录与未完成追问草稿分离存储
  - 首页新增“追问模式”开关并本地持久化
  - `/records` 顶部新增“未完成追问”分区；首页不放“继续追问”入口
  - 新增 `/intake/:id` 追问页
  - 正式记录新增 `actionAdvice`
  - `symptomSummary` 只要字段存在且类型正确就原样保留，不再做 fallback 或内容纠偏
  - 支持强制结束追问、恢复未完成会话、基于已关联 session 重新追问并更新原记录
- 变更原因：
  - 需要让 AI 在信息不足时继续追问，同时保持 MVP 架构简单，不引入账号、云同步和服务端会话存储
  - 需要避免未完成草稿污染正式记录与报告
- 影响范围：
  - `README.md`
  - `docs/02-13`
  - 新增 ADR-0003
  - `lib/features/intake/`
  - `lib/features/settings/`
  - `lib/features/health_record/`
  - `lib/features/ai/`
  - `lib/core/database/`
  - 相关 widget / service / remote contract 测试
- 需要补的测试：
  - 追问模式开关
  - `/ai/intake` 契约
  - 会话落库、恢复、强制结束、重新追问
  - `/ai/extract` 回归
- 风险：
  - 本地状态机复杂度上升
  - 真实 worker 的 `/ai/intake` 行为仍需要额外验证

### 2026-03-18 - 真实 AI 验证收口与无毫秒 `eventTime`

- 原需求：
  - `eventTime` 只要求带 `+08:00`，未明确是否保留毫秒
  - mock 验证完成后是否必须立刻执行真实 AI 集成测试未固定
- 新需求：
  - 出站 `eventTime` 统一改为不带毫秒、带 `+08:00` 的 ISO 8601
  - 完成 mock 验证后，应评估并尽量执行真实 AI 集成测试
- 变更原因：
  - 真实上游对时间格式更严格
- 影响范围：
  - `README.md`
  - `docs/06`
  - `docs/08-12`
  - AI remote contract 相关实现与测试

### 2026-03-18 - 记录时间收敛为单一 `eventTime`

- 原需求：
  - 新增记录链路中同时维护 `eventStartTime`、`eventEndTime`、`createdAt`、`updatedAt`
- 新需求：
  - 用单一 `eventTime` 语义收敛记录时间，并映射到 `createdAt`
- 变更原因：
  - 降低字段复杂度，统一记录与报告时间口径

### 2026-03-17 - 文档体系迁移与补齐

- 原需求：
  - 仓库使用旧文档组织方式
- 新需求：
  - 迁移到编号文档体系，并要求代码、文档、测试同步维护
