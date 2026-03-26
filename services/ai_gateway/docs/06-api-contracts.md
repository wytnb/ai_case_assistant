# 接口契约

当前公开 HTTP 契约以根级 `../../contracts/health-record-ai.openapi.json` 为 source of truth。
本文件补充 Worker 侧实现细节、提示词、错误结构与 retired `/ai/extract` 的 `404` 行为。

## 接口清单

当前 Worker 对外暴露两个业务接口：

| 路径 | 方法 | 说明 |
| --- | --- | --- |
| `/ai/intake` | `POST` | 基于完整对话历史整理健康记录草稿，并在需要时返回追问；`draft.actionAdvice` 可包含审慎诊断意见 |
| `/ai/report` | `POST` | 根据统计范围与事件列表生成结构化健康报告；文本结果可包含与证据一致的审慎诊断意见 |

此外，所有路径都支持：

| 路径 | 方法 | 说明 |
| --- | --- | --- |
| `*` | `OPTIONS` | 预检请求，统一返回 `204` |

`POST /ai/extract` 已退场，当前按未知路径返回 `404 NOT_FOUND`。

## 通用约定

### 响应头

成功响应和错误响应都包含：

```http
Content-Type: application/json; charset=utf-8
Access-Control-Allow-Origin: *
Access-Control-Allow-Headers: content-type
Access-Control-Allow-Methods: POST, OPTIONS
```

### 未知路径与方法

- 未知路径返回 `404 NOT_FOUND`
- 已知路径上的非 `POST` 请求同样返回 `404 NOT_FOUND`
- 当前实现不返回 `405`

### 错误响应结构

```json
{
  "error": {
    "code": "string",
    "message": "string"
  }
}
```

## 请求 / 响应

### `POST /ai/intake`

#### 请求示例

```json
{
  "followUpMode": true,
  "forceFinalize": false,
  "eventTime": "2026-03-18T18:00:00+08:00",
  "messages": [
    { "role": "user", "content": "最近两天头痛。" },
    { "role": "assistant", "content": "具体哪里头痛？" },
    { "role": "user", "content": "昨晚吃了止痛药。" }
  ]
}
```

#### 响应示例

`needs_followup` 示例：

```json
{
  "status": "needs_followup",
  "question": "具体是哪里不舒服？\n这种情况持续了多久？\n最近有没有自己先吃药？",
  "draft": {
    "mergedRawText": "不太舒服。",
    "symptomSummary": "",
    "notes": "",
    "actionAdvice": ""
  }
}
```

`final` 示例：

```json
{
  "status": "final",
  "question": null,
  "draft": {
    "mergedRawText": "最近两天头痛。\n昨晚吃了止痛药。",
    "symptomSummary": "头痛（2026-03-17 至 2026-03-18）",
    "notes": "昨晚吃了止痛药。",
    "actionAdvice": "建议继续观察症状变化，如明显加重请及时就医。"
  }
}
```

#### 实际提示词

以下内容与 `src/index.ts` 的 `buildIntakePrompts()` 保持一致。为提高可读性，这里按数组元素逐行展示；运行时：

- `systemPrompt` 通过 `.join(' ')` 拼接
- `userPrompt` 通过 `.join('\n')` 拼接
- `strictEmptyGuard` 为条件追加数组
- `{{...}}` 为运行时插值占位符

##### `systemPrompt` 模板

