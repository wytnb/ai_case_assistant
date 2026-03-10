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
5. 命名必须体现业务语义，不使用 `data1`、`temp`、`helper`、`manager` 之类模糊名称，除非其职责本来就是通用管理器。

## 文件命名规则

- 页面：`xxx_page.dart`
- 组件：`xxx_widget.dart` 或按具体职责命名，例如 `health_record_card.dart`
- Provider：`xxx_provider.dart`
- Repository 接口：`xxx_repository.dart`
- Repository 实现：`xxx_repository_impl.dart`
- DTO：`xxx_dto.dart`
- Entity：`xxx_entity.dart`
- VO：`xxx_vo.dart`
- Mapper：`xxx_mapper.dart`
- Service：`xxx_service.dart`
- Data source：`xxx_local_data_source.dart`、`xxx_remote_data_source.dart`
- Use case：`xxx_use_case.dart`
- Route 常量：`xxx_routes.dart` 或 `app_routes.dart`

## 目录命名规则

- feature 名称使用业务语义，例如 `health_record`、`report`、`settings`
- 不使用 `common_feature`、`misc`、`temp`、`helpers` 这类含义模糊目录
- 私有页面组件优先放在本 feature 内，不提前放入 `shared`

## 页面命名方式

- 页面类统一以 `Page` 结尾，例如 `HealthRecordListPage`
- 页面文件对应 `snake_case`，例如 `health_record_list_page.dart`
- 页面内私有组件优先用 `_XxxSection`、`_XxxCard` 表达职责

## Provider 命名方式

- Provider 名称必须体现职责与返回值，例如：
  - `healthRecordRepositoryProvider`
  - `healthRecordDetailProvider`
  - `createHealthRecordUseCaseProvider`
- 不使用 `commonProvider`、`globalProvider`、`tempProvider` 之类模糊名称
- 异步状态 Provider 若为 `FutureProvider` / `AsyncNotifierProvider`，命名仍使用业务语义，不在名称里强调类型

## Repository / DTO / Entity / VO / Mapper / Service 命名方式

### Repository

- 接口：`HealthRecordRepository`
- 实现：`HealthRecordRepositoryImpl`

### DTO

- 面向序列化与传输的对象统一以 `Dto` 结尾
- 例：`HealthEventDto`

### Entity

- 面向领域语义的对象统一以 `Entity` 结尾
- 例：`HealthEventEntity`

### VO

- 面向展示层组合值对象统一以 `Vo` 结尾
- 例：`HealthEventSummaryVo`

### Mapper

- 负责对象转换的类统一以 `Mapper` 结尾
- 例：`HealthEventMapper`

### Service

- 仅用于承载明确基础能力或外部能力调用
- 例：`AiProxyService`
- 不使用 `Service` 代替 Repository 或 Use case

## 通用代码组织规范

1. 单个文件只承载一个主职责。
2. 一个页面文件中可以包含少量私有组件；跨页面复用后再抽离。
3. DTO、Entity、Mapper 不混写在同一文件。
4. 公共常量集中在 `core/constants/` 或 feature 内局部常量文件。
5. 不在页面文件中定义仓储实现、复杂解析器、数据库访问逻辑。
6. 不将多种不相关 extension 混放在同一文件。

## Flutter / Dart 统一风格要求

1. 优先使用不可变对象。
2. 明确区分同步与异步方法；异步方法命名使用动词，不追加 `Async`。
3. 空安全必须完整使用；避免随意使用 `!`。
4. 页面应优先拆为：
   - 状态获取
   - 页面骨架
   - 分区组件
5. 业务逻辑不写进 `build()` 中。
6. 列表项、卡片项、表单区块超过一定复杂度时拆成私有组件。
7. 字符串文案不在多个文件中复制粘贴；相同文案需局部收口。

## 错误处理规范

1. 所有远程调用必须捕获并映射为统一错误语义。
2. JSON 解析失败不能直接崩溃；必须返回可识别的失败结果。
3. 数据库读写失败必须向上抛出可处理错误，不吞异常。
4. 页面必须处理至少三类状态：
   - loading
   - success
   - error
5. 错误提示优先给用户可理解文案，不直接暴露原始异常堆栈。

## 日志规范

1. 仅在关键节点打日志：
   - AI 请求开始 / 成功 / 失败
   - 数据库写入失败
   - JSON 解析失败
   - 文件保存失败
2. 日志不记录敏感原文全文，尤其是完整病例文本、完整图片路径、完整个人隐私信息。
3. 日志内容应包含：
   - 模块
   - 动作
   - 结果
   - 必要时的错误码或异常类型
4. 不用 `print` 作为正式日志方案；统一走项目日志封装。

## 注释规范

1. 优先写“为什么”而不是“这行代码在做什么”。
2. 对公共类、公共方法、复杂 Mapper、复杂解析逻辑可写简短注释。
3. 注释必须与代码同步更新；失效注释应删除。
4. 不写重复代码字面意思的注释。

## 常见模式的统一写法

### 新增页面

- 放在 `presentation/pages/xxx_page.dart`
- 如有复用组件，则在 `presentation/widgets/` 建立对应组件文件
- 页面通过 Provider 获取状态，不直接 `new RepositoryImpl`

### 新增本地数据源

- 放在 `data/datasources/`
- 对外暴露清晰方法名，例如 `saveHealthEvent`、`getHealthEventById`
- 不在方法名中暴露底层表名或 SQL 细节

### 新增远程 AI 调用

- DTO 放在 `data/models/`
- 远程调用放在 `data/datasources/` 或独立 `service`
- Repository 负责把 DTO 转为 Entity 或可用结果对象
- 页面不直接接触 Dio response

### 新增 Mapper

- 一类对象转换只建一个明确 Mapper
- Mapper 不承担网络、存储、副作用逻辑
- Mapper 方法命名使用 `toEntity`、`toDto`、`toVo`

## 允许的实现方式

- 使用 Riverpod 管理依赖与状态
- 使用 freezed / json_serializable 管理模型代码生成
- 使用统一错误对象向上暴露失败信息
- 使用局部私有组件保持页面可读性
- 使用 DTO → Mapper → Entity 的转换路径

## 禁止的实现方式

- 页面直接调用 Dio
- 页面直接读写 Drift / SQLite
- 页面直接处理文件路径拼接
- 用 `dynamic` 逃避模型约束
- 用 Map 在多层之间长期传递业务对象
- 把 DTO 当作页面展示对象长期传递
- 把“临时修复”写成长期通用模式
