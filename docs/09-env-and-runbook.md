# 环境与运行手册

## 环境清单

- workspace 根目录：运行文档 / 契约 / 一致性校验脚本
- Flutter app：`apps/ai_case_assistant/`
- AI gateway：`services/ai_gateway/`
- 测试环境：当前没有独立测试服或预发环境

## 配置项

### app 侧

| 配置项 | 环境 | 是否必填 | 作用 | 备注 |
|---|---|---|---|---|
| `AI_API_BASE_URL` | run / test | 否 | AI gateway 基础地址 | 默认值为 `https://ai-api-worker.wytai.workers.dev` |
| `RUN_REAL_AI_API_TESTS` | test | 否 | 开启真实 AI 集成测试 | 默认 `false` |

### gateway 侧

gateway 自身运行所需的 `.dev.vars`、`DEEPSEEK_API_KEY`、`DEEPSEEK_MODEL` 统一见 `services/ai_gateway/docs/09-env-and-runbook.md`。

## 本地启动

### 启动 Flutter app

在 `apps/ai_case_assistant/` 下执行：

```bash
cd apps/ai_case_assistant
fvm flutter pub get
fvm flutter run
```

预期结果：

- Flutter 依赖安装完成
- App 成功启动到首页

### 启动 AI gateway

在 `services/ai_gateway/` 下执行：

```bash
cd services/ai_gateway
npm install
npm run dev
```

预期结果：

- Worker 本地开发服务启动
- `/ai/intake` 与 `/ai/report` 可供联调

## 常用验证命令

### 根目录执行

```bash
python scripts/check_doc_sync.py --working-tree --no-strict
python scripts/verify/check_ai_contract_sync.py
```

### app 目录执行

```bash
cd apps/ai_case_assistant
fvm flutter analyze
fvm flutter test
```

真实 AI 自动化：

```bash
cd apps/ai_case_assistant
fvm flutter test test/features/ai/real_ai_api_test.dart --dart-define=RUN_REAL_AI_API_TESTS=true --dart-define=AI_API_BASE_URL=https://ai-api-worker.wytai.workers.dev
```

### gateway 目录执行

```bash
cd services/ai_gateway
npm test
```

## 验证分层入口

### 第一层：workspace 一致性检查

在根目录执行：

- `python scripts/check_doc_sync.py --working-tree --no-strict`
- `python scripts/verify/check_ai_contract_sync.py`

适用场景：

- 文档、契约、目录结构、规则文件改动
- 跨 app + gateway 的接口同步任务

### 第二层：app 默认快速验证

在 `apps/ai_case_assistant/` 下执行：

- `fvm flutter analyze`
- `fvm flutter test`

适用场景：

- 绝大多数 app 代码改动
- 页面、Provider、数据库、本地附件逻辑改动

### 第三层：真实 AI 自动化

在 `apps/ai_case_assistant/` 下执行显式开启项：

- `fvm flutter test test/features/ai/real_ai_api_test.dart --dart-define=RUN_REAL_AI_API_TESTS=true --dart-define=AI_API_BASE_URL=<gateway-url>`

触发条件：

- `/ai/intake`、`/ai/report` 请求体或响应解析变化
- `core/network/`、`core/config/`、`features/intake/`、`features/ai/` 变化

### 第四层：gateway 自动化 / live / smoke

具体触发条件见 `services/ai_gateway/docs/10-testing-strategy.md`。

## 当前主链路说明

- 新增记录默认调用 `/ai/intake`
- 报告生成调用 `/ai/report`
- `/ai/extract` 已从 app 当前实现退场，只保留 gateway retired `404` 回归

## 发布前最小验证建议

1. 根目录执行 `python scripts/check_doc_sync.py --working-tree --no-strict`
2. 根目录执行 `python scripts/verify/check_ai_contract_sync.py`
3. `cd apps/ai_case_assistant && fvm flutter analyze`
4. `cd apps/ai_case_assistant && fvm flutter test`
5. 若改动涉及 app AI 主链路，评估真实 AI 自动化
6. 若改动涉及 gateway 运行时代码或部署配置，按服务侧闭环追加 `npm test`、`npm run test:live`、`npm run deploy` 与 smoke

## 当前平台与标识事实

- FVM 版本锁定在 `3.41.4`
- Android `applicationId` 当前仍为 `com.example.ai_case_assistant`
- iOS / macOS bundle id 当前仍为 `com.example.aiCaseAssistant`

## 常见故障

- 从仓库根目录直接执行 `fvm flutter ...`
  - 现已不再适用；请先进入 `apps/ai_case_assistant/`
- Drift 生成代码缺失或过期
  - 进入 `apps/ai_case_assistant/` 后重新执行 `build_runner`
- AI gateway 不可达
  - 检查 `AI_API_BASE_URL` 与网络状态
- gateway 本地调试缺少凭据
  - 检查 `services/ai_gateway/.dev.vars` 是否存在且不含占位值

## 排查顺序

1. 确认当前命令是否在正确目录执行
2. 确认 app 与 gateway 依赖已安装
3. 确认共享契约与实现一致
4. 确认 `AI_API_BASE_URL` 可访问
5. 若是 app 主链路问题，先跑 app 自动化
6. 若是 gateway 问题，再按服务侧测试策略执行
