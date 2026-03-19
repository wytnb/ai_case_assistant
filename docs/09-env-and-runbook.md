# 环境与运行手册

## 环境清单

- 本地开发：Flutter + FVM，本地运行、调试、测试
- 演示环境：Android 真机或模拟器，本地连接 AI worker
- 测试环境：当前没有独立测试服或预发环境
- 生产环境：当前没有正式 CI/CD 或生产发布流水线

## 配置项

| 配置项 | 环境 | 是否必填 | 作用 | 备注 |
|---|---|---|---|---|
| `AI_API_BASE_URL` | run / test | 否 | AI worker 基础地址 | 默认值为 `https://ai-api-worker.wytai.workers.dev` |
| `USE_MOCK_AI_EXTRACT` | run | 否 | 切换旧 `/ai/extract` 到本地 mock | 当前不影响默认新增记录主链路 |
| `RUN_REAL_AI_API_TESTS` | test | 否 | 开启真实 AI 集成测试 | 默认 `false` |

## 本地启动

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

## 常用验证命令

静态检查：

```bash
fvm flutter analyze
```

默认测试：

```bash
fvm flutter test
```

真实 AI 接口测试：

```bash
fvm flutter test test/features/ai/real_ai_api_test.dart --dart-define=RUN_REAL_AI_API_TESTS=true --dart-define=AI_API_BASE_URL=https://your-worker.example.com
```

文档同步检查：

```bash
python scripts/check_doc_sync.py --working-tree --no-strict
```

## 当前主链路说明

- 新增记录默认调用 `/ai/intake`。
- `/ai/extract` 仍保留，但主要用于旧链路兼容与回归测试。
- 首页“追问模式”只影响 `/ai/intake` 请求中的 `followUpMode`。
- 报告仍调用 `/ai/report`，且只读取正式 `health_events`。

## 发布前最小验证建议

1. `fvm flutter analyze`
2. `fvm flutter test`
3. 如触及 `/ai/intake`、`/ai/extract`、网络层、环境变量或主链路页面，评估并尽量执行真实 AI 测试
4. 在 Android 设备上跑一遍首页、`/records/new`、`/records`、`/intake/:id`、`/records/:id`、`/reports`
5. 若设备依赖 Clash 等代理访问上游，保留代理，不把“关闭代理”当成默认排障动作

## 当前平台与标识事实

- FVM 版本锁定在 `3.41.4`
- Android `applicationId` 当前仍为 `com.example.ai_case_assistant`
- iOS / macOS bundle id 当前仍为 `com.example.aiCaseAssistant`
- Web `manifest.json` 名称和描述仍保留默认占位文本

## 常见故障

- FVM 命令尾部出现 `Can't load Kernel binary: Invalid SDK hash.`
  - 当前在本仓库不阻塞 `flutter analyze` 与 `flutter test`
- Drift 生成代码缺失或过期
  - 重新执行 `build_runner build`
- AI worker 不可达
  - 检查 `AI_API_BASE_URL` 与网络状态
  - 注意 `USE_MOCK_AI_EXTRACT` 只覆盖旧 `/ai/extract`，不能替代 `/ai/intake`
- 真机依赖代理访问 AI
  - 保留代理并结合应用日志继续排查

## 排查顺序

1. 确认 FVM、Flutter 与依赖已安装
2. 确认 `build_runner` 已生成最新 Drift 文件
3. 确认设备或模拟器可用
4. 确认 `AI_API_BASE_URL` 可访问
5. 如是文档同步问题，再运行 `scripts/check_doc_sync.py`
