# 规则与边界情况

## 规则清单

| 编号 | 规则 | 优先级 |
|---|---|---|
| R-01 | `rawText.trim()` 必须非空，且长度不能超过 1000 | 高 |
| R-02 | 新增记录默认调用 `/ai/intake`，旧 `/ai/extract` 只保留兼容与回归用途 | 高 |
| R-03 | 追问模式开关通过 `SettingsRepository` 读写，不在页面里直接写 SQL | 高 |
| R-04 | 未完成追问草稿只能落 `intake_*` 表，不能污染正式记录与报告 | 高 |
| R-05 | `draft.symptomSummary` 只要字段存在且类型为字符串，就原样保留 | 高 |
| R-06 | 不对 `symptomSummary` 做首句 fallback、内容纠偏或自定义替换 | 高 |
| R-07 | `notes`、`actionAdvice`、`mergedRawText`、`symptomSummary` 入库前只做外层 `trim()` | 中 |
| R-08 | `trim()` 后即使为空字符串，也保留为空字符串，不转 `null` | 中 |
| R-09 | `questioning` 会话恢复时应自动重放本轮请求 | 中 |
| R-10 | 重新追问完成时必须更新原正式记录，而不是新建重复记录 | 高 |
| R-11 | 报告只能读取正式 `health_events`，不带入未完成 session | 高 |
| R-12 | 只有已关联 intake session 的正式记录才允许重新追问 | 中 |
| R-13 | 首次进入系统时必须完成免责勾选并同意，未同意前不能继续操作首页入口 | 高 |
| R-14 | 报告详情页末尾必须固定展示免责说明，不依赖报告内容是否完整 | 中 |

## 边界条件

- `/ai/intake` 返回 `draft.symptomSummary=""`
  - 预期：合法，保留空字符串。
- `/ai/intake` 缺失 `draft.symptomSummary`
  - 预期：`invalidResponsePayload`。
- `/ai/intake` 返回很短、很弱、表达一般的摘要
  - 预期：只要类型正确，就合法保留。
- `/ai/extract` 返回 `symptomSummary=""`
  - 预期：合法，保留空字符串。
- `/ai/extract` 缺失 `symptomSummary`
  - 预期：`invalidResponsePayload`。
- 首页没有 `follow_up_mode_enabled`
  - 预期：读取默认值 `false`。
- 首页没有 `first_use_disclaimer_accepted`
  - 预期：读取默认值 `false` 并触发首次免责弹窗。
- 存在多个未完成会话
  - 预期：都展示在 `/records` 顶部分区，按 `updatedAt` 倒序。
- 用户恢复到 `questioning` 会话
  - 预期：页面自动继续本轮请求，而不是卡在中间状态。
- 用户对已完成记录重新追问
  - 预期：更新原记录，保留原 `createdAt`。
- 报告详情页打开任意报告
  - 预期：页面末尾固定展示免责说明。

## 冲突处理

- “内容质量一般”与“payload 非法”冲突时，以结构合法性为准，不把内容质量问题判成非法响应。
- “首页当前开关值”与“历史会话快照值”冲突时，以 `followUpModeSnapshot` 还原历史会话上下文，不反写旧会话。
- “旧 `/ai/extract` 记录详情打开了”与“详情页提供重新追问入口”冲突时，以是否存在已关联 session 为准；没有关联 session 就不展示入口。

## 异常场景

- 网络异常导致 `/ai/intake` 失败
  - 页面提示错误
  - 当前会话与历史消息保留在本地
- 数据库写入失败
  - 本轮操作失败
  - 不把未完成草稿写入正式记录
- 首次免责同意写入失败
  - 弹窗保持打开
  - 用户不能继续操作首页入口
- 附件转正失败
  - 正式记录创建流程视为失败
  - 已完成的临时文件操作应尽量回滚
- 真实 AI 验证未执行
  - 最终汇报必须写明未执行原因与剩余风险

## 默认兜底行为

- 缺失设置 key 时，由仓库层返回默认值，不要求预插所有设置。
- 首页首次免责弹窗为强阻断：不可点空白关闭、不可返回关闭、未勾选同意时按钮不可点击。
- 详情页展示 `rawText`、`symptomSummary`、`notes`、`actionAdvice` 时：
  - `null` 或空字符串统一展示中性空状态文案
  - 不生成替代内容
- `/records` 顶部分区为空时，页面只显示正式记录区或空状态。
