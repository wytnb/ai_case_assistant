# 测试策略

## 测试目标

- 确认新增记录默认 `/ai/intake` 主链路可稳定工作。
- 确认追问模式开关、会话恢复、强制结束、重新追问等关键状态机稳定。
- 确认未完成追问不会污染正式记录与报告。
- 确认 `/ai/extract` 兼容回归与 `symptomSummary` 新规则稳定。
- 明确哪些覆盖已经自动化，哪些仍依赖真实 AI 或手工 smoke。

## 测试分层

### Widget

- 首页首次免责弹窗显示、强阻断与同意后放行
- 首页追问模式开关显示、切换与重建后持久化
- `/records` 未完成追问分区与正式记录区展示
- `/records/new` 在 `followUpMode=false` 时 direct-final
- `/records/new` 在 `followUpMode=true` 且 `needs_followup` 时进入追问页
- `/intake/:id` 继续补充、强制结束、恢复 `awaiting_user_input`
- `/intake/:id` 恢复 `questioning` 自动重放
- 详情页展示 `actionAdvice`、空状态文案、重新开启追问入口
- 报告详情页末尾免责说明展示

### Database / Service

- `app_settings` typed key-value 读写
- 缺失 key 时默认值逻辑
- `first_use_disclaimer_accepted` 缺失或类型异常时按未同意处理
- `intake_sessions`、`intake_messages`、`intake_session_attachments` 落库与排序
- 首轮 final 创建 session 与正式记录
- `needs_followup` 不污染 `health_events`
- `forceFinalize` 后生成正式记录并回填 `healthEventId`
- 重新追问更新原正式记录而非重复创建
- 报告查询不带入未完成 session

### Remote contract

- `/ai/intake` 请求体字段、消息顺序、`followUpMode`、`forceFinalize`、`eventTime`
- `/ai/intake` 的 `needs_followup` / `final` 解析
- `/ai/intake` 中 `draft.symptomSummary=""` 仍保留
- `/ai/intake` 缺失 `draft.symptomSummary` 时按 `invalidResponsePayload`
- `/ai/extract` 不再使用 `rawText` 首句 fallback
- `/ai/extract` 中 `symptomSummary=""` 仍保留
- `/ai/extract` 缺失 `symptomSummary` 时按 `invalidResponsePayload`

### 真实接口 / 手工验证

- `test/features/ai/real_ai_api_test.dart`
- Android 真机或模拟器 smoke

## 当前自动化覆盖

| 测试文件 | 当前覆盖点 |
|---|---|
| `test/widget_test.dart` | 首页主入口与追问模式开关存在 |
| `test/app/presentation/home_page_test.dart` | 首页首次免责弹窗、同意放行、追问模式开关持久化 |
| `test/features/health_record/presentation/create_health_record_page_test.dart` | 新增记录页提交、路由与错误边界 |
| `test/features/health_record/presentation/health_record_list_page_test.dart` | 未完成追问区与正式记录区展示 |
| `test/features/health_record/presentation/health_record_detail_page_test.dart` | `actionAdvice`、空状态与重开入口 |
| `test/features/report/presentation/report_detail_page_test.dart` | 报告详情页末尾免责说明 |
| `test/features/intake/presentation/intake_page_test.dart` | 继续追问、强制结束、恢复 `questioning` |
| `test/features/intake/intake_service_test.dart` | 设置、会话、正式记录更新、报告隔离 |
| `test/features/ai/data/remote_ai_services_test.dart` | `/ai/intake`、`/ai/extract`、`/ai/report` 契约解析 |
| `test/core/database/app_database_test.dart` | 数据库与迁移基础覆盖 |

## 覆盖要求

### 当前必须守住的高风险点

- `/ai/intake` 请求体必须完整并使用完整消息历史。
- `symptomSummary` 的“字符串即保留”规则不能回退。
- 强制结束与重新追问不能产生重复正式记录。
- 未完成追问不能进入正式记录列表或报告。
- 首次免责同意必须在未同意前强阻断首页入口。
- Drift schema 5 迁移必须平稳。

### 真实接口 / 手工 smoke 触发条件

以下场景必须评估并尽量执行真实 AI 验证：

- `/ai/intake`、`/ai/extract`、`/ai/report` 请求体或响应解析变化
- `features/ai/`、`core/network/`、`core/config/` 变化
- `AI_API_BASE_URL`、`RUN_REAL_AI_API_TESTS`、`USE_MOCK_AI_EXTRACT` 行为变化

以下场景必须评估并尽量执行手工 smoke：

- 首页主入口变化
- 首页首次免责弹窗与同意放行行为变化
- `/records/new`、`/records`、`/records/:id`、`/intake/:id` 主链路变化
- `/reports/:id` 详情展示变化
- 附件暂存与转正逻辑变化

## 通过标准

必须通过的命令：

- `fvm flutter pub run build_runner build --delete-conflicting-outputs`
- `python scripts/check_doc_sync.py --working-tree --no-strict`
- `fvm flutter analyze`
- `fvm flutter test`

视变更类型追加：

- `fvm flutter test test/features/ai/real_ai_api_test.dart --dart-define=RUN_REAL_AI_API_TESTS=true --dart-define=AI_API_BASE_URL=...`
- Android 真机或模拟器 smoke

## 当前无法完全自动化的项目

- 图片选择到系统相册的完整真机交互
- 真实 AI 在不同网络环境下的稳定性
- 多平台打包后的产物可用性
