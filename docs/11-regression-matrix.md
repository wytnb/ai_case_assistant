# 回归矩阵

| 功能/模块 | 改动触发条件 | 风险等级 | 必测场景 | 可选场景 | 自动化情况 | 备注 |
|---|---|---|---|---|---|---|
| 首页与主路由 | 调整首页入口、路由路径、导航文案 | 中 | 首页可打开，三个主入口可点击 | 导航返回路径 | 部分自动化 | `test/widget_test.dart` 仅覆盖首页入口 |
| 新增健康记录 | 修改表单、提取前后逻辑、保存流程 | 高 | `rawText.trim()` 必填、1000 字边界、1001 字阻止提交、成功后返回列表 | 保存失败提示 | 部分自动化 | 已有 `create_health_record_page_test.dart` 和 `app_database_test.dart` |
| 附件本地保存 | 修改图片选择、复制路径、回滚逻辑 | 高 | 图片复制成功后详情可回显 | 复制失败回滚 | 仅手工 | 当前没有附件存储自动化测试 |
| 健康记录列表 / 详情 | 修改查询、排序、展示字段 | 高 | 列表按 `createdAt` 倒序、详情展示单一 `事件时间`、备注空值降级 | 图片加载失败降级 | 部分自动化 | 列表与详情页 widget 测试已覆盖单一时间口径 |
| `/ai/extract` 契约 | 修改请求体、响应校验、异常映射 | 高 | 发送 `rawText` 与 `eventTime`、`eventTime` 为不带毫秒的 `+08:00` 格式、超 1000 字拒绝、解析合法响应 | `symptomSummary` 回退逻辑 | 有自动化 | `remote_ai_services_test.dart` |
| `/ai/report` 契约 | 修改请求体、返回字段、异常映射 | 高 | 发送单一 `eventTime`，不再发送 `eventStartTime` / `eventEndTime`，解析合法响应 | 空事件列表行为 | 有自动化 | 空事件列表上游语义待确认 |
| 数据库迁移 | 修改 schemaVersion、迁移逻辑 | 高 | schema 2 的 `event_time` 升级到 `createdAt`、schema 3 删除旧时间列 | 大量旧数据迁移 | 有自动化 | `app_database_test.dart` |
| 报告生成与覆盖 | 修改范围计算、去重、落库 | 高 | 7 / 30 / 90 天范围、同范围覆盖更新 | 重复报告清理 | 部分自动化 | 去重逻辑暂无独立测试 |
| 报告详情 | 修改 `adviceJson` 解析或 Markdown 展示 | 中 | 建议列表正常展示、解析失败降级 | 长 Markdown 可读性 | 仅手工 | 详情页暂无自动化 |
| 文档 / 规则脚本 | 修改 AGENTS、docs-policy、同步脚本 | 中 | 文档路径被脚本识别，旧路径不残留 | `.cursor` 规则同步 | 仅手工 | 需运行 `scripts/check_doc_sync.py` |
