# 系统架构

## 架构目标

- 以 Flutter 客户端为中心，尽快交付可演示的本地优先 MVP
- 把页面、AI 调用、本地数据库和附件存储的边界保持清晰
- 在不过度引入样板抽象的前提下，保留后续拆分空间

## 模块划分

| 模块 | 职责 | 输入 | 输出 | 依赖 |
|---|---|---|---|---|
| `app` | 应用装配、主题、路由、首页 | 路由状态、Provider | 页面入口 | `features`, `core` |
| `core/config` | 读取 dart-define | 编译期变量 | 配置常量 | 无 |
| `core/network` | 创建 Dio | `AppConfig` | `Dio` 实例 | `dio` |
| `core/database` | Drift 数据库与查询方法 | 表定义、查询参数 | DataClass / 持久化操作 | `drift`, feature 表 |
| `features/ai` | AI 接口、异常、mock / remote 实现 | 原始文本、报告事件 | 提取结果、报告结果 | `core/network` |
| `features/health_record` | 记录创建、列表、详情、附件复制 | 表单输入、图片路径 | 健康记录与附件 | `core/database`, `features/ai` |
| `features/report` | 报告生成、列表、详情 | 报告类型、范围内记录 | 报告落库与展示 | `core/database`, `features/ai` |

## 依赖关系

- `app` -> `core` / `features`
- `features/*/presentation/pages` -> `features/*/presentation/providers`
- `features/health_record/presentation/providers` -> `core/database`, `features/ai`, 本 feature 本地存储
- `features/report/presentation/providers` -> `core/database`, `features/ai`
- `features/ai/presentation/providers` -> `features/ai/data`, `core/network`
- `core/database` -> feature 内的 Drift 表定义

当前明确不做的依赖方向：

- 页面直接调用 Dio
- 页面直接读写 Drift / SQLite
- 页面直接拼装文件路径或复制附件
- 页面直接处理原始 HTTP payload

## 关键时序

### 记录创建时序

1. 页面触发 `CreateHealthRecordController`
2. `HealthRecordService` 调用 `AiExtractService`
3. 提取结果通过校验后写入 `health_events`
4. 选择了图片时复制文件并写入 `attachments`
5. Controller 刷新列表和详情 Provider

### 报告生成时序

1. 页面触发 `GenerateWeeklyReportController.generateReport`
2. `ReportService` 计算时间范围并查询 `health_events`
3. 将记录映射为 `AiReportEvent`
4. 调用 `AiReportService.generateReport`
5. 覆盖写入或新建 `reports`
6. Controller 刷新列表和详情 Provider

## 外部依赖

- Flutter / Material 3
- Riverpod
- go_router
- Dio
- Drift / SQLite
- image_picker
- path_provider / path
- 外部 AI 代理接口

## 当前工程组织约定

这是从当前代码结构中抽出的事实，而不是未来设计图：

- 页面文件使用 `*_page.dart`
- Provider 文件使用 `*_provider.dart` 或 `*_providers.dart`
- Drift 表定义放在 `data/local/tables/`
- AI 接口和值对象集中在 `features/ai/`
- 当前允许 `health_record` 与 `report` 通过 Provider 文件中的轻服务类承接编排逻辑
- 当前允许页面直接消费 Drift 生成的 DataClass 作为读取结果

## 技术约束

- 当前仓库是本地优先架构，主数据承载是 Drift 与本地文件系统
- 当前 AI 能力通过 `AI_API_BASE_URL` 指向的代理服务提供，不直连模型供应商 SDK
- 当前只有提取链路支持 mock 开关，报告链路没有 mock 服务
- `freezed` / `json_serializable` 已声明依赖，但当前业务代码未实际采用
- 报告详情保留 Markdown 原文，没有富渲染

## 空目录与占位事实

仓库中存在以下空目录或仅目录占位，它们不是“已实现功能”的证据：

- `lib/shared/`
- `lib/app/bootstrap`
- `lib/app/theme`
- `lib/core/constants`
- `lib/core/error`
- `lib/core/storage`
- `lib/core/utils`
- `lib/features/settings/`
- `lib/features/health_record/domain/`
- `lib/features/health_record/data/datasources`
- `lib/features/health_record/data/models`
- `lib/features/health_record/data/repositories`
- `lib/features/report/domain/`

文档在描述这些目录时必须写成“目录存在但当前没有实现文件”。

## 风险与取舍

- 记录与报告的业务编排目前集中在 Provider / 轻服务层，文件复杂度后续可能继续上升
- 数据库查询方法集中在 `AppDatabase`，后续若场景增加可能需要更明确的 feature 数据访问边界
- Android / iOS / macOS / Web 仍保留默认应用标识或描述，占位信息未产品化
- 当前没有 CI、没有统一日志平台，验证主要依赖本地命令与手工演示
- 本地 FVM 命令会出现 `Invalid SDK hash` 警告，虽不阻塞 `analyze` 与 `test`，但仍是工具链待确认问题

