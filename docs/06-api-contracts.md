# 接口契约

## 接口清单

- `POST /ai/extract`
- `POST /ai/report`

当前客户端没有接入其他后端接口，也没有鉴权相关请求头约定。

## 请求 / 响应

### `POST /ai/extract`

- 方法：`POST`
- 路径：`/ai/extract`
- 用途：从用户原始文本中提取摘要与备注

#### 请求字段

| 字段 | 类型 | 必填 | 含义 | 备注 |
|---|---|---|---|---|
| `rawText` | `string` | 是 | 用户原始描述 | 客户端会先 `trim()`；空字符串视为无效输入；长度不得超过 1000 字 |
| `eventTime` | `string` | 是 | 本次记录时间 | 必须是带 `+08:00`、且不带毫秒的 ISO 8601 字符串，例如 `2026-03-18T10:20:30+08:00` |

#### 响应字段

| 字段 | 类型 | 含义 | 备注 |
|---|---|---|---|
| `symptomSummary` | `string` | 摘要 | 为空或缺失时客户端会回退到 `rawText` 首句 |
| `notes` | `string?` | 备注 | 缺失、空白或非字符串时客户端按 `null` 处理 |

#### 当前客户端处理规则

- `rawText` 在调用前会校验为非空且不超过 1000 字；校验失败时不发请求
- 如果响应不是对象，视为无效 payload
- `notes` 不会被客户端补伪造文案
- 当前不会把图片内容发送到该接口

### `POST /ai/report`

- 方法：`POST`
- 路径：`/ai/report`
- 用途：根据时间范围内的健康事件生成汇总报告

#### 请求字段

| 字段 | 类型 | 必填 | 含义 | 备注 |
|---|---|---|---|---|
| `reportType` | `string` | 是 | 报告类型 | 当前只发送 `week` / `month` / `quarter` |
| `rangeStart` | `string` | 是 | 范围开始时间 | ISO 8601 |
| `rangeEnd` | `string` | 是 | 范围结束时间 | ISO 8601 |
| `events` | `array` | 是 | 参与汇总的事件列表 | 可为空列表 |

`events[]` 当前字段如下：

| 字段 | 类型 | 必填 | 含义 | 备注 |
|---|---|---|---|---|
| `id` | `string` | 是 | 记录 ID | 来自 `HealthEvent.id` |
| `eventTime` | `string` | 是 | 事件时间 | 当前复用不带毫秒、带 `+08:00` 的 ISO 8601 序列化口径 |
| `sourceType` | `string` | 是 | 来源类型 | 当前总是 `text` |
| `rawText` | `string?` | 否 | 原始文本 | 客户端会截断到最多 500 字符 |
| `symptomSummary` | `string?` | 否 | 摘要 | 空白转 `null` |
| `notes` | `string?` | 否 | 备注 | 空白转 `null` |

#### 响应字段

| 字段 | 类型 | 含义 | 备注 |
|---|---|---|---|
| `title` | `string` | 报告标题 | 必须是非空字符串 |
| `summary` | `string` | 报告摘要 | 必须是非空字符串 |
| `advice` | `string[]` | 建议列表 | 必须是字符串数组，元素不能为空白 |
| `markdown` | `string` | Markdown 正文 | 必须是非空字符串 |

#### 当前客户端处理规则

- 客户端在调用前会校验 `reportType` 非空且 `rangeEnd >= rangeStart`
- 当前客户端仍会把空 `events` 列表发送给上游；上游应返回何种空报告语义仍待确认
- 响应不是对象、缺字段、字段类型错误时，视为无效 payload
- 客户端发送 `eventTime`，不再发送 `eventStartTime` / `eventEndTime`

## 错误语义

当前没有确认过的上游业务错误码表，客户端记录的是“本地映射后的异常类型”。

### 提取接口客户端异常

| 异常类型 | 含义 | 处理建议 |
|---|---|---|
| `invalidRequestPayload` | 客户端本地输入非法 | 提示修正输入后重试 |
| `network` | 网络连接异常或超时类连接问题 | 提示检查网络后重试 |
| `upstreamHttpError` | AI 服务返回非成功 HTTP 状态 | 稍后重试 |
| `invalidResponsePayload` | 响应结构无效 | 取消保存并提示失败 |
| `unknown` | 其他未知错误 | 稍后重试 |

### 报告接口客户端异常

| 异常类型 | 含义 | 处理建议 |
|---|---|---|
| `invalidRequestPayload` | 客户端本地参数非法 | 检查范围与类型 |
| `timeout` | 连接、发送或接收超时 | 稍后重试 |
| `network` | 网络连接异常 | 检查网络后重试 |
| `upstreamHttpError` | AI 服务返回非成功 HTTP 状态 | 稍后重试 |
| `invalidResponsePayload` | 响应结构不符合当前契约 | 视为生成失败 |
| `unknown` | 其他未知错误 | 稍后重试 |

## 鉴权

- 当前客户端没有鉴权 token、用户态或签名机制
- 若未来引入鉴权，应补充到本文件与 `docs/09-env-and-runbook.md`

## 幂等 / 重试

- 当前没有幂等键
- 新增记录失败后需由用户手动重试
- 报告生成失败后需由用户手动重试
- 同一报告范围重复生成时，客户端会在本地按覆盖更新处理，不保留重复结果

## 兼容性要求

- `/ai/extract` 必须接受 `rawText` 与 `eventTime`
- `/ai/extract` 返回体当前至少应兼容 `symptomSummary` 与 `notes`
- `/ai/report` 必须继续返回 `title`、`summary`、`advice`、`markdown`
- 若上游新增字段，客户端当前会忽略未使用字段
- 若上游删除现有必需字段或更改类型，当前客户端会按失败处理
