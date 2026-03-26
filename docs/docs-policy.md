# 文档策略（docs-policy）

本文件定义项目文档体系的完整清单、主题边界、更新时机、取证规则、模板、示例、命名与放置规则，以及新建文档判定逻辑。
`AGENTS.md` 负责要求 AI 必须遵守，本文件负责说明“信息应该写到哪里、凭什么写、什么时候更新、何时新建文档”。

当前仓库是单仓 monorepo：

- `apps/ai_case_assistant/` 为 Flutter 客户端
- `services/ai_gateway/` 为 AI gateway
- 根级 `docs/` 负责 workspace 与业务本体事实
- 根级 `contracts/` 负责共享机器可读契约

## 1. 目标

文档体系需要同时满足以下目标：

1. 新接手的人能快速理解项目并开始工作。
2. AI 在改代码时会同步补文档、补测试、补验证说明。
3. 项目在频繁需求变更下，范围、影响面、风险与回归点可追踪。
4. AI 能自行判断“更新已有文档”还是“新增文档”，而不是只更新代码。
5. 业务知识不长期散落在聊天记录、提交说明和口头沟通中。

## 2. 总原则

### 2.1 优先更新已有文档

默认先更新已有文档，不默认新建。

### 2.2 事实必须有证据

允许写入文档的事实来源只有：

- 代码实现
- 配置文件
- 测试
- 脚本
- 可直接从仓库结构推断的低风险事实
- 已被以上证据支撑的稳定文档事实

信息不足时，明确写“待确认”，不要编造。

### 2.3 取证优先级

当代码、配置、测试、脚本与旧文档之间存在冲突时，取证优先级如下：

1. 当前代码实现
2. 当前配置文件
3. 当前测试
4. 当前脚本
5. 已被上述事实支持的稳定文档

旧文档不能互相引用来自证。

### 2.4 区分三类信息

每份文档都要明确区分：

- 当前已实现
- 当前未实现但方向明确
- 待确认 / 未证实

### 2.5 一份文档只负责一个主题

避免把范围、流程、架构、接口、数据模型、测试策略混写在同一篇里。

### 2.6 文档要支撑变更管理

文档不仅要描述“现在是什么”，还要让维护者回答：

- 为什么这样做
- 改了什么
- 会影响什么
- 应该补哪些测试和 smoke

## 3. 何时更新已有文档，何时新建文档

### 3.1 默认判断流程

1. 这次信息能否清晰归入已有文档主题？
   - 能：更新已有文档。
2. 这次只是补充、修正、澄清还是局部同步？
   - 是：更新已有文档。
3. 这次是否形成新的长期主题，并且后续会被反复引用？
   - 否：不要新建。
4. 独立成文是否能明显降低未来维护成本？
   - 否：不要新建。
5. 以上都满足时，允许新建文档。

### 3.2 通常不应新建文档的情况

- 一次性任务说明
- 局部 bug 修复
- 小范围字段修正
- 临时排障记录
- 已有文档下一小节即可承接的内容

### 3.3 应考虑新建文档的情况

- 新增长期存在的业务主题
- 新增独立子系统
- 新增会被反复引用的规则集合
- 重要架构决策需要单独留痕
- 现有文档已经过长且继续追加会降低可维护性

## 4. 文档总清单与主题归属

### 仓库入口

- `README.md`
  - 用途：项目是什么、怎么跑、去哪里读详细文档
  - 更新时机：项目定位、运行方式、验证命令、关键目录变化

- `AGENTS.md`
  - 用途：AI 执行规则、文档与测试同步规则
  - 更新时机：协作规则、完成定义、输出格式变化

### docs/

- `docs/00-index.md`
  - 用途：文档导航与阅读顺序
  - 更新时机：新增、删除、重命名文档

- `docs/01-overview.md`
  - 用途：项目概览、目标用户、问题、核心价值、成功标准
  - 更新时机：项目定位、成功标准、版本目标变化

- `docs/02-scope-and-nongoals.md`
  - 用途：当前范围、不做什么、版本边界、延期项
  - 更新时机：范围、优先级、阶段边界变化

- `docs/03-business-flows.md`
  - 用途：主流程、异常流程、状态流转
  - 更新时机：记录链路、报告链路、失败路径变化

- `docs/04-domain-model.md`
  - 用途：核心对象、关系、字段语义、不变量
  - 更新时机：实体语义或对象关系变化

