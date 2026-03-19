# 系统架构

## 架构目标

- 以 Flutter 客户端为中心，快速交付可演示的本地优先 MVP。
- 把页面、追问状态机、AI 请求、本地数据库与附件存储边界保持清晰。
- 在不引入过度抽象的前提下，为后续扩展保留空间。

## 模块划分

| 模块 | 职责 | 输入 | 输出 | 依赖 |
|---|---|---|---|---|
| `app` | 应用装配、路由、首页入口 | Provider、路由状态 | 页面入口 | `core`, `features` |
| `core/config` | 读取 `dart-define` | 编译期变量 | 配置常量 | - |
| `core/network` | 创建 Dio | `AppConfig` | `Dio` 实例 | `dio` |
| `core/database` | Drift 数据库、迁移、基础查询 | 表定义、查询条件 | DataClass 与持久化方法 | `drift` |
| `features/settings` | 设置项仓库与 Provider | `app_settings` | 跟页面交互的设置值 | `core/database` |
| `features/ai` | `/ai/extract`、`/ai/report` 的 remote client 与异常映射 | 原始文本、报告事件 | 提取结果、报告结果 | `core/network` |
| `features/intake` | `/ai/intake` remote client、本地追问状态机、追问页、暂存附件 | 消息历史、会话状态、附件 | intake session、正式记录编排结果 | `core/database`, `features/ai`, `features/health_record` |
| `features/health_record` | 正式记录创建、列表、详情、附件转正显示 | 正式记录与附件 | 列表/详情页数据 | `core/database`, `features/intake` |
| `features/report` | 报告生成、列表、详情 | 正式记录范围查询 | 报告落库与展示 | `core/database`, `features/ai` |

## 依赖关系

- `app` -> `core` / `features`
- `presentation/pages` -> `presentation/providers`
- `presentation/providers` -> `service/repository/remote`
- `features/intake` -> `core/database`, `core/network`, `features/health_record`
- `features/settings` -> `core/database`
- `features/report` 只查询正式 `health_events`

当前明确不做的依赖方向：

- 页面直接调用 Dio
- 页面直接读写 Drift / SQLite
- 页面直接拼接附件本地路径
- 页面直接解析原始 HTTP payload
- 设置页或首页直接写 SQL

## 关键时序

### 新增记录时序

1. `/records/new` 页面读取 `followUpModeEnabledProvider`。
2. 页面调用 `intakeActionControllerProvider`。
3. `IntakeService` 创建本地 session、首条 message、暂存附件。
4. `RemoteAiIntakeService` 请求 `/ai/intake`。
5. 如果返回 `needs_followup`：
   - 写 assistant message
   - 更新 session 草稿字段与状态
   - 跳转 `/intake/:id`
6. 如果返回 `final`：
   - 创建或更新 `health_events`
   - 转正附件到 `attachments`
   - 更新 session 的 `healthEventId` 和状态

### 追问恢复时序

1. `/records` 查询 `unfinishedIntakeSessionsProvider`。
2. 用户进入 `/intake/:id`。
3. 页面读取会话与消息历史。
4. 若状态为 `questioning`，`IntakePage` 自动触发 `resumeQuestioning`。
5. 服务层使用完整历史重放本轮请求。

### 重新追问时序

1. 详情页通过 `linkedIntakeSessionsProvider` 找到已关联 session。
2. 用户进入原 `/intake/:id`。
3. 后续 `final` 时由 `IntakeService` 更新原 `health_event`。

## 路由结构

- `/`
- `/records`
- `/records/new`
- `/records/:id`
- `/intake/:id`
- `/reports`
- `/reports/:id`

## 工程组织约定

- `features/intake/` 承接本次追问能力。
- Drift 表定义放在 `data/local/tables/`。
- 页面状态机放在 Provider / Service，不塞进 Widget。
- Settings 通过 Repository + Provider 访问，不在页面里直接写数据库。
- 旧 `/ai/extract` 链路保留，但默认新增页不再直接依赖它。

## 技术约束

- 当前仓库是本地优先架构，主数据载体是 Drift 与本地文件系统。
- AI 能力通过 `AI_API_BASE_URL` 指向的 worker 提供。
- 未完成追问草稿完全在客户端保存，不引入服务端会话存储。
- 本版会话附件只支持初始新增页选图，追问页不新增附件输入。

## 风险与取舍

- `IntakeService` 承担了会话编排、正式记录更新与附件转正，复杂度高于单纯远程调用。
- 所有会话状态都保存在客户端，本地数据库异常会直接影响恢复能力。
- 旧 `/ai/extract` 记录没有 session 关联，无法获得重新追问能力。
