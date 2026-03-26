# 范围与非目标

## 当前范围

- 对外提供两个公开业务端点：
  - `POST /ai/intake`
  - `POST /ai/report`
- 在 `/ai/intake` 中接收完整消息历史，并返回 `needs_followup` 或 `final`
- 在 `/ai/intake` 中使用调用方传入的 `eventTime` 作为相对时间锚点
- 在 `/ai/report` 中基于传入事件生成结构化报告
- 统一返回 JSON 成功响应与统一结构错误响应

## 当前不做

- 服务端持久化会话、草稿或历史记录
- 独立公开的 `/ai/extract` 提取端点
- 鉴权、租户隔离、速率限制
- 数据库、缓存、对象存储、队列
- 除 `/ai/intake`、`/ai/report` 之外的公开业务端点

## 版本边界

- `/ai/intake.messages[*].content` 的总长度必须控制在 `6000` 字以内
- `/ai/intake` 由客户端提交完整历史；Worker 不保存会话状态
- `/ai/intake.eventTime` 必须是带 `+08:00` 的 ISO 8601 字符串
- `/ai/report.events[]` 必须显式包含 `eventTime`、`rawText`、`symptomSummary`、`notes`
- `/ai/report` 的业务正文总长度上限为 `10000` 字

## 延期项 / 候选项

- 服务端会话管理
- 数据持久化与检索
- 更细的调用方鉴权
- 更复杂的报告模板与多模型路由

## 已知约束

- Cloudflare Worker 运行环境
- DeepSeek 同步调用
- 当前没有 CI/CD、数据库或外部存储
- 历史文档中仍会提到 `/ai/extract`，但它只作为已退场能力的背景记录存在
