# 发布 Smoke 清单

## 发布前检查

- `npm test` 通过
- `npm run test:live` 通过
- 文档、测试、代码已同步
- 本次如果新增了 ADR，`docs/00-index.md` 已更新

## 发布后检查

- `OPTIONS /ai/intake` 返回 `204`
- `POST /ai/intake` happy path 返回 `200`
- `POST /ai/report` happy path 返回 `200`
- `POST /ai/extract` 返回 `404`

## 核心闭环验证

### `/ai/intake` 预检

```bash
curl -i -X OPTIONS "https://ai-api-worker.wytai.workers.dev/ai/intake"
```

断言：

- HTTP `204`
- 包含 CORS 头

### `/ai/intake` happy path

```bash
curl -i -X POST "https://ai-api-worker.wytai.workers.dev/ai/intake" \
  -H "Content-Type: application/json" \
  -d "{\"followUpMode\":true,\"forceFinalize\":true,\"eventTime\":\"2026-03-18T18:00:00+08:00\",\"messages\":[{\"role\":\"user\",\"content\":\"最近三天心脏不舒服。\"}]}"
```

断言：

- HTTP `200`
- 返回字段包含 `status`、`question`、`draft`
- `draft` 中包含 `mergedRawText`、`symptomSummary`、`notes`、`actionAdvice`
- `symptomSummary` 不应为空字符串
- `symptomSummary` 的结束边界应体现 `eventTime` 对应日期，本例应包含 `2026-03-18`

### `/ai/intake` follow-up

```bash
curl -i -X POST "https://ai-api-worker.wytai.workers.dev/ai/intake" \
  -H "Content-Type: application/json" \
  -d "{\"followUpMode\":true,\"forceFinalize\":false,\"eventTime\":\"2026-03-18T18:00:00+08:00\",\"messages\":[{\"role\":\"user\",\"content\":\"不太舒服。\"}]}"
```

断言：

- HTTP `200`
- `status` 为 `needs_followup`
- `question` 为非空字符串

### `/ai/report`

```bash
curl -i -X POST "https://ai-api-worker.wytai.workers.dev/ai/report" \
  -H "Content-Type: application/json" \
  -d "{\"reportType\":\"week\",\"rangeStart\":\"2026-03-01\",\"rangeEnd\":\"2026-03-07\",\"events\":[{\"eventTime\":\"2026-03-02T18:30:00+08:00\",\"rawText\":\"轻微头痛，休息后缓解。\",\"symptomSummary\":\"头痛（2026-03-02）\",\"notes\":null}]}"
```

断言：

- HTTP `200`
- 返回字段包含 `title`、`summary`、`advice`、`markdown`
- `advice` 为非空数组
- `advice[0]` 不是口号式短语

### retired `/ai/extract`

```bash
curl -i -X POST "https://ai-api-worker.wytai.workers.dev/ai/extract" \
  -H "Content-Type: application/json" \
  -d "{\"rawText\":\"最近三天心脏不舒服。\",\"eventTime\":\"2026-03-18T18:00:00+08:00\"}"
```

断言：

- HTTP `404`
- 响应体为：

```json
{
  "error": {
    "code": "NOT_FOUND",
    "message": "Route not found."
  }
}
```

## 监控项

- 当前仓库未在 `docs/` 中沉淀独立监控面板或告警规则
- 至少确认 smoke 响应中没有出现 `UPSTREAM_*` 或 `INTERNAL_ERROR` 错误结构
- 若本轮涉及真实部署，记录部署时间与 smoke 结果，便于后续排查

## 回滚条件

- `/ai/intake` 成功响应结构发生非预期变化
- `/ai/intake` 在 `followUpMode=false` 或 `forceFinalize=true` 时仍返回 `needs_followup`
- `/ai/report` 成功响应结构发生非预期变化
- `/ai/report.advice` 退化为明显过短的口号
- `/ai/extract` 没有返回 `404`

## 回滚说明

- 待确认：当前 `docs/` 中未沉淀独立回滚脚本或分步骤回滚手册
- 若需要回滚，应先恢复到最近一次已验证通过的部署版本，再重新执行本清单

## Windows 中文输入防踩坑（本次复盘）

### 这次遇到的问题

1. 在 Windows PowerShell 里直接拼接 JSON 字符串调用 `curl/curl.exe`，容易因为引号与转义问题触发 `400 INVALID_JSON`
2. 某些执行方式下，中文可能变成 `????`，导致 `/ai/intake` 识别为乱码
3. 在 PowerShell 字符串里写 `\u4e2d\u6587` 不会自动转成中文字符，可能原样发给服务端

### 统一推荐做法（避免再试错）

- 对包含中文请求体的 smoke，统一使用 Node `fetch + JSON.stringify`
- 中文内容可在 JS 字符串里用 `\uXXXX` 表示，Node 会正确解码
- 先检查 `/ai/intake` 返回的 `draft.mergedRawText` 是否仍是可读中文，再做后续业务断言

可直接使用以下命令：

```bash
node -e "(async()=>{const base='https://ai-api-worker.wytai.workers.dev'; const opts=await fetch(base+'/ai/intake',{method:'OPTIONS'}); const intakeHappyBody={followUpMode:true,forceFinalize:true,eventTime:'2026-03-18T18:00:00+08:00',messages:[{role:'user',content:'\u6700\u8fd1\u4e09\u5929\u5fc3\u810f\u4e0d\u8212\u670d\u3002'}]}; const intakeHappyResp=await fetch(base+'/ai/intake',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify(intakeHappyBody)}); const intakeHappy=await intakeHappyResp.json(); const intakeFollowBody={followUpMode:true,forceFinalize:false,eventTime:'2026-03-18T18:00:00+08:00',messages:[{role:'user',content:'\u4e0d\u592a\u8212\u670d\u3002'}]}; const intakeFollowResp=await fetch(base+'/ai/intake',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify(intakeFollowBody)}); const intakeFollow=await intakeFollowResp.json(); const reportBody={reportType:'week',rangeStart:'2026-03-01',rangeEnd:'2026-03-07',events:[{eventTime:'2026-03-02T18:30:00+08:00',rawText:'\u8f7b\u5fae\u5934\u75db\uff0c\u4f11\u606f\u540e\u7f13\u89e3\u3002',symptomSummary:'\u5934\u75db\uff082026-03-02\uff09',notes:null}]}; const reportResp=await fetch(base+'/ai/report',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify(reportBody)}); const report=await reportResp.json(); const extractResp=await fetch(base+'/ai/extract',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({rawText:'\u6700\u8fd1\u4e09\u5929\u5fc3\u810f\u4e0d\u8212\u670d\u3002',eventTime:'2026-03-18T18:00:00+08:00'})}); const extractText=await extractResp.text(); console.log(JSON.stringify({options:{status:opts.status,allowOrigin:opts.headers.get('access-control-allow-origin'),allowMethods:opts.headers.get('access-control-allow-methods')},intakeHappy:{status:intakeHappyResp.status,intakeStatus:intakeHappy.status,mergedRawText:intakeHappy?.draft?.mergedRawText,symptomSummary:intakeHappy?.draft?.symptomSummary},intakeFollow:{status:intakeFollowResp.status,intakeStatus:intakeFollow.status,questionLength:(intakeFollow.question||'').trim().length},report:{status:reportResp.status,hasTitle:!!report.title,adviceCount:Array.isArray(report.advice)?report.advice.length:0,firstAdviceLength:Array.isArray(report.advice)&&report.advice[0]?report.advice[0].trim().length:0},extract:{status:extractResp.status,body:extractText}},null,2));})();"
```
