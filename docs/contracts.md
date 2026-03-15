# 数据契约

## 文档目的

本文件定义核心数据结构、字段含义、字段约束、状态枚举、AI JSON 结构以及 DTO / Entity / ViewModel / Domain Model 的职责边界。  
本文件是模型、接口、落库和解析实现的最终口径。

## 契约使用原则

1. **结构化事实字段**与**展示缓存字段**必须分开定义，不混用。
2. 原始输入、结构化提取结果、展示摘要、聚合报告属于不同层级对象，不可互相替代。
3. AI 返回值只有在通过标准化与校验后，才可作为结构化结果落库。
4. 列表页为了性能允许保存少量冗余展示字段，但冗余字段不是事实主来源。
5. 当前 MVP 优先保证：
   - 可落库
   - 可回显
   - 可追溯
   - 可失败兜底
6. 当前不为了少量查询需求提前引入复杂拆表，但也不把本应结构化的数据塞进字符串摘要字段。

---

## 一、通用字段规则

### 1. ID 规则

1. 业务主键统一使用字符串 UUID。
2. UUID 由客户端生成。
3. 数据库内部若存在技术性自增主键，不对外暴露，也不作为跨层传递的主标识。
4. 页面路由参数、跨模块传递、对象关联统一使用业务 UUID。

### 2. 时间字段规则

1. Dart / 本地数据库中使用 `DateTime` 表达时间。
2. JSON / HTTP 契约中统一使用 ISO 8601 字符串，并包含时区偏移。
3. 各时间字段语义必须固定：
   - `eventTime`：健康事件发生时间
   - `createdAt`：记录创建时间
   - `updatedAt`：记录最后更新时间
   - `generatedAt`：报告或提取结果生成完成时间
4. 时间范围统一使用：
   - `rangeStart`
   - `rangeEnd`
5. 若 AI 推断了时间，必须在结构化结果中记录时间来源，不能与用户明确输入的时间混淆。

### 3. 可空规则

1. 能从业务上确定为必有的信息，不设为可空。
2. 会受 AI 解析稳定性影响的字段，可以可空。
3. 可空字段必须有明确降级行为。
4. 不允许使用“空字符串”代替 `null` 作为缺失值。

### 4. 命名规则

1. 字段名统一使用 `camelCase`。
2. 不使用含义模糊的字段名，例如 `desc`、`info1`、`tmpValue`。
3. 枚举值统一使用小写 `snake_case` 或小写单词，不混用大小写风格。
4. 同一语义在不同对象中使用同名字段，例如 `createdAt`、`updatedAt`、`status`。

### 5. 事实字段与缓存字段规则

1. **事实字段**：用于表达业务真实状态，必须稳定、可追溯、可被其他流程依赖。
2. **缓存字段**：用于提升列表展示或快速回显，可以冗余，但必须从事实字段推导而来。
3. 缓存字段不得承担结构化主来源职责。
4. 一旦事实字段与缓存字段冲突，以事实字段为准。

---

## 二、核心实体清单

1. `HealthEvent`
2. `Attachment`
3. `FollowupSession`
4. `ExtractResult`
5. `Report`

---

## 三、核心实体定义

## 1. HealthEvent

健康事件是核心主对象，表示一次有时间语义的健康相关记录。

### 当前本地表最小骨架

第二批“本地数据层最小骨架”落地时，`HealthEvent` 先只覆盖文本记录 MVP 所需的最小字段。  
AI 追问、提取结果、状态流转等字段不在本批本地表中落地，后续在对应能力接入时再扩展。

### 字段定义

| 字段名 | 类型 | 必填 | 层级 | 含义 | 约束 |
| --- | --- | --- | --- | --- | --- |
| id | String | 是 | 事实字段 | 健康事件业务主键 | UUID |
| eventTime | DateTime | 是 | 事实字段 | 健康事件发生时间 | 可来自用户输入、当前时间或 AI 推断后的回填 |
| sourceType | String | 是 | 事实字段 | 当前记录来源类型 | 当前至少能表达文本记录来源；详细枚举后续再收敛 |
| rawText | String? | 否 | 原始输入字段 | 用户原始文本输入 | 当前文本记录 MVP 建议优先写入该字段 |
| symptomSummary | String? | 否 | 缓存字段 | 用于列表展示的简短摘要文本 | 纯文本，不是 JSON；建议 120 字以内 |
| notes | String? | 否 | 补充字段 | 人工补充备注 | 纯文本，可空 |
| createdAt | DateTime | 是 | 事实字段 | 创建时间 | 不可为空 |
| updatedAt | DateTime | 是 | 事实字段 | 更新时间 | 每次修改后更新 |

### 约束

