# Android 真机测试操作手册

## 目标与适用范围

本文是本项目后续 Android 真机测试的标准操作说明，负责回答“怎么连接、怎么安装、怎么运行、怎么抓日志、怎么排障”。

- 主机口径固定为 Windows + PowerShell + FVM + ADB。
- 本文只覆盖 Android 真机 smoke 的执行步骤，不替代 [docs/10-testing-strategy.md](docs/10-testing-strategy.md) 的触发规则，也不替代 [docs/12-release-smoke-checklist.md](docs/12-release-smoke-checklist.md) 的发布检查项。
- 纯文本主链路、关键页面基础打开这类低设备依赖场景，仍优先按现有策略使用 Android 模拟器。

## 当前已确认的仓库事实

- FVM 锁定版本为 `3.41.4`，见 `.fvm/fvm_config.json`。
- Android `applicationId` 为 `com.example.ai_case_assistant`，见 `android/app/build.gradle.kts`。
- 真实 AI 默认通过 `AI_API_BASE_URL` 指向的 worker 访问上游，默认值为 `https://ai-api-worker.wytai.workers.dev`。
- README 已明确提示：当前真实 AI 链路依赖代理 / 梯子访问 Cloudflare；真机排障时保留代理，不把“关闭代理”当成默认动作。
- `USE_MOCK_AI_EXTRACT` 只覆盖旧 `/ai/extract`，不能替代默认新增记录主链路使用的 `/ai/intake`。

## 前置检查

主机和仓库准备：

- 已安装 Flutter、FVM、Android Studio、Android SDK、ADB。
- 当前仓库依赖已安装，必要时已重新生成 Drift 代码。
- 若本次依赖真实 AI，已确认代理可用且 `AI_API_BASE_URL` 可访问。

建议按顺序执行：

```bash
fvm --version
adb version
fvm flutter doctor -v
fvm flutter pub get
fvm flutter pub run build_runner build --delete-conflicting-outputs
fvm flutter devices
```

说明：

- 纯文档任务或未触及 Drift schema 的任务，不必每次都执行 `build_runner build`。
- 多设备同时在线时，后续命令统一显式带 `-d <device-id>`，避免误装到错误设备。

## 设备连接

1. 在 Android 真机上开启开发者选项与 USB 调试。
2. 用数据线连接主机，并在手机上确认“允许 USB 调试 / 信任此电脑”。
3. 执行 `adb devices`，确认设备状态为 `device`，而不是 `unauthorized` 或 `offline`。
4. 执行 `fvm flutter devices`，记录 Flutter 识别到的 `<device-id>`。
5. 如果 `adb devices` 可见但 `fvm flutter devices` 不可见，先执行一次 `fvm flutter doctor -v` 排查 Android toolchain。

常用确认命令：

```bash
adb devices
fvm flutter devices
```

如果设备不可见，优先检查：

- USB 调试是否已开启。
- 手机上是否点过授权弹窗。
- 数据线是否支持数据传输。
- Android Studio / SDK / platform-tools 是否可用。

如需重置 ADB 连接，可执行：

```bash
adb kill-server
adb start-server
adb devices
```

## 运行方式

### 调试运行

优先使用 `flutter run`，因为它会同时完成安装、启动和实时日志输出：

```bash
fvm flutter run -d <device-id>
```

如果本次需要显式指定真实 AI 地址：

```bash
fvm flutter run -d <device-id> --dart-define=AI_API_BASE_URL=https://ai-api-worker.wytai.workers.dev
```

如果只是验证旧 `/ai/extract` 链路，可额外传入：

```bash
fvm flutter run -d <device-id> --dart-define=USE_MOCK_AI_EXTRACT=true
```

### 安装包验证

当目标是确认安装包可以被真机安装、覆盖安装和启动时，使用 APK 构建 + ADB 安装：

