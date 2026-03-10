# 数据契约

## 文档目的

本文件定义核心数据结构、字段含义、字段约束、状态枚举、AI JSON 结构以及 DTO / Entity / ViewModel / Domain Model 的职责边界。  
本文件是模型、接口、落库和解析实现的最终口径。

## 通用字段规则

### ID 规则

1. 业务主键统一使用字符串 UUID。
2. UUID 由客户端生成。
3. 数据库内部若存在技术性自增主键，不对外暴露，也不作为跨层传递的主标识。
4. 任何页面路由参数、跨模块传递、接口关联优先使用业务 UUID。

### 时间字段规则

1. Dart / 本地数据库中使用 `DateTime` 表达时间。
2. JSON / HTTP 契约中统一使用 ISO 8601 字符串，并包含时区偏移。
3. `eventTime` 表示健康事件发生时间；`createdAt` 表示记录创建时间；`updatedAt` 表示最后更新时间。
4. 需要时间范围时，统一使用：
   - `rangeStart`
   - `rangeEnd`

### 可空规则

1. 能从业务上确定为必有的信息，不设为可空。
2. 会受到 AI 解析结果稳定性影响的字段，可空。
3. 可空字段必须有明确“缺失时如何处理”的页面或解析兜底方案。

### 命名规则

1. 字段名统一使用 `camelCase`。
2. 不使用缩写不清的字段名，例如 `desc`、`info1`、`tmpValue`。
3. 枚举值统一使用小写 `snake_case` 或小写单词，不混用大小写风格。

## 核心实体清单

1. `HealthEvent`
2. `Attachment`
3. `FollowupSession`
4. `ExtractResult`
5. `Report`
6. `FollowupQuestion`
7. `FollowupAnswer`
8. `SymptomItem`

## 实体定义

## HealthEvent

健康事件是核心主对象，表示一次有时间语义的健康相关记录。

| 字段名 | 类型 | 必填 | 含义 | 约束 |
| --- | --- | --- | --- | --- |
| id | String | 是 | 健康事件业务主键 | UUID |
| inputType | String | 是 | 输入来源类型 | 见 `InputType` |
| userInputText | String? | 否 | 用户原始文本输入；语音场景存转写文本 | 文本为空时，必须至少有附件或语音转写结果 |
| eventTime | DateTime | 是 | 健康事件发生时间 | 可由用户输入、当前时间或 AI 提取后回填 |
| status | String | 是 | 当前处理状态 | 见 `HealthEventStatus` |
| symptomSummary | String? | 否 | 简短症状摘要 | 用于列表展示，不代替完整提取结果 |
| createdAt | DateTime | 是 | 创建时间 | 不可为空 |
| updatedAt | DateTime | 是 | 更新时间 | 每次修改后更新 |

### HealthEvent 约束

1. `HealthEvent` 必须先保留原始输入，再追加 AI 结果。
2. `status` 表示本条记录的整体处理状态，不等于提取结果状态。
3. `symptomSummary` 用于展示层快速摘要，不作为唯一事实来源。

## Attachment

附件表示挂靠在健康事件下的原始文件。

| 字段名 | 类型 | 必填 | 含义 | 约束 |
| --- | --- | --- | --- | --- |
| id | String | 是 | 附件业务主键 | UUID |
| healthEventId | String | 是 | 所属健康事件 ID | 必须指向已有 `HealthEvent` |
| filePath | String | 是 | 本地文件绝对路径或应用私有目录相对路径 | 必须可由当前应用访问 |
| fileType | String | 是 | 附件类型 | MVP 当前仅支持 `image` |
| sourceType | String | 是 | 附件来源 | 见 `AttachmentSourceType` |
| createdAt | DateTime | 是 | 创建时间 | 不可为空 |

### Attachment 约束

1. 当前 MVP 只允许图片附件。
2. 删除附件时，业务层必须同时考虑文件删除与元数据删除的一致性。
3. 文件不存在时，不应导致详情页崩溃；应展示降级提示。

## FollowupSession

追问会话表示围绕某次健康事件进行的一轮追问记录。

| 字段名 | 类型 | 必填 | 含义 | 约束 |
| --- | --- | --- | --- | --- |
| id | String | 是 | 追问会话业务主键 | UUID |
| healthEventId | String | 是 | 所属健康事件 ID | 必须指向已有 `HealthEvent` |
| questionsJson | String | 是 | 追问问题 JSON 字符串 | 结构见 `FollowupQuestion` |
| answersJson | String? | 否 | 用户回答 JSON 字符串 | 结构见 `FollowupAnswer` |
| status | String | 是 | 追问会话状态 | 见 `FollowupSessionStatus` |
| createdAt | DateTime | 是 | 创建时间 | 不可为空 |
| updatedAt | DateTime | 是 | 更新时间 | 每次保存回答后更新 |

