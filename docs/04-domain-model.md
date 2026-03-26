# 领域模型

## 实体清单

- `AppSetting`：本地全局设置项，采用 typed key-value。
- `IntakeSession`：一次本地追问会话，承接未完成草稿与最终正式记录的桥接关系。
- `IntakeMessage`：追问会话中的消息历史。
- `IntakeSessionAttachment`：会话阶段暂存的本地附件。
- `HealthEvent`：正式健康记录。
- `Attachment`：正式健康记录下的本地附件。
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

### `IntakeSession`

- `eventTime`：本次记录的业务时间锚点，创建会话时捕获，整个会话期间不变。
- `followUpModeSnapshot`：创建时的首页开关快照，后续首页开关变化不反写历史会话。
- `mergedRawText` / `draftSymptomSummary` / `draftNotes` / `draftActionAdvice`：当前轮 AI 草稿快照。

### `HealthEvent`

- `rawText`：正式记录原始描述，来自 `draft.mergedRawText`。
- `symptomSummary`：正式记录摘要，只要字段存在且是字符串就原样保留。
- `notes`：补充说明，允许空字符串。
- `actionAdvice`：保守建议或审慎诊断意见，允许空字符串。
- `status`：`active/deleted`，用于软删除。

### `Report`

- `reportType`：当前支持 `week/month/quarter`。
- `rangeStart` / `rangeEnd`：报告统计范围。
- `title` / `summary` / `advice` / `markdown`：来自 `/ai/report` 的结果。

## 生命周期

- `AppSetting`
  - 创建：首次写入某个设置 key
  - 更新：同 key 覆盖写入
- `IntakeSession`
  - 创建：新建记录时创建
  - 更新：继续追问、强制结束、重新追问、完成正式记录时更新
  - 删除：未完成草稿允许用户硬删除；已关联正式记录被删除时标记为 `deleted`
- `HealthEvent`
  - 创建：第一次 `final` 时写入
  - 更新：重新追问完成时更新原记录
  - 删除：用户删除时改为软删除，保留数据库行
- `Report`
  - 创建：报告首次生成
  - 覆盖：同 `reportType + rangeStart + rangeEnd` 再生成时覆盖

## 不变量

- `AppSetting` 同一行只能有一个 value 列非空。
- `follow_up_mode_enabled` 缺失时默认值为 `false`。
- `first_use_disclaimer_accepted` 缺失或类型异常时默认值为 `false`。
- `IntakeMessage.content` 经过 `trim()` 后不能为空。
- 未完成追问不能写入 `health_events` 或报告输入。
- 重新追问完成时更新原 `HealthEvent`，不创建重复正式记录。
- `status=deleted` 的正式记录不再参与列表、详情、继续补充入口和报告输入。
- 历史旧 `/ai/extract` 记录可读取，但不再视为当前新增主链路的一部分。