```bash
fvm flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

说明：

- `-r` 表示覆盖安装已有同包名应用。
- 安装软件时，系统会弹出安装提示框，Codex 需要点击“继续安装”按钮。
- 如果当前任务是候选发布包验证，应改用该任务实际需要的构建命令和产物，再沿用同样的 ADB 安装步骤。

### 可选清理重装

如果怀疑旧安装状态、权限状态或本地数据污染了验证结果，可先卸载再重装：

```bash
adb uninstall com.example.ai_case_assistant
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

## 仓库专属真机 smoke 流程

当 [docs/10-testing-strategy.md](docs/10-testing-strategy.md) 或 [docs/12-release-smoke-checklist.md](docs/12-release-smoke-checklist.md) 判定“必须上真机”时，至少覆盖以下步骤：

1. 安装并启动 Android 包，确认首页可以正常打开。
2. 打开新增记录页并选择图片，确认系统相册可以打开。
3. 检查图片权限与失败提示是否正常。
4. 选图后确认缩略图正常显示。
5. 保存记录后，确认附件已复制到应用私有目录并可在详情页回显。
6. 在详情页确认图片预览正常，并可点击进入全屏预览。
7. 重启 App 后再次打开详情页，确认数据与附件仍可读取。
8. 如果本次依赖真实 AI，保留 Clash 或其他代理，确认真实 AI 主链路可用。

补充约束：

- 纯文本主链路、关键页面基础打开、导航回归优先走模拟器，不因本文存在而放大真机范围。
- Web Chrome 只允许在“需要补一个真实 AI 文本主链路验证，且真机在保留代理的前提下仍不可行”时作为备用方案。
- Web Chrome 不能替代 Android 安装、权限、相册、附件、本地文件或设备网络行为验证。

## 日志与排障

### 首选日志方式

- 首选直接使用 `fvm flutter run -d <device-id>`，因为安装、启动和 Flutter 运行日志都在同一个终端里。
- 如果应用已经单独安装完成，或需要观察系统层日志，再使用 `adb logcat`。

```bash
adb logcat
adb shell pm list packages com.example.ai_case_assistant
```

### 常见问题

- 设备不可见
  - 先检查 `adb devices` 是否可见，再检查 `fvm flutter devices`。
  - 若 ADB 状态为 `unauthorized`，回到手机重新确认授权弹窗。
  - 若状态为 `offline`，重插数据线并重启 ADB。
- 安装失败或覆盖安装异常
  - 先确认包名仍为 `com.example.ai_case_assistant`。
  - 必要时执行 `adb uninstall com.example.ai_case_assistant` 后重装。
- App 能装但真实 AI 不通
  - 先确认代理仍开启，不要先做“关闭代理”的排障。
  - 检查 `AI_API_BASE_URL` 是否正确、网络是否可达。
  - 注意 `USE_MOCK_AI_EXTRACT` 不能替代 `/ai/intake` 主链路。
- 模拟器通过但真机失败
  - 优先怀疑图片权限、系统相册入口、应用私有目录文件读写、真实设备网络与代理差异。
- 真机真实 AI 文本链路仍然受阻
  - 先保留代理继续排查网络、证书、上游连通性。
  - 只有在确实需要补文本链路验证时，才追加 Web Chrome 备用 smoke，并在最终汇报中说明它不能替代 Android 验证。

## 跳过与汇报要求

如果本次没有执行 Android 真机 smoke，最终汇报至少写明：

- 未执行的验证类型。
- 未执行原因。
- 原本应覆盖的能力点。
- 剩余风险。

如果本次执行了 Android 真机 smoke，最终汇报至少写明：

- 使用了哪些命令。
- 跑了哪些手工步骤。
- 是否依赖真实 AI、是否保留代理。
- 仍未覆盖的验证项与原因。

## 相关文档

- 环境与运行总览见 [docs/09-env-and-runbook.md](docs/09-env-and-runbook.md)。
- 测试分层与触发条件见 [docs/10-testing-strategy.md](docs/10-testing-strategy.md)。
- 发布前 smoke 勾选项见 [docs/12-release-smoke-checklist.md](docs/12-release-smoke-checklist.md)。
