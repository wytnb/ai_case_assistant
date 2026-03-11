# AI 健康病例助手 · AI 协作入口

## 目的

本文件是 AI 进入仓库后的第一入口。
它只负责说明：先读什么、按什么规则工作、遇到冲突怎么办、改完代码后必须做什么。
它不承载长期产品事实、字段口径、页面交互细节或设计原因。

## 项目文档体系

### AI 执行层

- `AGENTS.md`：AI 协作总入口；定义阅读顺序、冲突优先级、总体执行原则、输出约束、文档同步规则。
- `docs/product_facts.md`：产品长期事实；定义产品目标、目标用户、核心对象、长期成立的产品原则。
- `docs/product_notes.md`：当前阶段产品规则；定义 MVP 范围、阶段性取舍、当前不做什么、已知限制与演进方向。
- `docs/architecture.md`：长期架构事实；定义技术栈、分层、模块职责、目录组织、路由组织、依赖方向与边界。
- `docs/architecture_notes.md`：架构取舍说明；定义为什么这样选、当前限制、技术债、阶段性妥协与后续演进方向。
- `docs/conventions.md`：工程与编码规范；定义命名、目录、文件、错误处理、日志、注释和常见模式的统一写法。
- `docs/workflow.md`：AI 工作流程规范；定义接到任务后如何收敛范围、如何拆任务、何时只给方案、何时可直接改代码、如何同步文档。
- `docs/contracts.md`：数据契约；定义核心实体、字段、状态枚举、AI JSON 结构、DTO / Entity / ViewModel / Domain Model 边界。
- `docs/acceptance.md`：验收标准；定义页面、交互、数据、异常、文档同步的完成口径。
- `docs/doc_sync_matrix.md`：文档同步矩阵；定义“改哪类代码，必须检查和更新哪些文档”。

### 人类存档层

- `README.md`：项目入口说明；面向第一次打开仓库的人。
- `docs/project_overview.md`：项目全貌说明；面向未来维护者、面试官、合作者。

## AI 推荐阅读顺序

### 处理任何任务前的默认顺序

1. `AGENTS.md`
2. `docs/workflow.md`
3. 与任务直接相关的专用文档
4. 相关代码目录
5. 当任务涉及代码改动时，在结束前必须再读一次 `docs/doc_sync_matrix.md`

### 按任务类型补充阅读

- 页面任务：`product_facts` → `product_notes` → `architecture` → `contracts` → `acceptance`
- 数据模型任务：`architecture` → `contracts` → `acceptance`
- AI 接口任务：`product_notes` → `architecture` → `contracts` → `acceptance`
- Bug 修复任务：`architecture` → `contracts` → `conventions` → `acceptance`
- 说明文档任务：`README.md` / `project_overview.md`
- 规则或流程任务：`AGENTS.md` → `workflow.md` → `doc_sync_matrix.md`

## 文档冲突时的优先级

### 总体优先级

1. 用户当前明确任务
2. `AGENTS.md`
3. 专用约束文档
   - `docs/product_facts.md`
   - `docs/architecture.md`
   - `docs/contracts.md`
   - `docs/acceptance.md`
   - `docs/doc_sync_matrix.md`
4. 阶段性说明文档
   - `docs/product_notes.md`
   - `docs/architecture_notes.md`
5. 风格与流程文档
   - `docs/workflow.md`
   - `docs/conventions.md`
6. 人类说明文档
   - `README.md`
   - `docs/project_overview.md`

### 专项冲突规则

- `product_facts` 与 `product_notes` 冲突时：
  - 产品长期事实以 `product_facts` 为准；
  - 当前阶段范围、妥协、限制以 `product_notes` 为准。
- `architecture` 与 `architecture_notes` 冲突时：
  - 当前结构事实以 `architecture` 为准；
  - 阶段性取舍与技术债说明以 `architecture_notes` 为准。
- `contracts` 与任何说明性文档冲突时：
  - 字段、枚举、JSON、ID、时间字段口径以 `contracts` 为准。
