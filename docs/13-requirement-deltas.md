# 需求变更记录

## 维护说明

本文档用于记录需求理解、范围边界和阶段性取舍的变更。无法从仓库直接确认的历史事实不做编造，只记录当前任务中可确认的变化。

## 变更记录

### 2026-03-26 - 仓库收口为 monorepo，并把 Flutter app 迁入 `apps/ai_case_assistant`

- 原需求：
  - 仓库根目录直接承载 Flutter 工程
  - `services/ai_gateway/` 已复制进入仓库，但根级入口、文档、契约与测试还未完成 monorepo 收口
  - app 文档、代码和测试里仍把 `/ai/extract` 当成当前能力的一部分
- 新需求：
  - 根目录成为 monorepo workspace 层
  - Flutter app 迁入 `apps/ai_case_assistant/`
  - `contracts/health-record-ai.openapi.json` 成为共享契约源
  - app 当前公开能力收敛为 `/ai/intake` 与 `/ai/report`
- 变更原因：
  - 让 app、gateway、文档、测试与契约在一个仓库内围绕同一套事实协作
  - 清理已退场 `/ai/extract` 在 app 侧的漂移残留
- 影响范围：
  - 根级 README / AGENTS / docs / scripts
  - `apps/ai_case_assistant/**`
  - `services/ai_gateway/**`
  - `contracts/**`
- 需要更新的文档：
  - 根级入口文档、workspace 文档、接口契约文档、运行文档、测试文档
  - gateway 的入口与运行 / 契约说明
- 需要补的测试：
  - app 的 `/ai/intake`、`/ai/report` 契约解析与真实 AI 测试
  - root 级共享契约一致性校验
- 风险：
  - Flutter 工程迁移后，部分本地 IDE / 命令路径可能需要重新适配
  - 文档中若仍遗留旧路径或旧接口，会继续造成理解漂移
- 后续动作：
  - 若后面继续扩展 AI 能力，先从共享契约出发改起

### 2026-03-26 - 记录返回链路与真机测试默认保留已安装 App

- 原需求：
  - 新增记录后进入正式记录详情或草稿追问页时，返回目标未被统一约束
  - `/records` 作为根路由时，返回行为未明确要求回首页
  - 真机测试文档只保留“可选清理重装”，但没有明确“测试结束后默认不卸载 App”的口径
- 新需求：
  - 新增记录后进入正式记录详情页时，返回应落到 `/records?tab=records`
  - 新增记录后进入草稿追问页时，返回应落到 `/records?tab=drafts`
  - `/records` 作为根路由时，返回应回首页 `/`
  - 若页面本身已有可回退的上层路由，仍优先 `pop` 回现有上一页，不强行改写已有列表栈
  - 真机 smoke 结束后默认保留手机中已安装的 App
  - `adb uninstall com.example.ai_case_assistant` 只保留为排障、清理重装或明确需要验证冷安装时的操作
- 变更原因：
  - 统一正式记录、草稿追问与记录列表之间的返回链路，避免新增流程把用户留在无明确上一层的页面
  - 降低真机测试后的重复安装成本，避免把“卸载收尾”误当成标准流程
- 影响范围：
  - `docs/03-business-flows.md`
  - `docs/09-env-and-runbook.md`
  - `docs/11-regression-matrix.md`
  - `docs/12-release-smoke-checklist.md`
  - `docs/14-android-real-device-testing-sop.md`
  - `lib/app/router/`
  - `lib/features/health_record/`
  - `lib/features/intake/`
  - 相关 widget 测试
- 需要补的测试：
  - 新增记录 direct-final 后从详情返回到 `/records?tab=records`
  - 新增记录 needs-followup 后从追问页返回到 `/records?tab=drafts`
  - `/records` 根路由返回到首页
  - `/records/:id` 与 `/intake/:id` 根路由的返回兜底
  - 详情页 / 追问页删除成功后的返回目标
- 风险：
  - 路由回退行为依赖 `context.canPop()` 判断，后续若调整路由组织方式，需要同步回归这些返回链路
  - 真机测试默认保留已安装 App，若测试人需要验证冷安装或清理本地状态，仍需显式执行卸载

### 2026-03-26 - Android 包部署收口为 ADB 直装

- 原需求：
  - Android 包允许通过手机下载 APK 后手动安装
  - 文档没有统一约束安装前的设备数量检查
  - 安装成功后的自动启动与安装失败时的完整错误保留要求不明确
  - 仍默认接受手机端“继续安装”页面作为安装流程的一部分
