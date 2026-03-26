# AI 健康病例助手 Monorepo

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
