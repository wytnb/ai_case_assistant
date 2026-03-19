# AI 健康病例助手

## 项目简介

AI 健康病例助手是一个以 Flutter 客户端为中心的本地优先 MVP。当前主目标不是做成完整医疗系统，而是跑通一条可演示、可验证的健康记录闭环：

1. 用户输入初始健康描述，可选附带图片附件。
2. 新增记录默认调用 `POST /ai/intake`。
3. 当开启“追问模式”时，客户端在本地 Drift 中保存追问会话、消息历史和会话暂存附件。
4. AI 可返回继续追问或直接完成；完成后再生成正式健康记录。
5. 正式记录与未完成追问草稿严格分离存储。
6. 客户端可查看记录列表、详情和周期报告。

仓库包含 Android、iOS、macOS、Linux、Windows、Web 的 Flutter 骨架，但当前文档和验证重点仍以 Android 本地使用场景为主。

## 当前实现状态

### 已落地能力

- 首页 `/`
  - 提供“追问模式”开关，并通过本地 `app_settings` 持久化。
- 健康记录列表 `/records`
  - 顶部显示未完成追问分区。
  - 下方显示正式健康记录列表。
- 新增健康记录 `/records/new`
  - 默认走 `POST /ai/intake`。
  - 可根据 AI 返回直接生成正式记录，或进入追问页。
- 追问页 `/intake/:id`
  - 展示消息历史、当前问题、继续补充输入框、发送按钮、强制结束按钮。
- 健康记录详情 `/records/:id`
  - 展示 `rawText`、`symptomSummary`、`notes`、`actionAdvice`、附件。
  - 对已关联 intake session 的正式记录提供“继续补充并重新追问”入口。
- 报告 `/reports`、`/reports/:id`
  - 仍基于正式 `health_events` 生成，不带入未完成追问草稿。
- AI 接口
  - `POST /ai/intake`
  - `POST /ai/extract`
  - `POST /ai/report`

### 当前明确未落地

- 账号体系
- 云同步
- 服务端会话存储
- OCR / 图片内容提取
- 复杂医学结构化 schema
- 记录编辑 / 删除
- 追问页内新增附件

## 本次关键规则

- 追问会话状态只保存在客户端 Drift，不放到 worker。
- 正式记录与未完成追问草稿分离存储；未完成会话不能污染正式记录列表和报告。
- 新增记录默认调用 `/ai/intake`，旧 `/ai/extract` 保留但不再是默认新增链路。
- `symptomSummary` 只要字段存在且类型为字符串，就原样保留；允许空字符串，不做首句 fallback，不做内容纠偏。
- `notes`、`actionAdvice`、`mergedRawText`、`symptomSummary` 在入库前只做外层 `trim()`；`trim()` 后即使为空字符串也保留为空字符串。

## 技术栈

- Flutter 3.41.4 via FVM
- Dart 3.11.1
- Material 3
- Riverpod
- go_router
- Dio
- Drift
- image_picker
- path_provider / path
- uuid
- intl

补充说明：

- `freezed` 与 `json_serializable` 仍在依赖中声明，但当前业务代码未采用。
- 当前没有 CI 配置，也没有正式发布流水线。

## 快速启动

### 前置要求

- 已安装 Flutter 与 FVM
- 已安装 Android Studio / Android SDK / ADB
- 需要演示真机或模拟器时，设备已可正常连接

### 常用命令

安装依赖：

```bash
fvm flutter pub get
```

生成 Drift 代码：

```bash
fvm flutter pub run build_runner build --delete-conflicting-outputs
```

启动应用：

```bash
fvm flutter run
```

指定 AI 代理地址：

```bash
fvm flutter run --dart-define=AI_API_BASE_URL=https://your-worker.example.com
```

使用本地 mock 提取服务：

```bash
fvm flutter run --dart-define=USE_MOCK_AI_EXTRACT=true
```

## 验证命令

静态检查：

```bash
fvm flutter analyze
```

默认自动化测试：

```bash
fvm flutter test
```

真实 AI 接口集成测试：

```bash
fvm flutter test test/features/ai/real_ai_api_test.dart --dart-define=RUN_REAL_AI_API_TESTS=true --dart-define=AI_API_BASE_URL=https://your-worker.example.com
```

文档同步检查：

```bash
python scripts/check_doc_sync.py --working-tree --no-strict
```

说明：

- 如果改动触及 `/ai/intake`、`/ai/extract`、`features/ai/`、`core/network/`、`AI_API_BASE_URL` 或主链路页面，应评估并尽量执行真实 AI 验证或手工 smoke。
- 当前本地 FVM 命令末尾可能输出 `Can't load Kernel binary: Invalid SDK hash.` 警告，但在本仓库里不阻塞 `flutter analyze` 与 `flutter test`。

## 仓库结构

- `lib/app/`：应用入口、主题、路由、首页
- `lib/core/`：配置、Dio、Drift 数据库、公共装配
- `lib/features/ai/`：`/ai/extract`、`/ai/report` 及相关异常与值对象
- `lib/features/intake/`：`/ai/intake`、追问状态机、追问页、会话持久化
- `lib/features/settings/`：设置项 Repository 与 Provider
- `lib/features/health_record/`：正式记录创建、列表、详情、附件转正存储
- `lib/features/report/`：报告生成、列表、详情
- `test/`：自动化测试
- `docs/`：项目事实文档
- `scripts/`：文档同步与后续验证脚本

## 文档入口

建议阅读顺序：

1. [AGENTS.md](/c:/files/VibeCoding/ai_case_assistant/AGENTS.md)
2. [docs/00-index.md](/c:/files/VibeCoding/ai_case_assistant/docs/00-index.md)
3. [docs/docs-policy.md](/c:/files/VibeCoding/ai_case_assistant/docs/docs-policy.md)
4. 与当前任务最相关的编号文档

高频文档：

- [docs/02-scope-and-nongoals.md](/c:/files/VibeCoding/ai_case_assistant/docs/02-scope-and-nongoals.md)
- [docs/03-business-flows.md](/c:/files/VibeCoding/ai_case_assistant/docs/03-business-flows.md)
- [docs/05-system-architecture.md](/c:/files/VibeCoding/ai_case_assistant/docs/05-system-architecture.md)
- [docs/06-api-contracts.md](/c:/files/VibeCoding/ai_case_assistant/docs/06-api-contracts.md)
- [docs/07-data-model.md](/c:/files/VibeCoding/ai_case_assistant/docs/07-data-model.md)
- [docs/10-testing-strategy.md](/c:/files/VibeCoding/ai_case_assistant/docs/10-testing-strategy.md)
- [docs/adr/ADR-0003-client-owned-intake-sessions-and-separated-draft-storage.md](/c:/files/VibeCoding/ai_case_assistant/docs/adr/ADR-0003-client-owned-intake-sessions-and-separated-draft-storage.md)

## 当前已知限制

- 数据只保存在本地数据库与应用私有目录；换机或卸载会丢失。
- AI 提取、追问和报告依赖网络；离线时只能查看已有本地数据。
- 首页当前只放主入口和追问模式开关，不显示最近记录摘要。
- 图片附件会跟随记录在本地保存，但当前不会参与 `/ai/intake` 或 `/ai/extract`。
- 只有通过 `/ai/intake` 创建的正式记录才会关联 intake session；旧 `/ai/extract` 历史记录没有重新追问入口。
