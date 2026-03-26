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
fvm flutter test test/features/ai/real_ai_api_test.dart --dart-define=RUN_REAL_AI_API_TESTS=true --dart-define=AI_API_BASE_URL=https://ai-api-worker.wytai.workers.dev
```

文档同步检查：

```bash
python scripts/check_doc_sync.py --working-tree --no-strict
```

## 验证分层入口

Android 真机的连接、安装、运行、日志与排障统一见 [docs/14-android-real-device-testing-sop.md](docs/14-android-real-device-testing-sop.md)。本节只保留验证分层入口与触发边界。

### 默认快速验证

绝大多数任务默认只跑这一层：

1. `fvm flutter analyze`
2. `fvm flutter test`

说明：

- 这一层覆盖所有本地自动化测试。
- `test/features/ai/real_ai_api_test.dart` 默认不跑。
- 纯文档、纯文案、小范围非主链路改动，默认停在这一层即可。
- 如果本次同时改动文档，再额外执行 `python scripts/check_doc_sync.py --working-tree --no-strict`。

### Android 模拟器 smoke

仅在以下情况触发：

- 首页、路由、关键页面交互变化
- 新增记录页、列表页、详情页、报告页的 UI 或导航变化
- `features/ai/`、`core/network/`、`core/config/` 行为变化
- 需要验证真实 AI 主链路，但本次不涉及相册、附件、本地文件或设备特性

建议步骤：

1. 启动 Android 模拟器
2. 打开首页并确认三个入口可进入
3. 跑一遍纯文本新增记录主链路，不选择图片
4. 打开列表、详情、报告列表、报告详情
5. 如本次涉及真实 AI 契约或网络配置变化，补一遍“纯文本 + 真实 AI” smoke

说明：

- 模拟器只负责纯文本主链路和关键页面基础打开。
- 不要求在模拟器验证系统相册、图片权限、附件复制、真实文件回显或安装体验。

### Android 真机 smoke

以下情况必须上真机：

- 图片选择、附件相关逻辑变化
- `image_picker` 调用路径变化
- 附件复制、删除、回滚、本地文件路径变化
- 详情页图片预览、全屏预览变化
- Android 安装、启动、包体、权限、代理网络相关变化
- 演示版、候选发布版、最终交付前验收

执行摘要：

1. 先按 [docs/14-android-real-device-testing-sop.md](docs/14-android-real-device-testing-sop.md) 完成设备连接、安装 / 运行与日志准备。
2. 再按本节触发条件和 [docs/12-release-smoke-checklist.md](docs/12-release-smoke-checklist.md) 完成相册、权限、附件、预览、重启回显与真实 AI 链路验证。
3. 只有真机在保留代理的前提下仍无法打通真实 AI 文本链路时，才评估 Web Chrome 备用 smoke。

说明：

- 真机范围包括相册、附件、本地文件、安装和代理网络。
- 若真实 AI 依赖 Clash 等代理访问上游，保留代理，不把“关闭代理”当成默认排障动作。

### Web Chrome 备用 smoke

仅在以下条件同时满足时允许追加：

- 需要补一个真实 AI 文本主链路验证
- Android 真机在保留代理的前提下仍无法打通真实 AI 主链路

说明：

- Web Chrome 只能补 UI 与真实 AI 文本主链路。
- Web Chrome 不能替代 Android 安装、附件、权限、相册、设备特有行为验证。

## 当前主链路说明

- 新增记录默认调用 `/ai/intake`。
- `/ai/extract` 仍保留，但主要用于旧链路兼容与回归测试。
- 首页“追问模式”只影响 `/ai/intake` 请求中的 `followUpMode`。
- 报告仍调用 `/ai/report`，且只读取正式 `health_events`。

## 发布前最小验证建议

1. 固定执行 `python scripts/check_doc_sync.py --working-tree --no-strict`
2. 固定执行 `fvm flutter analyze`
3. 固定执行 `fvm flutter test`
4. 如触及 `/ai/intake`、`/ai/extract`、`features/ai/`、`core/network/`、`core/config/` 或环境变量，评估并尽量执行真实 AI 测试
5. 如只是纯文本主链路、关键页面或导航变化，优先执行 Android 模拟器 smoke
6. 如涉及相册、附件、本地文件、安装、权限或代理网络，必须执行 Android 真机 smoke，操作步骤统一按 [docs/14-android-real-device-testing-sop.md](docs/14-android-real-device-testing-sop.md)
7. 只有真机在保留代理的前提下仍无法打通真实 AI 文本链路时，才追加 Web Chrome smoke，并明确它不能替代 Android 验证

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
  - 保留代理并结合 [docs/14-android-real-device-testing-sop.md](docs/14-android-real-device-testing-sop.md) 的日志步骤继续排查
- 真机真实 AI 主链路受阻
  - 先在保留代理的前提下继续排查网络、证书、上游连通性
  - 仅在需要补文本链路验证且真机仍不可行时，追加 Web Chrome smoke
- 模拟器验证通过但真机失败
  - 优先怀疑图片权限、相册入口、应用私有目录文件读写或代理网络差异

## 排查顺序

1. 确认 FVM、Flutter 与依赖已安装
2. 确认 `build_runner` 已生成最新 Drift 文件
3. 确认设备或模拟器可用
4. 确认 `AI_API_BASE_URL` 可访问
5. 若是纯文本主链路问题，先用模拟器复现
6. 若是相册、附件、预览、安装或代理网络问题，切到真机排查
7. 如是文档同步问题，再运行 `scripts/check_doc_sync.py`