- 新需求：
  - Android 包部署统一改为主机侧 ADB 直装，不再通过手机下载 APK 后手动安装
  - 安装前必须先执行 `adb devices`，确认只有一台目标真机且状态为 `device`
  - 标准安装命令统一为 `adb install -r -t -g <APK路径>`
  - 安装成功后自动启动应用
  - 安装失败时输出并保留完整 ADB 错误信息
  - 安装流程不依赖手机上的“继续安装”页面
- 变更原因：
  - 降低人工安装步骤带来的不确定性，避免把手机端交互误当成标准部署流程
  - 统一 Windows + PowerShell + ADB 的真机部署口径，方便复现和排障
- 影响范围：
  - `README.md`
  - `docs/09-env-and-runbook.md`
  - `docs/12-release-smoke-checklist.md`
  - `docs/14-android-real-device-testing-sop.md`
- 需要补的测试：
  - 本次为文档与部署流程口径收敛，不新增代码测试
- 风险：
  - 若执行人未先清理多余在线设备，仍可能把 APK 装到错误真机
  - 文档收敛后，实际自动化脚本若仍沿用旧安装方式，需要后续同步

### 2026-03-26 - 记录页签化、删除分流与报告已删来源提示

- 原需求：
  - `/records` 使用“正式记录 + 未完成追问分区”展示
  - 列表页和详情页没有统一删除入口
  - 报告详情页不会提示来源记录在报告生成后被删除
  - 草稿删除策略未落地
- 新需求：
  - `/records` 改为“正式记录 / 草稿记录”双 tab，并支持按 `eventTime` 日期范围筛选
  - 正式记录在列表页和 `/records/:id` 支持软删除
  - 草稿记录在列表页和 `/intake/:id` 支持硬删除，需同时清理 session、消息和暂存附件
  - 报告详情页在命中“报告生成后来源记录被删除”时显示红字提示“部分记录来源已被删除”
  - 列表页与草稿/正式 panel 标题统一改为原始文本；继续追问页与详情页按钮文案同步调整
- 变更原因：
  - 需要让记录管理更贴近用户心智，同时保留正式记录与草稿记录不同的删除语义
  - 需要让历史报告在不重算的前提下提示来源已变化
- 影响范围：
  - `docs/02-12`
  - `lib/core/database/`
  - `lib/features/health_record/`
  - `lib/features/intake/`
  - `lib/features/report/`
  - 相关 database / service / widget 测试
- 需要补的测试：
  - schema 6 迁移
  - 正式记录软删除
  - 草稿硬删除
  - 报告已删来源提示
  - 列表页日期范围筛选
- 风险：
  - 草稿硬删除若文件清理失败，可能残留不可见临时文件
  - 报告已删来源提示是布尔提示，不展示具体删除来源明细

### 2026-03-19 - 测试流程收敛为“自动化 / 模拟器 / 真机 / Web 备用”四层

- 原需求：
  - 测试文档对自动化、设备 smoke、真实 AI 验证的责任边界不够清晰
  - Android 模拟器与真机的适用范围没有明确拆开
  - Web Chrome 备用 smoke 的触发条件与能力边界不够明确
- 新需求：
  - 默认快速验证固定为 `fvm flutter analyze` 与 `fvm flutter test`
  - `test/features/ai/real_ai_api_test.dart` 继续保留，但属于显式开启的本地自动化项，默认不跑
  - 首页、路由、纯文本新增记录、列表页、详情页、报告页基础打开，优先由 Android 模拟器 smoke 覆盖
  - 相册、附件、本地文件、`image_picker`、图片预览、安装、权限、代理网络统一收敛到 Android 真机 smoke
  - Web Chrome 只允许在保留代理的前提下真机仍无法打通真实 AI 文本链路时，作为备用验证
  - 允许跳过非必要层级，但最终汇报必须写明未执行验证、原因与剩余风险
- 变更原因：
  - 降低日常迭代的时间成本与 token 消耗
  - 减少没有收益的真机验证，同时保留高风险设备行为的必要覆盖
  - 统一 README、运行手册、测试策略、回归矩阵与发布 smoke 的口径
- 影响范围：
  - `README.md`
  - `docs/09-env-and-runbook.md`
  - `docs/10-testing-strategy.md`
  - `docs/11-regression-matrix.md`
  - `docs/12-release-smoke-checklist.md`
- 需要补的测试：
  - 本次为文档与验证策略收敛，不新增代码测试
- 风险：
  - 若执行人错误判断触发条件，可能把应上真机的附件类改动停在模拟器
  - Web Chrome 备用 smoke 容易被误用为 Android 验证替代，需要在最终汇报中持续约束

