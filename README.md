# AI 健康病例助手 Monorepo

## APK 包位置指引

- 当前根目录交付文件：`ai_case_assistant-release.apk`
- 当前工作区中的绝对路径：`C:\files\AI\ai_case_assistant\ai_case_assistant-release.apk`
- Flutter 原始构建输出仍位于：`apps/ai_case_assistant/build/app/outputs/flutter-apk/app-release.apk`
- 如需重新打包：进入 `apps/ai_case_assistant/` 后执行 `fvm flutter build apk --release`，再将产物同步到仓库根目录

## 背景
AI 健康病例助手是一个面向个人健康记录整理场景的 Flutter 客户端项目。 当前仓库的核心目标不是做成完整医疗平台，而是交付一个可真实演示、可保存本地数据、可接入 AI 整理与报告生成的 MVP。

## 当前痛点主要来自三个方面：
- 健康相关信息分散在文本、相册和零碎记忆里，后续难以回顾
- 用户在就医前往往记不清近期症状、持续时间和变化过程
- 只有原始文本或图片时，不便于按时间线整理和汇总

## 目标用户
- 重视个人健康管理的普通用户
- 需要持续记录症状、检查结果、就诊线索和图片材料的人
- 希望在就医前快速整理近期健康信息的人
- 当前仓库不是为医院、医生工作站、保险理赔或科研统计场景设计。

## 目标问题
- 让用户能够低门槛记录健康相关原始输入
- 让系统把原始输入整理成可回顾的结构化健康事件
- 让用户能够按时间范围生成周期性总结，而不是只保留孤立记录

## 核心价值
- 对用户的价值：减少健康信息散落与回忆成本，提升回顾效率
- 对项目的价值：提供一个本地优先、AI 协作、Flutter MVP 的完整示例仓库

## APP业务介绍：

当前仓库已经收敛为一个单一 git 仓库管理的 monorepo。

- Flutter 客户端位于 `apps/ai_case_assistant/`
- AI gateway 位于 `services/ai_gateway/`
- 根目录承载 workspace 级文档、规则、脚本与共享契约

## 仓库结构

```text
.
|-- apps/
|   `-- ai_case_assistant/     # Flutter 客户端
|-- contracts/                 # app 与 gateway 共享契约
|-- docs/                      # monorepo / app / workspace 文档
|-- scripts/                   # workspace 级校验脚本
|-- services/
|   `-- ai_gateway/            # AI gateway
|-- AGENTS.md                  # monorepo 根级执行规则
`-- README.md                  # monorepo 根级入口
```

## 当前 AI 能力

- app 新增记录主链路默认走 `POST /ai/intake`
- app 报告生成走 `POST /ai/report`
- `POST /ai/extract` 已从 app 当前实现退场，只保留 gateway 侧 retired `404` 回归
- 共享 HTTP 契约以 [contracts/health-record-ai.openapi.json](./contracts/health-record-ai.openapi.json) 为准

## 阅读顺序

1. [README.md](./README.md)
2. [AGENTS.md](./AGENTS.md)
3. [docs/00-index.md](./docs/00-index.md)
4. [docs/15-monorepo-workspace.md](./docs/15-monorepo-workspace.md)
5. 若任务涉及 gateway，再读 [services/ai_gateway/README.md](./services/ai_gateway/README.md) 与 [services/ai_gateway/AGENTS.md](./services/ai_gateway/AGENTS.md)

## 快速开始

### 运行 Flutter app

在 `apps/ai_case_assistant/` 下执行：

```bash
cd apps/ai_case_assistant
fvm flutter pub get
fvm flutter run
```

预期结果：

- Flutter 依赖安装完成
- App 成功启动到首页

### 运行 AI gateway

在 `services/ai_gateway/` 下执行：

```bash
cd services/ai_gateway
npm install
npm run dev
```

预期结果：

- Worker 本地开发服务启动
- `/ai/intake` 与 `/ai/report` 可供本地联调

## 常用验证命令

### Workspace 级校验

在仓库根目录执行：

```bash
python scripts/check_doc_sync.py --working-tree --no-strict
python scripts/verify/check_ai_contract_sync.py
```

### Flutter app 校验

在 `apps/ai_case_assistant/` 下执行：

```bash
cd apps/ai_case_assistant
fvm flutter analyze
fvm flutter test
```

可选真实 AI 自动化：

```bash
cd apps/ai_case_assistant
fvm flutter test test/features/ai/real_ai_api_test.dart --dart-define=RUN_REAL_AI_API_TESTS=true --dart-define=AI_API_BASE_URL=https://case-assistant-gateway.wytai.workers.dev
```

### Gateway 校验

在 `services/ai_gateway/` 下执行：

```bash
cd services/ai_gateway
npm test
```

`npm run test:live`、`npm run deploy` 与线上 smoke 只在改动触发 gateway 运行时闭环时执行，详情见服务侧文档。

## 新增 AI 功能的默认修改顺序

1. 先更新共享契约 `contracts/health-record-ai.openapi.json`
2. 再同步 gateway 实现与 app 调用
3. 再同步根级 / 服务级文档
4. 最后补测试与一致性校验

## 相关入口

- [docs/00-index.md](./docs/00-index.md)：根级文档索引
- [docs/15-monorepo-workspace.md](./docs/15-monorepo-workspace.md)：workspace 结构、职责、协作顺序
- [docs/06-api-contracts.md](./docs/06-api-contracts.md)：根级契约解释
- [services/ai_gateway/docs/06-api-contracts.md](./services/ai_gateway/docs/06-api-contracts.md)：gateway 实现说明