### FollowupSession 约束

1. 问题和回答的顺序必须可还原。
2. 即使用户跳过回答，也需要有明确状态。
3. `questionsJson` 与 `answersJson` 仅作为存储载体；页面层不直接处理裸 JSON 字符串。

## ExtractResult

提取结果表示 AI 对单个健康事件做出的结构化整理结果。

| 字段名 | 类型 | 必填 | 含义 | 约束 |
| --- | --- | --- | --- | --- |
| id | String | 是 | 提取结果业务主键 | UUID |
| healthEventId | String | 是 | 所属健康事件 ID | 必须指向已有 `HealthEvent` |
| modelName | String? | 否 | 使用的模型名或代理标识 | 可选 |
| rawResultJson | String? | 否 | AI 原始返回 JSON 字符串 | 用于追溯与排障 |
| normalizedResultJson | String? | 否 | 标准化后 JSON 字符串 | 结构见下文 |
| status | String | 是 | 提取结果状态 | 见 `ExtractResultStatus` |
| failureReason | String? | 否 | 失败原因摘要 | 失败时可写入 |
| createdAt | DateTime | 是 | 创建时间 | 不可为空 |

### ExtractResult 约束

1. `rawResultJson` 不可直接作为页面展示主来源。
2. `normalizedResultJson` 才是落库后的稳定口径。
3. 若提取失败，允许仅保存 `failureReason` 和 `rawResultJson`。

## Report

报告表示某一时间范围内多个健康事件的聚合输出。

| 字段名 | 类型 | 必填 | 含义 | 约束 |
| --- | --- | --- | --- | --- |
| id | String | 是 | 报告业务主键 | UUID |
| reportType | String | 是 | 报告类型 | 见 `ReportType` |
| rangeStart | DateTime | 是 | 报告时间范围起点 | 不可为空 |
| rangeEnd | DateTime | 是 | 报告时间范围终点 | 不可为空，且必须晚于 `rangeStart` |
| sourceEventCount | int | 是 | 参与汇总的事件数量 | 最小为 0 |
| reportContent | String? | 否 | 报告正文，优先存 Markdown | 可为空 |
| reportSummary | String? | 否 | 报告摘要 | 可为空 |
| reportStatus | String | 是 | 报告状态 | 见 `ReportStatus` |
| generatedAt | DateTime? | 否 | 生成完成时间 | 成功时应有值 |
| createdAt | DateTime | 是 | 记录创建时间 | 不可为空 |

### Report 约束

1. 报告的主展示内容优先使用 `reportContent`。
2. 报告列表可使用 `reportSummary`。
3. 报告失败时，页面必须可区分“尚未生成”和“生成失败”。

## 值对象定义

## FollowupQuestion

| 字段名 | 类型 | 必填 | 含义 | 约束 |
| --- | --- | --- | --- | --- |
| questionId | String | 是 | 问题 ID | 在同一会话内唯一 |
| questionText | String | 是 | 问题文本 | 不可为空 |
| answerType | String | 是 | 回答类型 | MVP 当前固定为 `text` |
| isRequired | bool | 是 | 是否必答 | MVP 可默认 `false` |

## FollowupAnswer

| 字段名 | 类型 | 必填 | 含义 | 约束 |
| --- | --- | --- | --- | --- |
| questionId | String | 是 | 对应问题 ID | 必须能在问题列表中找到 |
| answerText | String? | 否 | 用户回答文本 | 可为空，表示跳过 |
| skipped | bool | 是 | 是否跳过 | 与 `answerText` 一起判断状态 |

## SymptomItem

| 字段名 | 类型 | 必填 | 含义 | 约束 |
| --- | --- | --- | --- | --- |
| label | String | 是 | 症状名称 | 不可为空 |
| normalizedLabel | String? | 否 | 归一化后的症状名 | 可为空 |
| severity | String | 是 | 症状强度 | 见 `SymptomSeverity` |
| durationText | String? | 否 | 时长描述 | 可为空 |
| note | String? | 否 | 补充说明 | 可为空 |

## 状态枚举定义

## InputType

- `text`
- `image`
- `voice`
- `mixed`

## HealthEventStatus

- `draft`：已创建原始记录，尚未进入追问或提取
- `followup_pending`：等待追问
- `extracting`：正在执行结构化提取
- `completed`：已有可用结构化结果
- `failed`：提取或保存失败

## AttachmentSourceType

- `camera`
- `gallery`

## FollowupSessionStatus

- `pending`
- `answered`
- `skipped`
- `completed`
- `failed`

## ExtractResultStatus

- `success`
- `partial`
- `failed`

## ReportType

- `week`
- `month`
- `quarter`

## ReportStatus

- `pending`
- `generating`
- `success`
- `failed`
- `expired`

