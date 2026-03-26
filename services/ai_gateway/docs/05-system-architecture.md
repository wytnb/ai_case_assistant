# 系统架构

## 架构目标

- 维持单 Worker、同步调用 DeepSeek 的最小实现
- 对外只暴露必要且稳定的 HTTP JSON 契约
- 将症状摘要格式化收敛在 Worker 内部，而不是暴露独立提取端点
- 保持 intake 无状态，避免引入服务端会话存储

## 模块划分

- 路由与统一错误响应：处理 `OPTIONS`、端点分发、未知路径与统一错误结构
- `/ai/intake` 输入校验：校验 `followUpMode`、`forceFinalize`、`eventTime`、`messages`
- `/ai/intake` 上游交互：构造 prompt、调用 DeepSeek、校验上游 payload
- `/ai/intake` 草稿组装：合并 `user` 消息、本地格式化 `symptomSummary`、执行严格重试与本地兜底
- `/ai/report` 输入校验：校验 `reportType`、范围字段、`events[]`
- `/ai/report` 报告生成：空事件直接本地返回，非空事件调用 DeepSeek 并校验结果

## 依赖关系

- Worker 路由层依赖统一 JSON/错误响应工具
- `/ai/intake` 与 `/ai/report` 共享 DeepSeek 请求封装与模型选择逻辑
- `/ai/intake` 依赖时间归一化、结构化症状校验、摘要格式化、本地兜底推断
- `/ai/report` 依赖请求校验、业务正文长度统计与上游报告结果校验
- 文档中的业务事实以 `docs/` 为 source of truth，执行规则由 `AGENTS.md` 约束

## 关键时序

### intake 链路

1. 调用方提交 `followUpMode`、`forceFinalize`、`eventTime`、`messages`
2. Worker 校验请求并生成 `mergedRawText`
3. Worker 调用 DeepSeek，要求返回 `status`、`question`、`symptoms`、`notes`、`actionAdvice`
4. 如果上游把明显可读的非空 `mergedRawText` 误提取成空 `symptoms` 和空 `notes`，Worker 会先严格重试一次
5. Worker 本地校验 `symptoms`，并格式化 `draft.symptomSummary`；若严格重试后仍是双空，则按本地兜底规则回填
6. Worker 根据 `followUpMode` / `forceFinalize` 决定最终对外状态

### report 链路

1. 调用方提交 `reportType`、时间范围与 `events[]`
2. Worker 校验 `events[]` 与业务正文长度
3. 若 `events` 为空，直接返回本地空报告
4. 若 `events` 非空，调用 DeepSeek
5. Worker 校验结果并返回

## 外部依赖

- DeepSeek `chat/completions`
- Cloudflare Workers 运行时
- Wrangler 4 本地开发与部署工具链

## 技术约束

- `/ai/intake` 保持无状态；Worker 不保存会话，客户端必须每轮传完整消息历史
- `draft.symptomSummary` 由 Worker 本地统一格式化
- 对明显可读但被上游提取成双空的 intake 文本，Worker 负责做最后兜底，避免把非空输入稳定返回为空草稿
- `DEEPSEEK_MODEL` 若配置为非 chat 模型，Worker 自动回退到 `deepseek-chat`
- 旧公开 `/ai/extract` 端点已退场；相关能力只作为内部实现细节存在

## 风险与取舍

- intake 的追问质量仍受模型行为影响
- 症状结构化能力仍依赖上游返回的 `symptoms`
- 下线 `/ai/extract` 后，外部调用方若未迁移，会直接收到 `404 NOT_FOUND`
- 当前没有服务端持久化与幂等去重，调用方需要自行承担会话和重试策略
