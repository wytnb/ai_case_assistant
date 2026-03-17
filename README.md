# AI 健康病例助手

## 项目简介

AI 健康病例助手是一个以 Android 演示为主的 Flutter 移动端 MVP 项目。
当前目标不是做成完整医疗产品，而是跑通一个真实可演示的闭环：

1. 输入健康相关原始描述
2. 可选选择多张图片附件
3. 调用 AI 提取摘要、备注和事件时间
4. 本地保存健康记录与附件
5. 浏览记录列表与详情
6. 生成并查看周报、月报、季报

仓库包含 Android、iOS、macOS、Linux、Windows、Web 的 Flutter 骨架，但当前文档和演示目标以 Android 本地使用场景为主。

## 当前实现状态

### 已落地能力

- 首页 `/`
- 健康记录列表 `/records`
- 新增健康记录 `/records/new`
- 健康记录详情 `/records/:id`
- 报告列表 `/reports`
- 报告详情 `/reports/:id`
- `POST /ai/extract`
- `POST /ai/report`
- Drift 本地数据库与附件本地复制

### 当前明确未落地

- 记录编辑 / 删除
- 附件删除
- AI 追问页与追问会话落库
- OCR / 图片内容提取
- 设置页
- 云同步
- 账号体系

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

- `freezed` 与 `json_serializable` 已在依赖中声明，但当前业务代码尚未实际使用。
- 当前没有 CI 配置，也没有正式发布流水线。

## 快速启动

### 前置要求

- 已安装 Flutter 与 FVM
- 已安装 Android Studio / Android SDK / ADB
- 需要演示真机或模拟器时，已连接设备

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

文档同步检查脚本：

```bash
python scripts/check_doc_sync.py --working-tree --no-strict
```

说明：

- 真实 AI 集成测试默认跳过，只有显式传入 `RUN_REAL_AI_API_TESTS=true` 才会运行。
- 当前 FVM 命令在本地会输出 `Can't load Kernel binary: Invalid SDK hash.` 警告，但 `flutter analyze` 与 `flutter test` 仍可完成。

## 仓库结构

- `lib/app/`：应用入口、主题装配、路由、首页
- `lib/core/`：配置、Dio、Drift 数据库
- `lib/features/ai/`：AI 接口、异常、mock / remote 实现
- `lib/features/health_record/`：记录创建、列表、详情、附件本地存储
- `lib/features/report/`：报告生成、列表、详情
- `test/`：当前自动化测试主目录
- `docs/`：项目事实文档
- `scripts/`：文档同步与后续验证脚本入口

## 文档入口

建议阅读顺序：

1. [AGENTS.md](/c:/files/VibeCoding/ai_case_assistant/AGENTS.md)
2. [docs/00-index.md](/c:/files/VibeCoding/ai_case_assistant/docs/00-index.md)
3. [docs/docs-policy.md](/c:/files/VibeCoding/ai_case_assistant/docs/docs-policy.md)
4. 与当前任务相关的编号文档

文档模板、完整清单、示例和新增文档判定规则统一见 `docs/docs-policy.md`。

高频文档：

- [docs/01-overview.md](/c:/files/VibeCoding/ai_case_assistant/docs/01-overview.md)
- [docs/02-scope-and-nongoals.md](/c:/files/VibeCoding/ai_case_assistant/docs/02-scope-and-nongoals.md)
- [docs/03-business-flows.md](/c:/files/VibeCoding/ai_case_assistant/docs/03-business-flows.md)
- [docs/05-system-architecture.md](/c:/files/VibeCoding/ai_case_assistant/docs/05-system-architecture.md)
- [docs/09-env-and-runbook.md](/c:/files/VibeCoding/ai_case_assistant/docs/09-env-and-runbook.md)
- [docs/10-testing-strategy.md](/c:/files/VibeCoding/ai_case_assistant/docs/10-testing-strategy.md)

## 当前已知限制

- 数据仅保存在本地数据库和应用私有目录，换机或卸载会丢失。
- AI 提取和报告生成依赖网络；无网络时只能查看已有本地数据。
- 首页当前只有入口，不展示最近记录或统计摘要。
- `HealthEvent.sourceType` 当前统一写为 `text`。
- 图片附件会本地保存，但当前不会参与 AI 提取。
- 报告详情展示 Markdown 原文，没有富渲染。
- Android `applicationId`、iOS/macOS bundle id、Web manifest 描述仍保留默认占位值，尚未做产品化整理。

## 相关支持目录

- `.cursor/rules/`：Cursor 规则文件
- `scripts/verify/`：固定验证脚本的预留目录
- `tests/regression/`：后续专项回归用例的预留目录