1. `HealthEvent` 在当前批次必须先保留原始输入，再为后续 AI 处理和详情展示留出扩展位。
2. `sourceType` 当前只作为字符串落库，不在本批引入额外状态枚举约束。
3. `rawText`、`symptomSummary`、`notes` 都必须是纯文本，不允许写入任意 JSON。
4. `symptomSummary` 是**展示缓存字段**，不是结构化事实字段。
5. `createdAt` 表示记录创建时间，`updatedAt` 表示记录最后更新时间，语义不得混用。
6. AI 追问、提取、报告相关字段与状态不在本批 `HealthEvent` 表中落地。

---

## 2. Attachment

附件表示挂靠在健康事件下的原始文件。

### 当前本地表最小骨架

第二批本地数据层只要求先表达“一个健康记录对应多个附件”的关系。  
附件来源、MIME、文件大小和复杂删除联动不在本批强制落地。

### 字段定义

| 字段名 | 类型 | 必填 | 含义 | 约束 |
| --- | --- | --- | --- | --- |
| id | String | 是 | 附件业务主键 | UUID |
| healthEventId | String | 是 | 所属健康事件 ID | 必须指向已有 `HealthEvent` |
| filePath | String | 是 | 附件路径 | 推荐保存应用私有目录相对路径，不保存平台相关临时 URI |
| fileType | String | 是 | 附件类型 | 当前先保留为字符串，后续可再收敛枚举 |
| createdAt | DateTime | 是 | 创建时间 | 不可为空 |

### 约束

1. 当前结构上必须能表达“一个 `HealthEvent` 对应多个 `Attachment`”。
2. `healthEventId` 应关联到已有健康事件；本批允许先不实现复杂级联删除。
3. 推荐保存应用可控目录路径，不保存一次性临时 URI。
4. `fileType` 当前保留为字符串，不在本批提前扩展来源、大小、MIME 等附加字段。
5. 文件不存在时，不应导致详情页崩溃；应展示降级提示。

---

## 3. FollowupSession

追问会话表示围绕某次健康事件进行的一轮追问记录。

### 字段定义

| 字段名 | 类型 | 必填 | 含义 | 约束 |
| --- | --- | --- | --- | --- |
| id | String | 是 | 追问会话业务主键 | UUID |
| healthEventId | String | 是 | 所属健康事件 ID | 必须指向已有 `HealthEvent` |
| schemaVersion | int | 是 | 追问 JSON 结构版本 | 当前固定为 `1` |
| questionsJson | String | 是 | 追问问题 JSON | 结构见 `FollowupQuestion[]` |
| answersJson | String? | 否 | 用户回答 JSON | 结构见 `FollowupAnswer[]` |
| status | String | 是 | 追问会话状态 | 见 `FollowupSessionStatus` |
| createdAt | DateTime | 是 | 创建时间 | 不可为空 |
| updatedAt | DateTime | 是 | 更新时间 | 每次保存回答后更新 |

### 约束

1. 问题与回答顺序必须可还原。
2. `questionsJson` 与 `answersJson` 必须是合法 JSON 数组。
3. 页面层不直接处理裸 JSON 字符串，应先解析为结构对象。
4. 当前阶段同一健康事件可存在多轮追问，但页面默认只面向“当前有效会话”展示。

---

## 4. ExtractResult

提取结果表示 AI 对单个健康事件做出的结构化整理结果。

### 字段定义

| 字段名 | 类型 | 必填 | 层级 | 含义 | 约束 |
| --- | --- | --- | --- | --- | --- |
| id | String | 是 | 事实字段 | 提取结果业务主键 | UUID |
| healthEventId | String | 是 | 事实字段 | 所属健康事件 ID | 必须指向已有 `HealthEvent` |
| modelName | String? | 否 | 元数据字段 | 使用的模型名或代理标识 | 可空 |
| schemaVersion | int | 是 | 事实字段 | 结构化结果版本 | 当前固定为 `1` |
| rawResultJson | String? | 否 | 追溯字段 | AI 原始返回 JSON 字符串 | 用于追溯与排障 |
| normalizedResultJson | String? | 否 | 事实字段 | 标准化后 JSON 字符串 | 结构见下文 |
| status | String | 是 | 事实字段 | 提取结果状态 | 见 `ExtractResultStatus` |
| failureReason | String? | 否 | 事实字段 | 失败原因摘要 | 失败时可写入 |
| createdAt | DateTime | 是 | 事实字段 | 创建时间 | 不可为空 |

### 约束

1. `rawResultJson` 不可直接作为页面展示主来源。
2. `normalizedResultJson` 才是落库后的稳定口径。
3. 若提取失败，允许仅保存 `failureReason` 和 `rawResultJson`。
4. 当前阶段一个健康事件可有多条提取结果记录，但页面默认读取最新成功结果；若没有成功结果，则读取最近一次失败状态用于提示。

