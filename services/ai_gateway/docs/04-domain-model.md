# 领域模型

## 实体清单

- `IntakeRequest`
- `AiIntakeMessage`
- `StructuredSymptom`
- `StructuredSymptomsPayload`
- `IntakeModelResult`
- `IntakeDraft`
- `IntakeResponse`
- `ReportRequest`
- `ReportEvent`
- `ReportResult`

## 实体关系

- `IntakeRequest` 包含一个按顺序排列的 `AiIntakeMessage[]`
- DeepSeek 基于 `IntakeRequest` 生成 `IntakeModelResult`
- `IntakeModelResult.symptoms` 由 `StructuredSymptom[]` 构成，`notes` 与 `actionAdvice` 为补充文本；其中 `actionAdvice` 可承载操作/观察建议或审慎诊断意见
- Worker 将 `IntakeModelResult` 本地格式化为 `IntakeDraft`
- `IntakeResponse` 由 `status`、`question` 与 `draft: IntakeDraft` 组成
- `ReportRequest` 包含报告周期与一个 `ReportEvent[]`
- `ReportResult` 由 `title`、`summary`、`advice`、`markdown` 组成，是 `/ai/report` 的最终输出；其中自由文本字段可承载与输入证据一致的审慎诊断意见

## 字段语义

### `IntakeRequest`

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `followUpMode` | `boolean` | 是否允许本轮返回追问 |
| `forceFinalize` | `boolean` | 是否要求当前按已有信息直接收口 |
| `eventTime` | `string` | intake 阶段唯一时间锚点，必须是中国时区 `+08:00` ISO 8601 字符串 |
| `messages` | `AiIntakeMessage[]` | 完整会话历史 |

### `AiIntakeMessage`

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `role` | `"user" \| "assistant"` | 消息角色；`user` 代表患者，`assistant` 代表 AI |
| `content` | `string` | 消息正文，进入主流程前会 `trim()` |

### `StructuredSymptom`

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `name` | `string` | 症状或不适标签，不是诊断结论 |
| `startTime` | `string \| null` | 症状开始时间或可推断下界 |
| `endTime` | `string \| null` | 症状结束时间或可推断上界 |
| `precision` | `"date" \| "datetime"` | 时间精度 |

### `StructuredSymptomsPayload`

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `symptoms` | `StructuredSymptom[]` | 上游返回的结构化症状列表 |
| `notes` | `string` | 否认信息、诱因、用药、就医、背景等补充说明 |

### `IntakeModelResult`

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `status` | `"needs_followup" \| "final"` | 上游建议的 intake 状态 |
| `question` | `string \| null` | 下一轮问题；`final` 时必须为 `null` |
| `symptoms` | `StructuredSymptom[]` | 结构化正向症状 |
| `notes` | `string` | 补充说明 |
| `actionAdvice` | `string` | 中性、谨慎、可执行的操作/观察建议或审慎诊断意见 |

### `IntakeDraft`

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `mergedRawText` | `string` | 所有 `user` 消息按顺序合并后的完整描述 |
| `symptomSummary` | `string` | Worker 本地格式化后的症状摘要 |
| `notes` | `string` | 否认信息、诱因、缓解/加重、用药、就医、背景等补充说明 |
| `actionAdvice` | `string` | 一条操作/观察建议或审慎诊断意见 |

### `IntakeResponse`

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `status` | `"needs_followup" \| "final"` | 当前是否还需要继续追问 |
| `question` | `string \| null` | 下一轮问题；`final` 时必须为 `null` |
| `draft` | `IntakeDraft` | 当前阶段整理出的记录草稿 |

### `ReportRequest`

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `reportType` | `"week" \| "month" \| "quarter"` | 报告周期类型 |
| `rangeStart` | `string` | 报告统计起始边界 |
| `rangeEnd` | `string` | 报告统计结束边界 |
| `events` | `ReportEvent[]` | 统计范围内的记录列表 |

### `ReportEvent`

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `eventTime` | `string \| null` | 记录创建时间，不表示症状发生区间 |
| `rawText` | `string \| null` | 原始描述 |
| `symptomSummary` | `string \| null` | 归一化后的症状摘要 |
| `notes` | `string \| null` | 补充说明 |

### `ReportResult`

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `title` | `string` | 报告标题 |
| `summary` | `string` | 总体评估与趋势归纳；可包含审慎诊断倾向 |
| `advice` | `string[]` | 建议/审慎诊断意见列表；每一项都应是完整建议句 |
| `markdown` | `string` | 完整 Markdown 报告正文；可包含与 `advice` 一致的审慎诊断表述 |

## 生命周期

1. 调用方提交 `IntakeRequest`
2. DeepSeek 先返回 `IntakeModelResult`
3. Worker 将 `symptoms` 本地格式化为 `IntakeDraft`
4. Worker 返回 `IntakeResponse`
5. 调用方也可以提交 `ReportRequest`
6. Worker 校验并生成 `ReportResult`

## 不变量

- `/ai/intake` 成功响应固定包含 `status`、`question`、`draft`
- `/ai/intake.draft.mergedRawText` 只由 `user` 消息组成
- `/ai/intake.question` 在 `final` 时必须为 `null`
- `symptomSummary` 中的时间展示由 Worker 统一格式化
- `/ai/report.events[]` 统一使用 `eventTime`
- `/ai/report.advice[]` 每一项都必须是非空字符串
- `StructuredSymptom.name` 始终表示症状或不适标签，不承载诊断结论

## 待确认问题

- 当前无需要额外确认的领域对象；若后续新增持久化实体，再补充实体关系与生命周期