- `docs/05-system-architecture.md`
  - 用途：模块边界、依赖方向、工程组织、技术约束
  - 更新时机：目录职责、依赖边界、组织方式变化

- `docs/06-api-contracts.md`
  - 用途：接口请求 / 响应、错误语义、兼容要求
  - 更新时机：AI 请求 / 响应 JSON、客户端校验规则变化

- `docs/07-data-model.md`
  - 用途：数据库 / 本地文件模型、迁移策略、兼容要求
  - 更新时机：表结构、schemaVersion、文件路径口径变化

- `docs/08-rules-and-edge-cases.md`
  - 用途：业务规则、边界条件、默认兜底和异常处理
  - 更新时机：校验规则、降级规则、范围计算规则变化

- `docs/15-monorepo-workspace.md`
  - 用途：workspace 结构、职责边界、跨 app/gateway 协作顺序
  - 更新时机：目录结构、运行入口、跨模块协作顺序变化

- `docs/09-env-and-runbook.md`
  - 用途：环境要求、dart-define、启动、验证入口与排障总览
  - 更新时机：环境变量、启动方式、验证命令变化

- `docs/10-testing-strategy.md`
  - 用途：测试分层、现状、覆盖要求、通过标准
  - 更新时机：测试口径、验证门槛、覆盖重点变化

- `docs/11-regression-matrix.md`
  - 用途：高风险模块与必测回归项
  - 更新时机：高风险流程变化、历史 bug 或架构边界变化

- `docs/12-release-smoke-checklist.md`
  - 用途：发布前后 smoke 检查
  - 更新时机：演示发布流程、关键验收点变化

- `docs/13-requirement-deltas.md`
  - 用途：记录需求理解、范围边界、文档体系的重要变化
  - 更新时机：范围变化、重要取舍变化、文档体系迁移

- `docs/14-android-real-device-testing-sop.md`
  - 用途：Android 真机连接、安装、运行、日志抓取与排障 SOP
  - 更新时机：真机 smoke 操作步骤、设备排障方式、安装与运行流程变化

- `docs/adr/*.md`
  - 用途：记录重要架构决策及再评估条件
  - 更新时机：架构方向、模块边界、兼容策略、技术路线变化

### 配套目录

- `.cursor/rules/`
  - 用途：Cursor 规则镜像
  - 更新时机：`AGENTS.md` 或文档 / 测试规则变化

- `contracts/`
  - 用途：app 与 gateway 的共享机器可读契约
  - 更新时机：HTTP 请求 / 响应 shape、错误结构、公开接口列表变化

- `scripts/verify/`
  - 用途：固定验证脚本目录
  - 更新时机：新增稳定验证脚本时

- `tests/regression/`
  - 用途：专项回归用例目录说明或回归用例集合
  - 更新时机：开始建设专项回归集时

## 5. 变更类型到文档的映射

| 变更类型 | 至少应检查 / 更新的文档 |
|---|---|
| 项目目标或成功标准变化 | `README.md`, `docs/01-overview.md`, `docs/02-scope-and-nongoals.md` |
| monorepo 结构或目录职责变化 | `README.md`, `docs/00-index.md`, `docs/05-system-architecture.md`, `docs/15-monorepo-workspace.md`, `docs/13-requirement-deltas.md` |
| 范围、非目标或阶段边界变化 | `docs/02-scope-and-nongoals.md`, `docs/13-requirement-deltas.md` |
| 业务流程变化 | `docs/03-business-flows.md`, `docs/08-rules-and-edge-cases.md`, `docs/11-regression-matrix.md` |
| 核心对象 / 字段语义变化 | `docs/04-domain-model.md`, `docs/06-api-contracts.md`, `docs/07-data-model.md` |
| AI 请求 / 响应变化 | `contracts/health-record-ai.openapi.json`, `docs/06-api-contracts.md`, `docs/08-rules-and-edge-cases.md`, `docs/10-testing-strategy.md` |
| 表结构 / 迁移 / 文件路径变化 | `docs/07-data-model.md`, `docs/10-testing-strategy.md` |
| 模块边界 / 依赖方向变化 | `docs/05-system-architecture.md`, `docs/11-regression-matrix.md`, `docs/adr/*.md` |
| 环境变量 / 运行方式 / 验证命令变化 | `README.md`, `docs/09-env-and-runbook.md`, `docs/12-release-smoke-checklist.md`, `docs/14-android-real-device-testing-sop.md` |
| Android 真机连接 / 安装 / 运行 / 排障流程变化 | `README.md`, `docs/09-env-and-runbook.md`, `docs/12-release-smoke-checklist.md`, `docs/14-android-real-device-testing-sop.md` |
| 测试口径变化 | `docs/10-testing-strategy.md`, `docs/11-regression-matrix.md`, `docs/12-release-smoke-checklist.md` |
| 发布与演示流程变化 | `docs/12-release-smoke-checklist.md`, `docs/13-requirement-deltas.md` |
| AI 协作或文档同步规则变化 | `AGENTS.md`, `docs/docs-policy.md`, `.cursor/rules/*`, `scripts/check_doc_sync.py` |

