# 文档同步矩阵

## 文档目的

本文件定义代码改动与文档更新之间的映射关系。
它回答：改了哪类代码后，必须检查和更新哪些文档。

本文件是 AI 执行层文档。
它只定义文档同步规则，不定义产品事实、字段契约或页面逻辑。

## 使用规则

1. 任何代码改动任务，在结束前都必须检查本文件。
2. 若代码改动命中了某类影响面，必须检查对应文档是否需要更新。
3. 只要对应文档内容发生事实变化、规则变化或当前状态变化，就必须在同一任务中更新。
4. 若最终判断无需更新任何文档，必须明确输出：
   - `No document update required.`
   - 具体理由。
5. 若任务目标是“根据实际代码进度同步文档”，必须先以代码为证据，再决定各层文档的更新范围。

## 检查顺序

1. 用户可见行为是否改变
2. 数据模型、字段、枚举、JSON、解析规则是否改变
3. 架构边界、模块职责、依赖方向是否改变
4. 编码规范、实现习惯、通用错误处理是否改变
5. 完成口径是否改变
6. 面向人的项目说明是否改变
7. AI 协作规则本身是否改变

## 映射规则

## 一、产品行为变化

### 触发条件

- 新增用户可见功能
- 删除用户可见功能
- 页面主链路变化
- MVP 范围变化
- 当前不做的功能范围变化

### 必查文档

- `docs/product_notes.md`
- `docs/acceptance.md`

### 视情况更新

- `README.md`
- `docs/project_overview.md`

### 说明

- 长期产品定义未变时，不更新 `docs/product_facts.md`
- 只是当前阶段范围变化时，只更新 `product_notes`

## 二、长期产品事实变化

### 触发条件

- 产品目标变化
- 目标用户变化
- 核心业务对象变化
- 长期产品原则变化
- 关键术语定义变化

### 必查文档

- `docs/product_facts.md`

### 视情况更新

- `docs/project_overview.md`
- `README.md`

## 三、数据模型 / 字段 / 枚举 / JSON 变化

### 触发条件

- Drift 表字段变化
- 数据库生成对象含义变化
- AI 请求 / 响应 JSON 变化
- JSON 解析策略变化
- ID 规则变化
- 时间字段规则变化
- 本地文件路径口径变化

### 必查文档

- `docs/contracts.md`

### 视情况更新

- `docs/acceptance.md`

### 说明

- 数据口径变化时，不得只改代码不改 `contracts`

## 四、架构边界 / 模块职责变化

### 触发条件

- 新增 feature
- feature 职责调整
- 分层边界调整
- Provider 与服务层归属变化
- 路由组织变化
- 状态管理方案变化
- 本地存储、网络层、AI 代理边界变化

### 必查文档

- `docs/architecture.md`

### 视情况更新

- `docs/architecture_notes.md`

### 说明

- 若只是阶段性 workaround、技术债、已知限制变化，优先更新 `architecture_notes`

## 五、编码规范 / 通用实现方式变化

### 触发条件

- 命名规范变化
- 文件组织方式变化
- 通用错误处理风格变化
- 日志规范变化
- 当前允许的薄服务 / Provider 组织方式变化
- 允许 / 禁止的实现方式变化

### 必查文档

- `docs/conventions.md`

## 六、工作流程 / AI 协作规则变化

### 触发条件

- AI 接任务后的阅读顺序变化
- 输出格式要求变化
- 允许的顺手修改范围变化
- 禁止的顺手修改行为变化
- 文档同步流程变化
- 文档同步任务的取证方式变化

### 必查文档

- `AGENTS.md`
- `docs/workflow.md`

### 视情况更新

- `docs/doc_sync_matrix.md`

## 七、完成口径变化

### 触发条件

- 页面最低完成标准变化
- 数据读写完成标准变化
- 错误提示最低要求变化
- AI 异常兜底要求变化
- 文档同步被纳入或移出完成定义

### 必查文档

- `docs/acceptance.md`

## 八、面向人的项目状态变化

### 触发条件

- 当前已实现内容变化
- 当前阶段说明变化
- 运行方式变化
- 目录结构说明变化
- 项目整体介绍需要同步

### 必查文档

- `README.md`

### 视情况更新

- `docs/project_overview.md`

## 九、临时技术债或阶段性限制变化

### 触发条件

- 新增或消除阶段性 workaround
- 当前已知技术限制变化
- 可接受的技术债范围变化
- 未来演进方向变化

### 必查文档

- `docs/architecture_notes.md`

### 视情况更新

- `docs/product_notes.md`

## 十、文档对齐实际代码进度

### 触发条件

- 用户明确要求按当前实现同步文档
- 现有文档出现“计划中的功能写成已实现”
- 现有文档遗漏了已落地的页面、字段、脚本或限制

### 必查文档

- `docs/product_notes.md`
- `docs/architecture.md`
- `docs/contracts.md`
- `docs/acceptance.md`
- `README.md`
- `docs/project_overview.md`

### 视情况更新

- `docs/product_facts.md`
- `docs/architecture_notes.md`
- `docs/conventions.md`
- `AGENTS.md`
- `docs/workflow.md`

## 典型代码改动与建议文档

### 新增页面

优先检查：

- `docs/product_notes.md`
- `docs/acceptance.md`
- `README.md`

若页面改变模块边界，再检查：

- `docs/architecture.md`
- `docs/architecture_notes.md`

### 修改数据表 / 模型 / JSON

优先检查：

- `docs/contracts.md`

若影响完成口径，再检查：

- `docs/acceptance.md`

### 修改路由结构

优先检查：

- `docs/architecture.md`

若人类入口说明受影响，再检查：

- `README.md`
- `docs/project_overview.md`

### 修改 AI 接口返回格式或兜底逻辑

优先检查：

- `docs/contracts.md`
- `docs/acceptance.md`

若改变当前功能范围，再检查：

- `docs/product_notes.md`

### 修改 Provider / 服务组织方式

优先检查：

- `docs/architecture.md`
- `docs/architecture_notes.md`
- `docs/conventions.md`

### 修改错误处理和日志模式

优先检查：

- `docs/conventions.md`

## 可不更新文档的条件

仅当以下条件同时满足时，才可不更新任何文档：

1. 本次改动是纯实现细节修复或纯内部重构；
2. 未改变用户可见行为；
3. 未改变字段、枚举、JSON、架构边界、规范或完成口径；
4. 最终输出明确写出：
   - `No document update required.`
   - 具体理由。

## 禁止做法

- 改了代码但不检查本文件
- 明明改了数据口径却不更新 `contracts`
- 明明改了当前范围却不更新 `product_notes`
- 明明改了完成口径却不更新 `acceptance`
- 把长期事实误写进阶段性文档
- 把临时 workaround 误写进结构事实文档
- 把未来计划页面、对象、路由写成当前已实现