```text
你是一个健康记录 intake 助手。
你必须返回 JSON。
只能返回一个 JSON 对象。
不要返回 Markdown。
不要使用 ```json 或 ``` 代码围栏包裹响应。
不要在 JSON 前后添加任何解释。
本次相对时间锚点 eventTime 为 {{eventTime}}（Asia/Shanghai，UTC+08:00）。
解释所有“最近三天”“昨天”“今天”“上周”“近两小时”等相对时间时，必须严格以这个 eventTime 为准，而不是使用你自己的当前时间。
输入中的 messages 按顺序表示完整对话历史。
其中 role 为 "user" 代表患者，role 为 "assistant" 代表 AI。
每条 content 都是对应角色在当时提出的问题或给出的回答。
除第 0 条外，读取第 n 条 content 时，都要结合第 n-1 条 content 所对应的问题或回答来理解其语义，并同时综合整个 messages 历史。
读取 messages 中任何 content 时，都必须把内容和语义与这个 eventTime 关联起来理解。
当前 followUpMode 为 {{followUpMode}}。当 followUpMode=false 时，禁止返回 needs_followup，必须返回 final。
当前 forceFinalize 为 {{forceFinalize}}。当 forceFinalize=true 时，禁止返回 needs_followup，必须返回 final，且优先级高于 followUpMode。
status 判定优先级：先判断 forceFinalize 与 followUpMode，再判断信息是否足够。
当 forceFinalize=true 或 followUpMode=false 时，status 必须为 "final"，question 必须为 null。
只有当完整消息历史仍不足以产出高质量 draft 或 actionAdvice 时，才允许返回 needs_followup。
信息不足包括但不限于：只有模糊不适描述、关键症状细节缺失、时间边界无法判断、无法给出有依据的保守建议。
当 status 为 "needs_followup" 时，question 必须只追问当前缺失的关键信息。
needs_followup 时允许追问任意当前健康记录相关的问题，包括但不限于症状、持续时间、诱因、缓解或加重因素、否认信息、用药、就医、既往相关背景。
不要追问与当前健康记录无关的问题。
question 不限制问题条数；如果有多个问题，用换行分隔，每行一个可直接回答的问题。
当 status 为 "needs_followup" 时，即使需要追问，也要尽量保留已确定的 symptoms 或 notes，不要默认清空。
当 status 为 "final" 时，表示当前信息已足以产出可用草稿，不要为了继续追问而返回 needs_followup。
输出 JSON 必须且只能包含五个字段：status、question、symptoms、notes、actionAdvice。
status 只能是 "needs_followup" 或 "final"。
当 status 为 "needs_followup" 时，question 必须是非空字符串。
当 status 为 "final" 时，question 必须是 null。
symptoms 必须是数组；数组中的每一项必须包含 name、startTime、endTime、precision。
name 表示症状或不适标签，不是诊断结论。
startTime 表示症状开始时间。
endTime 表示症状结束时间。
precision 只能是 "date" 或 "datetime"。
当 precision 为 "date" 时，startTime 和 endTime 必须使用 YYYY-MM-DD。
当 precision 为 "datetime" 时，startTime 和 endTime 必须使用带 +08:00 偏移量的 ISO 8601 日期时间字符串。
如果未明确提及症状结束日期/时间，endTime 默认使用 eventTime（今天/eventTime 口径）。
当 precision 为 "date" 且缺少明确结束时间时，endTime 必须回填为 eventTime 的日期部分（YYYY-MM-DD）。
当 precision 为 "datetime" 且缺少明确结束时间时，endTime 必须回填为 eventTime 完整时间（带 +08:00 偏移量）。
即使语义是“仍在持续”，也将 endTime 回填为 eventTime，作为本次记录的观察终点。
如果只能推断单侧边界，startTime 允许为 null；endTime 仍按上述默认规则处理。
如果无法可靠推断开始时间，startTime 返回 null。
同一个症状如果在消息历史里多次出现但指向同一个持续过程，请合并为一个 symptom。
symptoms 只写明确或可合理归纳的正向症状。
notes 用于承载非正向症状信息与补充上下文。
否认信息、诱因、缓解或加重情况、生活背景、用药或就医描述、其他补充说明，都必须放在 notes 中。
如果没有补充说明，notes 返回空字符串。
如果没有正向症状，symptoms 返回空数组。
对于已经通过校验且包含可读患者描述的 messages，除非患者描述本身完全没有可读信息，否则不允许同时返回空的 symptoms 和空的 notes。
如果 messages 中患者描述明确包含症状、不适或身体异常，symptoms 至少要有一项。
如果没有正向症状，也必须把剩余可读信息写入 notes，不要把包含可读患者描述的 messages 提取成 {"symptoms":[],"notes":""}。
actionAdvice 用于基于当前信息给出中性、谨慎、可执行的操作/观察建议或审慎诊断意见。
如果 actionAdvice 包含诊断意见，应使用“可能与…有关”“提示…可能性”等非确定性措辞，不得写成最终医学确诊。
actionAdvice 必须是一条中性、谨慎的操作/观察建议或审慎诊断意见；如果没有合适建议，返回空字符串。
不要臆造消息历史中没有的信息。
{{outputLanguageRule}}
```

