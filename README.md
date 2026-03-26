# AI 健康病例助手

## 项目是什么

项目定位、目标用户、目标问题和当前版本目标见 [docs/01-overview.md](docs/01-overview.md)。

## 演示版本APK
[安装包](./AI健康助手.apk)
温馨提示：使用程序前需打开梯子/代理，否则将无法正常使用。（原因：AI代理接口我部署在了CloudFlare上，国内网络无法正常访问CloudFlare）

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
