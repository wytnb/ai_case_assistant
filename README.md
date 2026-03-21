# AI 健康病例助手

## 项目是什么

项目定位、目标用户、目标问题和当前版本目标见 [docs/01-overview.md](docs/01-overview.md)。

## 演示版本APK
[安装包](./AI健康助手.apk)

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

环境变量、验证命令、真实 AI 测试和排障说明见 [docs/09-env-and-runbook.md](docs/09-env-and-runbook.md)。
发布前 smoke 检查见 [docs/12-release-smoke-checklist.md](docs/12-release-smoke-checklist.md)。

## 去哪里读详细文档

- 项目概览：[`docs/01-overview.md`](docs/01-overview.md)
- 环境与运行手册：[`docs/09-env-and-runbook.md`](docs/09-env-and-runbook.md)
- 完整文档索引：[`docs/00-index.md`](docs/00-index.md)
