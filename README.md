# AI 健康病例助手

## 项目简介

AI 健康病例助手是一个单人开发的移动端 MVP 项目。  
项目目标是在 Android 真机上尽快做出可演示版本，用于作品展示、面试和学习 AI 辅助开发。

应用面向重视健康的普通用户，帮助用户通过文字、图片、语音等方式记录健康信息，并通过 AI 将输入整理为结构化事件，再生成周期性健康报告。

## 项目目标

当前阶段的目标不是商业化，而是尽快跑通一个可演示闭环：

1. 录入健康信息
2. 结构化整理输入
3. 本地保存记录与附件
4. 浏览历史记录
5. 生成周报 / 月报 / 季报

## 当前阶段

- 已完成基础环境配置
- 已完成 Flutter 项目初始化
- 已进入正式开发阶段
- 已建立 AI 协作文档体系
- 当前重点是稳定目录、契约、文档同步机制与 AI 协作边界，降低后续开发漂移

## 技术栈概览

- Flutter
- Dart
- Riverpod
- go_router
- Dio
- freezed / json_serializable
- Drift（优先）
- 本地图片存储
- WorkManager
- 极薄 AI API 代理

## 目录概览

以下为推荐结构概览，实际以仓库当前代码为准：

- `lib/app/`：应用启动、路由、主题、全局装配
- `lib/core/`：通用基础能力，如网络、存储、错误、工具
- `lib/features/`：按功能划分的业务模块
- `lib/shared/`：跨模块复用的 UI 与 Provider
- `docs/`：项目文档
- `scripts/`：本地辅助脚本
- `AGENTS.md`：AI 协作入口
- `README.md`：项目入口说明

## 如何运行项目

### 环境要求

- 已安装 Flutter
- 已安装 Android Studio / Android SDK / ADB
- 已安装 FVM
- 已连接 Android 14 真机或已创建模拟器

### 运行步骤

1. 安装依赖

`fvm flutter pub get`

2. 生成代码（如项目已使用 freezed / json_serializable / drift）

`fvm flutter pub run build_runner build --delete-conflicting-outputs`

3. 启动应用

`fvm flutter run`

### 说明

- 项目默认使用 FVM 固定 Flutter 版本。
- 本地数据库、图片附件、环境变量等本地文件不应提交到 Git。
- 若 AI 代理未配置完成，相关功能应允许以 mock / 占位方式运行，而不影响基础页面演示。

## 当前已实现内容

当前仓库重点处于“工程规范与协作约束”阶段，通常包括：

- Flutter 基础工程已初始化
- 目录结构已编排
- Android 真机开发环境已可用
- AI 执行层与人类存档层文档已建立
- 文档同步矩阵已建立
- 文档同步检查脚本已加入

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

- `scripts/check_doc_sync.py`：检查本次代码改动是否需要同步更新文档，并给出建议文档列表
- `scripts/run_doc_sync_check.bat`：Windows 下运行文档同步检查脚本的快捷入口

## 当前已确定的核心原则

- 离线优先
- 薄后端
- 本地结构化数据优先
- AI 输出 JSON 化
- 先做可演示 MVP，再逐步增强

## 后续计划概览

1. 固化核心数据模型
2. 固化 AI 接口契约
3. 建立 MVP 页面路由
4. 跑通“录入 → 结构化 → 保存 → 浏览 → 报告”闭环
5. 再逐步补充异常处理、后台任务、就医前摘要等增强能力
