# 数据契约

## 文档目的

本文件定义当前已落地的数据结构、字段含义、字段约束、AI JSON 结构以及当前跨层对象边界。
本文件是模型、接口、落库和解析实现的最终口径。

## 契约使用原则

1. 只记录当前仓库已经落地或已经被真实请求 / 响应使用的口径。
2. 原始输入、附件、报告属于不同层级对象，不可互相替代。
3. AI 返回值只有在通过当前客户端校验或兜底规则后，才可用于页面展示或落库。
4. 若代码中尚未出现某对象的真实实现，不在本文件中把它写成“当前契约”。
5. 当前 MVP 优先保证：
   - 可落库
   - 可回显
   - 可追溯
   - 可失败兜底

## 一、通用字段规则

### 1. ID 规则

1. 业务主键统一使用字符串 UUID。
2. UUID 由客户端生成。
3. 数据库内部若存在技术性自增主键，不对外暴露，也不作为跨层传递的主标识。
4. 路由参数和对象关联统一使用业务 UUID。

### 2. 时间字段规则

1. Dart / 本地数据库中使用 `DateTime` 表达时间。
2. `POST /ai/report` 请求体中统一使用 ISO 8601 字符串。
3. 当前已使用时间字段语义如下：
   - `eventStartTime`：健康事件开始时间，来自 `/ai/extract`
   - `eventEndTime`：健康事件结束时间，来自 `/ai/extract`
   - `createdAt`：记录创建时间
   - `updatedAt`：记录最后更新时间
   - `generatedAt`：报告生成完成时间
   - `rangeStart`：报告时间范围起点
   - `rangeEnd`：报告时间范围终点

### 3. 可空规则

1. `HealthEvent.rawText` 在数据库层可空，但当前新增记录页要求必填。
2. `symptomSummary`、`notes` 允许为空，用于承接 AI 返回不完整时的结果；其中 `symptomSummary` 可客户端兜底，`notes` 缺失时保持为空。
3. `Attachment` 和 `Report` 的当前落地字段全部为必填。
4. 不使用空字符串代替 `null` 表达缺失值。

### 4. 命名规则

1. 字段名统一使用 `camelCase`。
2. 同一语义在不同对象中保持同名，例如 `createdAt`、`rangeStart`、`rangeEnd`。
3. 枚举字符串当前直接使用小写英文值，例如 `text`、`image`、`week`。

## 二、当前已落地核心对象

1. `HealthEvent`
2. `Attachment`
3. `Report`
4. `AiExtractResult`
5. `AiReportEvent`
6. `AiReportResult`

## 三、核心对象定义

## 1. HealthEvent

当前对应 Drift 表：`health_events`

### 字段定义

| 字段名 | 类型 | 必填 | 含义 | 当前口径 |
| --- | --- | --- | --- | --- |
| id | String | 是 | 健康事件业务主键 | UUID |
| eventStartTime | DateTime | 是 | 事件开始时间 | 由 `/ai/extract` 返回，保存前必须校验通过 |
| eventEndTime | DateTime | 是 | 事件结束时间 | 由 `/ai/extract` 返回，保存前必须校验通过 |
| sourceType | String | 是 | 记录来源类型 | 当前统一写入 `text` |
| rawText | String? | 否 | 用户原始描述 | 新增页要求必填，多行文本 |
| symptomSummary | String? | 否 | AI 提取后的摘要 | 优先使用远程返回，否则客户端兜底生成 |
| notes | String? | 否 | AI 提取后的备注 | 仅保存 AI 返回的原始文本；缺失时为空 |
| createdAt | DateTime | 是 | 创建时间 | 新记录保存时写入当前时间；旧数据迁移时回填旧 `eventTime` |
| updatedAt | DateTime | 是 | 更新时间 | 当前首次保存时与 `createdAt` 相同 |

### 约束

1. `rawText` 是当前记录链路的事实主来源。
2. `sourceType` 当前尚未细分 `mixed`，即使记录带有图片附件，也仍写入 `text`。
3. `symptomSummary` 和 `notes` 都是纯文本，不存 JSON。
4. 列表页优先展示 `symptomSummary`，为空时退回 `rawText` 前 40 个字符。
5. 列表页时间排序与报表筛选统一基于 `eventEndTime`。
6. `eventStartTime`、`eventEndTime` 必须同时存在，且 `eventStartTime <= eventEndTime`。
7. 当前没有 `status`、`inputType`、`followup` 等附加字段。

