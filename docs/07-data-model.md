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
| `event_start_time` | INTEGER / DATETIME | NOT NULL | 无 | 事件开始时间 |
| `event_end_time` | INTEGER / DATETIME | NOT NULL | 无 | 事件结束时间 |
| `source_type` | TEXT | NOT NULL | 无 | 当前固定 `text` |
| `raw_text` | TEXT | NULLABLE | `NULL` | 原始描述 |
| `symptom_summary` | TEXT | NULLABLE | `NULL` | AI 摘要 |
| `notes` | TEXT | NULLABLE | `NULL` | AI 备注 |
| `created_at` | INTEGER / DATETIME | NOT NULL | 无 | 记录创建时间 |
| `updated_at` | INTEGER / DATETIME | NOT NULL | 无 | 记录更新时间 |

### 表：`attachments`

| 字段 | 类型 | 约束 | 默认值 | 说明 |
|---|---|---|---|---|
| `id` | TEXT | PK | 无 | 业务 UUID |
| `health_event_id` | TEXT | FK -> `health_events.id` | 无 | 所属记录 |
| `file_path` | TEXT | NOT NULL | 无 | 复制后的本地路径 |
| `file_type` | TEXT | NOT NULL | 无 | 当前固定 `image` |
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
| `created_at` | INTEGER / DATETIME | NOT NULL | 无 | 首次创建时间 |

## 索引

当前代码中没有显式声明二级索引或唯一索引：

| 名称 | 类型 | 字段 | 用途 |
|---|---|---|---|
| `health_events` 主键 | 主键 | `id` | 记录唯一标识 |
| `attachments` 主键 | 主键 | `id` | 附件唯一标识 |
| `reports` 主键 | 主键 | `id` | 报告唯一标识 |

补充事实：

- `attachments.health_event_id` 存在外键引用
- 报告逻辑上的唯一范围由查询与覆盖更新保证，数据库层当前没有唯一约束

## 迁移策略

- 当前 `schemaVersion = 3`
- `from < 2`：创建 `reports` 表
- `from < 3`：将旧 `health_events.event_time` 迁移为：
  - `event_start_time = event_time`
  - `event_end_time = event_time`
  - `created_at = event_time`

当前没有单独的 SQL 迁移文件，迁移逻辑写在 `AppDatabase.migration` 中。

## 删除策略

- 当前没有记录删除或报告删除的用户入口
- 新增记录失败时，已复制的附件文件会立即回滚删除
- 报告重复生成时，保留第一条有效报告并删除其余同范围重复记录
- 当前没有“卸载前导出”或“定时清理旧附件”的策略

## 兼容要求

- 旧版本数据若仍使用 `event_time`，升级到 schema 3 时必须可迁移
- `rawText`、`symptomSummary`、`notes` 允许为空
- `adviceJson` 即使内容损坏，详情页也不能崩溃，只能降级为空建议列表
- 附件路径必须指向应用仍可访问的文件；文件失效时页面需降级提示

## 测试关注点

- 迁移测试：验证 `event_time` 升级为 `eventStartTime` / `eventEndTime`
- 排序测试：记录列表按 `eventEndTime` 倒序
- 范围测试：报告源记录按 `eventEndTime` 落入范围筛选
- 空值测试：`notes` 缺失时仍可成功保存并在详情页显示空状态

