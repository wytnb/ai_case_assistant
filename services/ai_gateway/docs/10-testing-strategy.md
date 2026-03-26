# 测试策略

## 测试目标

- 保障 `/ai/intake` 的开关、消息历史、时间锚点与草稿结构稳定
- 保障 `/ai/report` 的输入校验、报告输出结构与空报告分支稳定
- 保障 retired `/ai/extract`、未知路径与非法方法维持既定路由行为
- 保障 prompt、上游 payload 校验、本地格式化与兜底逻辑不回退

## 测试层定义

- 本地自动化测试：`npm test`
- live 测试：`npm run test:live`
- 线上 smoke：按 `docs/12-release-smoke-checklist.md`

## 按任务类型的测试要求

### 接口契约变化

- 更新契约单测
- 更新 `docs/06-api-contracts.md`
- 更新根级 `../../contracts/health-record-ai.openapi.json`
- 若触发强制闭环，`npm run test:live` 与线上 smoke 为必跑项

### intake 相关改动

- 覆盖 `/ai/intake` 的 `followUpMode` / `forceFinalize` / `eventTime` / `messages` 校验
- 覆盖 `/ai/intake` 的 `needs_followup` / `final` 分支
- 覆盖 `/ai/intake.draft.mergedRawText` 与 `draft.symptomSummary` 的格式稳定性
- 覆盖 intake prompt 自包含规则、严格重试与本地兜底逻辑

### report 相关改动

- 覆盖 `/ai/report` 输入校验
- 覆盖空报告分支
- 覆盖 `advice` 的完整句校验
- 覆盖旧字段 `eventStartTime` / `eventEndTime` 的失败路径

### 端点退场 / 路由变更

- 覆盖被移除端点的 `404` 回归
- 覆盖已知路径非 `POST` 的 `404`
- 覆盖全局 `OPTIONS` 的 `204`

## 当前覆盖现状

- `test/index.spec.ts`
  - 使用 mock DeepSeek 响应校验 `/ai/intake`、`/ai/report` 的 prompt、payload、格式化、兜底与输入校验
  - 覆盖 retired `/ai/extract`、未知路径、非法方法与长度边界
- `test/index.live.spec.ts`
  - 使用真实 `DEEPSEEK_API_KEY` 对 `/ai/intake`、`/ai/report` 做 live 集成验证
  - 覆盖 retired `/ai/extract` 的真实路由行为

## 边界测试要求

- `/ai/intake` 需要覆盖 `6000` 字通过与 `6001` 字失败
- `/ai/report` 需要覆盖 `10000` 字通过与 `10001` 字失败
- `/ai/intake.draft.symptomSummary` 需要覆盖单侧区间、未知时间、多行展示
- `/ai/intake` 需要覆盖 `followUpMode=false` 与 `forceFinalize=true` 的强制收口
- `/ai/report` 需要覆盖 `events=[]` 的本地空报告

## 回归测试要求

- 新功能至少补 happy path、1 个边界场景、1 个失败场景
- bug 修复要补或更新回归测试，确保修复前会失败
- 契约变化要补或更新集成测试
- 退场端点、错误结构、提示词自包含规则属于高风险回归点，不能只靠人工记忆验证

## 测试数据策略

- 本地自动化测试优先使用 mock DeepSeek 响应，稳定校验请求 payload 与 Worker 本地逻辑
- live 测试使用真实 `DEEPSEEK_API_KEY`，用于观察上游模型实际行为与契约符合度
- smoke 请求体优先使用可直接复现契约和中文输入场景的最小数据集

## 阻塞处理规则

- 若本轮仅改人类阅读文档，不触发强制测试与部署闭环
- 若本轮改动包含 `src/**` 或线上运行配置，必须按顺序执行 `npm test`、`npm run test:live`、`npm run deploy`、线上 smoke
- 若任一必跑项因凭据、环境或发布条件缺失无法执行，必须在最终汇报中明确未执行项与阻塞原因，且任务不得标记“完成”

## 通过标准

- 代码改动对应的本地自动化测试全部通过
- 触发强制闭环时，`npm test`、`npm run test:live`、`npm run deploy` 与 smoke 全部完成
- 文档、测试、实现口径一致
