# 测试策略

## 测试目标

- 让 monorepo 改动默认先停留在本地快速验证层。
- 保障 `/ai/intake` 与 `/ai/report` 的请求体、响应解析与错误映射稳定。
- 保障 app、gateway、文档、共享契约不会再次漂移。
- 明确哪些验证可跳过，以及跳过后最终汇报必须写出的剩余风险。

## 当前自动化覆盖

### app 侧

| 测试文件 | 当前覆盖点 |
|---|---|
| `apps/ai_case_assistant/test/widget_test.dart` | 首页主入口与追问模式开关存在 |
| `apps/ai_case_assistant/test/app/presentation/home_page_test.dart` | 首页首次免责弹窗、同意放行、追问模式开关持久化 |
| `apps/ai_case_assistant/test/features/health_record/presentation/create_health_record_page_test.dart` | 新增记录页提交、路由与错误边界 |
| `apps/ai_case_assistant/test/features/health_record/presentation/health_record_list_page_test.dart` | 双 tab、日期范围筛选、删除后列表更新 |
| `apps/ai_case_assistant/test/features/health_record/presentation/health_record_detail_page_test.dart` | `actionAdvice`、空状态、删除入口与“追加补充”按钮 |
| `apps/ai_case_assistant/test/features/intake/intake_service_test.dart` | 会话、正式记录更新、报告隔离、附件转正 |
| `apps/ai_case_assistant/test/features/ai/data/remote_ai_services_test.dart` | `/ai/intake`、`/ai/report` 契约解析 |
| `apps/ai_case_assistant/test/features/ai/real_ai_api_test.dart` | 显式开启的真实 AI 集成测试 |
| `apps/ai_case_assistant/test/core/database/app_database_test.dart` | 数据库与迁移基础覆盖 |

### workspace / gateway 侧

| 检查或测试 | 当前覆盖点 |
|---|---|
| `python scripts/check_doc_sync.py --working-tree --no-strict` | 文档同步提醒 |
| `python scripts/verify/check_ai_contract_sync.py` | 共享契约、app/gateway 路由与关键文档一致性 |
| `cd services/ai_gateway && npm test` | gateway 路由、提示词、输入校验、retired `/ai/extract` `404` |

## 测试分层

### 第一层：workspace 一致性检查

默认命令：

- `python scripts/check_doc_sync.py --working-tree --no-strict`
- `python scripts/verify/check_ai_contract_sync.py`

适用场景：

- monorepo 结构、文档、规则、共享契约变化

### 第二层：app 默认快速验证

默认必须执行：

- `cd apps/ai_case_assistant && fvm flutter analyze`
- `cd apps/ai_case_assistant && fvm flutter test`

### 第三层：真实 AI 自动化

显式开启项：

- `cd apps/ai_case_assistant && fvm flutter test test/features/ai/real_ai_api_test.dart --dart-define=RUN_REAL_AI_API_TESTS=true --dart-define=AI_API_BASE_URL=<gateway-url>`

默认不跑，但在以下情况必须评估并在可行时执行：

- `/ai/intake` 或 `/ai/report` 请求体 / 响应解析变化
- `features/intake/`、`features/ai/`、`core/network/`、`core/config/` 变化

### 第四层：gateway 自动化 / live / 线上 smoke

只在改动触发 gateway 运行时闭环时执行。规则见 `services/ai_gateway/docs/10-testing-strategy.md`。

## 回归重点

- `/ai/intake` 请求体必须完整并使用完整消息历史
- `symptomSummary` 的“字符串即保留”规则不能回退
- 强制结束与重新追问不能产生重复正式记录
- 未完成追问不能进入正式记录列表或报告
- 正式记录软删除后不能继续参与列表、详情、报告输入或继续补充入口
- 草稿硬删除后不能残留 session / message / intake attachment 行
- `contracts/health-record-ai.openapi.json` 与 app / gateway / 文档必须一致

## 可跳过条件

以下情况允许停在第一层或第二层，不再追加更重验证：

- 纯文档、纯文案改动
- 小范围非主链路改动，且不触发真实 AI 或 gateway 运行时闭环

以下情况允许跳过真实 AI 自动化或服务侧 live / deploy，但必须在最终汇报写清楚：

- 当前机器没有可用凭据
- 当前网络或上游服务不可用
- 当前任务未触发对应闭环

## 通过标准

默认通过标准：

- 根目录一致性检查通过
- `cd apps/ai_case_assistant && fvm flutter analyze`
- `cd apps/ai_case_assistant && fvm flutter test`

按变更类型追加：

- app 真实 AI 自动化
- `cd services/ai_gateway && npm test`
- `cd services/ai_gateway && npm run test:live`
- `cd services/ai_gateway && npm run deploy`
- 线上 smoke
