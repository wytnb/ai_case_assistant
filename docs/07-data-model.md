# 数据模型

## 存储清单

- Drift 数据库文件：`app_database.sqlite`
- 正式附件目录：`<documents>/health_records/<healthEventId>/attachments/`
- 追问暂存附件目录：`<documents>/intake_sessions/<sessionId>/attachments/`

## 表结构

### 表：`app_settings`

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| `key` | TEXT | PK | 设置项唯一标识，例如 `follow_up_mode_enabled` |
| `value_type` | TEXT | NOT NULL | 只能是 `bool/int/double/string/json` |
| `bool_value` | INTEGER/BOOL | NULLABLE | 仅 `value_type=bool` 时可非空 |
| `int_value` | INTEGER | NULLABLE | 仅 `value_type=int` 时可非空 |
| `double_value` | REAL | NULLABLE | 仅 `value_type=double` 时可非空 |
| `string_value` | TEXT | NULLABLE | 仅 `value_type=string` 时可非空 |
| `json_value` | TEXT | NULLABLE | 仅 `value_type=json` 时可非空 |
| `created_at` | INTEGER/DATETIME | NOT NULL | 首次创建时间 |
| `updated_at` | INTEGER/DATETIME | NOT NULL | 最后更新时间 |

表级约束：

- `value_type` 必须在允许枚举内。
- 同一行五个 value 列只能有一个非空，并且必须与 `value_type` 对应。

### 表：`intake_sessions`

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| `id` | TEXT | PK | 追问会话 ID，UUID |
| `health_event_id` | TEXT | NULLABLE | 正式记录 ID，完成后回填 |
| `event_time` | INTEGER/DATETIME | NOT NULL | 本次记录的业务时间锚点 |
| `follow_up_mode_snapshot` | INTEGER/BOOL | NOT NULL | 创建会话时的首页开关快照 |
| `status` | TEXT | NOT NULL | `questioning/awaiting_user_input/finalized/finalized_by_force` |
| `initial_raw_text` | TEXT | NOT NULL | 用户第一次提交的原始描述 |
| `merged_raw_text` | TEXT | NULLABLE | 当前轮合并后的描述 |
| `latest_question` | TEXT | NULLABLE | 最近一次 AI 问题 |
| `draft_symptom_summary` | TEXT | NULLABLE | 当前轮摘要草稿 |
| `draft_notes` | TEXT | NULLABLE | 当前轮备注草稿 |
| `draft_action_advice` | TEXT | NULLABLE | 当前轮建议草稿 |
| `created_at` | INTEGER/DATETIME | NOT NULL | 会话创建时间 |
| `updated_at` | INTEGER/DATETIME | NOT NULL | 会话最后更新时间 |

### 表：`intake_messages`

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| `id` | TEXT | PK | 消息 ID，UUID |
| `session_id` | TEXT | FK -> `intake_sessions.id` | 所属会话 |
| `seq` | INTEGER | NOT NULL | 会话内顺序号 |
| `role` | TEXT | NOT NULL | `user` / `assistant` |
| `content` | TEXT | NOT NULL | 消息正文 |
| `created_at` | INTEGER/DATETIME | NOT NULL | 创建时间 |

索引 / 唯一约束：

- `(session_id, seq)` 唯一。

### 表：`intake_session_attachments`

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| `id` | TEXT | PK | 暂存附件 ID，UUID |
| `session_id` | TEXT | FK -> `intake_sessions.id` | 所属会话 |
| `file_path` | TEXT | NOT NULL | 暂存文件路径 |
| `file_type` | TEXT | NOT NULL | 当前固定为 `image` |
| `created_at` | INTEGER/DATETIME | NOT NULL | 创建时间 |

### 表：`health_events`

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| `id` | TEXT | PK | 正式记录 ID |
| `source_type` | TEXT | NOT NULL | 当前固定为 `text` |
| `raw_text` | TEXT | NULLABLE | 正式记录原始描述 |
| `symptom_summary` | TEXT | NULLABLE | 正式记录摘要 |
| `notes` | TEXT | NULLABLE | 正式记录备注 |
| `action_advice` | TEXT | NULLABLE | 正式记录建议 |
| `created_at` | INTEGER/DATETIME | NOT NULL | 正式记录创建时间 |
| `updated_at` | INTEGER/DATETIME | NOT NULL | 正式记录最后更新时间 |

补充规则：

- 首次 finalize 时：`created_at = updated_at = session.event_time`
- 重新追问更新原记录时：保留原 `created_at`，只刷新 `updated_at`

### 表：`attachments`

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| `id` | TEXT | PK | 附件 ID |
| `health_event_id` | TEXT | FK -> `health_events.id` | 所属正式记录 |
| `file_path` | TEXT | NOT NULL | 转正后的文件路径 |
| `file_type` | TEXT | NOT NULL | 当前固定为 `image` |
| `created_at` | INTEGER/DATETIME | NOT NULL | 创建时间 |

### 表：`reports`

当前结构未因本次追问能力而变化，但报告查询改为只读取正式 `health_events`。

## 迁移策略

- 当前 `schemaVersion = 5`
- `from < 2`
  - 创建 `reports`
- `from < 3`
  - 将旧 `health_events.event_time` 迁移为 `health_events.created_at`
- `from < 5`
  - 对 `health_events` 做表迁移，新增 `action_advice`
  - 创建 `app_settings`
  - 创建 `intake_sessions`
  - 创建 `intake_messages`
  - 创建 `intake_session_attachments`

补充事实：

- 历史记录迁移后 `health_events.action_advice` 默认为 `NULL`。
- 迁移不会为历史 `/ai/extract` 记录补建 intake session。

## 删除与清理策略

- 当前没有用户可见的记录删除入口。
- 会话完成后，暂存附件会转正为正式附件；未完成会话仍保留暂存附件。
- 报告重复生成时，保留最新结果并清理同范围旧结果。

## 兼容要求

- 缺失 `follow_up_mode_enabled` 时，必须由 `SettingsRepository` 返回默认值 `false`。
- 未完成追问不得出现在正式记录列表与报告查询中。
- `symptom_summary`、`notes`、`action_advice` 允许为空字符串。
- 旧 `/ai/extract` 历史记录在 schema 5 下仍可正常读取。
