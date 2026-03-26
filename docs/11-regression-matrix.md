# 回归矩阵

| 场景 / 模块 | 默认自动化 | 追加验证 | 触发条件 | 备注 / 剩余风险 |
|---|---|---|---|---|
| monorepo 结构与入口 | 根目录两个 Python 校验 | 无 | 根目录 README / AGENTS / docs / scripts / contracts 变化 | 先守住 workspace 入口与路径口径 |
| 新增记录纯文本主链路 | `cd apps/ai_case_assistant && fvm flutter test` | 视情况补真实 AI 自动化 | `/records/new` UI、提交、路由、`/ai/intake` 变化 | 不选图片时默认不要求真机 |
| 追问页与会话恢复 | `cd apps/ai_case_assistant && fvm flutter test` | 视情况补真实 AI 自动化 | `/intake/:id` 页面、状态恢复、强制结束变化 | 需要关注同 session 更新原记录 |
| `/ai/intake` 契约与解析 | app 测试 + 根级契约脚本 | 真实 AI 自动化 | 请求体、响应解析、异常映射变化 | 默认以共享契约为准 |
| `/ai/report` 契约与生成 | app 测试 + 根级契约脚本 | 真实 AI 自动化 | 报告请求、解析、配置变化 | 关注 `advice` 结构稳定性 |
| gateway 路由与 retired 端点 | `cd services/ai_gateway && npm test` | `npm run test:live` / smoke | `services/ai_gateway/src/**`、路由或部署配置变化 | `/ai/extract` 应继续返回 `404` |
| 正式记录删除 | `cd apps/ai_case_assistant && fvm flutter test` | 模拟器 / 真机按需 | 列表、详情、删除、linked session 变化 | 需确认软删除后入口收敛 |
| 图片选择与附件链路 | app 自动化部分覆盖 | Android 真机 | `image_picker`、附件复制、预览、本地文件路径变化 | 真机仍是最高优先级 |
