# 数据模型

## 存储清单

- Drift 数据库文件：`app_database.sqlite`
- 数据库表：`health_events`、`attachments`、`reports`
- 本地文件目录：`<documents>/health_records/<healthEventId>/attachments/`

## 结构定义

### 表：`health_events`

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|---|---|---|---|---|
| `id` | TEXT | PK | 无 | 业务 UUID |
| `source_type` | TEXT | NOT NULL | 无 | 当前固定为 `text` |
| `raw_text` | TEXT | NULLABLE | `NULL` | 原始描述 |
| `symptom_summary` | TEXT | NULLABLE | `NULL` | AI 摘要 |
| `notes` | TEXT | NULLABLE | `NULL` | AI 备注 |
| `created_at` | INTEGER / DATETIME | NOT NULL | 无 | 记录创建时间，同时作为业务语义上的 `eventTime` |
| `updated_at` | INTEGER / DATETIME | NOT NULL | 无 | 记录更新时间；创建时与 `created_at` 相同 |

补充事实：

- `eventTime` 是业务字段名，不单独持久化为 `event_time` 列。
- 当前实现中，新增记录时先取一次客户端本地时间，再同时写入 `created_at` 与 `updated_at`。
- 历史上的 `event_start_time` / `event_end_time` 已从当前 schema 中移除。

### 表：`attachments`

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|---|---|---|---|---|
| `id` | TEXT | PK | 无 | 业务 UUID |
| `health_event_id` | TEXT | FK -> `health_events.id` | 无 | 所属记录 |
| `file_path` | TEXT | NOT NULL | 无 | 复制后的本地路径 |
| `file_type` | TEXT | NOT NULL | 无 | 当前固定为 `image` |
| `created_at` | INTEGER / DATETIME | NOT NULL | 无 | 附件记录创建时间 |

### 表：`reports`

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|---|---|---|---|---|
| `id` | TEXT | PK | 无 | 业务 UUID |
| `report_type` | TEXT | NOT NULL | 无 | `week` / `month` / `quarter` |
| `range_start` | INTEGER / DATETIME | NOT NULL | 无 | 报告起始时间 |
| `range_end` | INTEGER / DATETIME | NOT NULL | 无 | 报告结束时间 |
| `title` | TEXT | NOT NULL | 无 | 报告标题 |
| `summary` | TEXT | NOT NULL | 无 | 报告摘要 |
| `advice_json` | TEXT | NOT NULL | 无 | 建议数组的 JSON 字符串 |
| `markdown` | TEXT | NOT NULL | 无 | Markdown 正文 |
| `generated_at` | INTEGER / DATETIME | NOT NULL | 无 | 本次生成时间 |
| `created_at` | INTEGER / DATETIME | NOT NULL | 无 | 首次落库时间 |

## 索引

当前代码中没有额外声明二级索引或唯一索引。

| 名称 | 类型 | 字段 | 用途 |
|---|---|---|---|
| `health_events` 主键 | 主键 | `id` | 记录唯一标识 |
| `attachments` 主键 | 主键 | `id` | 附件唯一标识 |
| `reports` 主键 | 主键 | `id` | 报告唯一标识 |

补充事实：

- `attachments.health_event_id` 存在外键引用。
- 列表查询与报告源记录查询当前都按 `health_events.created_at` 倒序或范围过滤。

## 迁移策略

- 当前 `schemaVersion = 4`
- `from < 2`：创建 `reports` 表
- `from < 3`：将旧 `health_events.event_time` 迁移到新的 `created_at`
- `from < 4`：重建 `health_events` 表结构，移除 `event_start_time` / `event_end_time`

补充事实：

- schema 2 迁移到 schema 4 后，旧 `event_time` 不再保留为独立列，历史记录的业务 `eventTime` 语义直接由 `created_at` 承接。
- schema 3 迁移到 schema 4 后，保留原有 `created_at` / `updated_at`，仅删除开始/结束时间列。
- 当前没有独立 SQL 迁移文件，迁移逻辑写在 `AppDatabase.migration` 中。

## 删除策略

- 当前没有记录删除或报告删除的用户入口
- 新增记录失败时，已复制的附件文件会立即回滚删除
- 报告重复生成时，保留最新写入结果并删除同范围冗余记录
- 当前没有“卸载前导出”或“定时清理旧附件”的策略

## 兼容要求

- 旧版本数据若仍使用 `event_time`，升级到 schema 4 时必须可迁移
- schema 3 中的 `event_start_time` / `event_end_time` 升级到 schema 4 时必须被移除
- `rawText`、`symptomSummary`、`notes` 允许为空
- `eventTime` 不单独存库，所有新旧记录都以 `created_at` 作为单一时间事实源
- `adviceJson` 即使内容损坏，详情页也不能崩溃，只能降级为空建议列表
- 附件路径必须指向应用仍可访问的文件；文件失效时页面需降级提示

## 测试关注点

- 迁移测试：验证 schema 2 的 `event_time` 升级后映射到 `createdAt`
- 迁移测试：验证 schema 3 升级后删除 `event_start_time` / `event_end_time`
- 创建测试：验证同一个 `eventTime` 同时写入 `createdAt` / `updatedAt`
- 排序测试：记录列表按 `createdAt` 倒序
- 范围测试：报告源记录按 `createdAt` 落入范围筛选
- 空值测试：`notes` 缺失时仍可成功保存并在详情页显示空状态
