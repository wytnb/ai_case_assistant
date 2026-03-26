# 回归矩阵

| 功能/模块 | 改动触发条件 | 必补自动化测试 | 必跑本地命令 | Live / 线上验证 | 备注 / 风险 |
| --- | --- | --- | --- | --- | --- |
| `/ai/intake` 输入校验 | 修改开关字段、`messages`、长度上限、`eventTime` 校验 | 缺 `followUpMode`、缺 `forceFinalize`、非法 `eventTime`、空 `messages`、`6000` 字通过、`6001` 字失败 | `npm test` | 优先 `npm run test:live`；已部署时补 intake smoke | 这是当前主要公开契约面 |
| `/ai/intake` 上游 payload 与状态控制 | 修改 intake prompt、payload 校验、`needs_followup/final` 逻辑、强制收口规则 | `needs_followup` 多行问题、`followUpMode=false` 强制 final、`forceFinalize=true` 强制 final、缺 `status/question/symptoms/notes/actionAdvice`、非法 symptom item | `npm test` | 优先 `npm run test:live`；已部署时补 intake smoke | 追问质量和状态控制都受模型影响 |
| `/ai/intake` 草稿组装与摘要格式化 | 修改 `mergedRawText`、`symptomSummary` 格式化逻辑、`actionAdvice` 字段、本地双空兜底 | 只合并 user 消息、单侧区间占位、未知时间、摘要文本稳定性、双空重试后本地兜底 | `npm test` | 优先 `npm run test:live` | 这是用户最直接感知的输出 |
| `/ai/report` 输入与输出校验 | 修改 `events[]`、长度上限、空报告分支、`advice` 结构 | `10000` 字通过、`10001` 字失败、空报告、空白 advice、非字符串 advice、旧字段失败 | `npm test` | 任务影响真实上游时优先 `npm run test:live`；已部署时补 report smoke | 报告生成会直接影响用户展示 |
| 退场端点与路由 | 删除或新增公开端点、调整路径处理规则 | 被移除端点 `404`、未知路径 `404`、已知路径非 `POST` 的 `404` | `npm test` | 已部署时补 smoke | 旧调用方可能仍会访问已退场端点 |
