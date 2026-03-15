# AI 健康病例助手

## 项目简介

AI 健康病例助手是一个以 Android 演示为主的移动端 MVP 项目。
项目目标是做出一个可以真实跑通的“健康记录 + AI 整理 + 报告生成”闭环，用于作品展示、面试讲解和 AI 协作开发实践。

当前版本已经不是单纯的工程骨架，而是具备以下真实链路：

1. 输入原始描述
2. 可选选择多张图片
3. 调用 AI 提取摘要与备注
4. 本地保存健康记录与附件
5. 浏览记录列表与详情
6. 生成并查看周报 / 月报 / 季报

## 当前已实现内容

### 页面与路由

- 首页 `/`
- 健康记录列表 `/records`
- 新增记录 `/records/new`
- 健康记录详情 `/records/:id`
- 报告列表 `/reports`
- 报告详情 `/reports/:id`

### 健康记录能力

- 文本录入健康信息
- 从相册选择多张图片
- 图片缩略图预览
- 提交前调用 AI 提取 `symptomSummary` 和 `notes`
- 本地保存健康记录到 Drift
- 将图片复制到应用私有目录
- 详情页回显附件，并支持点击放大查看

### 报告能力

- 手动切换并生成 `week`、`month`、`quarter`
- 生成结果落库到本地 `reports` 表
- 同一时间范围重复生成时按覆盖更新处理
- 报告详情页展示标题、摘要、建议和 Markdown 原文

### AI 能力

- `POST /ai/extract`
- `POST /ai/report`
- `USE_MOCK_AI_EXTRACT=true` 时可切换到本地 mock 提取实现

## 当前未实现内容

以下能力仍未落地：

- AI 追问页与追问会话落库
- 独立提取结果表
- 记录编辑 / 删除
- 语音输入
- OCR 或图片内容提取
- 设置页
- 云同步
- 账号体系

## 技术栈概览

### 当前实际使用

- Flutter
- Dart
- Riverpod
- go_router
- Dio
- Drift
- image_picker
- path_provider / path
- uuid
- intl

### 当前用于代码生成

- build_runner
- drift_dev

### 已引入但暂未在业务代码中使用

- freezed / json_serializable

## 目录概览

- `lib/app/`：应用入口、路由、首页
- `lib/core/`：配置、Dio、Drift 数据库入口
- `lib/features/ai/`：AI 接口、异常、mock / remote 实现
- `lib/features/health_record/`：记录表、附件存储、记录页面与 Provider
- `lib/features/report/`：报告表、报告页面与 Provider
- `docs/`：项目文档
- `scripts/`：文档同步检查脚本
- `test/`：测试
- `AGENTS.md`：AI 协作入口

## 如何运行项目

### 环境要求

- 已安装 Flutter
- 已安装 Android Studio / Android SDK / ADB
- 已安装 FVM
- 已连接 Android 真机或已创建模拟器

### 运行步骤

1. 安装依赖

```bash
fvm flutter pub get
```

2. 生成 Drift 代码

```bash
fvm flutter pub run build_runner build --delete-conflicting-outputs
```

3. 启动应用

```bash
fvm flutter run
```

### 常用可选参数

指定 AI 代理地址：

```bash
fvm flutter run --dart-define=AI_API_BASE_URL=https://your-worker.example.com
```

使用本地 mock 提取：

```bash
fvm flutter run --dart-define=USE_MOCK_AI_EXTRACT=true
```

运行真实 AI 接口集成测试：

```bash
fvm flutter test test/features/ai/real_ai_api_test.dart --dart-define=RUN_REAL_AI_API_TESTS=true --dart-define=AI_API_BASE_URL=https://your-worker.example.com
```

## 当前实现细节说明

- 首页当前仍是静态入口页，不展示最近记录摘要。
- 新增记录时，AI 提取当前只提交 `rawText`，图片不会传给 AI。
- `HealthEvent.sourceType` 当前统一保存为 `text`。
- 报告详情页当前直接显示 Markdown 原文，没有 Markdown 富渲染。
- 当前仅有基础首页 widget smoke test，测试覆盖仍在补充中。

## 核心文档入口

### 面向 AI 协作

- `AGENTS.md`
- `docs/product_facts.md`
- `docs/product_notes.md`
- `docs/architecture.md`
- `docs/architecture_notes.md`
- `docs/conventions.md`
- `docs/workflow.md`
- `docs/contracts.md`
- `docs/acceptance.md`
- `docs/doc_sync_matrix.md`

### 面向人类阅读

- `README.md`
- `docs/project_overview.md`

## 脚本入口

- `scripts/check_doc_sync.py`：检查代码改动是否需要同步更新文档，并给出建议文档列表
- `scripts/run_doc_sync_check.bat`：Windows 下运行文档同步检查脚本的快捷入口

## 当前已确定的核心原则

- 离线优先保存本地数据
- AI 只做辅助整理，不做诊断
- 先做可演示 MVP，再逐步增强
- 当前以真实可运行闭环优先，不急于补齐所有抽象层

## 后续计划概览

1. 让首页承载更多真实数据概览
2. 补充记录编辑 / 删除与更完整的附件管理
3. 继续收敛健康记录和报告模块的服务边界
4. 补 AI 追问和更细粒度结构化结果
5. 增加测试覆盖与更多异常场景验证
