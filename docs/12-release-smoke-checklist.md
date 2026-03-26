# 发布 Smoke 清单

当前仓库没有正式 CI/CD 或线上发布流水线。本清单用于本地演示包、阶段性发版候选和关键改动后的最小 smoke 检查。

## 发布前检查

- [ ] `README.md`、相关 docs 已同步
- [ ] 如改了 Drift schema，已执行 `fvm flutter pub run build_runner build --delete-conflicting-outputs`
- [ ] `python scripts/check_doc_sync.py --working-tree --no-strict` 通过
- [ ] `fvm flutter analyze` 通过
- [ ] `fvm flutter test` 通过
- [ ] 已判断本次只需默认快速验证、还是需要模拟器 / 真机 / Web 备用 smoke
- [ ] 若改动触及 `/ai/intake`、`/ai/extract`、`/ai/report`、`features/ai/`、`core/network/`、`core/config/` 或环境变量，已评估真实 AI 自动化测试
- [ ] 若使用真实 AI，`AI_API_BASE_URL` 可访问

## Android 模拟器 smoke

触发条件：

- 首页、路由、关键页面交互变化
- 新增记录页、列表页、详情页、报告页的 UI 或导航变化
- `features/ai/`、`core/network/`、`core/config/` 行为变化
- 需要验证真实 AI 纯文本主链路，但本次不涉及相册、附件、本地文件或设备特性

检查项：

- [ ] 首页可以正常打开
- [ ] 首页三个入口可以进入
- [ ] 纯文本新增记录主链路可以完成，不选择图片
- [ ] `/records` 可以打开
- [ ] `/records` 的“正式记录 / 草稿记录”双 tab 可以切换
- [ ] `/records` 日期范围筛选可用，清空筛选后列表恢复
- [ ] `/records/:id` 可以打开
- [ ] `/records/:id` 可执行删除正式记录并返回列表
- [ ] `/reports` 可以打开
- [ ] `/reports/:id` 可以打开
- [ ] 若报告覆盖的来源记录在报告生成后被删除，`/reports/:id` 会显示“部分记录来源已被删除”
- [ ] 如本次涉及真实 AI 契约或网络配置变化，已补一遍“纯文本 + 真实 AI” smoke

说明：

- 模拟器 smoke 不要求验证系统相册、图片权限、附件复制、文件回显、安装体验或代理网络。

## Android 真机 smoke

具体执行方式统一按 [docs/14-android-real-device-testing-sop.md](docs/14-android-real-device-testing-sop.md)。本节只保留发布前必须勾选的触发条件与检查项。

触发条件：

- 图片选择、附件相关逻辑变化
- `image_picker` 调用路径变化
- 附件复制、删除、回滚、本地文件路径变化
- 详情页图片预览、全屏预览变化
- Android 安装、启动、包体、权限、代理网络相关变化
- 演示版、候选发布版、最终交付前验收

检查项：

- [ ] 安装前已执行 `adb devices`，并确认只有一台目标真机且状态为 `device`
- [ ] Android 包通过 `adb install -r -t -g <APK路径>` 安装，不依赖手机端“继续安装”页面
- [ ] 安装成功后已自动启动应用
- [ ] 若安装失败，已保留并汇报完整 ADB 错误输出
- [ ] 新增记录页可以打开系统相册
- [ ] 图片权限与失败提示正常
- [ ] 选图后缩略图正常显示
- [ ] 保存记录后附件已复制到应用私有目录并可回显
- [ ] 记录详情页图片预览正常
- [ ] 点击后可进入全屏预览
- [ ] 重启 App 后数据与附件仍可读取
- [ ] 若本次依赖真实 AI，保留 Clash 或其他代理条件下主链路可用

说明：

- 真机 smoke 是发布候选和最终验收的默认要求。
- 不要把“关闭代理”写成默认排障步骤。
- Android 包部署默认走主机侧 ADB 直装，不再采用手机下载 APK 后手动安装。

## Web Chrome 备用 smoke

仅在以下条件同时满足时允许执行：

- 需要补一个真实 AI 文本主链路验证
- Android 真机在保留代理的前提下仍无法打通真实 AI 主链路

检查项：

- [ ] 已在最终汇报注明这是“Web Chrome 备用 smoke”
- [ ] 已说明触发 Web 备用的原因
- [ ] 已在 Web Chrome 验证首页与纯文本新增记录主链路
- [ ] 已在最终汇报注明它不覆盖 Android 安装、附件、权限、相册、设备特有行为

## 真实 AI 契约观察点

- [ ] `/ai/intake` 请求带 `followUpMode`
- [ ] `/ai/intake` 强制结束时请求带 `forceFinalize=true`
- [ ] `/ai/intake` 请求带完整 `messages`
- [ ] `/ai/extract` 与 `/ai/intake` 中 `symptomSummary=""` 不会被客户端改写
- [ ] 所有出站 `eventTime` 使用不带毫秒、带 `+08:00` 的 ISO 8601

## 可跳过与汇报要求

允许跳过的前提：

- 本次改动只停留在默认快速验证范围
- 当前没有可用模拟器或真机
- 当前网络或上游服务不可用，无法完成真实 AI 验证

若有跳过，最终汇报必须写明：

- [ ] 跳过了哪一层验证
- [ ] 跳过原因
- [ ] 未覆盖的能力点
- [ ] 剩余风险

## 回滚条件

- 首页或主入口无法打开
- 首次免责弹窗可被跳过或同意后仍无法放行
- `/records/new` 主链路连续失败
- `/intake/:id` 无法恢复或会话状态错乱
- 草稿删除后仍能通过旧 `/intake/:id` 恢复
- 正式记录删除后仍能出现在列表、详情或报告输入
- 重新追问产生重复正式记录
- 未完成追问污染正式记录列表或报告
- 附件无法保存、回显或重启后丢失
- 图片预览或全屏预览失效
- 数据库升级后旧记录不可读