## 6. 模板

### 6.1 项目概览模板（01-overview.md）

```md
# 项目概览

## 背景
## 目标用户
## 目标问题
## 核心价值
## 成功标准
## 当前版本目标
## 相关文档
```

### 6.2 范围模板（02-scope-and-nongoals.md）

```md
# 范围与非目标

## 当前范围
## 当前不做
## 版本边界
## 延期项 / 候选项
## 已知约束
```

### 6.3 业务流程模板（03-business-flows.md）

```md
# 业务流程

## 流程清单
## 主流程
## 异常流程
## 状态流转
## 前置条件
## 后置条件
## 待确认问题
```

### 6.4 领域模型模板（04-domain-model.md）

```md
# 领域模型

## 实体清单
## 实体关系
## 字段语义
## 生命周期
## 不变量
## 待确认问题
```

### 6.5 系统架构模板（05-system-architecture.md）

```md
# 系统架构

## 架构目标
## 模块划分
## 依赖关系
## 关键时序
## 外部依赖
## 技术约束
## 风险与取舍
```

### 6.6 接口契约模板（06-api-contracts.md）

```md
# 接口契约

## 接口清单
## 请求 / 响应
## 错误语义
## 鉴权
## 幂等 / 重试
## 兼容性要求
```

### 6.7 数据模型模板（07-data-model.md）

```md
# 数据模型

## 存储清单
## 结构定义
## 索引
## 迁移策略
## 删除策略
## 兼容要求
## 测试关注点
```

### 6.8 规则与边界模板（08-rules-and-edge-cases.md）

```md
# 规则与边界

## 规则清单
## 优先级
## 边界条件
## 冲突处理
## 异常场景
## 默认兜底行为
```

### 6.9 环境与运行手册模板（09-env-and-runbook.md）

```md
# 环境与运行手册

## 环境清单
## 配置项
## 本地启动
## 常用验证命令
## 测试环境
## 发布流程
## 常见故障
## 排查步骤
```

### 6.10 测试策略模板（10-testing-strategy.md）

```md
# 测试策略

## 测试目标
## 测试分层
## 当前已有自动化
## 覆盖要求
## 真实接口 / 线上验证触发条件
## 当前无法自动化验证项
## 允许跳过条件
## 测试数据策略
## 通过标准
```

### 6.11 回归矩阵模板（11-regression-matrix.md）

```md
# 回归矩阵

| 功能/模块 | 改动触发条件 | 风险等级 | 必测场景 | 可选场景 | 自动化情况 | 备注 |
|---|---|---|---|---|---|---|
```

### 6.12 发布 Smoke 清单模板（12-release-smoke-checklist.md）

```md
# 发布 Smoke 清单

## 发布前检查
## 发布后检查
## 核心闭环验证
## 监控项
## 回滚条件
```

### 6.13 需求变更记录模板（13-requirement-deltas.md）

```md
# 需求变更记录

## 维护说明
## 变更记录

### YYYY-MM-DD - 变更标题
- 原需求：
- 新需求：
- 变更原因：
- 影响范围：
- 需要更新的文档：
- 需要补的测试：
- 风险：
- 后续动作：
```

### 6.14 Android 真机测试 SOP 模板（14-android-real-device-testing-sop.md）

```md
# Android 真机测试操作手册

## 目标与适用范围
## 当前已确认的仓库事实
## 前置检查
## 设备连接
## 运行方式
## 仓库专属真机 smoke 流程
## 日志与排障
## 跳过与汇报要求
## 相关文档
```

