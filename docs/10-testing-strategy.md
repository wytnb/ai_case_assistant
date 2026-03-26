# 测试策略

## 测试目标

- 让绝大多数任务停留在本地快速验证层，减少不必要的设备验证与 token 消耗。
- 在需要设备验证时，先用 Android 模拟器覆盖纯文本主链路，再把真机范围收敛到附件、安装和设备特性。
- 保留 `test/features/ai/real_ai_api_test.dart` 作为显式开启的真实 AI 集成测试，不把它混入默认自动化。
- 明确哪些验证可跳过，以及跳过后最终汇报必须写出的剩余风险。

## 当前自动化覆盖

| 测试文件 | 当前覆盖点 |
|---|---|
| `test/widget_test.dart` | 首页主入口与追问模式开关存在 |
| `test/app/presentation/home_page_test.dart` | 首页首次免责弹窗、同意放行、追问模式开关持久化 |
| `test/features/health_record/presentation/create_health_record_page_test.dart` | 新增记录页提交、路由与错误边界 |
| `test/features/health_record/presentation/health_record_list_page_test.dart` | 双 tab、原始文本标题、日期范围筛选、删除后列表更新 |
| `integration_test/health_record_list_page_test.dart` | Android 设备执行列表页筛选状态更新、草稿菜单删除与留在列表页 |
| `test/features/health_record/presentation/health_record_detail_page_test.dart` | `actionAdvice`、空状态、删除入口与“追加补充”按钮 |
| `test/features/report/presentation/report_detail_page_test.dart` | 报告详情页末尾免责说明与已删来源红字提示 |
| `test/features/intake/presentation/intake_page_test.dart` | 继续追问、强制结束、恢复 `questioning`、文案更新 |
| `test/features/intake/intake_service_test.dart` | 设置、会话、正式记录更新、报告隔离、附件转正 |
| `test/features/ai/data/remote_ai_services_test.dart` | `/ai/intake`、`/ai/extract`、`/ai/report` 契约解析 |
| `test/core/database/app_database_test.dart` | 数据库与迁移基础覆盖 |

## 测试分层

### 第一层：默认快速验证

默认必须执行：

- `fvm flutter analyze`
- `fvm flutter test`

这一层覆盖：

- 所有 unit / widget / database / service / remote contract 测试
- `CreateHealthRecordPage`、列表页、详情页、报告页等已有 widget 回归
- 附件转正、数据库迁移、AI JSON 解析等本地自动化可覆盖内容

这一层默认不执行：

- `test/features/ai/real_ai_api_test.dart`
- Android 模拟器 smoke
- Android 真机 smoke
- Web Chrome smoke

适用场景：

- 纯文档、纯文案改动
- 小范围非主链路 UI 微调
- 不影响 Android 设备特性、附件、本地文件、真实 AI 配置的代码改动
- 已有自动化覆盖充分的小改动

### 第二层：Android 模拟器 smoke

仅在以下情况触发：

- 首页、路由、关键页面交互变化
- 新增记录页、列表页、详情页、报告页的 UI 或导航变化
- `features/ai/`、`core/network/`、`core/config/` 行为变化
- 需要验证真实 AI 主链路，但本次不涉及相册、附件、本地文件或设备特性

模拟器必测项：

- 首页可以打开
- 首页三个入口可以进入
- 文本版新增记录主链路可完成，不选择图片
- 列表、详情、报告列表、报告详情可以打开
- 若本次涉及真实 AI 契约或网络配置变化，可追加“纯文本 + 真实 AI” smoke

模拟器明确不承担：

- 系统相册选择
- 图片权限弹窗与失败提示
- 附件复制到应用私有目录后的真实设备回显
- 安装体验、设备代理网络、设备文件系统行为

### 第三层：Android 真机 smoke

Android 真机 smoke 的连接、安装、运行、日志与排障步骤统一见 [docs/14-android-real-device-testing-sop.md](docs/14-android-real-device-testing-sop.md)。本节只定义触发条件与必测项。

只有以下情况必须上真机：

- 图片选择、附件相关逻辑变化
- `image_picker` 调用路径变化
- 附件复制、删除、回滚、本地文件路径变化
- 详情页图片预览、点击全屏预览变化
- Android 安装、启动、包体、权限、代理网络相关变化
- 演示版、候选发布版、最终交付前验收

真机必测项：

- 能正常打开系统相册并完成选图
- 图片权限与失败提示正常
- 选图后缩略图正常显示
- 保存记录后附件已复制到应用私有目录并可回显
- 详情页图片预览、点击全屏预览正常
- 重启 App 后数据与附件仍可读取
- 若真实 AI 依赖 Clash 或其他代理，保留代理条件下验证链路
- 若本次修改触及 `/records` 的筛选或删除交互，补跑 `integration_test/health_record_list_page_test.dart`

### 第四层：Web Chrome 备用 smoke

Web Chrome 不是默认层，也不能替代 Android 验证。

仅允许在以下前提下追加：

- 需要补一个真实 AI 文本主链路验证
- Android 真机在保留代理的前提下仍无法打通真实 AI 主链路

Web Chrome 仅覆盖：

- UI 基础打开
- 纯文本新增记录主链路
- 真实 AI 文本链路连通性

Web Chrome 不覆盖：

- Android 安装
- 图片附件
- 权限
- 系统相册
- 设备代理网络行为
- 任何依赖 `Image.file(...)`、应用私有目录或 Android 文件系统的验证

