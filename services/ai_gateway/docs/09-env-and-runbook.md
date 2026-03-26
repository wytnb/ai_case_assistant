# 环境与运行手册

## 官方参考

- Cloudflare Workers: https://developers.cloudflare.com/workers/
- Wrangler 配置: https://developers.cloudflare.com/workers/wrangler/configuration/
- Secrets: https://developers.cloudflare.com/workers/configuration/secrets/
- Limits: https://developers.cloudflare.com/workers/platform/limits/

## 环境清单

| 环境/阶段 | 说明 | 关键要求 |
| --- | --- | --- |
| 本地开发 | 使用 `.dev.vars` 提供本地绑定 | 至少配置 `DEEPSEEK_API_KEY` |
| 本地自动化测试 | 运行 `npm test` | 默认使用测试环境与 mock 上游 |
| live 测试 | 运行 `npm run test:live` | 需要真实 `DEEPSEEK_API_KEY` |
| 部署到 Cloudflare | 运行 `npm run deploy` | 触发强制闭环时为必做步骤 |

## 配置项

| 配置项 | 必填 | 说明 |
| --- | --- | --- |
| `DEEPSEEK_API_KEY` | 是 | DeepSeek 访问密钥 |
| `DEEPSEEK_MODEL` | 否 | 指定模型；非 chat 模型会回退到 `deepseek-chat` |
| `.dev.vars` | 本地必备 | 本地开发时存放 secrets，不写入 `wrangler.jsonc` |

配置规则：

- 密钥不要写入 `wrangler.jsonc`
- 本地开发使用 `.dev.vars`
- 若修改 `wrangler.jsonc` 中的绑定配置，需运行 `npx wrangler types`

`.dev.vars` 最小示例：

```dotenv
DEEPSEEK_API_KEY=your-deepseek-key
DEEPSEEK_MODEL=deepseek-chat
```

## 本地启动

以下命令都在 `services/ai_gateway/` 下执行。

1. `npm install`
2. 在当前目录创建 `.dev.vars`
3. 至少配置 `DEEPSEEK_API_KEY`
4. 执行 `npm run dev`

## 测试环境

- 本地自动化测试：`npm test`
  - 当前主要覆盖输入校验、路由、prompt/payload、格式化与兜底逻辑
- live 测试：`npm run test:live`
  - 需要真实 `DEEPSEEK_API_KEY`
  - 当前覆盖 `/ai/intake`、`/ai/report` 与 retired `/ai/extract`
- 线上 smoke：按 `docs/12-release-smoke-checklist.md`
  - 当改动触发强制闭环且成功部署后为必跑项

## 发布流程

### 文档-only 任务

1. 同步更新相关文档
2. 执行一致性检查，至少确认文档口径无冲突
3. 无需执行 `npm run deploy`

### 业务/运行时配置改动任务

当改动集合包含以下任一项时，触发“强制测试 + 部署闭环”：

- `src/**` 下任意文件改动
- 会影响线上运行行为的配置改动，至少包括 `wrangler.jsonc`、环境绑定相关配置

固定顺序如下：

1. `npm test`
2. `npm run test:live`
3. `npm run deploy`
4. 按 `docs/12-release-smoke-checklist.md` 执行线上 smoke

若任一步骤无法执行，必须在最终汇报中明确未执行项与阻塞原因，且该轮任务不得标记为“完成”。

## 常见故障

- `/ai/intake` 的 `status` / `question` / `actionAdvice` 不符合契约
- `/ai/intake.draft.symptomSummary` 的时间格式漂移
- Windows PowerShell 下 smoke 发送中文请求体后，服务端返回 `INVALID_JSON` 或把 `mergedRawText` 识别成乱码
- `/ai/report` 的 `advice` 退化为过短口号
- `POST /ai/extract` 仍被旧调用方访问而触发 `404`

## 排查步骤

1. 先看请求是否符合 `docs/06-api-contracts.md`
2. 再看本地自动化测试是否已覆盖当前变更
3. 若触发强制闭环，必须执行 `npm run test:live`
4. 若触发强制闭环并已部署，按 smoke 清单检查 intake happy path、follow-up、report happy path，以及 retired extract 的 `404`
5. 若 smoke 涉及中文请求体，优先按 `docs/12-release-smoke-checklist.md` 的“Windows 中文输入防踩坑”使用 Node `fetch + JSON.stringify`
