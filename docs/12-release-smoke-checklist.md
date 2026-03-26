# 发布 Smoke 清单

当前仓库没有正式 CI/CD 或线上发布流水线。本清单用于 monorepo 下的本地演示包、阶段性发版候选和关键改动后的最小 smoke 检查。

## 发布前检查

- [ ] `README.md`、相关 docs、共享契约已同步
- [ ] `python scripts/check_doc_sync.py --working-tree --no-strict` 通过
- [ ] `python scripts/verify/check_ai_contract_sync.py` 通过
- [ ] `cd apps/ai_case_assistant && fvm flutter analyze` 通过
- [ ] `cd apps/ai_case_assistant && fvm flutter test` 通过
- [ ] 已判断本次只需默认快速验证，还是需要真实 AI 自动化 / 真机 / gateway 闭环
- [ ] 若改动触及 `/ai/intake`、`/ai/report`、`features/intake/`、`features/ai/`、`core/network/`、`core/config/` 或环境变量，已评估真实 AI 自动化
- [ ] 若改动触及 `services/ai_gateway/src/**` 或部署配置，已按服务侧文档评估 `npm test`、`npm run test:live`、`npm run deploy` 与 smoke

## app 侧核心闭环

- [ ] 首页可以正常打开
- [ ] 首页三个入口可以进入
- [ ] 纯文本新增记录主链路可以完成
- [ ] `/records` 可以打开，正式记录 / 草稿记录双 tab 可切换
- [ ] `/records/:id` 可以打开并执行删除正式记录
- [ ] `/intake/:id` 能继续追问或删除草稿
- [ ] `/reports` 与 `/reports/:id` 可以打开

## AI 契约观察点

- [ ] `/ai/intake` 请求带 `followUpMode`
- [ ] `/ai/intake` 强制结束时请求带 `forceFinalize=true`
- [ ] `/ai/intake` 请求带完整 `messages`
- [ ] `/ai/report` 只基于正式记录生成
- [ ] app 当前代码不再请求已退场的 `/ai/extract`

## Android 真机 smoke

以下情况必须上真机：

- 图片选择、附件相关逻辑变化
- `image_picker` 调用路径变化
- 附件复制、删除、回滚、本地文件路径变化
- 详情页图片预览、全屏预览变化
- Android 安装、启动、包体、权限、代理网络相关变化

真机检查项：

- [ ] 安装前已执行 `adb devices`，并确认目标真机状态为 `device`
- [ ] 在 `apps/ai_case_assistant/` 下执行过运行或打包命令
- [ ] 新增记录页可以打开系统相册
- [ ] 选图后缩略图正常显示
- [ ] 保存记录后附件已复制到应用私有目录并可回显
- [ ] 重启 App 后数据与附件仍可读取

## 可跳过与汇报要求

若有跳过，最终汇报必须写明：

- [ ] 跳过了哪一层验证
- [ ] 跳过原因
- [ ] 未覆盖的能力点
- [ ] 剩余风险