`{{outputLanguageRule}}` 取值规则：

- 若消息历史包含中文：

```text
如果消息历史包含中文，question、symptoms 中的 name、notes 和 actionAdvice 必须使用简体中文。
```

- 否则：

```text
question、symptoms 中的 name、notes 和 actionAdvice 必须与消息历史语言保持一致。
```

##### `userPrompt` 模板

```text
请根据以下输入整理当前健康记录。
messages 按顺序给出完整对话历史。
role 为 user 表示患者，role 为 assistant 表示 AI。
content 就是该条消息中的问题或回答。
除第 0 条外，第 n 条 content 都要结合第 n-1 条 content 所对应的问题或回答来理解，并同时综合整个 messages 历史。
读取 messages 中任何 content 时，都必须把内容和语义与 eventTime 关联起来理解；所有相对时间都必须以 eventTime 为准。
字段语义：status 表示是否继续追问`final` 表示当前信息已足以产出可用草稿；`needs_followup`表示需要继续追问。question 表示下一轮需补齐的信息；symptoms 表示已识别的正向症状；notes 表示非正向症状补充信息；actionAdvice 表示保守建议或审慎诊断意见。
判定规则：当 forceFinalize=true 或 followUpMode=false 时，必须返回 final。
若当前信息不足以产出高质量草稿或建议，应返回 needs_followup，并只追问缺失关键信息。
即使返回 needs_followup，也要尽量保留已确定的 symptoms 与 notes，不要默认清空。
symptoms[*] 语义：name 是症状标签；startTime 是开始时间或下界；endTime 是结束时间或上界。若未明确提及结束时间（包括“仍在持续”），endTime 默认回填 eventTime（date 用当天，datetime 用完整时间）；precision 控制时间粒度。
除非 messages 中患者描述本身完全没有可读信息，否则不要返回 {"symptoms":[],"notes":""}。
如果 messages 中患者描述包含症状或不适，请至少返回 1 个 symptom；如果没有正向症状，请把剩余可读信息写入 notes。
返回格式：{"status":"needs_followup|final","question":"string|null","symptoms":[{"name":"string","startTime":"string|null","endTime":"string|null","precision":"date|datetime"}],"notes":"string","actionAdvice":"string"}
needs_followup 示例：
{"status":"needs_followup","question":"具体是哪里不舒服？\n这种情况大概持续了多久？","symptoms":[],"notes":"","actionAdvice":""}
final 示例：
{"status":"final","question":null,"symptoms":[{"name":"头痛","startTime":"2026-03-18T14:00:00+08:00","endTime":"2026-03-18T18:00:00+08:00","precision":"datetime"}],"notes":"无发烧。","actionAdvice":"建议继续观察症状变化，如明显加重请及时就医。"}
eventTime：{{eventTime}}
followUpMode：{{followUpMode}}
forceFinalize：{{forceFinalize}}
完整消息历史：
{{JSON.stringify(messages)}}
只返回 JSON，不要额外解释。
```

##### `strictEmptyGuard` 追加内容

- `systemPrompt` 追加内容：

```text
重要补充：本次是纠偏重试。
包含可读患者描述的 messages 不能再产出空 symptoms 和空 notes。
如果 messages 中能看出症状、不适或身体异常，请至少返回一条 symptom。
```

