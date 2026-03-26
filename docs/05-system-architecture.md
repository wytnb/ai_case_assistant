# 系统架构

## 架构目标

- 以 monorepo 根目录为统一工作入口。
- 让 Flutter 客户端、AI gateway、共享契约、文档与测试在一个仓库中协作。
- 在不引入过度抽象的前提下，为后续扩展保留空间。

## 模块划分

| 模块 | 目录 | 职责 | 依赖 |
|---|---|---|---|
| workspace | 仓库根目录 | 统一入口、规则、脚本、共享契约、根级文档 | `docs/`, `scripts/`, `contracts/` |
| app | `apps/ai_case_assistant/` | 页面、路由、本地持久化、追问会话状态、附件存储、报告展示 | gateway, Drift, 本地文件系统 |
| gateway | `services/ai_gateway/` | `POST /ai/intake` 与 `POST /ai/report`，以及 retired `/ai/extract` 的 `404` 路由行为 | DeepSeek, Cloudflare Workers |

## App 内部模块

| 模块 | 职责 | 依赖 |
|---|---|---|
| `app` | 应用装配、路由、首页入口 | `core`, `features` |
| `core/config` | 读取 `dart-define` | - |
| `core/network` | 创建 Dio | `AppConfig` |
| `core/database` | Drift 数据库、迁移、基础查询 | `drift` |
| `features/settings` | 设置项仓库与 Provider | `core/database` |
| `features/ai` | `/ai/report` remote client、共享时间格式化、异常映射 | `core/network` |
| `features/intake` | `/ai/intake` remote client、本地追问状态机、追问页、暂存附件 | `core/database`, `features/health_record` |
| `features/health_record` | 正式记录列表、详情、删除、附件读取 | `core/database`, `features/intake` |
| `features/report` | 报告生成、列表、详情 | `core/database`, `features/ai` |

## 依赖关系

- workspace 级契约先于 app / gateway 变更
- `apps/ai_case_assistant/` 通过 HTTP 依赖 gateway，不直接依赖 gateway 源码
- `presentation/pages` -> `presentation/providers`
- `presentation/providers` -> `service/repository/remote`
- `features/intake` -> `core/database`, `core/network`, `features/health_record`
- `features/report` 只查询正式 `health_events`

当前明确不做的依赖方向：

- 页面直接调用 Dio
- 页面直接读写 Drift / SQLite
- 页面直接拼接附件本地路径
- 页面直接解析原始 HTTP payload
- app 直接把 `services/ai_gateway/` 当成本地库依赖

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

### 报告生成时序

1. app 按时间范围查询正式 `health_events`。
2. `RemoteAiReportService` 请求 `/ai/report`。
3. 结果写入 `reports` 并在详情页展示。

## 工程组织约定

- monorepo 根目录只放 workspace 层内容，不再承载 Flutter 工程根。
- Flutter 工程固定放在 `apps/ai_case_assistant/`。
- gateway 固定放在 `services/ai_gateway/`。
- 共享 HTTP 契约固定放在 `contracts/`。
- 根级 `docs/` 记录 workspace 与业务事实；服务实现细节写在 `services/ai_gateway/docs/`。

## 技术约束

- 当前仓库是本地优先架构，主数据载体是 Drift 与本地文件系统。
- AI 能力通过 `AI_API_BASE_URL` 指向的 gateway 提供。
- 未完成追问草稿完全在客户端保存，不引入服务端会话存储。
- 当前 app 主链路不再直接调用已退场的 `/ai/extract`。

## 风险与取舍

- `IntakeService` 仍承担会话编排、正式记录更新与附件转正，复杂度高于单纯远程调用。
- 所有会话状态都保存在客户端，本地数据库异常会直接影响恢复能力。
- 历史旧 `/ai/extract` 记录没有 session 关联，无法获得重新追问能力。
