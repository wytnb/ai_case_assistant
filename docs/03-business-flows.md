# 业务流程

## 流程清单

- 首次进入并同意免责说明
- 新增健康记录并启动 intake
- 继续追问直到完成
- 中断后恢复追问
- 提前结束追问
- 基于正式记录重新开启追问
- 浏览正式记录与草稿记录
- 删除正式记录或草稿记录
- 生成并查看健康报告

## 主流程

### 流程 1：首次进入并同意免责说明

1. 用户首次打开应用进入首页 `/`。
2. 客户端读取 `app_settings.first_use_disclaimer_accepted`，缺失时按 `false` 处理。
3. 当值为 `false` 时，首页弹出不可关闭免责弹窗。
4. 用户勾选同意并提交后，客户端将 `first_use_disclaimer_accepted=true` 持久化。
5. 弹窗关闭，用户可继续使用首页入口和后续功能。

### 流程 2：新增记录并启动 intake

1. 用户进入 `/records/new`，输入初始 `rawText`，可选图片附件。
2. 页面校验 `rawText.trim()` 非空且不超过 1000 字。
3. 客户端创建本地 intake session、首条 user message 和会话暂存附件。
4. 客户端调用 `POST /ai/intake`，请求中始终带：
   - `followUpMode`
   - `forceFinalize`
   - `eventTime`
   - 完整 `messages`
5. 如果返回 `needs_followup`：
   - 写 assistant message
   - 更新 session 草稿字段与状态
   - 跳转 `/intake/:id`
6. 如果返回 `final`：
   - 创建或更新正式 `health_events`
   - 转正附件到 `attachments`
   - 更新 session 的 `healthEventId` 和状态
   - 跳转 `/records/:id`

### 流程 3：继续追问直到完成

1. 用户进入 `/intake/:id`。
2. 页面展示消息历史、输入框和发送按钮。
3. 用户输入补充内容并发送。
4. 客户端将该轮 user message 落库，重新带完整消息历史调用 `POST /ai/intake`。
5. 如果返回 `needs_followup`，继续更新草稿和消息历史。
6. 如果返回 `final`，更新正式记录或创建正式记录，并结束会话。

### 流程 4：中断后恢复追问

1. 用户在追问过程中离开页面、关闭 App 或杀进程。
2. 重新进入应用后，`/records` 的“草稿记录” tab 展示 `questioning` 或 `awaiting_user_input` 会话。
3. 用户点击“继续追问”进入 `/intake/:id`。
4. 如果该会话状态仍是 `questioning`，页面会自动重放当前完整历史，继续请求 AI 完成本轮。

### 流程 5：提前结束追问

1. 用户在追问页点击“直接生成记录”。
2. 客户端调用 `POST /ai/intake`，请求中 `forceFinalize=true`。
3. worker 返回 `final`。
4. 客户端生成或更新正式记录。
5. 会话状态标记为 `finalized_by_force`。

### 流程 6：重新开启追问

1. 用户打开一个已关联 intake session 的正式记录详情页。
2. 点击“追加补充”。
3. 客户端进入原 session 对应的 `/intake/:id`。
4. 用户补充新信息后再次调用 `/ai/intake`。
5. 最终完成时更新原正式记录，不新建重复记录。

### 流程 7：浏览、删除、生成报告

1. `/records` 页面展示“正式记录 / 草稿记录”两个 tab。
2. 正式记录按 `createdAt` 过滤与排序；草稿按 `eventTime` 与 `updatedAt` 过滤与排序。
3. 删除正式记录时执行软删除，并同步把已关联 session 标记为 `deleted`。
4. 删除草稿记录时硬删除 session、消息、暂存附件与暂存文件。
5. `/reports` 按时间范围查询正式 `health_events`，调用 `POST /ai/report` 生成报告。
6. 未完成追问草稿不会进入报告输入。

## 异常流程

- `rawText` 为空或超过 1000 字：前端校验拦截，不发请求。
- `/ai/intake` 或 `/ai/report` 返回缺字段、错类型或结构非法：视为 `invalidResponsePayload`，不写入正式记录或报告。
- 网络失败、上游 HTTP 失败、数据库写入失败或附件转正失败：当前操作失败，页面提示错误，不把未完成草稿写进正式记录。
- 删除正式记录失败或删除草稿失败：当前删除操作失败，列表与详情保持原状态。
- 历史旧 `/ai/extract` 记录打开详情页时，不显示“追加补充”入口，因为它没有已关联 session。

## 状态流转

| 对象 | 初始状态 | 触发动作 | 新状态 | 备注 |
|---|---|---|---|---|
| 首页追问模式 | `false` | 用户切换开关 | `true/false` | 通过 `app_settings` 持久化 |
| 首页免责同意 | `false` | 用户勾选并点击“同意并继续” | `true` | key 为 `first_use_disclaimer_accepted` |
| intake session | 新建 | 首轮请求发出 | `questioning` | 本轮 AI 正在处理中 |
| intake session | `questioning` | 返回继续追问 | `awaiting_user_input` | 保存最新问题 |
| intake session | `questioning` | 返回最终完成 | `finalized` | 首轮 direct-final 也保留 session |
| intake session | `awaiting_user_input` | 用户继续补充并请求 | `questioning` | 进入下一轮处理中 |
| intake session | `awaiting_user_input` | 强制结束完成 | `finalized_by_force` | 由 `forceFinalize=true` 触发 |
| intake session | 已关联正式记录 | 正式记录被删除 | `deleted` | 用于屏蔽已删除记录的补充入口 |
| 正式记录 | 不存在 | 首次完成 | 已创建 | `createdAt = session.eventTime` |
| 正式记录 | 已存在 | 重新追问完成 | 已更新 | 保留原 `createdAt`，刷新 `updatedAt` |
| 正式记录 | `active` | 用户删除 | `deleted` | 写入 `deletedAt`，不物理删除数据库行 |

## 前置条件

- 设备已安装应用并可正常读写本地数据库与应用私有目录。
- 若要请求 AI，gateway 地址必须可访问。
- 若要保存图片附件，用户已从系统相册成功选择图片。

## 后置条件

- 未完成追问只存在于 `intake_sessions`、`intake_messages`、`intake_session_attachments`。
- 正式记录完成后，`health_events` 与 `attachments` 中存在对应落库结果。
- 报告生成后，`reports` 中存在对应范围的正式报告。