---

## 5. Report

报告表示某一时间范围内多个健康事件的聚合输出。

### 当前本地表最小骨架

当前批次先落地“手动生成近 7 天周报”的最小字段集，优先保证可生成、可落库、可回显。  
月报、季报、自动调度、导出与分享能力不在本批落地。

### 字段定义

| 字段名 | 类型 | 必填 | 层级 | 含义 | 约束 |
| --- | --- | --- | --- | --- | --- |
| id | String | 是 | 事实字段 | 报告业务主键 | UUID |
| reportType | String | 是 | 事实字段 | 报告类型 | 当前先固定使用 `week` |
| rangeStart | DateTime | 是 | 事实字段 | 报告时间范围起点 | 不可为空 |
| rangeEnd | DateTime | 是 | 事实字段 | 报告时间范围终点 | 不可为空，且不得早于 `rangeStart` |
| title | String | 是 | 事实字段 | 报告标题 | 非空文本 |
| summary | String | 是 | 缓存字段 | 列表摘要 | 非空文本 |
| adviceJson | String | 是 | 事实字段 | 建议列表 JSON 字符串 | 内容必须是 `string[]` 的 JSON |
| markdown | String | 是 | 事实字段 | 报告正文 Markdown | 非空文本 |
| generatedAt | DateTime | 是 | 事实字段 | 生成完成时间 | 不可为空 |
| createdAt | DateTime | 是 | 事实字段 | 记录创建时间 | 不可为空 |

### 约束

1. 当前批次只生成 `week` 报告，不引入 month / quarter 页面入口。
2. `adviceJson` 存储 `string[]` 的 JSON 字符串，详情页展示前需反序列化。
3. 报告详情主展示内容优先使用 `markdown`，列表摘要使用 `summary`。
4. 当范围内没有健康事件时，仍允许提交 `events: []` 生成并保存空报告。

---

## 四、值对象定义

## 1. FollowupQuestion

| 字段名 | 类型 | 必填 | 含义 | 约束 |
| --- | --- | --- | --- | --- |
| questionId | String | 是 | 问题 ID | 在同一会话内唯一 |
| questionText | String | 是 | 问题文本 | 不可为空 |
| answerType | String | 是 | 回答类型 | 当前仅允许 `text` |
| isRequired | bool | 是 | 是否必答 | 当前可默认 `false` |

## 2. FollowupAnswer

| 字段名 | 类型 | 必填 | 含义 | 约束 |
| --- | --- | --- | --- | --- |
| questionId | String | 是 | 对应问题 ID | 必须能在问题列表中找到 |
| answerText | String? | 否 | 用户回答文本 | 可为空，表示未填写 |
| skipped | bool | 是 | 是否跳过 | 与 `answerText` 一起判断状态 |

## 3. SymptomItem

| 字段名 | 类型 | 必填 | 含义 | 约束 |
| --- | --- | --- | --- | --- |
| label | String | 是 | 原始症状名 | 不可为空 |
| normalizedLabel | String? | 否 | 归一化症状名 | 可空 |
| severity | String | 是 | 症状强度 | 见 `SymptomSeverity` |
| durationText | String? | 否 | 时长描述 | 可空 |
| note | String? | 否 | 补充说明 | 可空 |

---

## 五、状态枚举定义

## 1. InputType

- `text`
- `image`
- `voice`
- `mixed`

## 2. EventTimeSource

- `user_input`
- `system_default`
- `ai_inferred`

## 3. HealthEventStatus

- `draft`：已创建原始记录，尚未发起追问或提取
- `followup_pending`：已有追问问题，等待用户补充
- `extracting`：正在执行结构化提取
- `completed`：已有可用结构化结果
- `failed`：当前处理链路失败

## 4. AttachmentSourceType

- `camera`
- `gallery`

## 5. FollowupSessionStatus

- `pending`：问题已生成，尚未开始填写
- `in_progress`：用户已开始填写，但未提交完成
- `completed`：回答已完成
- `skipped`：整轮追问被跳过
- `failed`：追问流程失败

### 说明

旧版的 `answered` 与 `completed` 语义容易重叠。  
当前统一保留 `completed` 表示本轮追问结束，避免双口径。

## 6. ExtractResultStatus

- `success`
- `partial`
- `failed`

## 7. ReportType

- `week`
- `month`
- `quarter`

## 8. ReportStatus

- `pending`
- `generating`
- `success`
- `failed`
- `expired`

## 9. SymptomSeverity

- `unknown`
- `mild`
- `moderate`
- `severe`

---

## 六、AI 输出 JSON 结构约束

