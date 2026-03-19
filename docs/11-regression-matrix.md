# 回归矩阵

| 功能 / 模块 | 改动触发条件 | 风险等级 | 必测场景 | 自动化情况 | 备注 |
|---|---|---|---|---|---|
| 首页与主入口 | 首页布局、追问模式开关、主导航变化 | 中 | 开关显示、切换、重启后持久化 | 有 | `home_page_test.dart`, `widget_test.dart` |
| 新增记录主链路 | `/records/new`、`IntakeService`、路由变化 | 高 | `followUpMode=false` direct-final；`followUpMode=true` 进入追问 | 有 | 默认链路已切到 `/ai/intake` |
| 追问页 | `/intake/:id` 页面或 provider/service 变化 | 高 | 继续补充、强制结束、恢复 `awaiting_user_input`、恢复 `questioning` | 有 | `intake_page_test.dart` |
| 未完成追问列表 | `/records` 顶部分区或 session 查询变化 | 高 | 多会话排序、正式记录区不混入未完成 session | 有 | `health_record_list_page_test.dart` |
| 正式记录详情 | 详情页字段、重新追问入口变化 | 高 | `actionAdvice` 展示、空状态、已关联 session 才显示入口 | 有 | `health_record_detail_page_test.dart` |
| `/ai/intake` 契约 | 请求体、响应解析、异常映射变化 | 高 | 请求字段、`needs_followup`、`final`、invalid payload | 有 | `remote_ai_services_test.dart` |
| `/ai/extract` 兼容回归 | 摘要处理或异常映射变化 | 高 | 不再首句 fallback；空字符串保留；缺字段才 invalid | 有 | `remote_ai_services_test.dart` |
| 设置存储 | `app_settings` 表或仓库逻辑变化 | 中 | typed key-value、默认值、约束 | 有 | `intake_service_test.dart` |
| 会话数据与附件暂存 | `intake_*` 表、附件存储逻辑变化 | 高 | 会话落库、顺序、附件转正、回填 `healthEventId` | 有 | `intake_service_test.dart` |
| 重新追问更新原记录 | finalize/update 逻辑变化 | 高 | 更新原 `health_event`，不新建重复记录 | 有 | `intake_service_test.dart` |
| 报告生成 | 报告查询或契约变化 | 高 | 报告只基于正式记录，不带入未完成 session | 有 | 数据与 remote 测试覆盖 |
| 数据库迁移 | `schemaVersion` 或迁移逻辑变化 | 高 | 老库升级到 schema 5 | 有 | `app_database_test.dart` |
| 真实 AI 与演示链路 | 网络层、环境变量、真实 worker 行为变化 | 高 | 真实接口与手工 smoke | 部分 | 需要额外执行 |
