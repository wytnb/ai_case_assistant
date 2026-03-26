# ADR-0003-下线公开 `/ai/extract` 并将症状结构化能力收敛为内部实现

## 背景

在新增 `/ai/intake` 之后，公开接口同时存在：

- `/ai/intake`
- `/ai/extract`
- `/ai/report`

但实际业务已不再使用 `/ai/extract`。继续保留它会带来两个问题：

1. 公开契约面多于当前真实需要，增加维护和 smoke 成本
2. `/ai/intake` 提示词一度通过“`symptoms` 规则与 `/ai/extract` 一致”来复用规则描述，但模型并看不到另一个接口的提示词，导致这条规则失效

## 决策问题

当 `/ai/extract` 已不再被业务使用时，是否还应继续作为公开端点保留？

## 备选方案

1. 保留 `/ai/extract`，仅修复 intake 提示词
2. 将 `/ai/extract` 标记为 deprecated，但仍继续对外提供
3. 正式下线 `/ai/extract`，将症状结构化与摘要格式化能力保留为 Worker 内部实现

## 取舍分析

### 保留 `/ai/extract`

- 优点：改动最小
- 缺点：继续维护一个不再使用的公开契约，文档、测试、smoke 长期负担更高

### deprecated 保留

- 优点：给旧调用方过渡期
- 缺点：当前仓库并无保留过渡期的明确需求，仍需继续维护多余端点

### 正式下线

- 优点：
  - 对外契约收敛为当前真实需要的两个端点
  - intake 提示词可以直接自包含完整 `symptoms` 规则
  - 文档、测试、live、smoke 口径更一致
- 缺点：
  - 旧调用方若未迁移，会直接收到 `404`

## 最终决策

采用方案 3：

- 正式下线公开 `POST /ai/extract`
- 保留结构化 `symptoms` 校验与 `symptomSummary` 格式化逻辑，但仅作为内部实现细节
- `/ai/intake` 提示词直接写出完整 `symptoms` 规则，不再跨接口引用
- 退休后的 `/ai/extract` 请求统一按现有未知路径策略返回 `404 NOT_FOUND`

## 影响

- 当前公开业务端点收敛为 `/ai/intake` 与 `/ai/report`
- 文档、测试、live、smoke 和 runbook 需要同步清理 `/ai/extract` 作为当前能力的描述
- `DEBUG_AI_EXTRACT` 环境变量不再保留
- ADR-0002 中“复用 `/ai/extract` 摘要格式化”的现时表述被本 ADR 覆盖；ADR-0002 保留为历史记录

## 何时需要重新评估

- 若未来再次出现独立文本提取的明确业务需求
- 若需要为第三方调用方重新暴露结构化症状提取接口