### 6.15 ADR 模板（docs/adr/*.md）

```md
# ADR-XXXX-标题

## 背景
## 决策问题
## 备选方案
## 取舍分析
## 最终决策
## 影响
## 何时需要重新评估
```

## 7. 示例

### 7.1 示例：新增一个接口字段

情形：

- 在已有 AI 接口中新增一个可选字段
- 不改变主流程

通常应：

- 更新 `docs/06-api-contracts.md`
- 若字段语义进入领域对象，更新 `docs/04-domain-model.md`
- 若测试口径变化，更新 `docs/10-testing-strategy.md`
- 补相关契约 / 集成式测试

通常不应：

- 新建专题文档

### 7.2 示例：新增一个长期存在的新流程

情形：

- 新增“审核流”或新的健康记录工作流
- 后续会被反复迭代

通常应：

- 更新 `docs/03-business-flows.md`
- 更新 `docs/08-rules-and-edge-cases.md`
- 更新 `docs/11-regression-matrix.md`
- 若范围边界变化，更新 `docs/02-scope-and-nongoals.md` 与 `docs/13-requirement-deltas.md`

如果现有流程文档已无法清晰承载，则可：

- 新建一个专题流程文档
- 并更新 `docs/00-index.md`

### 7.3 示例：调整模块边界

情形：

- 拆分服务
- 调整核心模块职责
- 改变依赖方向

通常应：

- 更新 `docs/05-system-architecture.md`
- 更新 `docs/11-regression-matrix.md`
- 新增或更新 `docs/adr/*.md`

### 7.4 示例：修复一个已知 bug

情形：

- 修复某个边界条件下的状态或解析错误

通常应：

- 更新相关主题文档，如果行为定义发生变化
- 必要时更新 `docs/08-rules-and-edge-cases.md`
- 补对应回归测试

通常不应：

- 新建新文档

## 8. 命名与放置规则

### 8.1 命名规则

- 项目事实文档使用固定编号前缀，如 `01-overview.md`
- 文档文件名使用小写英文、连字符或编号前缀
- ADR 使用 `ADR-XXXX-短标题.md`
- Cursor 规则放在 `.cursor/rules/`
- 专项回归目录放在 `tests/regression/`

### 8.2 放置规则

- 项目事实文档放在 `docs/`
- 架构决策记录放在 `docs/adr/`
- AI 执行规则放在仓库根目录与 `.cursor/rules/`
- 固定验证脚本放在 `scripts/verify/`
- 共享契约放在根级 `contracts/`
- Flutter 自动化测试当前放在 `apps/ai_case_assistant/test/` 或 `tests/regression/`

### 8.3 索引规则

只要新增、删除、重命名文档，必须同步更新：

1. `docs/00-index.md`
2. `README.md` 中受影响的入口说明
3. `AGENTS.md` 或 `.cursor/rules/` 中受影响的引用

## 9. 编写要求

### 9.1 不允许编造事实

以下内容如果仓库里没有证据，就不要写成既成事实：

- 不存在的页面、路由、数据表、接口
- 未配置的环境、CI、监控、发布流水线
- 未验证的上游错误码和返回结构
- 未落地的设置、同步、账号体系

### 9.2 明确标注待确认

当上游能力或历史背景无法从仓库中确认时，使用：

- `待确认`
- `当前可观察到的行为`
- `当前客户端实现`

不要把推断写成“产品规则已经确认”。

### 9.3 文档要与测试和脚本相互印证

- 有自动化测试时，写明具体覆盖范围
- 只有手工验证时，明确写“当前无法自动化验证”
- 有脚本时，写具体命令；没有脚本时，不要写虚构脚本名

## 10. 新建文档后的同步要求

如果新增、删除、重命名文档，必须同步更新：

1. `docs/00-index.md`
2. 受影响的入口说明
3. 相关规则文件中的引用
4. 若新增的是共享契约，还要同步更新 `docs/06-api-contracts.md`
4. `scripts/check_doc_sync.py` 中的文档集合与建议映射

## 11. 给 AI 的执行提示

当需求模糊时，优先：

1. 核对 `README.md`
2. 核对 `docs/01-overview.md`
3. 核对 `docs/02-scope-and-nongoals.md`
4. 核对 `docs/03-business-flows.md`
5. 再决定实现范围

不要跳过文档阶段直接做大范围推测性改动。
