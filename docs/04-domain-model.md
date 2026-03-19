# 领域模型

## 实体清单

- `AppSetting`：本地全局设置项，采用 typed key-value。
- `IntakeSession`：一次本地追问会话，承接未完成草稿与最终正式记录的桥接关系。
- `IntakeMessage`：追问会话中的消息历史。
- `IntakeSessionAttachment`：会话阶段暂存的本地附件。
- `HealthEvent`：正式健康记录。
- `Attachment`：正式健康记录下的本地附件。
- `AiExtractResult`：旧 `/ai/extract` 返回结果。
- `IntakeDraft`：`/ai/intake` 当前轮返回的草稿字段集合。
- `Report`：某个时间范围内正式健康记录的汇总。

## 实体关系

| 实体 A | 关系 | 实体 B | 说明 |
|---|---|---|---|
| `AppSetting` | 独立实体 | - | 通过 key-value 持久化全局设置 |
| `IntakeSession` | 1:N | `IntakeMessage` | 一次追问会话包含多条消息 |
| `IntakeSession` | 1:N | `IntakeSessionAttachment` | 会话阶段暂存多张附件 |
| `IntakeSession` | 0..1:1 | `HealthEvent` | 完成后回填 `healthEventId`；重新追问继续关联原正式记录 |
| `HealthEvent` | 1:N | `Attachment` | 正式记录可关联多张图片 |
| `HealthEvent` | 逻辑来源于 | `IntakeDraft` | `/ai/intake` 完成时把草稿写入正式记录 |
| `Report` | N:N（逻辑聚合） | `HealthEvent` | 报告按时间范围聚合正式记录，不单独持久化关联表 |

## 字段语义

### `AppSetting`

| 字段 | 类型 | 含义 | 规则 |
|---|---|---|---|
| `key` | `String` | 设置项唯一标识 | 全局唯一，推荐 `snake_case` |
| `valueType` | `String` | 当前值类型 | 只能是 `bool/int/double/string/json` |
| `boolValue` | `bool?` | 布尔值 | 仅 `valueType=bool` 时可非空 |
| `intValue` | `int?` | 整型值 | 仅 `valueType=int` 时可非空 |
| `doubleValue` | `double?` | 浮点值 | 仅 `valueType=double` 时可非空 |
| `stringValue` | `String?` | 普通字符串 | 仅 `valueType=string` 时可非空 |
| `jsonValue` | `String?` | JSON 字符串 | 仅 `valueType=json` 时可非空 |
| `createdAt` | `DateTime` | 首次创建时间 | 缺失 key 时不报错，由仓库层提供默认值 |
| `updatedAt` | `DateTime` | 最后更新时间 | 当前已用 key 为 `follow_up_mode_enabled`、`first_use_disclaimer_accepted` |

### `IntakeSession`

| 字段 | 类型 | 含义 | 规则 |
|---|---|---|---|
| `id` | `String` | 追问会话 ID | UUID |
| `healthEventId` | `String?` | 关联的正式记录 ID | 未完成时为空；完成后回填 |
| `eventTime` | `DateTime` | 本次记录的业务时间锚点 | 创建会话时捕获，整个会话期间不变 |
| `followUpModeSnapshot` | `bool` | 创建时的首页开关快照 | 后续首页开关变化不反写历史会话 |
| `status` | `String` | 会话状态 | `questioning/awaiting_user_input/finalized/finalized_by_force` |
| `initialRawText` | `String` | 用户第一次提交的原始描述 | 不因后续追问覆盖 |
| `mergedRawText` | `String?` | 当前轮合并后的原始描述 | 只要 worker 返回字符串就原样保存 |
| `latestQuestion` | `String?` | 当前轮 AI 最新问题 | 最近响应是 `needs_followup` 时有值 |
| `draftSymptomSummary` | `String?` | 当前轮症状摘要草稿 | 只要字段存在且类型正确，就原样保存 |
| `draftNotes` | `String?` | 当前轮备注草稿 | 入库前仅 `trim()`，空字符串也保留 |
| `draftActionAdvice` | `String?` | 当前轮操作/观察建议草稿 | 当前一轮最多一条，不客户端伪造 |
| `createdAt` | `DateTime` | 会话创建时间 | 首次创建时写入 |
| `updatedAt` | `DateTime` | 会话最后更新时间 | 每轮状态变化时更新 |

