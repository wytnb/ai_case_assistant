# 领域模型

## 实体清单

- `HealthEvent`：一次有时间语义的健康记录
- `Attachment`：挂靠在 `HealthEvent` 下的本地文件
- `AiExtractResult`：新增记录时的 AI 提取结果
- `Report`：某个时间范围内健康事件的聚合总结
- `AiReportEvent`：发送给 `/ai/report` 的事件载荷

## 实体关系

| 实体 A | 关系 | 实体 B | 说明 |
|---|---|---|---|
| `HealthEvent` | 1:N | `Attachment` | 一条记录可关联多张图片 |
| `HealthEvent` | 1:0..1 | `AiExtractResult` | 当前不单独落表，提取结果会折叠进入记录字段 |
| `Report` | N:N（逻辑汇总） | `HealthEvent` | 报告按时间范围汇总多条记录，不单独保存关联表 |
| `AiReportEvent` | 派生自 | `HealthEvent` | 客户端生成报告请求时从记录映射得到 |

## 字段语义

### `HealthEvent`

| 字段 | 类型 | 含义 | 是否必填 | 备注 |
|---|---|---|---|---|
| `id` | `String` | 业务主键 UUID | 是 | 客户端生成 |
| `sourceType` | `String` | 来源类型 | 是 | 当前固定为 `text` |
| `rawText` | `String?` | 用户原始描述 | 否 | 当前创建链路实际都会写入 |
| `symptomSummary` | `String?` | AI 摘要 | 否 | 提取缺失时可回退为 `rawText` 首句 |
| `notes` | `String?` | AI 备注 | 否 | 缺失时保持空值 |
| `createdAt` | `DateTime` | 事件时间 / 记录创建时间 | 是 | 创建链路中与 `eventTime` 语义一致 |
| `updatedAt` | `DateTime` | 记录更新时间 | 是 | 当前创建时与 `createdAt` 相同 |

### `Attachment`

| 字段 | 类型 | 含义 | 是否必填 | 备注 |
|---|---|---|---|---|
| `id` | `String` | 业务主键 UUID | 是 | 客户端生成 |
| `healthEventId` | `String` | 所属记录 ID | 是 | 外键指向 `HealthEvent.id` |
| `filePath` | `String` | 复制后的本地路径 | 是 | 指向应用私有目录 |
| `fileType` | `String` | 文件类型 | 是 | 当前固定为 `image` |
| `createdAt` | `DateTime` | 附件记录创建时间 | 是 | 客户端写入 |

### `AiExtractResult`

| 字段 | 类型 | 含义 | 是否必填 | 备注 |
|---|---|---|---|---|
| `symptomSummary` | `String` | 提取摘要 | 是 | 客户端会兜底生成 |
| `notes` | `String?` | 提取备注 | 否 | 缺失时返回 `null` |

### `AiReportEvent`

| 字段 | 类型 | 含义 | 是否必填 | 备注 |
|---|---|---|---|---|
| `id` | `String` | 记录 ID | 是 | 来自 `HealthEvent.id` |
| `eventTime` | `DateTime` | 事件时间 | 是 | 从 `HealthEvent.createdAt` 映射 |
| `sourceType` | `String` | 来源类型 | 是 | 当前固定为 `text` |
| `rawText` | `String?` | 原始文本 | 否 | 发送前会截断到最多 500 字符 |
| `symptomSummary` | `String?` | 摘要 | 否 | 空白转 `null` |
| `notes` | `String?` | 备注 | 否 | 空白转 `null` |

### `Report`

| 字段 | 类型 | 含义 | 是否必填 | 备注 |
|---|---|---|---|---|
| `id` | `String` | 业务主键 UUID | 是 | 客户端生成或复用已存在报告 ID |
| `reportType` | `String` | 报告类型 | 是 | `week` / `month` / `quarter` |
| `rangeStart` | `DateTime` | 范围开始时间 | 是 | 当天零点向前推算 |
| `rangeEnd` | `DateTime` | 范围结束时间 | 是 | 当天 23:59:59.999999 |
| `title` | `String` | 报告标题 | 是 | 来自 AI |
| `summary` | `String` | 报告摘要 | 是 | 来自 AI |
| `adviceJson` | `String` | 建议列表 JSON 字符串 | 是 | 客户端保存序列化结果 |
| `markdown` | `String` | Markdown 正文 | 是 | 当前以普通文本显示 |
| `generatedAt` | `DateTime` | 本次生成时间 | 是 | 客户端写入 |
| `createdAt` | `DateTime` | 首次创建时间 | 是 | 覆盖更新时保留旧值 |

## 生命周期

- `HealthEvent`
  - 创建：新增记录成功后写入
  - 更新：当前没有编辑入口
  - 删除：当前没有删除入口

- `Attachment`
  - 创建：记录创建成功时随图片一起写入
  - 回滚：记录创建失败时已复制文件会被删除
  - 删除：当前没有独立删除入口

- `Report`
  - 创建：报告首次生成时写入
  - 覆盖：同 `reportType + rangeStart + rangeEnd` 重新生成时覆盖更新
  - 清理：存在重复报告时保留第一条并删除其余记录

## 不变量

- `HealthEvent.id`、`Attachment.id`、`Report.id` 使用字符串 UUID
- `HealthEvent.createdAt == eventTime`，且创建时 `HealthEvent.updatedAt == HealthEvent.createdAt`
- `Attachment.healthEventId` 必须指向已有 `HealthEvent`
- `Attachment.filePath` 指向已复制到应用私有目录的路径
- `Report` 以 `reportType + rangeStart + rangeEnd` 作为逻辑唯一范围
- `notes` 缺失时保持为空值，不由客户端补伪造文案

## 待确认问题

- 未来若引入独立提取结果表，`AiExtractResult` 是否仍折叠到 `HealthEvent` 中待确认
- 未来若支持文本 + 图片混合来源，`sourceType` 是否扩展为更多枚举待确认
