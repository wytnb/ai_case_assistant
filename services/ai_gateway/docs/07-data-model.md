# 数据模型

## 存储清单

| 存储/载体 | 当前状态 | 说明 |
| --- | --- | --- |
| 数据库 | 当前无 | 仓库中没有数据库配置或表结构 |
| 对象存储 | 当前无 | 仓库中没有对象存储绑定 |
| 队列 | 当前无 | 仓库中没有队列绑定 |
| Worker 运行时对象 | 使用中 | 请求、响应、上游 payload 仅存在于单次请求生命周期内 |

## 结构定义

### intake 运行时对象

- `IntakeRequest`：包含 `followUpMode`、`forceFinalize`、`eventTime`、`messages`
- `IntakeModelResult`：包含 `status`、`question`、`symptoms`、`notes`、`actionAdvice`
- `IntakeDraft`：包含 `mergedRawText`、`symptomSummary`、`notes`、`actionAdvice`
- `IntakeResponse`：包含 `status`、`question`、`draft`

### report 运行时对象

- `ReportRequest`：包含 `reportType`、`rangeStart`、`rangeEnd`、`events`
- `ReportEvent`：显式包含 `eventTime`、`rawText`、`symptomSummary`、`notes`
- `ReportResult`：包含 `title`、`summary`、`advice`、`markdown`

### 结构约束

- `messages[*].content` 在进入主流程前会 `trim()`
- `draft.mergedRawText` 只由 `user` 消息拼接
- `draft.symptomSummary` 由 Worker 对 `symptoms` 本地格式化生成
- `symptoms[].precision` 只能是 `date` 或 `datetime`
- `events[].rawText`、`events[].symptomSummary`、`events[].notes` 允许为 `null`

## 索引

- 当前无数据库索引或持久化层索引
- 运行时对象只在单次请求内使用，不存在跨请求检索索引

## 迁移策略

- 当前无数据库迁移脚本
- 若未来引入持久化，需要新增独立迁移策略并同步更新本文件与 `docs/00-index.md`

## 删除策略

- 当前无持久化数据，因此不存在存储层删除策略
- 公开端点退场按接口契约处理；例如 `/ai/extract` 已退场并统一返回 `404 NOT_FOUND`

## 兼容要求

- 运行时对象不依赖持久化兼容层
- `/ai/report.events[]` 统一使用 `eventTime`，不再兼容旧的 `eventStartTime` / `eventEndTime`
- 对外兼容性要求以 `docs/06-api-contracts.md` 为准

## 测试关注点

- `/ai/intake` 的开关与长度校验
- `/ai/intake` 的 `question` / `draft` 结构校验
- `/ai/intake` 的摘要格式稳定性
- 结构化 `symptoms` 校验
- `symptomSummary` 格式化
- `/ai/report` 的事件结构校验