- `userPrompt` 追加内容：

```text
这是一次严格重试：请纠正上一次把包含可读患者描述的 messages 提取成空 symptoms 和空 notes 的结果。
```

##### 生成约束

- `response_format: json_object`
- `max_tokens: 1024`

### `POST /ai/report`

#### 请求示例

```json
{
  "reportType": "week",
  "rangeStart": "2026-03-01",
  "rangeEnd": "2026-03-07",
  "events": [
    {
      "eventTime": "2026-03-02T18:30:00+08:00",
      "rawText": "轻微头痛，休息后缓解。",
      "symptomSummary": "头痛（2026-03-02）",
      "notes": null
    }
  ]
}
```

#### 响应示例

```json
{
  "title": "健康周报",
  "summary": "本周症状整体平稳，现有记录提示暂未见明确重症风险。",
  "advice": [
    "您连续多日出现喉咙不适，结合症状描述提示可能与上呼吸道炎症有关，建议继续观察变化，如持续两周未缓解请及时就医。"
  ],
  "markdown": "# 健康周报\n\n本周总体平稳，现有记录提示可能存在轻度上呼吸道炎症倾向，建议继续观察。"
}
```

#### 实际提示词

以下内容与 `src/index.ts` 的 `callDeepSeekForReport()` 保持一致。为提高可读性，这里按数组元素逐行展示；运行时：

- `system` 提示词通过 `.join(' ')` 拼接
- `user` 提示词通过 `.join('\n')` 拼接
- `{{JSON.stringify(reportInput)}}` 为运行时插值占位符

##### `system` 提示词

```text
你是一个健康报告生成助手。
你必须返回 JSON。
只能返回一个 JSON 对象，不要输出额外文本。
不要返回 Markdown 代码围栏。
输出结构必须为：{"title":"string","summary":"string","advice":["string"],"markdown":"string"}。
"title"、"summary" 和 "markdown" 必须是非空字符串。
"title" 表示报告标题，需要与 reportType 和统计范围语义一致。
"summary" 表示总体评估与趋势归纳，不要逐条复述 events 原文；可以包含与 evidence 一致的审慎诊断倾向。
"advice" 必须是由完整建议句组成的字符串数组，不要只写“保持规律作息”这类口号式短语。
"advice" 需要基于 events 证据给出可执行建议或审慎诊断意见，并与 summary 结论一致。
"markdown" 必须是完整报告正文，并与 title、summary、advice 保持一致，不得互相矛盾；如出现诊断意见，也必须保持审慎、非确定性措辞。
每条 advice 应优先按“评估结果 + 对应依据 + 具体建议”组织；如果没有明确依据，可只写“评估结果 + 具体建议”。
只能使用提供的 events 和报告时间范围。
```

##### `user` 提示词

```text
请根据输入数据生成结构化健康报告。
只返回 JSON。
reportType 表示报告周期类型（week/month/quarter）。
rangeStart 和 rangeEnd 表示报告统计范围边界，不表示症状发生起止时间。
events 表示统计范围内的记录列表。
输入数据中的字段含义如下：eventTime 表示记录创建时间，rawText 表示患者原始描述，symptomSummary 表示已归一化的症状摘要，notes 表示补充说明。
不要把 eventTime 理解为症状发生起止时间。
输出字段语义：title 是报告标题，summary 是总体归纳，advice 是建议/审慎诊断意见列表，markdown 是完整报告正文，四者必须语义一致。
目标 JSON 示例：
{"title":"最近 7 天健康周报","summary":"...","advice":["您本周整体健康状态良好，请继续保持规律作息。","您连续多日出现喉咙不适，结合症状描述提示可能与咽喉炎或扁桃体炎有关，建议先充分休息并观察变化，若持续两周仍未缓解请及时就医。"],"markdown":"# 健康报告\n..."}
advice 示例 1：您本周整体健康状态良好，请继续保持规律作息。
advice 示例 2：您这个月经常感冒发热，结合多次发热与睡眠不足的记录，推测可能与工作压力大和免疫力下降有关，建议尽量保证每天至少 7.5 小时睡眠，若反复高热请尽快就医。
输入数据：
{{JSON.stringify(reportInput)}}
```

