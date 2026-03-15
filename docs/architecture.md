# 当前架构事实

## 文档目的

本文件定义系统当前采用的结构事实，包括技术栈、目录组织、模块职责、路由组织、状态管理和依赖约束。
本文件描述“代码现在是怎么组织的”，而不是解释为什么这样选择。

## 当前实际技术栈

### 运行时与框架

- Flutter
- Dart
- Material 3
- Riverpod
- go_router
- Dio
- Drift
- image_picker
- path_provider
- path
- uuid
- intl

### 代码生成与开发工具

- build_runner
- drift_dev

### 说明

- `freezed` / `json_serializable` 依赖已在工程中引入，但当前业务代码尚未实际使用。
- 当前仓库中没有接入 WorkManager、后台任务框架或独立设置模块。

## 总体架构原则

1. 以客户端为主，AI 服务端为薄代理。
2. 以本地数据库和本地文件存储为主数据承载方式。
3. 以 feature 为第一组织维度。
4. 路由统一收口在 `app/router/`。
5. 页面不直接调用 Dio，不直接读写本地文件。
6. 页面通过 Riverpod Provider 触发服务逻辑、读取异步状态和查询结果。
7. 当前阶段允许部分 feature 采用“Provider + 服务类”的薄分层，而不是一次性补齐 repository / use case / entity 全套抽象。

## 当前目录组织

### app

- `lib/app/app.dart`：`MaterialApp.router` 装配
- `lib/app/router/app_router.dart`：应用路由注册
- `lib/app/presentation/pages/home_page.dart`：首页

### core

- `lib/core/config/`：应用级配置，例如 dart-define 开关
- `lib/core/network/`：Dio Provider
- `lib/core/database/`：Drift 数据库入口、表注册、数据库方法、数据库 Provider

### features/ai

- `data/remote/`：远程 AI 服务实现
- `data/mock/`：本地 mock 提取服务
- `domain/services/`：AI 服务接口与当前请求 / 响应对象
- `domain/exceptions/`：AI 异常类型
- `presentation/providers/`：AI 服务 Provider 装配

### features/health_record

- `data/local/tables/`：健康记录与附件表定义
- `data/local/health_record_attachment_storage.dart`：附件复制与清理
- `presentation/providers/health_record_providers.dart`：列表、详情、附件、创建控制器和记录服务
- `presentation/pages/`：新增、列表、详情页面

### features/report

- `data/local/tables/`：报告表定义
- `presentation/providers/report_providers.dart`：报告筛选状态、列表、详情、生成控制器和报告服务
- `presentation/pages/`：报告列表、报告详情页面

## 当前分层边界

### 页面层

职责：

- 展示 UI
- 处理用户交互
- 订阅 Riverpod 状态
- 调用 Provider 暴露出的控制器或服务入口

禁止：

- 直接调用 Dio
- 直接复制或删除本地附件文件
- 直接拼装 AI 请求 JSON

### Provider / Feature Service 层

当前 `health_record` 和 `report` 采用这一层承接页面编排。

职责：

- 装配依赖
- 管理页面所需异步状态
- 调用数据库方法、AI 服务、附件存储
- 组织保存、查询、生成等用例流程

当前实现位置：

- `health_record/presentation/providers/health_record_providers.dart`
- `report/presentation/providers/report_providers.dart`

### Data 层

职责：

- Drift 表定义
- 本地文件存储实现
- 远程 AI 服务实现
- 数据库入口和数据库查询方法

### AI Domain 层

当前只在 AI 模块中显式存在。

职责：

- AI 提取与报告服务接口
- AI 请求 / 响应值对象
- AI 异常类型

## 当前模块职责

### app

- 启动应用
- 提供主题
- 注册路由

### core

- 提供 Dio
- 提供 Drift 数据库连接
- 汇总各 feature 的表注册和数据库方法

### features/ai

- 对外暴露 AI 提取与报告服务接口
- 封装远程请求、错误映射和返回值校验
- 提供 mock 提取实现切换

### features/health_record

- 创建健康记录
- 保存 AI 提取后的摘要与备注
- 复制图片附件到应用私有目录
- 查询记录列表、详情和附件

### features/report

- 读取指定时间范围内的健康记录
- 调用 AI 报告接口
- 将报告落库并处理同范围覆盖更新
- 展示报告列表和详情

## 路由组织事实

当前集中在 `lib/app/router/app_router.dart`：

- `/`：首页
- `/records`：健康记录列表
- `/records/new`：新增记录
- `/records/:id`：记录详情
- `/reports`：报告列表
- `/reports/:id`：报告详情

当前没有设置页、追问页、编辑页等额外路由。

## 状态管理事实

1. 使用 Riverpod 统一做依赖注入和页面异步状态。
2. 记录列表、详情、附件列表、报告列表、报告详情使用 `FutureProvider`。
3. 新增记录和生成报告使用 `AutoDisposeAsyncNotifierProvider`。
4. 报告类型切换使用 `StateProvider`。
5. 页面不直接持有 Dio 或 `AppDatabase` 实例。

## 当前数据承载边界

### 本地数据库

`AppDatabase` 当前注册了三张表：

- `health_events`
- `attachments`
- `reports`

数据库方法集中在 `lib/core/database/app_database.dart` 中，包括：

- 记录列表 / 详情查询
- 按时间范围查询记录
- 插入记录
- 插入附件
- 查询附件
- 插入报告
- 更新报告
- 查询报告
- 删除重复报告

### 本地文件系统

- 附件复制到应用 documents 目录下的 `health_records/<healthEventId>/attachments/`
- 当前仅处理图片附件
- 数据库存储的是复制后的目标文件路径

### 网络与 AI 代理

- `POST /ai/extract`：新增记录时调用
- `POST /ai/report`：生成报告时调用
- 当前不直连模型供应商接口，不在页面层处理原始 HTTP 响应

## 当前依赖方向约束

### 允许的依赖方向

- `app` → `core` / `features`
- `features/*/presentation/pages` → `features/*/presentation/providers`
- `features/*/presentation/providers` → `core` / `features/ai` / 本 feature 的 `data`
- `features/ai/presentation/providers` → `features/ai/data` / `core/network`
- `core/database` → feature 的 Drift 表定义

### 当前明确不做的依赖方向

- 页面 → Dio
- 页面 → 本地文件系统
- 页面 → Drift 表查询
- `core` → feature 页面

## 当前未落地的结构

以下结构不属于当前实现事实，不应写成“已存在”：

- `shared/` 公共 UI 层
- `features/settings`
- 健康记录或报告的 repository 接口与实现
- 健康记录或报告的独立 use case 层
- FollowupSession / ExtractResult 对应的数据表与页面