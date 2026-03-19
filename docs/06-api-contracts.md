# 接口契约

## 接口清单

- `POST /ai/intake`
- `POST /ai/extract`
- `POST /ai/report`

当前客户端没有账号体系，也没有鉴权相关请求头约定。

## `POST /ai/intake`

- 方法：`POST`
- 路径：`/ai/intake`
- 用途：新增记录主链路、继续追问、强制结束追问、重新追问

### 请求体

```json
{
  "followUpMode": true,
  "forceFinalize": false,
  "eventTime": "2026-03-18T18:00:00+08:00",
  "messages": [
    { "role": "user", "content": "string" },
    { "role": "assistant", "content": "string" }
  ]
}
```

### 请求字段规则

| 字段 | 类型 | 必填 | 含义 | 规则 |
|---|---|---|---|---|
| `followUpMode` | `bool` | 是 | 是否启用追问模式 | 首页开关关闭时必须传 `false` |
| `forceFinalize` | `bool` | 是 | 是否要求按当前信息直接完成 | 只有用户点击提前结束时传 `true` |
| `eventTime` | `string` | 是 | 本次记录的业务时间锚点 | 使用不带毫秒、带 `+08:00` 的 ISO 8601 |
| `messages` | `array` | 是 | 完整消息历史 | 不能为空；每条消息 `content.trim()` 后不能为空 |

`messages[]` 字段如下：

| 字段 | 类型 | 必填 | 含义 | 规则 |
|---|---|---|---|---|
| `role` | `string` | 是 | 消息角色 | 只能是 `user` / `assistant` |
| `content` | `string` | 是 | 消息正文 | 客户端出站前会做 `trim()` |

### 响应 1：需要继续追问

```json
{
  "status": "needs_followup",
  "question": "string",
  "draft": {
    "mergedRawText": "string",
    "symptomSummary": "string",
    "notes": "string",
    "actionAdvice": "string"
  }
}
```

### 响应 2：最终完成

```json
{
  "status": "final",
  "question": null,
  "draft": {
    "mergedRawText": "string",
    "symptomSummary": "string",
    "notes": "string",
    "actionAdvice": "string"
  }
}
```

### 当前客户端处理规则

- `status` 只能是 `needs_followup` 或 `final`。
- `needs_followup` 时：
  - `question` 必须是字符串。
- `final` 时：
  - `question` 必须是 `null`。
- `draft.mergedRawText`、`draft.symptomSummary`、`draft.notes`、`draft.actionAdvice` 都必须存在且为字符串。
- 只有字段缺失、类型错误、结构非法时，才视为 `invalidResponsePayload`。
- 内容短、空、一般、表达生硬，都不算非法 payload。
- `draft` 中的字符串会在客户端做外层 `trim()` 后使用；`trim()` 后即使为空字符串也保留为空字符串。

## `POST /ai/extract`

- 方法：`POST`
- 路径：`/ai/extract`
- 用途：旧新增记录链路与兼容回归验证

### 请求字段

| 字段 | 类型 | 必填 | 含义 | 规则 |
|---|---|---|---|---|
| `rawText` | `string` | 是 | 用户原始描述 | `trim()` 后不能为空，且不超过 1000 字 |
| `eventTime` | `string` | 是 | 本次记录时间 | 使用不带毫秒、带 `+08:00` 的 ISO 8601 |

### 响应字段

| 字段 | 类型 | 必填 | 含义 | 规则 |
|---|---|---|---|---|
| `symptomSummary` | `string` | 是 | 摘要 | 字段存在且类型为字符串时原样保留，允许空字符串 |
| `notes` | `string?` | 否 | 备注 | 字段存在且类型为字符串时保留，允许空字符串；缺失时按 `null` 处理 |

### 当前客户端处理规则

- 不再使用 `rawText` 首句作为 `symptomSummary` fallback。
- 不再对 AI 返回的 `symptomSummary` 做内容纠偏或自定义替换。
- `symptomSummary` 缺失或类型不是字符串时，才判定为 `invalidResponsePayload`。
- `notes` 缺失时按 `null`；若存在且是字符串，则保留其 `trim()` 结果，允许空字符串。

## `POST /ai/report`

- 方法：`POST`
- 路径：`/ai/report`
- 用途：根据时间范围内的正式健康记录生成汇总报告

### 请求字段

| 字段 | 类型 | 必填 | 含义 | 规则 |
|---|---|---|---|---|
| `reportType` | `string` | 是 | 报告类型 | 当前只发 `week` / `month` / `quarter` |
| `rangeStart` | `string` | 是 | 范围开始时间 | ISO 8601 |
| `rangeEnd` | `string` | 是 | 范围结束时间 | ISO 8601 |
| `events` | `array` | 是 | 正式记录事件列表 | 不包含未完成追问 |

### 错误语义

当前客户端统一映射本地异常类型：

| 异常类型 | 含义 | 适用接口 |
|---|---|---|
| `invalidRequestPayload` | 本地入参非法 | `/ai/intake` `/ai/extract` `/ai/report` |
| `network` | 网络连接异常 | `/ai/intake` `/ai/extract` `/ai/report` |
| `upstreamHttpError` | 上游返回非成功 HTTP 状态 | `/ai/intake` `/ai/extract` `/ai/report` |
| `invalidResponsePayload` | 响应结构不合法 | `/ai/intake` `/ai/extract` `/ai/report` |
| `unknown` | 其他未知错误 | `/ai/intake` `/ai/extract` `/ai/report` |

## 兼容性要求

- `/ai/intake` 是当前新增记录默认链路。
- `/ai/extract` 必须继续保留，直到明确移除旧链路。
- `/ai/report` 继续基于正式记录的 `eventTime` 语义工作。
- 若上游新增未使用字段，客户端当前忽略。
- 若上游删掉必需字段或改错类型，客户端按失败处理。
