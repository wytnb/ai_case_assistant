# 测试策略

## 测试目标

- 确认记录创建、报告生成和本地回显三条主链路在当前 MVP 下稳定可演示
- 在 AI 契约、数据库迁移、详情展示等高风险边界上保留自动化保护
- 明确哪些能力已有自动化、哪些仍依赖手工验证
- 明确什么情况下只需本地测试，什么情况下必须额外做真实接口或手工 smoke

## 测试分层

- Widget
  - 首页入口展示
  - 健康记录详情页备注与空状态展示

- Unit / Service
  - `MockAiExtractService`
  - `RemoteAiExtractService`
  - `RemoteAiReportService`

- Database / Integration-like
  - `AppDatabase` 读写、排序、范围过滤
  - `HealthRecordService.createHealthRecord`
  - Drift 迁移从 `event_time` 到 `eventStartTime` / `eventEndTime`

- Manual integration
  - `test/features/ai/real_ai_api_test.dart`
  - 真实 AI 接口测试默认跳过，需要显式开启

- E2E
  - 当前没有独立 E2E 测试

## 当前已有自动化

| 测试文件 | 当前覆盖点 | 类型 |
|---|---|---|
| `test/widget_test.dart` | 首页标题与三个入口 | Widget |
| `test/core/database/app_database_test.dart` | 创建记录、`notes` 空值、排序、报告筛选、迁移 | Database / Service |
| `test/features/ai/data/mock_ai_extract_service_test.dart` | mock 提取的 `notes` 空值语义 | Unit |
| `test/features/ai/data/remote_ai_services_test.dart` | 提取与报告 payload / 响应解析 | Unit |
| `test/features/health_record/presentation/health_record_detail_page_test.dart` | 详情页备注展示与空状态 | Widget |
| `test/features/ai/real_ai_api_test.dart` | 真实 AI 集成验证 | Manual integration |

当前执行结果基于 2026-03-17 的本地验证：

- `fvm flutter test`：15 个测试通过，8 个真实 AI 集成测试默认跳过
- `fvm flutter analyze`：通过

## 覆盖要求

### 当前必须守住的高价值覆盖点

- AI 提取返回时间字段的合法性
- 记录创建时 `notes` 的空值语义
- 记录列表排序和报告范围筛选
- 旧数据库向 schema 3 的迁移
- 报告请求发送 `eventStartTime` / `eventEndTime` 而非旧 `eventTime`

### 建议后续补充

- 新增记录页面的表单交互与错误提示
- 附件复制成功 / 回滚删除
- 报告列表和报告详情页面
- 报告覆盖更新与重复记录清理
- 首页到主链路页面的导航交互

## 边界测试要求

- 空值 / `null`
  - `notes` 缺失
  - `symptomSummary` 缺失
  - 空 `events` 列表生成报告

- 边界值
  - `eventStartTime == eventEndTime`
  - 报告范围边界为当天起止时间
  - 长文本 `rawText` 截断到 500 字符

- 非法输入
  - `/ai/extract` 缺失时间字段
  - `/ai/extract` 返回反向时间区间
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

当前仓库里，“线上测试”主要指两类：

- 真实 AI 接口验证
- 在真实设备或模拟器上的手工 smoke

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
  - FVM 命令尾部会出现 `Invalid SDK hash` 警告，但当前不阻塞分析与测试完成