## 2. Attachment

当前对应 Drift 表：`attachments`

### 字段定义

| 字段名 | 类型 | 必填 | 含义 | 当前口径 |
| --- | --- | --- | --- | --- |
| id | String | 是 | 附件业务主键 | UUID |
| healthEventId | String | 是 | 所属健康事件 ID | 引用 `health_events.id` |
| filePath | String | 是 | 复制后的本地文件路径 | 当前保存绝对路径 |
| fileType | String | 是 | 附件类型 | 当前固定为 `image` |
| createdAt | DateTime | 是 | 创建时间 | 与记录保存时间一致 |

### 约束

1. 当前只支持图片附件。
2. 附件在保存前会被复制到应用 documents 目录下：
   - `health_records/<healthEventId>/attachments/<attachmentId>.<ext>`
3. 数据库存储复制后的目标路径，而不是选择器临时 URI。
4. 详情页若文件缺失或图片加载失败，必须降级提示“图片加载失败”。

## 3. Report

当前对应 Drift 表：`reports`

### 字段定义

| 字段名 | 类型 | 必填 | 含义 | 当前口径 |
| --- | --- | --- | --- | --- |
| id | String | 是 | 报告业务主键 | UUID |
| reportType | String | 是 | 报告类型 | `week` / `month` / `quarter` |
| rangeStart | DateTime | 是 | 时间范围起点 | 本地按天计算 |
| rangeEnd | DateTime | 是 | 时间范围终点 | 本地按天计算 |
| title | String | 是 | 报告标题 | 来自 AI 响应 |
| summary | String | 是 | 报告摘要 | 来自 AI 响应 |
| adviceJson | String | 是 | 建议列表 JSON | `string[]` 序列化结果 |
| markdown | String | 是 | 报告正文 Markdown | 来自 AI 响应 |
| generatedAt | DateTime | 是 | 报告生成完成时间 | 生成成功后写入当前时间 |
| createdAt | DateTime | 是 | 报告创建时间 | 首次创建时写入，覆盖更新时保留原值 |

### 约束

1. `week` 对应最近 7 天，`month` 对应最近 30 天，`quarter` 对应最近 90 天。
2. `rangeStart` 为本地当天 00:00:00 向前推 `rangeDays - 1` 天。
3. `rangeEnd` 为本地当天 23:59:59.999999。
4. 同一 `reportType + rangeStart + rangeEnd` 只保留一条报告；重复生成时覆盖更新并删除额外重复项。
5. 报告详情页在展示前会把 `adviceJson` 解析为 `List<String>`；解析失败时按空列表处理。

## 4. AiExtractResult

当前定义位置：`features/ai/domain/services/ai_extract_service.dart`

| 字段名 | 类型 | 必填 | 含义 |
| --- | --- | --- | --- |
| symptomSummary | String | 是 | 提取摘要 |
| notes | String? | 否 | 提取备注 |
| eventStartTime | DateTime | 是 | 提取出的事件开始时间 |
| eventEndTime | DateTime | 是 | 提取出的事件结束时间 |

### 约束

1. 新增记录流程在入库前必须拿到该对象。
2. `symptomSummary` 缺失时仍会使用客户端兜底文本；`notes` 缺失时保持为空。
3. `eventStartTime`、`eventEndTime` 缺失、为空、类型错误、解析失败或先后顺序非法时，新增记录直接失败。
4. 当前没有独立的 ExtractResult 数据表。

## 5. AiReportEvent

当前定义位置：`features/ai/domain/services/ai_report_service.dart`

| 字段名 | 类型 | 必填 | 含义 |
| --- | --- | --- | --- |
| id | String | 是 | 健康事件 ID |
| eventStartTime | DateTime | 是 | 事件开始时间 |
| eventEndTime | DateTime | 是 | 事件结束时间 |
| sourceType | String | 是 | 来源类型 |
| rawText | String? | 否 | 原始描述 |
| symptomSummary | String? | 否 | 摘要 |
| notes | String? | 否 | 备注 |

### 约束

1. 生成报告前会从本地记录列表映射出该对象。
2. `rawText` 在发给 AI 前会被裁剪到最多 500 个字符。
3. 空字符串会在映射前被规范化为 `null`。
4. 报表筛选命中规则为：`eventEndTime` 落在 `rangeStart` 到 `rangeEnd` 之间。

## 6. AiReportResult

当前定义位置：`features/ai/domain/services/ai_report_service.dart`