## 显式开启项

### 真实 AI 自动化测试

`test/features/ai/real_ai_api_test.dart` 属于本地自动化中的显式开启项，不属于设备测试。

命令：

```bash
fvm flutter test test/features/ai/real_ai_api_test.dart --dart-define=RUN_REAL_AI_API_TESTS=true --dart-define=AI_API_BASE_URL=https://ai-api-worker.wytai.workers.dev
```

默认不跑，但在以下情况必须评估并在可行时执行：

- `/ai/intake`、`/ai/extract`、`/ai/report` 请求体或响应解析变化
- `features/ai/`、`core/network/`、`core/config/` 变化
- `AI_API_BASE_URL`、`RUN_REAL_AI_API_TESTS`、`USE_MOCK_AI_EXTRACT` 行为变化

如果没有执行，最终汇报必须写明：

- 未执行的是“真实 AI 自动化测试”
- 未执行原因
- 剩余风险

## 场景矩阵

| 场景 / 模块 | 默认自动化 | Android 模拟器 | Android 真机 | 是否可用 Web Chrome 备用 | 触发条件 | 备注 / 剩余风险 |
|---|---|---|---|---|---|---|
| `flutter analyze` / `flutter test` | 必跑 | 否 | 否 | 否 | 绝大多数任务 | 默认快速验证基线 |
| `test/features/ai/real_ai_api_test.dart` | 显式开启 | 否 | 否 | 否 | AI 契约、网络层、配置变化时评估 | 不属于设备测试；默认不跑 |
| 首页基础打开、三个入口、路由跳转 | 是 | 是 | 发布/验收时是 | 仅备用 | 首页、路由、关键页面交互变化 | 日常任务先模拟器即可 |
| 纯文本新增记录主链路 | 是 | 是 | 发布/验收时是 | 可作为文本链路备用 | `/records/new` UI、导航、`/ai/intake` 纯文本链路变化 | 不选图片时模拟器足够 |
| 列表页、详情页、报告页基础打开 | 是 | 是 | 发布/验收时是 | 仅备用 | 相关 UI 或导航变化 | 仅“基础打开”不要求真机 |
| 真实 AI 纯文本主链路 | 可选显式开启 | 是 | 当发布或演示依赖真机链路时是 | 可作为受阻时备用 | AI 契约、网络配置、主链路依赖真实 AI | 模拟器足够验证纯文本链路 |
| 图片选择、权限、失败提示 | 否 | 否 | 必须 | 否 | `image_picker`、权限、图片入口变化 | 系统相册与权限属于真机范围 |
| 附件复制、删除、回滚、本地文件路径 | 部分 | 否 | 必须 | 否 | 附件存储逻辑或路径变化 | 自动化只能覆盖部分，真实设备仍有风险 |
| 详情页图片预览、全屏预览 | 部分 | 否 | 必须 | 否 | `Image.file(...)` 预览链路变化 | 需要真机确认真实文件可读与回显 |
| Android 安装、启动、包体、代理网络 | 否 | 否 | 必须 | 否 | 安装包、权限、代理、发布候选变化 | Web 无法替代 |

## 可跳过条件

以下情况允许停在第一层，不再追加设备验证：

- 纯文档、纯文案改动
- 小范围非主链路改动，且不触发上表中的模拟器 / 真机条件
- 仅调整已有自动化已覆盖的本地逻辑，且不涉及真实 AI、附件、设备行为

以下情况允许跳过真实 AI 自动化或设备 smoke，但必须在最终汇报写清楚：

- 当前机器没有可用模拟器或真机
- 当前网络或上游服务不可用
- 发布链路之外的改动，经评估只影响低风险局部逻辑

最终汇报至少写明：

- 跳过了哪一层验证
- 跳过原因
- 该层原本应该覆盖什么
- 剩余风险

## 当前必须守住的高风险点

- `/ai/intake` 请求体必须完整并使用完整消息历史
- `symptomSummary` 的“字符串即保留”规则不能回退
- 强制结束与重新追问不能产生重复正式记录
- 未完成追问不能进入正式记录列表或报告
- 正式记录软删除后不能继续参与列表、详情、报告输入或继续补充入口
- 草稿硬删除后不能残留 session / message / intake attachment 行
- 首次免责同意必须在未同意前强阻断首页入口
- 附件转正失败不能把草稿误写进正式记录
- 图片附件相关变更必须通过真机验证

## 通过标准

默认通过标准：

- `fvm flutter analyze`
- `fvm flutter test`

按变更类型追加：

- `python scripts/check_doc_sync.py --working-tree --no-strict`
- `fvm flutter pub run build_runner build --delete-conflicting-outputs`
- `fvm flutter test test/features/ai/real_ai_api_test.dart --dart-define=RUN_REAL_AI_API_TESTS=true --dart-define=AI_API_BASE_URL=https://ai-api-worker.wytai.workers.dev`
- Android 模拟器 smoke
- Android 真机 smoke
- Web Chrome 备用 smoke

## 当前无法完全自动化的项目

- 系统相册选择与权限弹窗的完整交互
- 附件复制到应用私有目录后的设备侧回显与重启后可读性
- `Image.file(...)` 在真实设备上的预览与全屏预览
- 真实 AI 在代理网络环境下的稳定性
- Android 安装包、启动与设备网络条件
