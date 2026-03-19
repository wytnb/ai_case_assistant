# 业务流程

## 流程清单

- 新增健康记录，追问模式关闭
- 新增健康记录，追问模式开启
- 中断后恢复追问
- 提前结束追问
- 基于正式记录重新开启追问
- 浏览正式记录与未完成追问
- 生成并查看健康报告

## 主流程

### 流程 1：追问模式关闭时新增记录

1. 用户在首页打开应用，保持“追问模式”为关闭。
2. 用户进入 `/records/new`，输入初始 `rawText`，可选图片附件。
3. 页面校验 `rawText.trim()` 非空且不超过 1000 字。
4. 客户端在本地创建 intake session、首条 user message 和会话暂存附件。
5. 客户端调用 `POST /ai/intake`，请求中 `followUpMode=false`、`forceFinalize=false`。
6. worker 返回 `status=final`。
7. 客户端将 `draft.mergedRawText`、`draft.symptomSummary`、`draft.notes`、`draft.actionAdvice` 写入正式 `health_events`。
8. 客户端把会话暂存附件转正为 `attachments`，并回填 `intake_sessions.healthEventId`。
9. 页面跳转到记录详情页或列表页。

### 流程 2：追问模式开启时新增记录

1. 用户在首页打开“追问模式”。
2. 用户进入 `/records/new` 并提交初始描述。
3. 客户端创建本地 intake session，快照保存当前开关值到 `followUpModeSnapshot`。
4. 客户端调用 `POST /ai/intake`，请求中 `followUpMode=true`、`forceFinalize=false`。
5. 如果 worker 返回 `status=needs_followup`：
   - 客户端保存 AI 问题到 `intake_messages`
   - 更新 `mergedRawText`、`draftSymptomSummary`、`draftNotes`、`draftActionAdvice`
   - 会话状态更新为 `awaiting_user_input`
   - 跳转 `/intake/:id`
6. 如果 worker 返回 `status=final`：
   - 直接生成正式记录
   - 保存 `actionAdvice`
   - 会话状态更新为 `finalized`

### 流程 3：继续追问直到完成

1. 用户进入 `/intake/:id`。
2. 页面展示消息历史、当前问题、输入框和发送按钮。
3. 用户输入补充内容并发送。
4. 客户端将该轮 user message 落库，重新带完整消息历史调用 `POST /ai/intake`。
5. 如果返回 `needs_followup`，继续更新草稿和消息历史。
6. 如果返回 `final`，更新正式记录或创建正式记录，并结束会话。

### 流程 4：中断后恢复追问

1. 用户在追问过程中离开页面、关闭 App 或杀进程。
2. 重新进入应用后，`/records` 顶部“未完成追问”分区展示 `questioning` 或 `awaiting_user_input` 会话。
3. 用户点击“继续追问”进入 `/intake/:id`。
4. 如果该会话状态仍是 `questioning`，页面会自动重放当前完整历史，继续请求 AI 完成本轮。

### 流程 5：提前结束追问

1. 用户在追问页点击“退出追问，生成最终记录”。
2. 客户端调用 `POST /ai/intake`，请求中：
   - `followUpMode=true`
   - `forceFinalize=true`
   - `messages` 为完整消息历史
3. worker 返回 `final`。
4. 客户端生成或更新正式记录。
5. 会话状态标记为 `finalized_by_force`。

### 流程 6：重新开启追问

1. 用户打开一个已关联 intake session 的正式记录详情页。
2. 点击“继续补充并重新追问”。
3. 客户端进入原 session 对应的 `/intake/:id`。
4. 用户补充新信息后再次调用 `/ai/intake`。
5. 最终完成时更新原正式记录，不新建重复记录。

### 流程 7：浏览正式记录与未完成追问

1. 用户进入 `/records`。
2. 顶部分区展示未完成追问会话，按 `updatedAt` 倒序。
3. 下方展示正式 `health_events` 列表，按 `createdAt` 倒序。
4. 未完成会话不会出现在正式记录区。
5. 只有已关联 intake session 的正式记录才展示“继续补充”入口。

### 流程 8：生成并查看健康报告

1. 用户进入 `/reports`。
2. 选择 `week`、`month` 或 `quarter`。
3. 客户端按时间范围查询正式 `health_events`。
4. 客户端调用 `POST /ai/report`。
5. 报告结果写入或覆盖 `reports`。
6. 未完成追问草稿不会进入报告输入。

## 异常流程

- `rawText` 为空或超过 1000 字：前端校验拦截，不发请求。
- `/ai/intake` 或 `/ai/extract` 返回缺字段、错类型或结构非法：视为 `invalidResponsePayload`，不落正式记录。
- `/ai/intake` 返回内容质量一般、摘要很短或为空字符串：只要字段存在且类型正确，仍视为合法响应，原样保留。
- 网络失败、上游 HTTP 失败、数据库写入失败或附件转正失败：当前操作失败，页面提示错误，不把未完成草稿写进正式记录。
- 详情页打开的是旧 `/ai/extract` 记录：不显示重新追问入口。

## 状态流转

| 对象 | 初始状态 | 触发动作 | 新状态 | 备注 |
|---|---|---|---|---|
| 首页追问模式 | `false` | 用户切换开关 | `true/false` | 通过 `app_settings` 持久化 |
| intake session | 新建 | 首轮请求发出 | `questioning` | 本轮 AI 正在处理中 |
| intake session | `questioning` | 返回继续追问 | `awaiting_user_input` | 保存最新问题 |
| intake session | `questioning` | 返回最终完成 | `finalized` | 首轮 direct-final 也保留 session |
| intake session | `awaiting_user_input` | 用户继续补充并请求 | `questioning` | 进入下一轮处理中 |
| intake session | `awaiting_user_input` | 强制结束完成 | `finalized_by_force` | 由 `forceFinalize=true` 触发 |
| 正式记录 | 不存在 | 首次完成 | 已创建 | `createdAt = updatedAt = eventTime` |
| 正式记录 | 已存在 | 重新追问完成 | 已更新 | 保留原 `createdAt`，刷新 `updatedAt` |

## 前置条件

- 设备已安装应用并可正常读写本地数据库与应用私有目录。
- 若要请求 AI，上游地址必须可访问。
- 若要保存图片附件，用户已从系统相册成功选择图片。

## 后置条件

- 未完成追问只存在于 `intake_sessions`、`intake_messages`、`intake_session_attachments`。
- 正式记录完成后，`health_events` 与 `attachments` 中存在对应落库结果。
- 报告生成后，`reports` 中存在对应范围的正式报告。
