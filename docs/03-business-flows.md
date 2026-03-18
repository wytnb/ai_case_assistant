# 业务流程

## 流程清单

- 新增健康记录
- 浏览健康记录
- 生成并查看健康报告

## 主流程

### 流程 1：新增健康记录

1. 用户进入 `/records/new`
2. 输入 `rawText`，可选选择多张图片
3. 页面先校验 `rawText.trim()` 非空且不超过 1000 字
4. 页面调用 `CreateHealthRecordController.createHealthRecord`
5. `HealthRecordService` 取一次客户端本地时间，作为本次记录唯一的 `eventTime`
6. 客户端调用 `/ai/extract`，请求体发送 `rawText` 与 `eventTime`
7. 客户端校验提取结果为合法对象，并规范化摘要与备注
8. 将健康事件写入 `health_events`，其中 `createdAt == updatedAt == eventTime`
9. 若有图片，复制到应用私有目录并写入 `attachments`
10. 返回列表页并提示“记录已保存”

### 流程 2：浏览健康记录

1. 用户进入 `/records`
2. 列表页读取本地 `health_events`，按 `createdAt` 倒序展示
3. 用户进入 `/records/:id`
4. 详情页分别读取记录与附件
5. 页面展示原始文本、摘要、备注、单一事件时间和图片预览

### 流程 3：生成并查看健康报告

1. 用户进入 `/reports`
2. 选择 `week`、`month` 或 `quarter`
3. 页面调用 `GenerateWeeklyReportController.generateReport`
4. `ReportService` 计算当前时间范围并读取范围内记录
5. 客户端调用 `/ai/report`，事件载荷使用单一 `eventTime`
6. 将结果写入或覆盖更新 `reports`
7. 列表页展示该类型报告，用户可进入 `/reports/:id` 查看详情

## 异常流程

- `rawText` 为空：前端表单校验阻止提交
- `rawText` 超过 1000 字：前端表单校验阻止提交
- 图片选择失败：页面弹出错误提示，不退出当前页面
- `/ai/extract` 返回非对象等非法 payload：保存取消，页面提示失败
- 附件复制或数据库写入失败：已复制附件回滚删除，本次记录不保存
- 记录列表或报告列表加载失败：页面展示错误态和重试入口
- 详情页找不到记录 / 报告：页面展示说明态
- `adviceJson` 解析失败：报告详情页降级为空建议列表

## 状态流转

| 对象 | 初始状态 | 触发动作 | 新状态 | 备注 |
|---|---|---|---|---|
| 健康记录创建 | idle | 点击保存 | submitting | 按钮禁用 |
| 健康记录创建 | submitting | AI 提取 + 落库成功 | success | 返回列表并提示成功 |
| 健康记录创建 | submitting | AI / 文件 / 数据库失败 | error | 保留当前页并提示失败 |
| 记录列表 | loading | 查询成功 | loaded | 为空时展示空状态 |
| 记录列表 | loading | 查询失败 | error | 可重试 |
| 报告生成 | idle | 点击生成 | generating | 按钮禁用 |
| 报告生成 | generating | AI 返回合法结果 | success | 写入或覆盖 `reports` |
| 报告生成 | generating | AI / 数据失败 | error | 页面提示失败 |

## 前置条件

- 设备已安装应用并具备本地读写权限
- AI 提取与报告生成依赖的基地址可访问，或新增记录链路启用了 mock 提取
- 若要保存图片附件，用户已从系统相册成功选择图片

## 后置条件

- 新增记录成功后，本地数据库中存在健康事件，若有图片则存在附件记录
- 报告生成成功后，本地数据库中存在对应 `reportType + rangeStart + rangeEnd` 的有效报告
- 失败路径下不会出现“看似成功但实际未保存”的状态

## 待确认问题

- 当报告时间范围内没有任何健康事件时，上游 `/ai/report` 应返回空报告、提示性报告还是失败，当前未在客户端固定
- 未来若引入编辑 / 删除，历史附件的清理策略需要单独确认
