# 项目概览

## 背景

本仓库是一个最小化的 TypeScript Cloudflare Worker，当前对外暴露两个健康相关接口：

- `POST /ai/intake`
- `POST /ai/report`

它的职责不是长期存储数据，也不是做复杂业务编排，而是把输入校验、DeepSeek 调用、上游 JSON 清洗和稳定的 HTTP JSON 契约收敛在一个 Worker 中。

## 目标用户

- 需要基于完整对话历史整理健康记录草稿的调用方
- 需要基于一组健康事件生成周报、月报、季报的调用方
- 需要一个接口契约稳定、错误结构统一、易于对接的最小后端服务的维护者

## 目标问题

当前版本重点解决两个问题：

1. 基于完整对话历史整理健康记录草稿，并在需要时返回追问
   同时允许在 `draft.actionAdvice` 中输出与输入证据一致的审慎诊断意见
2. 把一组已有事件整理为结构化健康报告，并给出与输入证据一致的审慎诊断意见

在 intake 场景里，系统要求调用方显式传入 `eventTime` 作为时间锚点，让模型基于这个锚点推断症状持续时间，再由 Worker 本地把结构化时间结果格式化到 `draft.symptomSummary` 中。

## 核心价值

- 对外契约稳定：只有 `/ai/intake` 与 `/ai/report`
- 会话仍然无状态：`/ai/intake` 由客户端每轮传完整消息历史
- 输入约束明确：`/ai/intake` 强制要求 `eventTime`
- intake 草稿稳定：`draft.symptomSummary` 由 Worker 基于结构化 `symptoms` 统一格式化
- 输出口径统一：`/ai/intake.draft.actionAdvice` 与 `/ai/report` 文本字段允许给出审慎、非确定性的诊断意见
- 错误结构统一：`{ error: { code, message } }`
- 报告语义清晰：`/ai/report.events[].eventTime` 只表示记录创建时间

## 成功标准

- `/ai/intake` 能在信息不足时返回 `needs_followup`，否则返回 `final`
- `/ai/intake.draft.symptomSummary` 能稳定体现归一化时间信息
- `/ai/report` 统一使用单字段 `eventTime`
- `/ai/intake` 与 `/ai/report` 的自由文本字段可给出审慎诊断倾向，但不写成确定性诊断
- 旧字段 `eventStartTime` / `eventEndTime` 不再作为公开契约存在
- 文档、自动化测试、live 测试与 smoke 清单全部使用现口径

## 当前版本目标

- 保持单 Worker、同步调用 DeepSeek 的最小架构
- 让 `/ai/intake` 在不引入服务端会话状态的前提下支持多轮追问
- 让 `/ai/intake` 与 `/ai/report` 在不新增字段的前提下支持审慎诊断意见表达
- 让 Worker 专注于校验、格式化和契约稳定，而不是暴露独立的提取接口
- 持续把对外行为写入 `docs/`，避免代码与文档漂移

## 相关文档

- `docs/02-scope-and-nongoals.md`
- `docs/03-business-flows.md`
- `docs/04-domain-model.md`
- `docs/05-system-architecture.md`
- `docs/06-api-contracts.md`
- `docs/08-rules-and-edge-cases.md`
