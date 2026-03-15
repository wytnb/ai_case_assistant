# 工程与编码规范

## 文档目的

本文件统一代码风格、命名风格、工程组织方式和常见实现习惯。
本文件回答“代码应该怎么写、怎么放、怎么保持一致”，不定义产品规则和字段业务事实。

## 命名规范

### 总体规则

1. 文件名、目录名使用 `snake_case`。
2. Dart 类型名使用 `PascalCase`。
3. 变量、方法、Provider 名称使用 `camelCase`。
4. 布尔变量优先使用 `is`、`has`、`can`、`should` 前缀。
5. 命名必须体现业务语义，不使用 `data1`、`temp`、`helper`、`manager` 之类模糊名称，除非其职责本来就是通用工具。

## 文件命名规则

- 页面：`xxx_page.dart`
- Provider 文件：`xxx_providers.dart` 或 `xxx_provider.dart`
- 本地表：放在 `data/local/tables/`，文件名使用业务复数，例如 `health_events.dart`
- 本地存储辅助：`xxx_storage.dart`
- AI 远程服务：`remote_xxx_service.dart`
- AI mock 服务：`mock_xxx_service.dart`
- 异常：`xxx_exception.dart`
- Route 文件：`app_router.dart`

## 目录命名规则

- feature 名称使用业务语义，例如 `health_record`、`report`、`ai`
- 当前没有 `settings` 与 `shared` 目录，不提前为未来目录做占位说明
- 私有页面组件优先放在本页面文件内或当前 feature 内

## 页面命名方式

- 页面类统一以 `Page` 结尾，例如 `HealthRecordListPage`
- 页面文件对应 `snake_case`，例如 `health_record_list_page.dart`
- 页面内私有组件优先用 `_XxxSection`、`_XxxState`、`_XxxPreview` 表达职责

## Provider 命名方式

- Provider 名称必须体现职责与返回值，例如：
  - `healthRecordListProvider`
  - `healthRecordDetailProvider`
  - `createHealthRecordControllerProvider`
  - `reportListProvider`
- `StateProvider` 可体现“当前选择态”，例如 `selectedReportTypeProvider`
- `AsyncNotifier` 的 Provider 可以使用 `xxxControllerProvider`
- 不使用 `commonProvider`、`globalProvider`、`tempProvider` 之类模糊名称

## 当前阶段的服务类命名方式

当前项目允许在 feature 的 Provider 文件中放置轻量服务类，前提是它只服务当前 feature 的用例编排。

命名规则：

- 使用清晰业务名，例如 `HealthRecordService`、`ReportService`
- 如果类承担提交或按钮状态控制，可使用 `XxxController`
- 不为了形式统一，强行把所有编排类都命名为 repository 或 use case

## 通用代码组织规范

1. 单个文件只承载一个主职责。
2. 页面文件中可以包含少量私有组件。
3. Drift 表定义单独放在 `data/local/tables/`。
4. 应用级数据库连接与查询方法放在 `core/database/`。
5. AI 远程调用放在 `features/ai/data/remote/`。
6. 页面文件中不定义 Dio 请求、附件复制逻辑或数据库 SQL 细节。

## Flutter / Dart 统一风格要求

1. 优先使用不可变对象。
2. 明确区分同步与异步方法；异步方法命名使用动词，不追加 `Async`。
3. 空安全必须完整使用；避免随意使用 `!`。
4. 页面优先拆为：
   - 状态获取
   - 页面骨架
   - 私有组件
5. 业务逻辑不写进 `build()` 中。
6. 列表项、卡片项、表单区块超过一定复杂度时拆成私有组件。
7. 相同文案优先在当前页面内局部收口，而不是散落在多个方法里。

## 当前阶段允许的对象边界

1. AI 模块可使用显式接口和请求 / 响应对象。
2. 健康记录和报告模块当前允许直接使用 Drift 生成的 DataClass 作为列表 / 详情读取结果。
3. 若某个页面只是消费数据库实体并直接展示，可暂不额外创建 VO。
4. 当页面开始出现明显展示拼装或跨对象组合时，再引入专用 ViewModel。

## 错误处理规范

1. 所有远程 AI 调用必须捕获并映射为可识别异常。
2. AI 返回值校验失败不能直接崩溃；必须返回明确失败语义或走兜底逻辑。
3. 数据库读写失败必须向上抛出可处理错误，不吞异常。
4. 页面必须处理至少三类状态：
   - loading
   - success
   - error
5. 重要操作失败时，应给用户可理解的提示文案。

## 日志规范

1. 当前阶段统一避免使用 `print`。
2. 临时调试日志可使用 `debugPrint`，但只出现在关键网络或数据节点。
3. 日志不记录完整敏感原文，不打印完整病例全文或隐私内容。
4. 若日志用于排查，优先记录：
   - 模块
   - 动作
   - 结果
   - 必要时的错误类型或状态码

## 注释规范

1. 优先写“为什么”而不是“这行代码在做什么”。
2. 对公共类、公共方法、复杂错误映射可写简短注释。
3. 注释必须与代码同步更新；失效注释应删除。
4. 不写重复代码字面意思的注释。

## 常见模式的统一写法

### 新增页面

- 放在 `presentation/pages/xxx_page.dart`
- 页面通过 Provider 获取状态，不直接 new `Dio`、`AppDatabase` 或存储类
- 页面内的小型 UI 片段优先做私有组件

### 新增本地表

- 放在 `data/local/tables/`
- 表名使用清晰业务语义
- 主键继续沿用字符串 UUID

### 新增本地文件存储辅助

- 放在 `data/local/`
- 方法名描述业务动作，例如 `saveImageAttachment`
- 路径拼接和文件复制逻辑不进入页面层

### 新增远程 AI 调用

- 接口和值对象优先放在 `features/ai/domain/`
- 远程实现放在 `features/ai/data/remote/`
- Provider 装配放在 `features/ai/presentation/providers/`
- 页面不直接接触 Dio response

### 新增 feature 级服务类

- 优先放在当前 feature 的 `presentation/providers/`，前提是它主要服务页面编排
- 如果同一模块出现多个页面共用、对象转换增多、流程明显变复杂，再考虑独立拆分

## 允许的实现方式

- 使用 Riverpod 管理依赖与状态
- 使用 Drift 管理本地表与查询
- 使用 `debugPrint` 做少量关键调试日志
- 使用局部私有组件保持页面可读性
- 使用 feature 内部薄服务类承接当前 MVP 的业务编排

## 禁止的实现方式

- 页面直接调用 Dio
- 页面直接读写 Drift / SQLite
- 页面直接处理文件路径拼接
- 用 `dynamic` 逃避模型约束
- 用 Map 在多层之间长期传递业务对象
- 把“未来可能要用”的 repository / use case 抽象提前铺满整个项目
- 把 DTO 当作页面展示对象长期传递而不做最小语义约束