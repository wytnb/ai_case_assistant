# 测试策略

## 测试目标

- 确认记录创建、报告生成和本地回显三条主链路在当前 MVP 下稳定可演示
- 在 AI 契约、数据库迁移、列表/详情展示等高风险边界上保留自动化保护
- 明确哪些能力已有自动化，哪些仍依赖真实接口验证或手工 smoke
- 明确涉及 AI 契约、关键页面、环境变量时何时必须评估真实接口验证或手工 smoke

## 测试分层

- Widget
  - 首页入口显示
  - 新增记录页表单校验、1000 字边界与提交行为
  - 健康记录列表页单一时间展示
  - 健康记录详情页事件时间、备注与空状态展示
- Unit / Service
  - `MockAiExtractService`
  - `RemoteAiExtractService`
  - `RemoteAiReportService`
- Database / Integration-like
  - `AppDatabase` 读写、排序、范围过滤
  - `HealthRecordService.createHealthRecord`
  - Drift 迁移从 `event_time` 或 `event_start_time` / `event_end_time` 到 schema 4
- Manual integration
  - `test/features/ai/real_ai_api_test.dart`
  - 真实 AI 接口测试默认跳过，需要显式开启；mock 验证通过后必须立即执行一次
- E2E
  - 当前没有独立 E2E 测试

## 当前已有自动化

| 测试文件 | 当前覆盖点 | 类型 |
|---|---|---|
| `test/widget_test.dart` | 首页标题与三个入口 | Widget |
| `test/core/database/app_database_test.dart` | 创建记录、`notes` 空值、1000 字防御、按 `createdAt` 排序、报告筛选、schema 2/3 迁移到 schema 4 | Database / Service |
| `test/features/ai/data/mock_ai_extract_service_test.dart` | mock 提取摘要与 `notes` 语义 | Unit |
| `test/features/ai/data/remote_ai_services_test.dart` | `/ai/extract` 与 `/ai/report` 的 payload、响应解析、`eventTime` 序列化 | Unit |
| `test/features/health_record/presentation/create_health_record_page_test.dart` | 1000 字内提交、1000 字边界、1001 字报错 | Widget |
| `test/features/health_record/presentation/health_record_list_page_test.dart` | 列表页单一事件时间展示 | Widget |
| `test/features/health_record/presentation/health_record_detail_page_test.dart` | 详情页事件时间、备注与空状态 | Widget |
| `test/features/ai/real_ai_api_test.dart` | 真实 AI 集成验证 | Manual integration |

当前执行结果基于 2026-03-18 的本地验证：

- `fvm flutter test`：22 个测试通过，8 个真实 AI 集成测试默认跳过
- `fvm flutter analyze`：需在本次任务末重新执行确认

## 覆盖要求

### 当前必须守住的高价值覆盖点

- `/ai/extract` 请求必须发送 `rawText` 与不带毫秒、带 `+08:00` 的 `eventTime`
- `rawText.trim()` 为空或超过 1000 字时，前端与服务层都必须拒绝
- 创建记录时，同一个 `eventTime` 必须同时写入 `createdAt` / `updatedAt`
- 列表排序、详情展示、报告范围筛选都必须基于 `createdAt`
- `/ai/report` 请求必须发送单一 `eventTime`，不再发送 `eventStartTime` / `eventEndTime`
- Drift 迁移必须覆盖 schema 2 -> 4 与 schema 3 -> 4

### 建议后续补充

- 附件复制成功 / 回滚删除
- 报告列表与报告详情页
- 报告覆盖更新与重复记录清理
- 首页到主链路页面的导航交互

## 边界测试要求

- 空值 / `null`
  - `notes` 缺失
  - `symptomSummary` 缺失
  - 空 `events` 列表生成报告
- 边界值
  - `rawText.trim().length == 1000`
  - 报告范围边界为当天起止时间
- 非法输入
  - `/ai/extract` 缺失 `eventTime`
  - `/ai/extract` 的 `rawText` 超过 1000 字
  - `/ai/report` 非法 payload
- 状态切换
  - 提交中按钮禁用
  - 列表加载失败后的重试
  - 详情缺失对象时的说明态

## 回归测试要求

- bug fix 需要补回归测试或更新已有测试
- 契约变化需要更新对应单元 / 集成测试
- 高风险变更需要同步更新 `docs/11-regression-matrix.md`
- 发布影响变更需要复核 `docs/12-release-smoke-checklist.md`

## 真实接口 / 线上验证触发条件

当前仓库里，“线上验证”主要指两类：

- 真实 AI 接口验证
- 在真实设备或模拟器上的手工 smoke
  - Android 真机为主；若真机依赖 Clash 等代理访问真实 AI，上述代理应保留
  - 真机在保留代理的前提下仍无法跑通时，可补 Web Chrome 备用 smoke，但它不能替代 Android 专属验证

以下情况通常只需本地测试：

- 纯文档改动
- 纯静态文案改动
- 与 AI、网络、环境变量、关键页面主链路无关的局部实现修正

以下情况必须额外评估并在可行时执行真实 AI 接口验证：

- `/ai/extract` 或 `/ai/report` 请求体变化
- 响应解析、错误映射、超时或重试逻辑变化
- `features/ai/`、`core/network/`、`core/config/` 行为变化
- `AI_API_BASE_URL`、`RUN_REAL_AI_API_TESTS`、`USE_MOCK_AI_EXTRACT` 相关行为变化

以下情况必须额外评估并在可行时执行手工 smoke：

- 首页主入口变化
- 新增记录页、记录详情页、报告列表页、报告详情页的交互变化
- 附件选择、附件回显、报告生成等主链路变化
- 发布或演示步骤变化

如果真实接口验证或手工 smoke 未执行，最终汇报必须写明：

- 未执行的验证类型
- 未执行原因
- 剩余风险

## 当前无法自动化验证项

- 附件选择到系统相册的完整真机交互
- 真实 AI 代理在不同网络状态下的稳定性
- 应用安装包的真实发布流程
- 多平台打包后的产物可用性

## 允许跳过条件

- 本次任务是纯文档任务，且未改动任何真实运行路径
- 任务所需的真实 AI 代理不可用，无法完成真实接口验证
- 任务不触达关键页面主链路，不需要额外手工 smoke

即使允许跳过，也必须在最终汇报中说明原因。

## 测试数据策略

- 单元与数据库测试优先使用内存数据库、固定时间戳和假服务
- 真实 AI 测试只记录实际请求 / 响应，不依赖仓库内固定快照
- 当前仓库中没有单独 fixtures 目录

## 通过标准

- 必须通过的命令
  - `fvm flutter analyze`
  - `fvm flutter test`
- 视变更类型追加的验证
  - 真实 AI 接口测试
  - 关键页面手工 smoke
- 可接受的当前例外
  - 真实 AI 集成测试默认跳过，只有显式传入 `RUN_REAL_AI_API_TESTS=true` 才运行
  - 当前默认真实验证地址为 `https://ai-api-worker.wytai.workers.dev`
  - FVM 命令末尾会输出 `Invalid SDK hash` 警告，但当前不阻塞分析与测试完成
