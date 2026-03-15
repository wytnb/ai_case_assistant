# 架构说明与阶段性取舍

## 文档目的

本文件记录当前架构选择背后的原因、已知限制、可接受的技术债和未来可能调整的点。
本文件不替代架构事实文档。

## 为什么采用当前技术栈

### Flutter

当前目标是尽快做出 Android 真机可演示成品，同时保留未来跨平台潜力。
Flutter 适合单代码仓快速交付移动端 MVP。

### Riverpod

需要一个同时承担依赖注入、异步状态管理和页面交互状态组织的统一方案。
当前列表查询、详情查询、提交态和生成态都已通过 Riverpod 落地。

### go_router

当前项目已有首页、记录列表、记录详情、新增记录、报告列表和报告详情等多页面场景。
go_router 让这些入口统一收口在一个路由文件内，便于持续扩展。

### Dio

AI 提取和 AI 报告都已经接入真实 HTTP 调用，需要统一超时、错误映射和基础请求配置。

### Drift

当前数据以健康记录、附件、报告三类结构化对象为主，存在时间排序、范围查询和覆盖更新需求。
Drift 比简单 key-value 更适合当前实现。

## 为什么当前没有补齐完整分层

### 先跑通真实闭环

项目已经从“工程骨架”进入“有真实数据流的 MVP”。
当前最重要的是让新增记录、附件复制、AI 提取、列表详情、报告生成这些真实流程可演示、可保存、可回显。

### 控制抽象数量

`health_record` 和 `report` 当前都只有少量页面和少量用例。
在这个阶段，直接在 Provider 文件中承接薄服务层，可以减少样板代码和维护成本。

### 让 AI 模块先形成明确边界

当前 AI 能力最容易出现超时、异常、返回格式波动等问题，因此先把 AI 的接口、异常和 remote 实现在独立模块中收口。

## 当前已知限制

1. `health_record` 和 `report` 还没有 repository / use case 分层。
2. Drift 生成的 `HealthEvent`、`Attachment`、`Report` DataClass 当前会直接被页面消费。
3. 首页仍是静态入口页，没有承载真实数据摘要。
4. `HealthEvent.sourceType` 当前统一写为 `text`，尚未区分 `mixed`。
5. 报告详情页当前把 Markdown 当普通文本显示。
6. 报告网络日志当前使用 `debugPrint`，没有统一日志基础设施。
7. 当前测试覆盖较少，只保留首页 widget smoke test。

## 技术债说明

1. `health_record_providers.dart` 同时承载了 Provider 定义、服务类和创建控制器，后续复杂度上升时应继续拆分。
2. `report_providers.dart` 中的 `GenerateWeeklyReportController` 名称已不完全准确，因为它已经支持三种报告类型。
3. `AppDatabase` 目前直接暴露较多 feature 级查询方法，后续若场景增多，可以再收敛到更清晰的 feature 数据访问边界。
4. 报告详情的 Markdown 若要继续增强，需要后续引入专门渲染方案。

## 阶段性妥协说明

1. 当前只把 AI 模块做成相对清晰的 `domain + data + provider` 结构。
2. 健康记录和报告模块先采用“页面 -> Provider / Service -> Database / AI Service”的薄路径。
3. 当前允许数据库生成对象直接进入页面展示，只要字段含义清晰、没有越层调用即可。
4. 当前只为 AI 提取保留 mock 开关，以便在代理服务不可用时仍能演示新增记录流程。

## 后续可能的演进方向

1. 当记录和报告逻辑继续增长时，为 `health_record`、`report` 拆出独立 service / repository / use case。
2. 为记录详情和报告详情补更贴近展示层的 ViewModel。
3. 收敛统一日志方案，替换零散的 `debugPrint` 调试日志。
4. 引入 FollowupSession、ExtractResult 等更完整的数据结构时，再补更细的 AI 工作流分层。
5. 当首页承担更多真实信息后，再决定是否引入跨 feature 的共享组件层。

## 未来可能调整的点

- `sourceType` 的字段口径和对应页面展示
- Provider 文件与服务类的拆分方式
- AppDatabase 中查询方法的归属
- 报告 Markdown 的展示方式
- AI 代理部署平台与环境配置入口