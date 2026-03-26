# 接口契约

## 单一事实源

当前 app 与 gateway 的共享 HTTP 契约以 `contracts/health-record-ai.openapi.json` 为单一事实源。

本文件负责解释：

- 当前现行接口清单
- app 侧如何消费这些接口
- 错误映射与兼容口径

`services/ai_gateway/docs/06-api-contracts.md` 负责补充 Worker 实现细节、提示词与 retired 路由行为。

## 接口清单

- `POST /ai/intake`
- `POST /ai/report`

`POST /ai/extract` 不再属于当前 app 公开能力，也不在共享契约内；它只在 gateway 侧保留为 retired `404` 回归。

## `POST /ai/intake`

用途：

- 新增记录主链路
- 继续追问
- 强制结束追问
- 重新追问

共享契约中约束的关键字段：

| 字段 | 说明 |
|---|---|
| `followUpMode` | 是否允许本轮返回追问 |
| `forceFinalize` | 是否要求当前按已有信息直接收口 |
| `eventTime` | 本次记录唯一时间锚点，当前口径为不带毫秒、带 `+08:00` 的 ISO 8601 |
| `messages` | 完整对话历史，顺序即对话顺序 |

响应关键字段：

| 字段 | 说明 |
|---|---|
| `status` | `needs_followup` 或 `final` |
| `question` | 继续追问时为字符串，`final` 时为 `null` |
| `draft` | 当前阶段整理出的记录草稿 |

app 当前处理规则：

- `draft.mergedRawText`、`draft.symptomSummary`、`draft.notes`、`draft.actionAdvice` 都必须存在且为字符串。
- 只有字段缺失、类型错误、结构非法时，才视为 `invalidResponsePayload`。
- 字符串会在客户端做外层 `trim()` 后使用；`trim()` 后即使为空字符串也保留为空字符串。

## `POST /ai/report`

用途：

- 根据时间范围内的正式健康记录生成汇总报告

共享契约中约束的关键字段：

| 字段 | 说明 |
|---|---|
| `reportType` | 当前支持 `week` / `month` / `quarter` |
| `rangeStart` | 报告统计范围开始 |
| `rangeEnd` | 报告统计范围结束 |
| `events` | 正式记录事件列表 |

app 当前处理规则：

- app 当前会发送 `events[].id` 与 `events[].sourceType` 作为附加上下文；gateway 当前公开契约只强依赖 `eventTime`、`rawText`、`symptomSummary`、`notes`。
- `title`、`summary`、`markdown` 必须是非空字符串。
- `advice` 必须是非空字符串数组。

## 错误语义

当前 app 统一映射本地异常类型：

| 异常类型 | 含义 | 适用接口 |
|---|---|---|
| `invalidRequestPayload` | 本地入参非法 | `/ai/intake` `/ai/report` |
| `network` | 网络连接异常 | `/ai/intake` `/ai/report` |
| `upstreamHttpError` | 上游返回非成功 HTTP 状态 | `/ai/intake` `/ai/report` |
| `invalidResponsePayload` | 响应结构不合法 | `/ai/intake` `/ai/report` |
| `unknown` | 其他未知错误 | `/ai/intake` `/ai/report` |

## 兼容性要求

- `/ai/intake` 是当前新增记录默认链路。
- `/ai/report` 继续基于正式记录的 `eventTime` 语义工作。
- `/ai/extract` 已从 app 当前实现、文档与现行测试退场。
- 若上游新增未使用字段，app 当前忽略。
- 若上游删掉必需字段或改错类型，app 按失败处理。