| 字段名 | 类型 | 必填 | 含义 |
| --- | --- | --- | --- |
| title | String | 是 | 报告标题 |
| summary | String | 是 | 摘要 |
| advice | List<String> | 是 | 建议列表 |
| markdown | String | 是 | Markdown 正文 |

## 四、当前有效的字符串取值

## 1. HealthEvent.sourceType

当前已落地取值：

- `text`

说明：

- 即使记录附带图片，当前入库仍写 `text`。
- `image`、`mixed`、`voice` 等取值尚未在代码中落地。

## 2. Attachment.fileType

当前已落地取值：

- `image`

## 3. ReportType

当前已落地取值：

- `week`
- `month`
- `quarter`

## 五、AI JSON 契约

## 1. `POST /ai/extract`

### 请求体

```json
{
  "rawText": "string"
}
```

### 当前客户端响应期望

```json
{
  "symptomSummary": "string",
  "notes": "string",
  "eventStartTime": "2026-03-15T08:00:00.000",
  "eventEndTime": "2026-03-15T09:30:00.000"
}
```

### 当前客户端处理规则

1. 请求前会先对 `rawText` 执行 `trim()`。
2. 若 `rawText` 为空，客户端直接抛出 `invalidResponsePayload`，不会发请求。
3. 响应必须是对象；否则视为无效响应。
4. `symptomSummary` 若缺失、类型错误或空字符串，客户端会基于 `rawText` 第一段文本生成兜底摘要。
5. `notes` 若缺失、类型错误或空字符串，客户端将其视为 `null`，不再本地补写备注。
6. `eventStartTime`、`eventEndTime` 必须为可解析的 ISO 8601 字符串。
7. 若任一时间字段缺失、类型错误、解析失败或开始时间晚于结束时间，客户端直接判定为无效响应并拦截保存。
8. 当前提取请求不会携带图片内容。

## 2. `POST /ai/report`

### 请求体

```json
{
  "reportType": "month",
  "rangeStart": "2026-03-01T00:00:00.000",
  "rangeEnd": "2026-03-30T23:59:59.999999",
  "events": [
    {
      "id": "string",
      "eventStartTime": "2026-03-15T08:00:00.000",
      "eventEndTime": "2026-03-15T08:30:00.000",
      "sourceType": "text",
      "rawText": "string",
      "symptomSummary": "string",
      "notes": "string"
    }
  ]
}
```

### 当前客户端响应期望

```json
{
  "title": "本月健康报告",
  "summary": "本月主要问题为咽喉不适与轻度乏力。",
  "advice": [
    "保持规律作息"
  ],
  "markdown": "# 本月健康报告\n..."
}
```

### 当前客户端处理规则

1. `reportType` 不能为空。
2. `rangeEnd` 不得早于 `rangeStart`。
3. 响应必须是对象。
4. `title`、`summary`、`markdown` 必须是非空字符串。
5. `advice` 必须是字符串数组；若数组中出现非字符串项，整个响应视为无效。
6. 超时、网络异常、上游 HTTP 错误会被映射为 `AiReportException`。

## 六、当前跨层对象边界

### 1. 数据库对象

- 当前 `HealthEvent`、`Attachment`、`Report` 由 Drift 生成。
- 它们当前可以直接被列表页和详情页消费。

### 2. AI 对象

- AI 模块通过 `AiExtractService`、`AiReportService` 对外暴露能力。
- 页面不直接接触 Dio response。
- feature 服务层调用 AI 服务后，再把结果转换为本地保存或页面展示需要的字段。

### 3. 当前未落地对象

以下对象当前没有真实实现，不属于当前契约：

- `FollowupSession`
- `ExtractResult` 数据表
- 语音输入对象
- 设置页配置对象

## 七、JSON 异常时的当前兜底口径

### 提取接口

1. 响应不是对象：失败。
2. `symptomSummary` 缺失或为空：生成本地兜底摘要；`notes` 缺失或为空：保持为空。
3. 时间字段缺失、类型错误、无法解析或顺序非法：新增记录流程失败，页面提示“AI 返回的事件时间无效，保存已取消，请稍后重试”。
4. 网络或上游失败：新增记录流程失败，页面提示“保存失败，请稍后重试”。

### 报告接口

1. 响应不是对象：失败。
2. 任一必填文本字段为空：失败。
3. `advice` 不是纯字符串数组：失败。
4. 失败时不落库新报告，页面提示“生成失败，请稍后重试”。
