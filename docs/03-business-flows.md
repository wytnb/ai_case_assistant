# 业务流程

## 流程清单

- 首次进入并同意免责说明
- 新增健康记录，追问模式关闭
- 新增健康记录，追问模式开启
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
3. 当值为 `false` 时，首页弹出不可关闭免责弹窗（点击空白与返回键均无效）。
4. 用户阅读说明并勾选同意项后，“同意并继续”按钮变为可点击。
5. 用户点击“同意并继续”，客户端将 `first_use_disclaimer_accepted=true` 持久化。
6. 弹窗关闭，用户可继续使用首页入口和后续功能。

### 流程 2：追问模式关闭时新增记录

1. 用户在首页打开应用，保持“追问模式”为关闭。
2. 用户进入 `/records/new`，输入初始 `rawText`，可选图片附件。
3. 页面校验 `rawText.trim()` 非空且不超过 1000 字。
4. 客户端在本地创建 intake session、首条 user message 和会话暂存附件。
5. 客户端调用 `POST /ai/intake`，请求中 `followUpMode=false`、`forceFinalize=false`。
6. worker 返回 `status=final`。
7. 客户端将 `draft.mergedRawText`、`draft.symptomSummary`、`draft.notes`、`draft.actionAdvice` 写入正式 `health_events`。
8. 客户端把会话暂存附件转正为 `attachments`，并回填 `intake_sessions.healthEventId`。
9. 页面跳转到正式记录详情页 `/records/:id`。
10. 若该详情页当前没有可回退的路由栈，点击返回时跳转到 `/records?tab=records`。
11. 若 `/records` 当前没有可回退的路由栈，点击返回时跳转到首页 `/`。

### 流程 3：追问模式开启时新增记录

1. 用户在首页打开“追问模式”。
2. 用户进入 `/records/new` 并提交初始描述。
3. 客户端创建本地 intake session，快照保存当前开关值到 `followUpModeSnapshot`。
4. 客户端调用 `POST /ai/intake`，请求中 `followUpMode=true`、`forceFinalize=false`。
5. 如果 worker 返回 `status=needs_followup`：
   - 客户端保存 AI 问题到 `intake_messages`
   - 更新 `mergedRawText`、`draftSymptomSummary`、`draftNotes`、`draftActionAdvice`
   - 会话状态更新为 `awaiting_user_input`
   - 跳转 `/intake/:id`
   - 若该追问页当前没有可回退的路由栈，点击返回时跳转到 `/records?tab=drafts`
6. 如果 worker 返回 `status=final`：
   - 直接生成正式记录
   - 保存 `actionAdvice`
   - 会话状态更新为 `finalized`

### 流程 4：继续追问直到完成

1. 用户进入 `/intake/:id`。
2. 页面展示消息历史、输入框和发送按钮；`awaiting_user_input` 状态不再额外展示“等待你继续补充”说明卡。
3. 用户输入补充内容并发送。
4. 客户端将该轮 user message 落库，重新带完整消息历史调用 `POST /ai/intake`。
5. 如果返回 `needs_followup`，继续更新草稿和消息历史。
6. 如果返回 `final`，更新正式记录或创建正式记录，并结束会话。

### 流程 5：中断后恢复追问

1. 用户在追问过程中离开页面、关闭 App 或杀进程。
2. 重新进入应用后，`/records` 的“草稿记录” tab 展示 `questioning` 或 `awaiting_user_input` 会话。
3. 用户点击“继续追问”进入 `/intake/:id`。
4. 如果该会话状态仍是 `questioning`，页面会自动重放当前完整历史，继续请求 AI 完成本轮。

### 流程 6：提前结束追问

1. 用户在追问页点击“直接生成记录”。
2. 客户端调用 `POST /ai/intake`，请求中：
   - `followUpMode=true`
   - `forceFinalize=true`
   - `messages` 为完整消息历史
3. worker 返回 `final`。
4. 客户端生成或更新正式记录。
5. 会话状态标记为 `finalized_by_force`。

### 流程 7：重新开启追问

1. 用户打开一个已关联 intake session 的正式记录详情页。
2. 点击“追加补充”。
3. 客户端进入原 session 对应的 `/intake/:id`。
4. 用户补充新信息后再次调用 `/ai/intake`。
5. 最终完成时更新原正式记录，不新建重复记录。

