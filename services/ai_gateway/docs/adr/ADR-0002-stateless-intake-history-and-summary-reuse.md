# ADR-0002-`/ai/intake` 由客户端携带完整历史，并复用 `/ai/extract` 的摘要格式化

> 历史说明：本文关于“复用公开 `/ai/extract`”的表述已被 [ADR-0003](./ADR-0003-retire-public-extract-endpoint.md) 覆盖；当前做法是复用 Worker 内部的结构化校验与摘要格式化能力。

## 背景

仓库已经采用单 Worker、同步调用 DeepSeek、无数据库/缓存/队列的最小化架构。

在新增 `/ai/intake` 之前：

- 公开能力只有 `/ai/extract` 与 `/ai/report`
- Worker 没有服务端会话状态
- 稳定的 `symptomSummary` 格式化逻辑只存在于 `/ai/extract`

本次需要为 `ai_case_assistant` 增加“AI 追问、AI 建议”能力，同时保持 Worker 无状态，不引入新的持久化基础设施。

## 决策问题

`/ai/intake` 应如何支持多轮追问与草稿整理，同时保持无状态，并让摘要格式与 `/ai/extract` 保持一致。

## 备选方案

1. 由客户端每轮提交完整消息历史，Worker 不保存会话；模型返回结构化 `symptoms`，Worker 复用 `/ai/extract` 逻辑格式化 `symptomSummary`
2. 由 Worker 保存会话状态或草稿，再按会话 ID 增量追问
3. 让模型直接在 `/ai/intake` 中生成 `symptomSummary` 字符串

## 取舍分析

### 方案 1

优点：

- 保持现有单 Worker、无状态架构
- 不需要数据库、缓存或队列
- intake 与 extract 的摘要口径完全可控
- 公开契约仍然简单

缺点：

- 客户端必须每轮都传完整历史
- `/ai/intake` 的追问质量仍受模型行为影响

### 方案 2

优点：

- 客户端负担更小
- 更容易支持长对话或复杂追问策略

缺点：

- 超出当前仓库的最小化边界
- 会显著扩大系统复杂度和运维成本

### 方案 3

优点：

- 上游 payload 更简单
- 实现代码更少

缺点：

- `symptomSummary` 风格更依赖模型
- intake 与 extract 容易发生展示口径漂移

## 最终决策

采用方案 1：

- 新增 `POST /ai/intake`
- 继续保持 Worker 无状态；客户端每轮都传完整 `messages[]`
- `question` 继续使用 `string | null`
- `question` 允许多个问题，用换行分隔
- DeepSeek 返回 `status`、`question`、`symptoms`、`notes`、`actionAdvice`
- Worker 本地生成 `draft.mergedRawText`
- Worker 复用 `/ai/extract` 的 `symptoms -> symptomSummary` 格式化逻辑

## 影响

- 当前公开业务端点变为 `/ai/intake`、`/ai/extract`、`/ai/report`
- Worker 仍不需要数据库、缓存、队列或服务端会话
- `/ai/intake.draft.symptomSummary` 与 `/ai/extract.symptomSummary` 保持同口径
- 文档、测试与 smoke 需要补充 intake 的 happy path、强制收口与多问题追问场景

## 何时需要重新评估

出现以下任一情况时，应重新评估本 ADR：

- 客户端难以稳定携带完整消息历史
- `/ai/intake` 的追问质量或状态控制成为主要问题
- 需要支持远长于当前 `6000` 字限制的对话历史
- 需要引入持久化、异步任务或更复杂的会话管理
