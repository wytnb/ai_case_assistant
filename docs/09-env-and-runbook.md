# 环境与运行手册

## 环境清单

- 本地开发：Flutter + FVM，本地运行、调试、测试
- 演示环境：Android 真机或模拟器，本地连接 AI 代理
- 测试环境：当前没有独立测试服或预发环境
- 生产环境：当前没有正式生产发布流水线

## 配置项

| 配置项 | 环境 | 是否必填 | 作用 | 备注 |
|---|---|---|---|---|
| `AI_API_BASE_URL` | run / test | 否 | AI 代理基础地址 | 默认值为 `https://ai-api-worker.wytai.workers.dev`，当前真实验证也使用该地址 |
| `USE_MOCK_AI_EXTRACT` | run | 否 | 将提取链路切到本地 mock | 默认 `false` |
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

完成 mock 验证后，下一步必须执行上面的真实 AI 接口测试命令，并显式带上 `RUN_REAL_AI_API_TESTS=true`。
当前默认真实验证地址为 `https://ai-api-worker.wytai.workers.dev`。

文档同步检查：

```bash
python scripts/check_doc_sync.py --working-tree --no-strict
```

## 当前平台与标识事实

- FVM 版本锁定在 `3.41.4`
- Android `applicationId` 当前仍为 `com.example.ai_case_assistant`
- iOS / macOS bundle id 当前仍为 `com.example.aiCaseAssistant`
- Web `manifest.json` 名称和描述仍保留默认占位文本

这些是当前配置事实，不应在文档中写成“已完成产品化命名”。

## 测试环境

- 当前没有固定测试环境地址
- 当前没有共享测试账号
- 真实 AI 接口验证依赖手工提供 `AI_API_BASE_URL`

## 发布流程

当前没有 CI/CD 或正式发版流水线。

现阶段的“发布”更接近本地或演示版交付，建议最少执行：

1. `fvm flutter analyze`
2. `fvm flutter test`
3. 若先用 mock 验证，mock 通过后立即执行带 `RUN_REAL_AI_API_TESTS=true` 的真实 AI 集成测试
4. 核对 `AI_API_BASE_URL` 是否指向可用代理，或改用 mock 提取
5. 在 Android 设备上手工跑一遍记录与报告主链路；若设备依赖 Clash 等代理访问上游，保留代理，不把关闭代理作为默认排障步骤
6. 若真机在保留代理的前提下仍无法跑通，再补一条 `fvm flutter run -d chrome --dart-define=AI_API_BASE_URL=https://ai-api-worker.wytai.workers.dev` 的 Web Chrome 备用 smoke，并在结果中单独说明覆盖边界

## 常见故障

- 故障：FVM 命令尾部出现 `Can't load Kernel binary: Invalid SDK hash.`
  - 症状：`flutter --version`、`flutter analyze`、`flutter test` 结尾出现该警告
  - 处理方式：当前本地验证仍可完成，但需要在工具链维护时进一步排查 SDK 缓存状态

- 故障：Drift 生成代码缺失或过期
  - 症状：编译时报 `app_database.g.dart` 相关错误
  - 处理方式：重新运行 `build_runner build`

- 故障：AI 代理不可达
  - 症状：新增记录或报告生成提示失败
  - 处理方式：检查 `AI_API_BASE_URL`、网络状态，新增记录演示可切换 `USE_MOCK_AI_EXTRACT=true`

- 故障：Android 真机只能通过 Clash 等代理访问 AI 代理
  - 症状：主机侧真实 AI 集成测试通过，但真机手工 smoke 无法访问 `https://ai-api-worker.wytai.workers.dev`
  - 处理方式：保留设备代理并继续排查应用日志、页面错误提示和设备网络；不要把关闭代理作为默认处理。若真机仍无法打通，可追加 Web Chrome smoke 验证 UI 与真实 AI 主链路

- 故障：Python 不可用
  - 症状：`run_doc_sync_check.bat` 无法启动
  - 处理方式：安装 Python 3，或使用 `py -3`

## 排查步骤

1. 先确认 FVM、Flutter 与依赖已安装
2. 再确认 `build_runner` 已生成最新 Drift 文件
3. 再确认设备或模拟器可用
4. 再确认 AI 代理地址是否可访问；真机若依赖 Clash 等代理访问上游，应保持代理开启
5. 若是文档同步问题，再运行 `scripts/check_doc_sync.py`