### `IntakeMessage`

| 字段 | 类型 | 含义 | 规则 |
|---|---|---|---|
| `id` | `String` | 消息 ID | UUID |
| `sessionId` | `String` | 所属会话 ID | 外键指向 `IntakeSession.id` |
| `seq` | `int` | 顺序号 | 同一 session 内递增且唯一 |
| `role` | `String` | 消息角色 | `user` / `assistant` |
| `content` | `String` | 消息正文 | `trim()` 后不能为空 |
| `createdAt` | `DateTime` | 消息创建时间 | 本地写入 |

### `HealthEvent`

| 字段 | 类型 | 含义 | 规则 |
|---|---|---|---|
| `id` | `String` | 正式记录 ID | UUID |
| `sourceType` | `String` | 来源类型 | 当前固定为 `text` |
| `rawText` | `String?` | 正式记录原始描述 | `/ai/intake` 完成时使用 `draft.mergedRawText` |
| `symptomSummary` | `String?` | 正式记录摘要 | 不做 fallback，不做内容纠偏 |
| `notes` | `String?` | 正式记录备注 | 允许空字符串 |
| `actionAdvice` | `String?` | 正式记录建议 | 来源于最终 `draft.actionAdvice` |
| `createdAt` | `DateTime` | 正式记录创建时间 | 首次完成时等于 `session.eventTime` |
| `updatedAt` | `DateTime` | 最后更新时间 | 重新追问完成时刷新 |

### `Attachment`

| 字段 | 类型 | 含义 | 规则 |
|---|---|---|---|
| `id` | `String` | 附件 ID | UUID |
| `healthEventId` | `String` | 所属正式记录 ID | 外键指向 `HealthEvent.id` |
| `filePath` | `String` | 本地路径 | 指向应用私有目录 |
| `fileType` | `String` | 文件类型 | 当前固定为 `image` |
| `createdAt` | `DateTime` | 创建时间 | 转正时写入 |

### `IntakeDraft`

| 字段 | 类型 | 含义 | 规则 |
|---|---|---|---|
| `mergedRawText` | `String` | 当前轮合并后的用户描述 | 字段缺失或类型错误才算非法 payload |
| `symptomSummary` | `String` | 当前轮摘要草稿 | 字符串即保留，允许空字符串 |
| `notes` | `String` | 当前轮备注草稿 | 字符串即保留，允许空字符串 |
| `actionAdvice` | `String` | 当前轮建议草稿 | 字符串即保留，允许空字符串 |

## 生命周期

- `AppSetting`
  - 创建：首次写入某个设置 key
  - 更新：同 key 覆盖写入
- `IntakeSession`
  - 创建：新建记录时创建
  - 更新：继续追问、强制结束、重新追问、完成正式记录时更新
  - 删除：当前没有独立用户入口
- `HealthEvent`
  - 创建：第一次 `final` 时写入
  - 更新：重新追问完成时更新原记录
- `Report`
  - 创建：报告首次生成
  - 覆盖：同 `reportType + rangeStart + rangeEnd` 再生成时覆盖

## 不变量

- `AppSetting` 同一行只能有一个 value 列非空。
- `follow_up_mode_enabled` 缺失时默认值为 `false`。
- `first_use_disclaimer_accepted` 缺失或类型异常时默认值为 `false`。
- `IntakeMessage.content` 经过 `trim()` 后不能为空。
- 未完成追问不能写入 `health_events` 或报告输入。
- `symptomSummary` 只要字段存在且类型为字符串，就保留原值，哪怕为空或很短。
- 重新追问完成时更新原 `HealthEvent`，不创建重复正式记录。
