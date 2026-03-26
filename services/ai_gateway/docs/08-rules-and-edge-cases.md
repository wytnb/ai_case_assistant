# 规则与边界

## 规则清单

1. `/ai/intake.messages[*].content` 会先 `trim()` 再进入主流程
2. `/ai/intake.messages[*].content` 的总长度上限为 `6000` 个字符
3. `/ai/intake.eventTime` 必须存在，且必须是带 `+08:00` 的 ISO 8601 字符串
4. `/ai/intake.eventTime` 是 intake 阶段唯一时间锚点
5. `/ai/intake.draft.mergedRawText` 只合并 `user` 消息
6. `/ai/intake.messages[]` 需要按顺序理解：`role=user` 代表患者，`role=assistant` 代表 AI，`content` 为对应问题或回答
7. 除第 `0` 条外，读取第 `n` 条 `content` 时，需要结合第 `n-1` 条 `content` 的问答语义，并同时综合整个 `messages[]` 历史
8. 解释 `/ai/intake.messages[*].content` 中的相对时间时，必须始终与请求 `eventTime` 关联，不能使用模型自己的当前时间
9. `/ai/intake.question` 在 `needs_followup` 时必须是非空字符串，在 `final` 时必须为 `null`
10. `/ai/intake.question` 的问题范围是“当前健康记录相关”，不限于症状与持续时间
11. Worker 负责把结构化症状列表格式化为稳定的 `draft.symptomSummary`
12. 对非空 `mergedRawText`，除非输入本身完全没有可读信息，否则 intake 不应同时得到空 `symptoms` 和空 `notes`
13. `/ai/report.events[]` 每个对象都必须显式包含 `eventTime`、`rawText`、`symptomSummary`、`notes`
14. `/ai/report` 的业务正文总长度上限为 `10000`
15. `/ai/report.markdown` 必须与 `title`、`summary`、`advice` 语义一致，不得互相矛盾
16. 诊断意见只允许出现在自由文本字段中，不进入 `symptoms[].name`
17. 诊断意见必须使用审慎、非确定性表达，不能写成最终医学确诊
18. 诊断意见必须基于当前输入证据，不能臆造未提供事实

## 优先级

1. `/ai/intake.forceFinalize=true` 的优先级最高
2. `/ai/intake.followUpMode=false` 时，对外必须返回 `final`
3. 只有在未被前两条覆盖时，才根据“信息是否足够”决定 `needs_followup` 或 `final`
4. 时间解释优先级以请求 `eventTime` 为准，高于模型自己的当前时间
5. 对明显可读但上游产出双空草稿的情况，先严格重试，再执行本地兜底

## 边界条件

### `/ai/intake`

- `messages` 必须是非空数组
- `messages[*].role` 只能是 `user` 或 `assistant`
- `messages[*].content` 必须是非空字符串
- `symptoms[].name` 表示症状或不适标签，不是诊断结论
- `symptoms[].startTime` 表示症状开始时间或可推断下界
- `symptoms[].endTime` 表示症状结束时间或可推断上界；若未明确提及结束时间，包括“仍在持续”，默认回填为 `eventTime`
- `symptoms[].precision` 只能是 `date` 或 `datetime`
- `actionAdvice` 可包含操作/观察建议或审慎诊断意见，但诊断意见必须使用“可能与…有关”“提示…可能性”等非确定性措辞

### `/ai/report`

- `events` 允许为空数组
- `events=[]` 时直接返回本地空报告，不调用 DeepSeek
- `advice` 必须是完整建议句数组，不能退化为口号式短语
- `summary` / `markdown` 若出现诊断意见，必须与 `advice` 保持一致，且同样保持审慎、非确定性措辞

### `symptomSummary`

- 日期使用 `YYYY-MM-DD`
- 日期时间使用 `YYYY-MM-DD HH:mm`
- 同一个症状的展示格式为：`症状（时间描述）`
- 多个症状使用换行符 `\n` 分隔，每个症状独占一行
- 单侧边界统一使用区间占位；两侧都缺失时统一显示 `时间未说明`

## 冲突处理

- 当 `forceFinalize=true` 或 `followUpMode=false` 时，若上游返回 `needs_followup`，Worker 仍对外返回 `final`
- 当上游在 `needs_followup` 场景下已识别出部分 `symptoms` 或 `notes` 时，应优先保留，不应默认清空
- 当上游对明显可读的非空 `mergedRawText` 返回 `final` 且双空，Worker 会先严格重试一次；若仍双空，则本地兜底为 `symptomSummary` 或 `notes`
- 当报告输入为空事件列表时，直接走本地空报告分支，不再与上游生成逻辑竞争
- 当结构化症状字段与自由文本字段同时出现时，`symptoms[].name` 继续承载症状标签，诊断倾向只保留在 `actionAdvice`、`summary`、`advice`、`markdown`

## 异常场景

- 非法 JSON：返回 `400 INVALID_JSON`
- 缺失字段、类型错误、超长、非法 `eventTime`：返回 `400 INVALID_INPUT`
- 上游不可达或返回非 `2xx`：返回 `502 UPSTREAM_HTTP_ERROR`
- 上游返回结构不符合要求：返回 `502 UPSTREAM_INVALID_PAYLOAD`
- `/ai/extract` 相关请求：当前统一返回 `404 NOT_FOUND`

## 默认兜底行为

- `question` 多个问题时使用换行分隔，每行一个可直接回答的问题
- `endTime` 未明确提及时按 `eventTime` 回填，作为本次记录观察终点
- `draft.symptomSummary` 始终由 Worker 本地格式化，而不是直接使用模型拼接文本
- 若上游两次都把明显可读的非空输入提取成双空草稿，Worker 会按本地保守规则回填 `symptomSummary` 或 `notes`
- 未知路径与已知路径上的非 `POST` 请求统一返回 `404 NOT_FOUND`
