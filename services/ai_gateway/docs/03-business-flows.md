# 业务流程

## 流程清单

- `/ai/intake`：基于完整消息历史整理健康记录草稿，并在必要时返回追问
- `/ai/report`：基于统计范围与事件列表生成结构化健康报告
- 通用异常流程：统一处理非法输入、上游异常、未知路径与非法方法

## 主流程

### `/ai/intake`

1. 接收请求体，要求包含 `followUpMode`、`forceFinalize`、`eventTime`、`messages`
2. 校验请求体是 JSON 对象，且 `followUpMode` / `forceFinalize` 为布尔值
3. 校验 `eventTime` 是带 `+08:00` 的 ISO 8601 字符串，并归一化为中国时区时间锚点
4. 校验 `messages` 为非空数组；每条消息都必须包含合法的 `role` 和非空 `content`
5. 对每条 `content` 执行 `trim()`，统计总长度，限制为 `6000` 个字符
6. Worker 只合并 `user` 消息，按顺序用换行拼出 `mergedRawText`
7. 调用 DeepSeek，请模型基于完整消息历史返回 `status`、`question`、`symptoms`、`notes`、`actionAdvice`，其中 `actionAdvice` 可包含审慎、非确定性的诊断意见
8. Worker 校验上游 JSON 结构，并用内部格式化逻辑生成 `draft.symptomSummary`
9. 若上游返回 `final` 且对非空 `mergedRawText` 仍给出空 `symptoms` 和空 `notes`，Worker 会先用更严格提示词重试一次；若仍失败，则用本地兜底规则回填 `symptomSummary` 或 `notes`
10. 若 `forceFinalize=true` 或 `followUpMode=false`，Worker 对外强制返回 `final`
11. 返回 `{ status, question, draft }`

### `/ai/report`

1. 接收请求体，要求包含 `reportType`、`rangeStart`、`rangeEnd`、`events`
2. 校验 `reportType` 枚举值
3. 校验 `events` 是数组，且每个事件对象都显式包含 `eventTime`、`rawText`、`symptomSummary`、`notes`
4. 对字符串字段执行 `trim()`
5. 统计 `rawText`、`symptomSummary`、`notes` 的合并正文长度，限制为 `10000` 个字符
6. 若 `events` 为空，则直接返回本地空报告
7. 若 `events` 非空，则调用 DeepSeek 生成报告；报告文本可包含基于 `events` 证据的审慎诊断意见
8. 校验上游报告结构后返回最终结果

## 异常流程

### 输入非法

- 非法 JSON 返回 `400 INVALID_JSON`
- 字段缺失、类型错误、超长、非法 `eventTime` 返回 `400 INVALID_INPUT`

### 上游异常

- DeepSeek 不可达或返回非 `2xx`，返回 `502 UPSTREAM_HTTP_ERROR`
- DeepSeek HTTP body 非法 JSON，返回 `502 UPSTREAM_INVALID_JSON`
- DeepSeek 返回 JSON 但结构不符合要求，返回 `502 UPSTREAM_INVALID_PAYLOAD`

### 未知路径或非法方法

- 所有未知路径返回 `404 NOT_FOUND`
- 已知路径上的非 `POST` 请求同样返回 `404 NOT_FOUND`

## 状态流转

### `/ai/intake`

- 请求进入后先做输入校验；校验失败直接进入错误响应
- 校验通过后进入上游生成阶段
- 若信息不足且允许追问，流转到 `needs_followup`
- 若信息已足够，或 `forceFinalize=true`，或 `followUpMode=false`，流转到 `final`
- 若上游在 `final` 状态下产出双空草稿，先进入严格重试；仍失败时进入本地兜底

### `/ai/report`

- 请求进入后先做输入校验；校验失败直接进入错误响应
- `events=[]` 时直接流转到本地空报告
- `events` 非空时进入上游生成阶段
- 上游报告校验通过后返回最终报告

## 前置条件

- 环境中存在 `DEEPSEEK_API_KEY`
- 调用方已按当前契约组装请求
- 对 `/ai/intake`，调用方提供完整消息历史与唯一时间锚点 `eventTime`

## 后置条件

- 所有成功响应均为 JSON
- 所有错误响应均为统一错误结构
- `/ai/intake` 的 `draft.mergedRawText` 只反映 `user` 消息
- `/ai/report` 在空事件场景下不会调用 DeepSeek
- `/ai/intake` 与 `/ai/report` 均不会暴露旧的 `eventStartTime` / `eventEndTime` 公共契约
- `/ai/intake.draft.actionAdvice` 与 `/ai/report` 的文本输出若包含诊断意见，必须与输入证据一致，并保持审慎、非确定性措辞

## 待确认问题

- 当前无需要额外确认且会影响主流程的未决项