### 流程 8：浏览正式记录与草稿记录

1. 用户进入 `/records`。
2. 页面显示“正式记录 / 草稿记录”两个 tab。
3. 用户可按 `eventTime` 选择日期范围筛选；正式记录按 `createdAt` 过滤，草稿按 `eventTime` 过滤。
4. “草稿记录” tab 展示 `questioning` 或 `awaiting_user_input` 会话，按 `updatedAt` 倒序。
5. “正式记录” tab 展示正式 `health_events`，按 `createdAt` 倒序。
6. 草稿 tab 在筛选结果数量大于 0 时显示数字标识。
7. 用户从正式记录详情页返回时，优先回到已有列表；若当前详情页是根路由，则回到 `/records?tab=records`。
8. 用户从草稿追问页返回时，优先回到已有列表；若当前追问页是根路由，则回到 `/records?tab=drafts`。
9. 用户在 `/records` 返回时，优先回到已有上一页；若当前列表页是根路由，则回到首页 `/`。

### 流程 9：生成并查看健康报告

1. 用户进入 `/reports`。
2. 选择 `week`、`month` 或 `quarter`。
3. 客户端按时间范围查询正式 `health_events`。
4. 客户端调用 `POST /ai/report`。
5. 报告结果写入或覆盖 `reports`。
6. 未完成追问草稿不会进入报告输入。
7. 用户进入 `/reports/:id` 时，页面末尾固定展示免责说明。
8. 如果该报告覆盖的某些正式记录在报告生成后被删除，详情页额外展示红字提示“部分记录来源已被删除”。

### 流程 10：删除正式记录或草稿记录

1. 用户可在 `/records` 列表页删除单条正式记录或草稿记录。
2. 用户也可在 `/records/:id` 删除单条正式记录，或在 `/intake/:id` 删除当前草稿记录。
3. 删除正式记录时：
   - `health_events.status` 更新为 `deleted`
   - `health_events.deletedAt` 写入删除时间
   - 若该记录有关联 intake session，则该 session 状态更新为 `deleted`
4. 删除草稿记录时：
   - 删除 `intake_sessions`
   - 删除关联的 `intake_messages`
   - 删除关联的 `intake_session_attachments`
   - 删除暂存附件文件
5. 删除后：
   - 正式记录不再出现在列表、详情、继续补充入口和报告输入中
   - 草稿记录不再出现在草稿 tab，也不能通过原 `/intake/:id` 恢复

## 异常流程

- `rawText` 为空或超过 1000 字：前端校验拦截，不发请求。
- `/ai/intake` 或 `/ai/extract` 返回缺字段、错类型或结构非法：视为 `invalidResponsePayload`，不落正式记录。
- `/ai/intake` 返回内容质量一般、摘要很短或为空字符串：只要字段存在且类型正确，仍视为合法响应，原样保留。
- 网络失败、上游 HTTP 失败、数据库写入失败或附件转正失败：当前操作失败，页面提示错误，不把未完成草稿写进正式记录。
- 删除正式记录失败或删除草稿失败：当前删除操作失败，列表与详情保持原状态。
- 首次弹窗未勾选同意项：用户不能关闭弹窗，也不能继续操作首页入口。
- 详情页打开的是旧 `/ai/extract` 记录：不显示重新追问入口。

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
| intake session | `questioning/awaiting_user_input/finalized/finalized_by_force` | 关联正式记录被删除 | `deleted` | 仅用于屏蔽已关联 session |
| 正式记录 | 不存在 | 首次完成 | 已创建 | `createdAt = updatedAt = eventTime` |
| 正式记录 | 已存在 | 重新追问完成 | 已更新 | 保留原 `createdAt`，刷新 `updatedAt` |
| 正式记录 | `active` | 用户删除 | `deleted` | 写入 `deletedAt`，不物理删除数据库行 |

## 前置条件

- 设备已安装应用并可正常读写本地数据库与应用私有目录。
- 若要请求 AI，上游地址必须可访问。
- 若要保存图片附件，用户已从系统相册成功选择图片。

## 后置条件

- 未完成追问在未删除时只存在于 `intake_sessions`、`intake_messages`、`intake_session_attachments`。
- 正式记录完成后，`health_events` 与 `attachments` 中存在对应落库结果。
- 报告生成后，`reports` 中存在对应范围的正式报告。
