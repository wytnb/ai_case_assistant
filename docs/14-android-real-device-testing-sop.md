# Android 真机测试操作手册

## 目标与适用范围

本手册用于 `apps/ai_case_assistant/` 在 Android 真机上的连接、安装、运行、日志抓取与附件相关 smoke。

## 当前已确认的仓库事实

- Flutter app 当前位于 `apps/ai_case_assistant/`
- Android `applicationId` 为 `com.example.ai_case_assistant`
- 真实 AI 默认通过 `AI_API_BASE_URL` 指向 gateway
- app 当前新增主链路走 `/ai/intake`，不再依赖 `/ai/extract`

## 前置检查

在 `apps/ai_case_assistant/` 下执行：

```bash
cd apps/ai_case_assistant
fvm flutter doctor -v
fvm flutter pub get
fvm flutter devices
```

预期结果：

- Flutter toolchain 正常
- 目标设备出现在 Flutter 设备列表中

## 设备连接

在仓库根目录或任意终端执行：

```bash
adb devices
```

要求：

- 只保留一台目标真机
- 状态为 `device`

## 运行方式

### 直接运行

在 `apps/ai_case_assistant/` 下执行：

```bash
cd apps/ai_case_assistant
fvm flutter run -d <device-id>
```

如需真实 AI：

```bash
cd apps/ai_case_assistant
fvm flutter run -d <device-id> --dart-define=AI_API_BASE_URL=https://case-assistant-gateway.wytai.workers.dev
```

### 构建 APK

在 `apps/ai_case_assistant/` 下执行：

```bash
cd apps/ai_case_assistant
fvm flutter build apk --release
```

产物路径：

- `apps/ai_case_assistant/build/app/outputs/flutter-apk/app-release.apk`
- 如需仓库根目录交付包，可额外复制为 `ai_case_assistant-release.apk`

再用 ADB 安装：

```bash
adb install -r -g build/app/outputs/flutter-apk/app-release.apk
```

## 仓库专属真机 smoke 流程

1. 打开首页并确认首次免责弹窗 / 三个入口正常。
2. 进入新增记录页，选择图片并确认缩略图显示正常。
3. 提交一条记录，确认：
   - 纯文本与 AI 主链路可完成
   - 详情页可回显图片
4. 重启 App 后再次打开详情页，确认附件仍可读取。
5. 如本次改动涉及删除链路，验证删除后列表与详情状态正确。

## 日志与排障

- 优先使用 `fvm flutter run -d <device-id>` 观察实时日志。
- 安装失败时保留完整 ADB 输出。
- 真实 AI 不可达时，先检查 `AI_API_BASE_URL`、网络与代理，再判断是否需要跳过。

## 跳过与汇报要求

若未执行真机 smoke，最终汇报必须写明：

- 未执行原因
- 哪些设备相关能力未覆盖
- 剩余风险

## 相关文档

- `docs/09-env-and-runbook.md`
- `docs/10-testing-strategy.md`
- `docs/12-release-smoke-checklist.md`
