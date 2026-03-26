# 数据模型

## 存储清单

- Flutter app 工程目录：`apps/ai_case_assistant/`
- Drift 数据库文件：`app_database.sqlite`
- 正式附件目录：`<documents>/health_records/<healthEventId>/attachments/`
- 追问暂存附件目录：`<documents>/intake_sessions/<sessionId>/attachments/`

## 表结构

### 表：`app_settings`

- 承载 `follow_up_mode_enabled`、`first_use_disclaimer_accepted` 等全局设置。
- typed key-value：同一行五个 value 列只能有一个非空。

### 表：`intake_sessions`

- 追问会话主表。
- `event_time` 保存本次记录唯一业务时间锚点。
- `health_event_id` 在 finalize 后回填。

### 表：`intake_messages`

- 保存追问消息历史。
- `(session_id, seq)` 唯一。

### 表：`intake_session_attachments`

- 保存草稿阶段暂存附件。
- 会话完成时转正为正式附件。

### 表：`health_events`

- 保存正式健康记录。
- `status` 当前为 `active/deleted`。
- `action_advice` 保存审慎建议或操作建议。

### 表：`attachments`

- 保存正式记录附件。

### 表：`reports`

- 保存报告生成结果。
- 查询来源只允许正式 `health_events`。

## 迁移策略

- 当前 `schemaVersion = 6`
- `from < 2`：创建 `reports`
- `from < 3`：将旧 `health_events.event_time` 迁移为 `health_events.created_at`
- `from < 5`：
  - 对 `health_events` 做表迁移，新增 `action_advice`
  - 创建 `app_settings`
  - 创建 `intake_sessions`
  - 创建 `intake_messages`
  - 创建 `intake_session_attachments`
- `from >= 4 && from < 6`：
  - 对 `health_events` 新增 `status`
  - 对 `health_events` 新增 `deleted_at`

补充事实：

- 历史记录迁移后 `health_events.action_advice` 默认为 `NULL`。
- 迁移不会为历史旧 `/ai/extract` 记录补建 intake session。

## 删除与清理策略

- 正式记录删除为软删除：
  - `health_events.status = deleted`
  - `health_events.deleted_at` 写入删除时间
  - 不物理删除正式记录、正式附件和报告
- 草稿记录删除为硬删除：
  - 删除 `intake_sessions`
  - 删除 `intake_messages`
  - 删除 `intake_session_attachments`
  - 删除暂存附件文件

## 兼容要求

- 缺失 `follow_up_mode_enabled` 时，必须由 `SettingsRepository` 返回默认值 `false`。
- 缺失或类型异常的 `first_use_disclaimer_accepted`，必须由 `SettingsRepository` 返回默认值 `false`。
- 未完成追问不得出现在正式记录列表与报告查询中。
- `status=deleted` 的正式记录不得出现在正式记录列表、详情与报告查询中。
- `symptom_summary`、`notes`、`action_advice` 允许为空字符串。
- 历史旧 `/ai/extract` 记录在当前 schema 下仍可正常读取。