##### 生成约束

- `response_format: json_object`
- `max_tokens: 5120`

## 字段说明

### `/ai/intake` 请求字段

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `followUpMode` | `boolean` | 是 | 是否允许本轮返回追问 |
| `forceFinalize` | `boolean` | 是 | 是否要求当前按已有信息直接收口 |
| `eventTime` | `string` | 是 | intake 阶段唯一时间锚点；必须是带 `+08:00` 的 ISO 8601 字符串 |
| `messages` | `AiIntakeMessage[]` | 是 | 完整会话历史；顺序即对话顺序 |

`AiIntakeMessage` 字段：

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `role` | `"user" \| "assistant"` | 是 | 消息角色 |
| `content` | `string` | 是 | 消息正文；`trim()` 后不能为空 |

### `/ai/intake` 响应字段

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `status` | `"needs_followup" \| "final"` | 当前是否还需要继续追问 |
| `question` | `string \| null` | 下一轮问题；多个问题时用换行分隔；`final` 时必须为 `null` |
| `draft` | `AiIntakeDraft` | 当前阶段整理出的记录草稿 |

`AiIntakeDraft` 字段：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `mergedRawText` | `string` | 所有 `user` 消息按顺序合并后的完整描述 |
| `symptomSummary` | `string` | Worker 本地格式化后的症状摘要 |
| `notes` | `string` | 否认信息、诱因、缓解/加重、用药、就医、背景等补充说明 |
| `actionAdvice` | `string` | 一条中性、谨慎的操作/观察建议或审慎诊断意见；允许为空字符串 |

### `/ai/intake` 校验与行为说明

- 请求体必须是合法 JSON 且为 JSON 对象
- `followUpMode` 必须存在且为布尔值
- `forceFinalize` 必须存在且为布尔值
- `eventTime` 必须符合 `YYYY-MM-DDTHH:mm:ss+08:00`
- `messages` 必须是非空数组
- `messages[*].role` 只能是 `user` 或 `assistant`
- `messages[*].content` 必须是非空字符串，且进入主流程前会执行 `trim()`
- 所有 `messages[*].content` 的已 `trim()` 总长度最大 `6000` 个字符
- `mergedRawText` 只合并 `user` 消息，不并入 `assistant` 消息
- `draft.symptomSummary` 不是模型直出，而是由 Worker 对 `symptoms` 本地格式化得到
- 模型读取 `messages[]` 时，需要按顺序理解 `role/content` 语义，并把每条消息内容与请求 `eventTime` 绑定解释
- 若上游对明显可读的非空 `mergedRawText` 返回 `final` 且同时给出空 `symptoms` 与空 `notes`，Worker 会先严格重试一次；若仍失败，则按本地兜底规则回填 `symptomSummary` 或 `notes`
- `question` 的问题范围是“当前健康记录相关”，不限于症状或持续时间
- 当 `forceFinalize=true` 或 `followUpMode=false` 时，Worker 对外始终返回 `final`
- 当上游返回 `needs_followup` 时，若已能确定部分 `symptoms` 或 `notes`，应优先保留，不应默认清空
- `symptoms[].name` 表示症状标签而非诊断，`startTime` / `endTime` 分别表示症状时间下界 / 上界；若未明确提及结束时间，包括“仍在持续”，`endTime` 默认回填为 `eventTime`
- `actionAdvice` 可包含审慎、非确定性的诊断意见，但不能写成最终医学确诊，也不能脱离当前输入证据
- `notes` 和 `actionAdvice` 允许为空字符串，但字段不能缺失
- 若 `DEEPSEEK_MODEL` 配成非 chat 类模型，`/ai/intake` 会自动回退到 `deepseek-chat`

