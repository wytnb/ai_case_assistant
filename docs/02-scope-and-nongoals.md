# 范围与非目标

## 当前范围

当前 MVP 已纳入范围的能力如下：

- 根目录作为唯一 git 边界管理 app 与 gateway。
- Flutter 客户端位于 `apps/ai_case_assistant/`，gateway 位于 `services/ai_gateway/`。
- 首页提供主入口与“追问模式”开关。
- “追问模式”开关通过本地 `app_settings` 持久化，缺失设置时默认 `false`。
- 首次进入应用必须完成免责说明勾选与同意，未同意前不能继续使用首页。
- 新增记录默认走 `POST /ai/intake`，请求带 `followUpMode`、`forceFinalize`、`eventTime`、完整 `messages`。
- 用户可在新增记录页输入 `rawText` 并可选选择图片附件。
- 当 `followUpMode=false` 时，worker 应直接返回 `final`，客户端直接生成正式记录。
- 当 `followUpMode=true` 且 worker 返回 `needs_followup` 时，客户端本地创建 intake session、保存消息历史并跳转追问页。
- 用户可以继续追问、强制结束追问、退出 App 后恢复未完成会话、基于已关联 session 对正式记录重新追问。
- 正式记录与未完成追问草稿严格分离存储；未完成内容只落 `intake_*` 表，不进入 `health_events` 与报告查询。
- `/records` 使用“正式记录 / 草稿记录”双 tab 展示列表，并支持按 `eventTime` 日期范围筛选。
- 正式记录支持软删除；草稿记录支持硬删除。
- 正式记录详情页展示 `rawText`、`symptomSummary`、`notes`、`actionAdvice` 与附件。
- 报告页可生成 `week`、`month`、`quarter` 报告，且只基于正式 `health_events`。
- 根级 `contracts/health-record-ai.openapi.json` 作为 app 与 gateway 的共享 HTTP 契约。
- gateway 侧保留 retired `/ai/extract` -> `404` 回归，但它不再是 app 当前能力。

## 当前不做

- 账号登录、多用户、多档案
- 云同步、云端草稿、服务端会话存储
- OCR、图片内容提取、语音输入
- 自动诊断、在线问诊、医疗机构对接
- 通用化 AI gateway 平台改造
- 复杂医学结构化 schema
- 记录编辑
- 追问页内新增图片附件
- 报告富文本渲染增强

## 版本边界

### 当前 MVP

- Android 演示优先
- 单用户、本地优先
- AI 负责辅助追问、整理与汇总，不做最终医学诊断
- 主链路围绕“新增记录 -> 追问或完成 -> 浏览记录 -> 生成报告”
- monorepo 只做最小可行收口，不引入重型 workspace 工具

### 后续版本方向

以下方向在产品讨论中存在，但当前仓库未实现：

- 更完整的首页概览
- 记录编辑
- 更完整的附件管理
- 数据导出、备份、隐私保护增强
- 更精细的结构化健康字段

## 延期项 / 候选项

- 追问页补充上传新附件
- 报告详情富文本渲染
- 报告 mock 通道
- 独立的设置页

## 已知约束

### 技术约束

- 数据当前只保存在本地 Drift 与应用私有目录。
- AI 能力依赖 `services/ai_gateway/` 提供的 HTTP 接口。
- 图片附件不会直接参与 `/ai/intake` 或 `/ai/report` 请求体。
- 所有通过 `/ai/intake` 创建的正式记录都会保留并复用一个 intake session。
- 历史旧 `/ai/extract` 记录没有 intake session 关联。

### 运行约束

- 仓库有多平台骨架，但当前验证重点是 Android。
- 没有根级 workspace 工具链；运行方式依赖“进入对应目录执行命令”。
- 没有 CI、没有正式发布流水线、没有统一监控平台。

### 文档约束

- 历史需求变化没有完整回填记录。
- 无法从仓库直接确认的历史原因必须标记为“待确认”。
