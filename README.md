# AI 健康病例助手

## 项目是什么

项目定位、目标用户、目标问题和当前版本目标见 [docs/01-overview.md](docs/01-overview.md)。

## 演示版本 APK
[安装包](./AI健康助手.apk)

Android 包部署统一改为主机侧 ADB 直装，不再通过手机下载 APK 后手动点击安装。
标准流程是先执行 `adb devices` 确认只有一台目标真机且状态为 `device`，再执行 `adb install -r -t -g <APK路径>`，安装成功后自动启动应用；安装失败时保留完整 ADB 错误输出，不依赖手机上的“继续安装”页面。详细步骤见 [docs/14-android-real-device-testing-sop.md](docs/14-android-real-device-testing-sop.md)。

温馨提示：使用程序前需打开梯子/代理，否则将无法正常使用。（原因：AI 代理接口部署在 Cloudflare 上，国内网络无法正常访问 Cloudflare）

## 开发者留言
- 当前程序仍在继续开发中，更多功能与优化敬请期待。（现在页面太丑了，我晚点会改的哈哈哈）

## 怎么跑

前置要求：

- 已安装 Flutter 与 FVM
- 已安装 Android Studio / Android SDK / ADB
- 需要演示真机或模拟器时，设备已可正常连接

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

环境变量、验证命令、真实 AI 测试和排障总览见 [docs/09-env-and-runbook.md](docs/09-env-and-runbook.md)。
Android 真机连接、安装、运行与排障 SOP 见 [docs/14-android-real-device-testing-sop.md](docs/14-android-real-device-testing-sop.md)。
发布前 smoke 检查见 [docs/12-release-smoke-checklist.md](docs/12-release-smoke-checklist.md)。

## 去哪里读详细文档

- 项目概览：[`docs/01-overview.md`](docs/01-overview.md)
- 环境与运行手册：[`docs/09-env-and-runbook.md`](docs/09-env-and-runbook.md)
- Android 真机测试 SOP：[`docs/14-android-real-device-testing-sop.md`](docs/14-android-real-device-testing-sop.md)
- 完整文档索引：[`docs/00-index.md`](docs/00-index.md)