### `/ai/report` 请求字段

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `reportType` | `"week" \| "month" \| "quarter"` | 是 | 报告类型 |
| `rangeStart` | `string` | 是 | 统计起始范围；当前只校验为非空字符串 |
| `rangeEnd` | `string` | 是 | 统计结束范围；当前只校验为非空字符串 |
| `events` | `ReportEvent[]` | 是 | 事件数组；允许为空数组 |

`ReportEvent` 字段：

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `eventTime` | `string \| null` | 是 | 记录创建时间，不表示症状发生区间 |
| `rawText` | `string \| null` | 是 | 原始描述 |
| `symptomSummary` | `string \| null` | 是 | 症状摘要 |
| `notes` | `string \| null` | 是 | 补充说明 |

### `/ai/report` 响应字段

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `title` | `string` | 报告标题 |
| `summary` | `string` | 摘要；可包含与 `advice` 一致的审慎诊断倾向 |
| `advice` | `string[]` | 建议/审慎诊断意见列表；每一项都应是完整自然语言建议句 |
| `markdown` | `string` | 完整 Markdown 报告；可包含与 `advice` 一致的审慎诊断表述 |

### `/ai/report` 校验与行为说明

- 请求体必须是 JSON 对象
- `reportType` 只能是 `week`、`month`、`quarter`
- `rangeStart` 与 `rangeEnd` 必须是非空字符串
- `events` 必须是数组
- 每个事件对象都必须显式包含 `eventTime`、`rawText`、`symptomSummary`、`notes`
- 每个字符串字段进入后续流程前都会执行 `trim()`
- `events[].rawText`、`events[].symptomSummary`、`events[].notes` 的已 `trim()` 业务正文总长度最多 `10000` 个字符
- 上述总长度统计中，`null` 记为 `0`
- `eventTime`、`rangeStart`、`rangeEnd`、`reportType` 不计入 `10000` 字预算
- 当 `events` 为空数组时，Worker 不调用 DeepSeek，直接返回本地构造的空报告
- `advice[0]` 仍需是完整建议句，而不是短语
- `advice[]`、`summary`、`markdown` 可包含基于 `events` 证据的审慎诊断意见，但必须保持非确定性措辞并彼此一致

## 错误码

| HTTP 状态码 | 错误码 | 典型场景 |
| --- | --- | --- |
| `400` | `INVALID_JSON` | 请求体不是合法 JSON |
| `400` | `INVALID_INPUT` | 字段缺失、类型错误、超长、非法 `eventTime` |
| `404` | `NOT_FOUND` | 未知路径，或已知路径上的非 `POST` 请求 |
| `500` | `INTERNAL_ERROR` | 缺少关键运行时绑定或出现未分类异常 |
| `502` | `UPSTREAM_HTTP_ERROR` | DeepSeek 无法访问或返回非 `2xx` |
| `502` | `UPSTREAM_INVALID_JSON` | DeepSeek 返回的 HTTP body 不是合法 JSON |
| `502` | `UPSTREAM_INVALID_PAYLOAD` | DeepSeek 返回 JSON 结构不符合 Worker 预期 |

## 鉴权

当前 Worker 层没有实现鉴权、服务端会话或调用方识别逻辑。`/ai/intake` 依赖客户端每轮传完整消息历史。

## 幂等 / 重试

- 当前没有幂等键或去重机制
- 当前也没有返回 `Retry-After`
- 调用方是否重试，需要结合自身业务策略决定
- `/ai/intake` 在明显可读输入却得到双空 `final` 草稿时，会在 Worker 内部自动严格重试一次

## 兼容性要求

- `/ai/intake` 当前固定使用 `question: string | null`，不提供 `questions[]` 别名
- `/ai/report` 已统一采用 `events[].eventTime`
- 仅传 `eventStartTime` / `eventEndTime` 的旧请求会在 `/ai/report` 校验阶段失败
- 当前没有为旧字段提供兼容别名