## 1. `POST /ai/followup`

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
  "schemaVersion": 1,
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
3. 当前 `answerType` 仅允许 `text`。
4. 响应必须带 `schemaVersion`。

---

## 2. `POST /ai/extract`

### 请求体

```json
{
  "rawText": "string"
}
```

### 响应体

```json
{
  "symptomSummary": "string",
  "notes": "string"
}
```

### 约束

1. 响应必须是对象。
2. 请求体当前仅允许 `rawText` 作为输入，不携带图片内容。
3. `symptomSummary` 与 `notes` 都必须存在且为非空字符串。
4. 字段缺失或字段类型错误视为无效响应。
5. 若服务端返回空字符串，客户端可基于 `rawText` 生成最小可用的 `symptomSummary` 与 `notes` 作为兜底，不阻断新增记录保存。
6. 页面链路必须基于提取结果入库；网络或上游失败时走失败提示与重试路径。

---

## 3. `POST /ai/report`

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
  "markdown": "# 本周健康报告\n..."
}
```

### 约束

1. 响应必须是对象。
2. `title`、`summary`、`advice`、`markdown` 为当前最小必需字段。
3. `advice` 必须是字符串数组（`string[]`）。
4. 页面主展示优先使用 `markdown`，列表摘要使用 `summary`。

---

## 七、标准化结果结构口径

`ExtractResult.normalizedResultJson` 的标准结构定义如下：

```json
{
  "schemaVersion": 1,
  "eventTime": "2026-03-08T10:00:00+08:00",
  "eventTimeSource": "ai_inferred",
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

1. `schemaVersion` 必须存在。
2. `eventTime` 必须存在。
3. `eventTimeSource` 必须存在。
4. `symptoms`、`healthEvents`、`importantContext` 必须存在，允许为空数组。
5. `summary` 可空，但字段建议保留。

---

## 八、DTO / Entity / ViewModel / Domain Model 职责边界

## 1. DTO

- 只用于输入输出、序列化与反序列化
- 可以与接口或数据库字段形态接近
- 不承担页面展示逻辑

## 2. Entity

- 位于 domain 层
- 表达稳定业务语义
- 不依赖具体 JSON 结构和页面状态

## 3. ViewModel / VO

- 位于 presentation 层或 presentation 附近
- 只服务于页面展示组合
- 不回写数据库，不作为跨层标准对象

## 4. Domain Model

- 只在用例需要组合多个 Entity 时引入
- 若单个 Entity 足够表达业务，则不额外创建 Domain Model
- 不允许以“以后可能会用到”为理由滥建 Domain Model

---

## 九、核心对象结构口径

## 1. 文本输入

- 优先写入 `HealthEvent.userInputText`
- `inputType = text`

## 2. 图片输入

- 图片原文件写入本地文件系统
- `Attachment.filePath` 保存路径
- `inputType = image` 或 `mixed`

## 3. 语音输入

- 当前阶段以转写文本为主
- 转写文本写入 `HealthEvent.userInputText`
- 若未来保留音频文件，再单独扩展附件类型；当前不要求

## 4. 症状记录

- 症状事实优先落在 `ExtractResult.normalizedResultJson.symptoms`
- 列表页可读取 `HealthEvent.symptomSummary` 或 `primarySymptomsCacheJson`
- 详情页应读取完整结构化结果
- 不允许把结构化症状事实只存在 `symptomSummary` 中

## 5. 报告摘要

- 列表页可展示 `reportSummary`
- 详情页主内容使用 `reportContent`
- 两者不要求逐字一致，但必须来自同一份报告结果

---

## 十、JSON 解析失败时的兜底约束

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

---

## 十一、当前版本建议的最小落地实现

若当前仍处于 MVP 早期，推荐最小落地口径如下：

1. 当前本地数据层已落地 `HealthEvents`、`Attachments`、`Reports` 三张核心表。
2. `HealthEvent` 当前最小字段为：`id`、`eventTime`、`sourceType`、`rawText`、`symptomSummary`、`notes`、`createdAt`、`updatedAt`。
3. `Attachment` 当前最小字段为：`id`、`healthEventId`、`filePath`、`fileType`、`createdAt`。
4. `Report` 当前最小字段为：`id`、`reportType`、`rangeStart`、`rangeEnd`、`title`、`summary`、`adviceJson`、`markdown`、`generatedAt`、`createdAt`。
5. `HealthEvent.symptomSummary` 保留为纯文本摘要字段，不改成 JSON。
6. `Attachment.filePath` 统一收敛为应用可控目录路径，不混用绝对路径与临时 URI。
7. `FollowupSession`、`ExtractResult` 等 AI 能力相关表延后到对应批次再落地。