### 2026-03-19 - 首次免责强制同意与报告详情页尾免责提示

- 原需求：
  - 首次进入首页无需阅读并同意免责说明即可继续使用功能
  - 报告详情页没有固定免责提示
- 新需求：
  - 首次进入系统时必须弹出免责说明，用户勾选同意后才能继续使用首页入口
  - `first_use_disclaimer_accepted` 通过 `app_settings` 持久化，缺失或类型异常按未同意处理
  - 报告详情页 `/reports/:id` 末尾固定展示免责说明
- 变更原因：
  - 明确产品责任边界与 AI 辅助定位，降低用户将 AI 输出当作诊疗结论的风险
- 影响范围：
  - `README.md`
  - `docs/02-04`
  - `docs/07-08`
  - `docs/10-11`
  - `lib/app/presentation/pages/home_page.dart`
  - `lib/features/settings/`
  - `lib/features/report/presentation/pages/report_detail_page.dart`
  - 相关 widget / repository 测试
- 需要补的测试：
  - 首页首次免责弹窗（happy/boundary/failure）
  - `first_use_disclaimer_accepted` 读写与异常类型回退
  - 报告详情页尾免责说明展示
- 风险：
  - 弹窗文案较长，需关注小屏滚动可读性
  - 首次同意写入失败时会持续阻断首页入口

### 2026-03-19 - 客户端本地追问会话与 `/ai/intake` 主链路落地

- 原需求：
  - 新增记录主链路基于 `/ai/extract`
  - 没有本地追问会话、消息历史与恢复能力
  - 没有正式记录 `actionAdvice`
  - `symptomSummary` 允许客户端用 `rawText` 首句 fallback
- 新需求：
  - 新增记录默认切到 `POST /ai/intake`
  - 追问会话状态保存在客户端 Drift，不放到 worker
  - 正式记录与未完成追问草稿分离存储
  - 首页新增“追问模式”开关并本地持久化
  - `/records` 顶部新增“未完成追问”分区；首页不放“继续追问”入口
  - 新增 `/intake/:id` 追问页
  - 正式记录新增 `actionAdvice`
  - `symptomSummary` 只要字段存在且类型正确就原样保留，不再做 fallback 或内容纠偏
  - 支持强制结束追问、恢复未完成会话、基于已关联 session 重新追问并更新原记录
- 变更原因：
  - 需要让 AI 在信息不足时继续追问，同时保持 MVP 架构简单，不引入账号、云同步和服务端会话存储
  - 需要避免未完成草稿污染正式记录与报告
- 影响范围：
  - `README.md`
  - `docs/02-13`
  - 新增 ADR-0003
  - `lib/features/intake/`
  - `lib/features/settings/`
  - `lib/features/health_record/`
  - `lib/features/ai/`
  - `lib/core/database/`
  - 相关 widget / service / remote contract 测试
- 需要补的测试：
  - 追问模式开关
  - `/ai/intake` 契约
  - 会话落库、恢复、强制结束、重新追问
  - `/ai/extract` 回归
- 风险：
  - 本地状态机复杂度上升
  - 真实 worker 的 `/ai/intake` 行为仍需要额外验证

### 2026-03-18 - 真实 AI 验证收口与无毫秒 `eventTime`

- 原需求：
  - `eventTime` 只要求带 `+08:00`，未明确是否保留毫秒
  - mock 验证完成后是否必须立刻执行真实 AI 集成测试未固定
- 新需求：
  - 出站 `eventTime` 统一改为不带毫秒、带 `+08:00` 的 ISO 8601
  - 完成 mock 验证后，应评估并尽量执行真实 AI 集成测试
- 变更原因：
  - 真实上游对时间格式更严格
- 影响范围：
  - `README.md`
  - `docs/06`
  - `docs/08-12`
  - AI remote contract 相关实现与测试

### 2026-03-18 - 记录时间收敛为单一 `eventTime`

- 原需求：
  - 新增记录链路中同时维护 `eventStartTime`、`eventEndTime`、`createdAt`、`updatedAt`
- 新需求：
  - 用单一 `eventTime` 语义收敛记录时间，并映射到 `createdAt`
- 变更原因：
  - 降低字段复杂度，统一记录与报告时间口径

### 2026-03-17 - 文档体系迁移与补齐

- 原需求：
  - 仓库使用旧文档组织方式
- 新需求：
  - 迁移到编号文档体系，并要求代码、文档、测试同步维护
