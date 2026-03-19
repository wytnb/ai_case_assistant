# 发布 Smoke 清单

当前仓库没有正式 CI/CD 或线上发布流水线。本清单用于本地演示包、阶段性发版候选和关键改动后的最小 smoke 检查。

## 发布前检查

- [ ] `README.md`、`docs/00-index.md`、相关设计文档已同步
- [ ] 如改了 Drift schema，已执行 `fvm flutter pub run build_runner build --delete-conflicting-outputs`
- [ ] `python scripts/check_doc_sync.py --working-tree --no-strict` 通过
- [ ] `fvm flutter analyze` 通过
- [ ] `fvm flutter test` 通过
- [ ] 已确认本次演示使用真实 AI 还是 mock
- [ ] 若使用真实 AI，`AI_API_BASE_URL` 可访问
- [ ] 若改动触及 `/ai/intake`、`/ai/extract`、网络层或主链路，已评估真实 AI 测试

## 核心闭环验证

- [ ] 首页可以正常打开，并看到“追问模式”开关
- [ ] 切换“追问模式”，关闭并重新打开应用后状态仍然保留
- [ ] 在追问模式关闭时新增一条记录，客户端直接完成，不进入追问页
- [ ] 在追问模式开启时新增一条记录，worker 返回 `needs_followup` 后进入追问页
- [ ] 在追问页继续补充一次，最终完成并生成正式记录
- [ ] 在追问页点击“退出追问，生成最终记录”，最终生成正式记录
- [ ] 追问进行到一半时关闭 App，重新进入 `/records` 后能看到“未完成追问”，并可恢复
- [ ] `/records` 顶部未完成追问分区不会把草稿混进正式记录列表
- [ ] 打开正式记录详情，能看到 `actionAdvice`
- [ ] 对已关联 intake session 的正式记录点击“继续补充并重新追问”，最终更新原记录而不是新建重复记录
- [ ] 生成一份报告，确认未完成追问不会进入报告结果

## 真实 AI 契约观察点

- [ ] `/ai/intake` 请求带 `followUpMode`
- [ ] `/ai/intake` 强制结束时请求带 `forceFinalize=true`
- [ ] `/ai/intake` 请求带完整 `messages`
- [ ] `/ai/extract` 与 `/ai/intake` 中 `symptomSummary=""` 不会被客户端改写
- [ ] 所有出站 `eventTime` 使用不带毫秒、带 `+08:00` 的 ISO 8601

## 回滚条件

- 首页或主入口无法打开
- `/records/new` 主链路连续失败
- `/intake/:id` 无法恢复或会话状态错乱
- 重新追问产生重复正式记录
- 未完成追问污染正式记录列表或报告
- 数据库升级后旧记录不可读