## SymptomSeverity

- `unknown`
- `mild`
- `moderate`
- `severe`

## AI 输出 JSON 结构约束

## `POST /ai/followup`

### 请求体

```json
{
  "healthEventId": "string",
  "inputText": "string",
  "knownContext": {
    "historySummary": "string"
  }
}
```

### 响应体

```json
{
  "questions": [
    {
      "questionId": "q1",
      "questionText": "这种不舒服持续多久了？",
      "answerType": "text",
      "isRequired": false
    }
  ]
}
```

### 约束

1. `questions` 必须是数组。
2. 问题对象必须包含 `questionId`、`questionText`、`answerType`、`isRequired`。
3. MVP 当前 `answerType` 仅允许 `text`。

## `POST /ai/extract`

### 请求体

```json
{
  "healthEventId": "string",
  "inputText": "string",
  "followup": [
    {
      "questionId": "q1",
      "questionText": "这种不舒服持续多久了？",
      "answerText": "一天"
    }
  ]
}
```

### 响应体

```json
{
  "eventTime": "2026-03-08T10:00:00+08:00",
  "symptoms": [
    {
      "label": "胃部不适",
      "normalizedLabel": "胃部不适",
      "severity": "mild",
      "durationText": "一天",
      "note": null
    }
  ],
  "healthEvents": [
    "消化道不适"
  ],
  "importantContext": [
    "近期睡眠不足"
  ],
  "summary": "轻度胃部不适，伴随胀气。"
}
```

### 约束

1. 响应必须是对象。
2. `symptoms` 必须是数组；若无结果可为空数组，不可返回字符串。
3. `healthEvents` 与 `importantContext` 必须是字符串数组。
4. `summary` 可为空，但字段应保留。

## `POST /ai/report`

### 请求体

```json
{
  "reportType": "week",
  "rangeStart": "2026-03-01T00:00:00+08:00",
  "rangeEnd": "2026-03-07T23:59:59+08:00",
  "events": []
}
```

### 响应体

```json
{
  "title": "本周健康报告",
  "summary": "本周主要问题为睡眠不足和轻度胃部不适。",
  "advice": [
    "保持规律作息"
  ],
  "checkSuggestions": [
    "若胃部不适持续一周以上，建议就诊"
  ],
  "markdown": "# 本周健康报告\n..."
}
```

### 约束

1. `title`、`summary`、`advice`、`checkSuggestions`、`markdown` 为标准字段名。
2. `advice` 与 `checkSuggestions` 必须是数组。
3. 页面主展示优先使用 `markdown`，列表摘要可使用 `summary`。

## DTO / Entity / ViewModel / Domain Model 职责边界

### DTO

- 只用于输入输出、序列化与反序列化
- 可与接口、数据库字段形态接近
- 不承担页面展示逻辑

### Entity

- 位于 domain 层
- 表达稳定业务语义
- 不依赖具体 JSON 结构和页面状态

### ViewModel / VO

- 位于 presentation 层或 presentation 附近
- 只服务于页面展示组合
- 不回写数据库，不作为跨层标准对象

### Domain Model

- 只在用例需要组合多个 Entity 时引入
- 若单个 Entity 足够表达业务，则不额外创建 Domain Model
- 不允许以“以后可能会用到”为理由滥建 Domain Model

## 核心对象结构口径

## 文本输入

- 优先写入 `HealthEvent.userInputText`
- `inputType = text`

## 图片输入

- 图片原文件写入本地文件系统
- `Attachment.filePath` 保存路径
- `inputType = image` 或 `mixed`

## 语音输入

- MVP 以转写文本为主
- 转写文本写入 `HealthEvent.userInputText`
- 若保留音频文件，另行扩展附件类型；当前默认不要求

## 症状记录

- 症状信息优先落在 `ExtractResult.normalizedResultJson` 的 `symptoms` 数组
- 列表页只读取 `HealthEvent.symptomSummary` 作为摘要
- 详情页可读取完整结构化结果

## 报告摘要

- 列表页可展示 `reportSummary`
- 详情页主内容使用 `reportContent`
- 两者不要求完全一致，但应来自同一份报告结果

## JSON 解析失败时的兜底约束

1. 解析失败不能导致页面崩溃。
2. 解析失败时不得伪造结构化字段。
3. 解析失败时允许：
   - 保存原始输入
   - 保存 `rawResultJson`
   - 写入失败状态
   - 展示“解析失败，可重试”
4. 若 JSON 合法但字段缺失：
   - 缺失字段按可空字段处理
   - 必填核心结构缺失时，标记为失败或部分成功，不强行补齐
5. 若 JSON 类型不符合约定：
   - 不直接容忍为成功结果
   - 进入失败或部分成功分支，并保留原始响应用于排查