- `acceptance` 与实现习惯冲突时：
  - “做到什么算完成”以 `acceptance` 为准。
- `doc_sync_matrix` 与个人习惯冲突时：
  - 文档同步检查以 `doc_sync_matrix` 为准。

## AI 总体执行原则

1. 先收敛任务边界，再给方案或改代码。
2. 只改与任务直接相关的模块；默认不做顺手重构。
3. 新增代码必须落在既有架构边界内；禁止因为单个需求引入新的架构层。
4. 先遵守数据契约，再写页面与状态逻辑。
5. 先满足 MVP 可演示与可验收，再考虑泛化。
6. 对不确定事项采用保守默认值，不擅自扩展产品范围。
7. 输出必须让人能判断：改了什么、没改什么、风险在哪里、文档是否已同步。

## AI 不应做的事情

- 不把阶段性策略写入长期事实文档。
- 不跨层调用，例如页面直接读写数据库、页面直接拼装 HTTP 请求、页面直接解析 AI 原始 JSON。
- 不在无说明影响范围的情况下进行多模块改动。
- 不在无明确任务要求时重命名核心字段、调整目录结构、替换状态管理方案、替换数据库方案。
- 不为了“更完整”引入账号体系、云同步、后台管理系统、复杂权限系统等非 MVP 设施。
- 不把 AI 自由文本直接当作结构化事实落库。
- 不在单次任务中同时处理“功能新增 + 大范围重构 + 风格统一 + 性能优化”。

## 输出结果的总体约束

### 当输出方案时

必须说明：

- 任务理解
- 改动范围
- 涉及模块或文件类型
- 关键约束
- 默认假设
- 不处理的内容

### 当输出代码时

必须保证：

- 命名遵守 `docs/conventions.md`
- 字段遵守 `docs/contracts.md`
- 分层遵守 `docs/architecture.md`
- 完成口径满足 `docs/acceptance.md`
- 改动范围遵守 `docs/workflow.md`
- 文档同步检查遵守 `docs/doc_sync_matrix.md`
- All text files must use LF line endings. Do not introduce CRLF. Follow .gitattributes.

### 当输出最终结果时

必须说明：

- 修改了哪些代码文件
- 修改了哪些文档文件
- 哪些文档未改动
- 未改动的理由

## 当任务信息不足时的默认处理原则

1. 优先使用仓库现有结构、既有命名和既有契约；不要自创新模式。
2. 若产品规则不足，按 MVP、离线优先、薄后端、本地结构化数据优先、AI 输出 JSON 化处理。
3. 若页面细节不足，先实现最小可演示闭环，不补充高级交互。
4. 若异常处理细节不足，至少提供：
   - 加载中
   - 空状态
   - 错误提示
   - 可重试
5. 若 AI 输出不稳定，先做解析兜底与失败提示，不擅自猜测字段。
6. 若涉及破坏性改动且用户未明确要求，只给方案，不直接实施。

## 强制文档同步检查

### 基本规则

对任何会修改代码的任务，AI 在结束前都必须读取并执行 `docs/doc_sync_matrix.md` 中的检查规则。
这里的“执行”指：根据本次代码改动判断哪些文档受影响，并在同一任务中完成同步更新，而不是仅口头说明。

### 必做事项

1. 判断本次任务是否改动了：
   - 用户可见行为
   - 数据模型 / 枚举 / JSON
   - 架构边界 / 模块职责
   - 编码规范 / 通用实现方式
   - 完成口径
   - 面向人的项目状态说明
2. 根据 `docs/doc_sync_matrix.md` 映射受影响文档。
3. 在同一任务中更新所有受影响文档。
4. 若无需更新任何文档，必须明确写出：
   - `No document update required.`
   - 具体理由。

### 完成判定

若本次任务改动了代码，但没有执行文档同步检查，则任务不算完成。

## 默认完成定义

除非用户另有说明，一次任务完成至少应满足：

- 代码落在既有目录中
- 结构不越层
- 字段与 JSON 不漂移
- 最低异常处理存在
- 输出说明影响范围与剩余风险
- 文档同步检查已执行
