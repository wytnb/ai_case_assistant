import { afterEach, describe, expect, it, vi } from 'vitest';
import { createExecutionContext, waitOnExecutionContext } from 'cloudflare:test';
import worker from '../src/index';

const IncomingRequest = Request<unknown, IncomingRequestCfProperties>;
const EVENT_TIME = '2026-03-18T18:00:00+08:00';
type TestEnv = ReturnType<typeof makeEnvBase>;
type TestExecutionContext = ReturnType<typeof createExecutionContext>;
type WorkerFetchWithCtx = (request: Request, env: TestEnv, ctx: TestExecutionContext) => Promise<Response>;

function invokeWorker(request: Request, env: TestEnv, ctx: TestExecutionContext): Promise<Response> {
	return (worker.fetch as unknown as WorkerFetchWithCtx)(request, env, ctx);
}

function makeEnv(overrides: Partial<ReturnType<typeof makeEnvBase>> = {}) {
	return {
		...makeEnvBase(),
		...overrides,
	};
}

function makeEnvBase() {
	return {
		DEEPSEEK_API_KEY: 'test-key',
		DEEPSEEK_MODEL: 'deepseek-chat',
	};
}

function makeDeepSeekResponse(content: string): Response {
	return new Response(
		JSON.stringify({
			choices: [
				{
					message: {
						content,
					},
				},
			],
		}),
		{
			status: 200,
			headers: { 'content-type': 'application/json' },
		},
	);
}

function repeatedChinese(length: number): string {
	return '中'.repeat(length);
}

function makeIntakeBody(
	overrides: Partial<{
		followUpMode: boolean;
		forceFinalize: boolean;
		eventTime: string;
		messages: Array<{ role: string; content: string }>;
	}> = {},
) {
	return {
		followUpMode: true,
		forceFinalize: false,
		eventTime: EVENT_TIME,
		messages: [{ role: 'user', content: '最近两天头痛。' }],
		...overrides,
	};
}

function getRequestPayloadFromMock(
	mock: { mock: { calls: Array<Parameters<typeof globalThis.fetch>> } },
	callIndex = 0,
): {
	model: string;
	messages: Array<{ role: string; content: string }>;
	response_format: { type: string };
	max_tokens: number;
} {
	const selectedCall = mock.mock.calls[callIndex];
	expect(selectedCall).toBeTruthy();
	const init = selectedCall?.[1];
	expect(init).toBeTruthy();
	expect(typeof init?.body).toBe('string');

	return JSON.parse(init!.body as string) as {
		model: string;
		messages: Array<{ role: string; content: string }>;
		response_format: { type: string };
		max_tokens: number;
	};
}

afterEach(() => {
	vi.restoreAllMocks();
});

describe('/ai/intake', () => {
	it('sends self-contained intake prompts and returns a final draft with local symptomSummary formatting', async () => {
		const fetchSpy = vi.spyOn(globalThis, 'fetch').mockResolvedValue(
			makeDeepSeekResponse(
				'{"status":"final","question":null,"symptoms":[{"name":"头痛","startTime":"2026-03-17","endTime":"2026-03-18","precision":"date"}],"notes":"昨晚吃了止痛药。","actionAdvice":"建议继续观察症状变化，如明显加重请及时就医。"}',
			),
		);

		const request = new IncomingRequest('https://example.com/ai/intake', {
			method: 'POST',
			headers: { 'content-type': 'application/json' },
			body: JSON.stringify(
				makeIntakeBody({
					messages: [
						{ role: 'user', content: '最近两天头痛。' },
						{ role: 'assistant', content: '具体哪里头痛？' },
						{ role: 'user', content: '昨晚吃了止痛药。' },
					],
				}),
			),
		});
		const ctx = createExecutionContext();
		const response = await invokeWorker(request, makeEnv(), ctx);
		await waitOnExecutionContext(ctx);

		expect(response.status).toBe(200);
		await expect(response.json()).resolves.toEqual({
			status: 'final',
			question: null,
			draft: {
				mergedRawText: '最近两天头痛。\n昨晚吃了止痛药。',
				symptomSummary: '头痛（2026-03-17 至 2026-03-18）',
				notes: '昨晚吃了止痛药。',
				actionAdvice: '建议继续观察症状变化，如明显加重请及时就医。',
			},
		});

		const payload = getRequestPayloadFromMock(fetchSpy);
		expect(payload.max_tokens).toBe(1024);
		expect(payload.messages[0]?.content).toContain('symptoms 必须是数组；数组中的每一项必须包含 name、startTime、endTime、precision。');
		expect(payload.messages[0]?.content).toContain('如果未明确提及症状结束日期/时间，endTime 默认使用 eventTime（今天/eventTime 口径）。');
		expect(payload.messages[0]?.content).toContain('当 precision 为 "date" 且缺少明确结束时间时，endTime 必须回填为 eventTime 的日期部分（YYYY-MM-DD）。');
		expect(payload.messages[0]?.content).toContain('当 precision 为 "datetime" 且缺少明确结束时间时，endTime 必须回填为 eventTime 完整时间（带 +08:00 偏移量）。');
		expect(payload.messages[0]?.content).toContain('即使语义是“仍在持续”，也将 endTime 回填为 eventTime，作为本次记录的观察终点。');
		expect(payload.messages[0]?.content).toContain('如果只能推断单侧边界，startTime 允许为 null；endTime 仍按上述默认规则处理。');
		expect(payload.messages[0]?.content).toContain('如果无法可靠推断开始时间，startTime 返回 null。');
		expect(payload.messages[0]?.content).toContain('同一个症状如果在消息历史里多次出现但指向同一个持续过程，请合并为一个 symptom。');
		expect(payload.messages[0]?.content).toContain('否认信息、诱因、缓解或加重情况、生活背景、用药或就医描述、其他补充说明，都必须放在 notes 中。');
		expect(payload.messages[0]?.content).toContain('其中 role 为 "user" 代表患者，role 为 "assistant" 代表 AI。');
		expect(payload.messages[0]?.content).toContain('读取 messages 中任何 content 时，都必须把内容和语义与这个 eventTime 关联起来理解。');
		expect(payload.messages[0]?.content).toContain('status 判定优先级：先判断 forceFinalize 与 followUpMode，再判断信息是否足够。');
		expect(payload.messages[0]?.content).toContain('当 status 为 "needs_followup" 时，即使需要追问，也要尽量保留已确定的 symptoms 或 notes，不要默认清空。');
		expect(payload.messages[0]?.content).toContain('name 表示症状或不适标签，不是诊断结论。');
		expect(payload.messages[0]?.content).toContain('startTime 表示症状开始时间。');
		expect(payload.messages[0]?.content).toContain('endTime 表示症状结束时间。');
		expect(payload.messages[0]?.content).toContain('notes 用于承载非正向症状信息与补充上下文。');
		expect(payload.messages[0]?.content).toContain('actionAdvice 用于基于当前信息给出中性、谨慎、可执行的操作/观察建议/诊断。');
		expect(payload.messages[0]?.content).toContain('对于已经通过校验且包含可读患者描述的 messages，除非患者描述本身完全没有可读信息，否则不允许同时返回空的 symptoms 和空的 notes。');
		expect(payload.messages[0]?.content).not.toContain('/ai/extract');
		expect(payload.messages[0]?.content).not.toContain('mergedRawText');
		expect(payload.messages[1]?.content).toContain('role 为 user 表示患者，role 为 assistant 表示 AI。');
		expect(payload.messages[1]?.content).toContain('除第 0 条外，第 n 条 content 都要结合第 n-1 条 content 所对应的问题或回答来理解');
		expect(payload.messages[1]?.content).toContain('读取 messages 中任何 content 时，都必须把内容和语义与 eventTime 关联起来理解；所有相对时间都必须以 eventTime 为准。');
		expect(payload.messages[1]?.content).toContain('字段语义：status 表示是否继续追问');
		expect(payload.messages[1]?.content).toContain('question 表示下一轮需补齐的信息；symptoms 表示已识别的正向症状；notes 表示非正向症状补充信息；actionAdvice 表示保守建议。');
		expect(payload.messages[1]?.content).toContain('判定规则：当 forceFinalize=true 或 followUpMode=false 时，必须返回 final。');
		expect(payload.messages[1]?.content).toContain('即使返回 needs_followup，也要尽量保留已确定的 symptoms 与 notes，不要默认清空。');
		expect(payload.messages[1]?.content).toContain('若未明确提及结束时间（包括“仍在持续”），endTime 默认回填 eventTime（date 用当天，datetime 用完整时间）');
		expect(payload.messages[1]?.content).toContain('除非 messages 中患者描述本身完全没有可读信息，否则不要返回 {"symptoms":[],"notes":""}。');
		expect(payload.messages[0]?.content).not.toContain('如果无法可靠推断任何时间，startTime 和 endTime 都返回 null。');
		expect(payload.messages[1]?.content).not.toContain('仍在持续时为 null');
		expect(payload.messages[1]?.content).toContain('"role":"assistant","content":"具体哪里头痛？"');
		expect(payload.messages[1]?.content).not.toContain('worker 会');
		expect(payload.messages[1]?.content).not.toContain('mergedRawText：');
		expect(payload.messages[1]?.content).not.toContain('symptomSummary 字段');
	});

	it('returns needs_followup with a multi-line question when information is insufficient', async () => {
		vi.spyOn(globalThis, 'fetch').mockResolvedValue(
			makeDeepSeekResponse(
				'{"status":"needs_followup","question":"具体是哪里不舒服？\\n这种情况持续了多久？\\n最近有没有自己先吃药？","symptoms":[],"notes":"","actionAdvice":""}',
			),
		);

		const request = new IncomingRequest('https://example.com/ai/intake', {
			method: 'POST',
			headers: { 'content-type': 'application/json' },
			body: JSON.stringify(
				makeIntakeBody({
					messages: [{ role: 'user', content: '不太舒服。' }],
				}),
			),
		});
		const ctx = createExecutionContext();
		const response = await invokeWorker(request, makeEnv(), ctx);
		await waitOnExecutionContext(ctx);

		expect(response.status).toBe(200);
		await expect(response.json()).resolves.toEqual({
			status: 'needs_followup',
			question: '具体是哪里不舒服？\n这种情况持续了多久？\n最近有没有自己先吃药？',
			draft: {
				mergedRawText: '不太舒服。',
				symptomSummary: '',
				notes: '',
				actionAdvice: '',
			},
		});
	});

	it('forces final when followUpMode is false even if DeepSeek wants to continue asking questions', async () => {
		vi.spyOn(globalThis, 'fetch').mockResolvedValue(
			makeDeepSeekResponse(
				'{"status":"needs_followup","question":"具体是哪里不舒服？\\n最近有没有发烧？","symptoms":[{"name":"头痛","startTime":"2026-03-18","endTime":"2026-03-18","precision":"date"}],"notes":"","actionAdvice":"建议先休息并观察变化。"}',
			),
		);

		const request = new IncomingRequest('https://example.com/ai/intake', {
			method: 'POST',
			headers: { 'content-type': 'application/json' },
			body: JSON.stringify(makeIntakeBody({ followUpMode: false })),
		});
		const ctx = createExecutionContext();
		const response = await invokeWorker(request, makeEnv(), ctx);
		await waitOnExecutionContext(ctx);

		expect(response.status).toBe(200);
		await expect(response.json()).resolves.toEqual({
			status: 'final',
			question: null,
			draft: {
				mergedRawText: '最近两天头痛。',
				symptomSummary: '头痛（2026-03-18）',
				notes: '',
				actionAdvice: '建议先休息并观察变化。',
			},
		});
	});

	it('forces final when forceFinalize is true even if DeepSeek returns needs_followup', async () => {
		vi.spyOn(globalThis, 'fetch').mockResolvedValue(
			makeDeepSeekResponse(
				'{"status":"needs_followup","question":"最近有没有发烧？","symptoms":[],"notes":"目前只知道头痛。","actionAdvice":"建议继续观察症状变化。"}',
			),
		);

		const request = new IncomingRequest('https://example.com/ai/intake', {
			method: 'POST',
			headers: { 'content-type': 'application/json' },
			body: JSON.stringify(makeIntakeBody({ forceFinalize: true })),
		});
		const ctx = createExecutionContext();
		const response = await invokeWorker(request, makeEnv(), ctx);
		await waitOnExecutionContext(ctx);

		expect(response.status).toBe(200);
		await expect(response.json()).resolves.toEqual({
			status: 'final',
			question: null,
			draft: {
				mergedRawText: '最近两天头痛。',
				symptomSummary: '',
				notes: '目前只知道头痛。',
				actionAdvice: '建议继续观察症状变化。',
			},
		});
	});

	it('formats one-sided and unknown time ranges in symptomSummary', async () => {
		vi.spyOn(globalThis, 'fetch').mockResolvedValue(
			makeDeepSeekResponse(
				'{"status":"final","question":null,"symptoms":[{"name":"咳嗽","startTime":"2026-03-18","endTime":null,"precision":"date"},{"name":"胸闷","startTime":null,"endTime":"2026-03-18","precision":"date"},{"name":"心悸","startTime":"2026-03-18T09:30:00+08:00","endTime":null,"precision":"datetime"},{"name":"气短","startTime":null,"endTime":"2026-03-18T10:00:00+08:00","precision":"datetime"},{"name":"头晕","startTime":null,"endTime":null,"precision":"date"}],"notes":"吃辣后会加重。","actionAdvice":""}',
			),
		);

		const request = new IncomingRequest('https://example.com/ai/intake', {
			method: 'POST',
			headers: { 'content-type': 'application/json' },
			body: JSON.stringify(
				makeIntakeBody({
					messages: [{ role: 'user', content: '今天开始咳嗽，有点头晕，吃辣后会加重。' }],
				}),
			),
		});
		const ctx = createExecutionContext();
		const response = await invokeWorker(request, makeEnv(), ctx);
		await waitOnExecutionContext(ctx);

		expect(response.status).toBe(200);
		await expect(response.json()).resolves.toEqual({
			status: 'final',
			question: null,
			draft: {
				mergedRawText: '今天开始咳嗽，有点头晕，吃辣后会加重。',
				symptomSummary:
					'咳嗽（2026-03-18 至 不明日期）\n胸闷（不明日期 至 2026-03-18）\n心悸（2026-03-18 09:30 至 不明时间）\n气短（不明时间 至 2026-03-18 10:00）\n头晕（时间未说明）',
				notes: '吃辣后会加重。',
				actionAdvice: '',
			},
		});
	});

	it('retries intake once with a stricter prompt when a final draft is double-empty for non-empty input', async () => {
		const fetchSpy = vi
			.spyOn(globalThis, 'fetch')
			.mockResolvedValueOnce(
				makeDeepSeekResponse(
					'{"status":"final","question":null,"symptoms":[],"notes":"","actionAdvice":""}',
				),
			)
			.mockResolvedValueOnce(
				makeDeepSeekResponse(
					'{"status":"final","question":null,"symptoms":[{"name":"心脏不舒服","startTime":"2026-03-16","endTime":"2026-03-18","precision":"date"}],"notes":"","actionAdvice":"建议继续观察症状变化。"}',
				),
			);

		const request = new IncomingRequest('https://example.com/ai/intake', {
			method: 'POST',
			headers: { 'content-type': 'application/json' },
			body: JSON.stringify(
				makeIntakeBody({
					forceFinalize: true,
					messages: [{ role: 'user', content: '最近三天心脏不舒服。' }],
				}),
			),
		});
		const ctx = createExecutionContext();
		const response = await invokeWorker(request, makeEnv(), ctx);
		await waitOnExecutionContext(ctx);

		expect(response.status).toBe(200);
		expect(fetchSpy).toHaveBeenCalledTimes(2);
		const secondPayload = getRequestPayloadFromMock(fetchSpy, 1);
		expect(secondPayload.messages[0]?.content).toContain('重要补充：本次是纠偏重试。');
		expect(secondPayload.messages[1]?.content).toContain('这是一次严格重试：请纠正上一次把包含可读患者描述的 messages 提取成空 symptoms 和空 notes 的结果。');
		expect(secondPayload.messages[0]?.content).not.toContain('mergedRawText');
		expect(secondPayload.messages[1]?.content).not.toContain('mergedRawText');
		await expect(response.json()).resolves.toEqual({
			status: 'final',
			question: null,
			draft: {
				mergedRawText: '最近三天心脏不舒服。',
				symptomSummary: '心脏不舒服（2026-03-16 至 2026-03-18）',
				notes: '',
				actionAdvice: '建议继续观察症状变化。',
			},
		});
	});

	it('falls back to local symptom inference when strict retry still returns a double-empty final draft', async () => {
		const fetchSpy = vi
			.spyOn(globalThis, 'fetch')
			.mockResolvedValueOnce(
				makeDeepSeekResponse('{"status":"final","question":null,"symptoms":[],"notes":"","actionAdvice":""}'),
			)
			.mockResolvedValueOnce(
				makeDeepSeekResponse('{"status":"final","question":null,"symptoms":[],"notes":"","actionAdvice":""}'),
			);

		const request = new IncomingRequest('https://example.com/ai/intake', {
			method: 'POST',
			headers: { 'content-type': 'application/json' },
			body: JSON.stringify(
				makeIntakeBody({
					forceFinalize: true,
					messages: [{ role: 'user', content: '最近三天心脏不舒服。' }],
				}),
			),
		});
		const ctx = createExecutionContext();
		const response = await invokeWorker(request, makeEnv(), ctx);
		await waitOnExecutionContext(ctx);

		expect(response.status).toBe(200);
		expect(fetchSpy).toHaveBeenCalledTimes(2);
		await expect(response.json()).resolves.toEqual({
			status: 'final',
			question: null,
			draft: {
				mergedRawText: '最近三天心脏不舒服。',
				symptomSummary: '心脏不舒服（2026-03-16 至 2026-03-18）',
				notes: '',
				actionAdvice: '',
			},
		});
	});

	it('accepts empty notes and actionAdvice strings when symptoms are present', async () => {
		vi.spyOn(globalThis, 'fetch').mockResolvedValue(
			makeDeepSeekResponse(
				'{"status":"final","question":null,"symptoms":[{"name":"头痛","startTime":"2026-03-17","endTime":"2026-03-18","precision":"date"}],"notes":"","actionAdvice":""}',
			),
		);

		const request = new IncomingRequest('https://example.com/ai/intake', {
			method: 'POST',
			headers: { 'content-type': 'application/json' },
			body: JSON.stringify(makeIntakeBody()),
		});
		const ctx = createExecutionContext();
		const response = await invokeWorker(request, makeEnv(), ctx);
		await waitOnExecutionContext(ctx);

		expect(response.status).toBe(200);
		await expect(response.json()).resolves.toEqual({
			status: 'final',
			question: null,
			draft: {
				mergedRawText: '最近两天头痛。',
				symptomSummary: '头痛（2026-03-17 至 2026-03-18）',
				notes: '',
				actionAdvice: '',
			},
		});
	});

	it('returns NOT_FOUND for retired POST /ai/extract requests', async () => {
		const fetchSpy = vi.spyOn(globalThis, 'fetch');
		const request = new IncomingRequest('https://example.com/ai/extract', {
			method: 'POST',
			headers: { 'content-type': 'application/json' },
			body: JSON.stringify({ rawText: '最近三天心脏不舒服。', eventTime: EVENT_TIME }),
		});
		const ctx = createExecutionContext();
		const response = await invokeWorker(request, makeEnv(), ctx);
		await waitOnExecutionContext(ctx);

		expect(response.status).toBe(404);
		expect(fetchSpy).not.toHaveBeenCalled();
		await expect(response.json()).resolves.toEqual({
			error: {
				code: 'NOT_FOUND',
				message: 'Route not found.',
			},
		});
	});

	it('returns NOT_FOUND for non-POST /ai/intake requests', async () => {
		const request = new IncomingRequest('https://example.com/ai/intake', {
			method: 'GET',
		});
		const ctx = createExecutionContext();
		const response = await invokeWorker(request, makeEnv(), ctx);
		await waitOnExecutionContext(ctx);

		expect(response.status).toBe(404);
		await expect(response.json()).resolves.toEqual({
			error: {
				code: 'NOT_FOUND',
				message: 'Route not found.',
			},
		});
	});

	it('keeps unknown paths returning NOT_FOUND', async () => {
		const request = new IncomingRequest('https://example.com/not-found', {
			method: 'GET',
		});
		const ctx = createExecutionContext();
		const response = await invokeWorker(request, makeEnv(), ctx);
		await waitOnExecutionContext(ctx);

		expect(response.status).toBe(404);
		await expect(response.json()).resolves.toEqual({
			error: {
				code: 'NOT_FOUND',
				message: 'Route not found.',
			},
		});
	});

	it('returns INVALID_INPUT when followUpMode is missing', async () => {
		const fetchSpy = vi.spyOn(globalThis, 'fetch');
		const body = makeIntakeBody();
		delete (body as { followUpMode?: boolean }).followUpMode;

		const request = new IncomingRequest('https://example.com/ai/intake', {
			method: 'POST',
			headers: { 'content-type': 'application/json' },
			body: JSON.stringify(body),
		});
		const ctx = createExecutionContext();
		const response = await invokeWorker(request, makeEnv(), ctx);
		await waitOnExecutionContext(ctx);

		expect(response.status).toBe(400);
		expect(fetchSpy).not.toHaveBeenCalled();
		await expect(response.json()).resolves.toEqual({
			error: {
				code: 'INVALID_INPUT',
				message: '"followUpMode" is required and must be a boolean.',
			},
		});
	});

	it('returns INVALID_INPUT when intake eventTime is invalid', async () => {
		const fetchSpy = vi.spyOn(globalThis, 'fetch');
		const request = new IncomingRequest('https://example.com/ai/intake', {
			method: 'POST',
			headers: { 'content-type': 'application/json' },
			body: JSON.stringify(makeIntakeBody({ eventTime: '2026-03-18T10:00:00Z' })),
		});
		const ctx = createExecutionContext();
		const response = await invokeWorker(request, makeEnv(), ctx);
		await waitOnExecutionContext(ctx);

		expect(response.status).toBe(400);
		expect(fetchSpy).not.toHaveBeenCalled();
		await expect(response.json()).resolves.toEqual({
			error: {
				code: 'INVALID_INPUT',
				message: '"eventTime" is required and must be an ISO 8601 string with +08:00 offset.',
			},
		});
	});

	it('returns INVALID_INPUT when messages is empty', async () => {
		const fetchSpy = vi.spyOn(globalThis, 'fetch');
		const request = new IncomingRequest('https://example.com/ai/intake', {
			method: 'POST',
			headers: { 'content-type': 'application/json' },
			body: JSON.stringify(makeIntakeBody({ messages: [] })),
		});
		const ctx = createExecutionContext();
		const response = await invokeWorker(request, makeEnv(), ctx);
		await waitOnExecutionContext(ctx);

		expect(response.status).toBe(400);
		expect(fetchSpy).not.toHaveBeenCalled();
		await expect(response.json()).resolves.toEqual({
			error: {
				code: 'INVALID_INPUT',
				message: '"messages" is required and must be a non-empty array.',
			},
		});
	});

	it('accepts intake requests when combined message text is exactly 6000 characters', async () => {
		const fetchSpy = vi
			.spyOn(globalThis, 'fetch')
			.mockResolvedValue(
				makeDeepSeekResponse(
					'{"status":"final","question":null,"symptoms":[{"name":"持续不适","startTime":null,"endTime":null,"precision":"date"}],"notes":"","actionAdvice":""}',
				),
			);

		const request = new IncomingRequest('https://example.com/ai/intake', {
			method: 'POST',
			headers: { 'content-type': 'application/json' },
			body: JSON.stringify(
				makeIntakeBody({
					messages: [{ role: 'user', content: repeatedChinese(6000) }],
				}),
			),
		});
		const ctx = createExecutionContext();
		const response = await invokeWorker(request, makeEnv(), ctx);
		await waitOnExecutionContext(ctx);

		expect(response.status).toBe(200);
		expect(fetchSpy).toHaveBeenCalledTimes(1);
	});

	it('returns INVALID_INPUT when combined message text exceeds 6000 characters', async () => {
		const fetchSpy = vi.spyOn(globalThis, 'fetch');
		const request = new IncomingRequest('https://example.com/ai/intake', {
			method: 'POST',
			headers: { 'content-type': 'application/json' },
			body: JSON.stringify(
				makeIntakeBody({
					messages: [{ role: 'user', content: repeatedChinese(6001) }],
				}),
			),
		});
		const ctx = createExecutionContext();
		const response = await invokeWorker(request, makeEnv(), ctx);
		await waitOnExecutionContext(ctx);

		expect(response.status).toBe(400);
		expect(fetchSpy).not.toHaveBeenCalled();
		await expect(response.json()).resolves.toEqual({
			error: {
				code: 'INVALID_INPUT',
				message: '"messages" text content must be at most 6000 characters after trim.',
			},
		});
	});

	it('returns UPSTREAM_INVALID_PAYLOAD when intake payload is missing status', async () => {
		vi.spyOn(globalThis, 'fetch').mockResolvedValue(
			makeDeepSeekResponse('{"question":null,"symptoms":[],"notes":"","actionAdvice":""}'),
		);

		const request = new IncomingRequest('https://example.com/ai/intake', {
			method: 'POST',
			headers: { 'content-type': 'application/json' },
			body: JSON.stringify(makeIntakeBody()),
		});
		const ctx = createExecutionContext();
		const response = await invokeWorker(request, makeEnv(), ctx);
		await waitOnExecutionContext(ctx);

		expect(response.status).toBe(502);
		await expect(response.json()).resolves.toEqual({
			error: {
				code: 'UPSTREAM_INVALID_PAYLOAD',
				message: 'DeepSeek JSON must contain "status", "question", "symptoms", "notes", and "actionAdvice".',
			},
		});
	});

	it('returns UPSTREAM_INVALID_PAYLOAD when an intake symptom item is invalid', async () => {
		vi.spyOn(globalThis, 'fetch').mockResolvedValue(
			makeDeepSeekResponse(
				'{"status":"final","question":null,"symptoms":[{"name":"","startTime":"2026-03-17","endTime":"2026-03-18","precision":"date"}],"notes":"","actionAdvice":""}',
			),
		);

		const request = new IncomingRequest('https://example.com/ai/intake', {
			method: 'POST',
			headers: { 'content-type': 'application/json' },
			body: JSON.stringify(makeIntakeBody()),
		});
		const ctx = createExecutionContext();
		const response = await invokeWorker(request, makeEnv(), ctx);
		await waitOnExecutionContext(ctx);

		expect(response.status).toBe(502);
		await expect(response.json()).resolves.toEqual({
			error: {
				code: 'UPSTREAM_INVALID_PAYLOAD',
				message:
					'DeepSeek JSON "symptoms[0]" must contain non-empty "name", nullable "startTime"/"endTime", and "precision" of "date" or "datetime".',
			},
		});
	});
});
describe('/ai/report', () => {
	it('sends Chinese prompts to DeepSeek for report requests', async () => {
		const fetchSpy = vi.spyOn(globalThis, 'fetch').mockResolvedValue(
			makeDeepSeekResponse(
				'{"title":"健康周报","summary":"本周症状整体平稳。","advice":["建议继续观察喉咙不适的变化，如持续两周未缓解请及时就医。"],"markdown":"# 健康周报\\n\\n本周总体平稳。"}',
			),
		);

		const request = new IncomingRequest('https://example.com/ai/report', {
			method: 'POST',
			headers: { 'content-type': 'application/json' },
			body: JSON.stringify({
				reportType: 'week',
				rangeStart: '2026-03-01',
				rangeEnd: '2026-03-07',
				events: [
					{
						eventTime: '2026-03-02T18:30:00+08:00',
						rawText: '轻微头痛，休息后缓解。',
						symptomSummary: '头痛（2026-03-02）',
						notes: null,
					},
				],
			}),
		});
		const ctx = createExecutionContext();
		const response = await invokeWorker(request, makeEnv(), ctx);
		await waitOnExecutionContext(ctx);

		expect(response.status).toBe(200);
		await expect(response.json()).resolves.toEqual({
			title: '健康周报',
			summary: '本周症状整体平稳。',
			advice: ['建议继续观察喉咙不适的变化，如持续两周未缓解请及时就医。'],
			markdown: '# 健康周报\n\n本周总体平稳。',
		});

		const payload = getRequestPayloadFromMock(fetchSpy);
		expect(payload.max_tokens).toBe(5120);
		expect(payload.messages[0]?.content).toContain('"title" 表示报告标题，需要与 reportType 和统计范围语义一致。');
		expect(payload.messages[0]?.content).toContain('"summary" 表示总体评估与趋势归纳，不要逐条复述 events 原文。');
		expect(payload.messages[0]?.content).toContain('"advice" 必须是由完整建议句组成的字符串数组');
		expect(payload.messages[0]?.content).toContain('"markdown" 必须是完整报告正文，并与 title、summary、advice 保持一致，不得互相矛盾。');
		expect(payload.messages[1]?.content).toContain('reportType 表示报告周期类型（week/month/quarter）。');
		expect(payload.messages[1]?.content).toContain('rangeStart 和 rangeEnd 表示报告统计范围边界，不表示症状发生起止时间。');
		expect(payload.messages[1]?.content).toContain('eventTime 表示记录创建时间');
		expect(payload.messages[1]?.content).toContain('输出字段语义：title 是报告标题，summary 是总体归纳，advice 是建议列表，markdown 是完整报告正文，四者必须语义一致。');
	});

	it('falls back to deepseek-chat for report when DEEPSEEK_MODEL is not a chat model', async () => {
		const fetchSpy = vi.spyOn(globalThis, 'fetch').mockResolvedValue(
			makeDeepSeekResponse(
				'{"title":"健康周报","summary":"本周症状整体平稳。","advice":["建议继续观察。"],"markdown":"# 健康周报"}',
			),
		);

		const request = new IncomingRequest('https://example.com/ai/report', {
			method: 'POST',
			headers: { 'content-type': 'application/json' },
			body: JSON.stringify({
				reportType: 'week',
				rangeStart: '2026-03-01',
				rangeEnd: '2026-03-07',
				events: [
					{
						eventTime: '2026-03-02T18:30:00+08:00',
						rawText: '轻微头痛，休息后缓解。',
						symptomSummary: '头痛（2026-03-02）',
						notes: null,
					},
				],
			}),
		});
		const ctx = createExecutionContext();
		const response = await invokeWorker(
			request,
			makeEnv({ DEEPSEEK_MODEL: 'deepseek-reasoner' }),
			ctx,
		);
		await waitOnExecutionContext(ctx);

		expect(response.status).toBe(200);
		expect(getRequestPayloadFromMock(fetchSpy).model).toBe('deepseek-chat');
	});

	it('accepts report requests when combined business text is exactly 10000 characters', async () => {
		const fetchSpy = vi.spyOn(globalThis, 'fetch').mockResolvedValue(
			makeDeepSeekResponse(
				'{"title":"健康周报","summary":"本周症状整体平稳。","advice":["建议继续观察。"],"markdown":"# 健康周报"}',
			),
		);

		const request = new IncomingRequest('https://example.com/ai/report', {
			method: 'POST',
			headers: { 'content-type': 'application/json' },
			body: JSON.stringify({
				reportType: 'week',
				rangeStart: '2026-03-01',
				rangeEnd: '2026-03-07',
				events: [
					{
						eventTime: '2026-03-02T18:30:00+08:00',
						rawText: repeatedChinese(10000),
						symptomSummary: null,
						notes: null,
					},
				],
			}),
		});
		const ctx = createExecutionContext();
		const response = await invokeWorker(request, makeEnv(), ctx);
		await waitOnExecutionContext(ctx);

		expect(response.status).toBe(200);
		expect(fetchSpy).toHaveBeenCalledTimes(1);
	});

	it('returns INVALID_INPUT when combined report business text exceeds 10000 characters', async () => {
		const fetchSpy = vi.spyOn(globalThis, 'fetch');
		const request = new IncomingRequest('https://example.com/ai/report', {
			method: 'POST',
			headers: { 'content-type': 'application/json' },
			body: JSON.stringify({
				reportType: 'week',
				rangeStart: '2026-03-01',
				rangeEnd: '2026-03-07',
				events: [
					{
						eventTime: '2026-03-02T18:30:00+08:00',
						rawText: repeatedChinese(10001),
						symptomSummary: null,
						notes: null,
					},
				],
			}),
		});
		const ctx = createExecutionContext();
		const response = await invokeWorker(request, makeEnv(), ctx);
		await waitOnExecutionContext(ctx);

		expect(response.status).toBe(400);
		expect(fetchSpy).not.toHaveBeenCalled();
		await expect(response.json()).resolves.toEqual({
			error: {
				code: 'INVALID_INPUT',
				message: '"events" text content must be at most 10000 characters after trim.',
			},
		});
	});

	it('returns a stable empty report when events is an empty array', async () => {
		const fetchSpy = vi.spyOn(globalThis, 'fetch');

		const request = new IncomingRequest('https://example.com/ai/report', {
			method: 'POST',
			headers: { 'content-type': 'application/json' },
			body: JSON.stringify({
				reportType: 'week',
				rangeStart: '2026-03-01',
				rangeEnd: '2026-03-07',
				events: [],
			}),
		});
		const ctx = createExecutionContext();
		const response = await invokeWorker(request, makeEnv(), ctx);
		await waitOnExecutionContext(ctx);

		expect(response.status).toBe(200);
		expect(fetchSpy).not.toHaveBeenCalled();
		await expect(response.json()).resolves.toEqual({
			title: '最近 7 天健康周报',
			summary: '当前时间范围内暂无健康记录。',
			advice: ['当前时间范围内暂无明显健康异常记录，建议继续记录日常健康情况，便于后续生成更有参考价值的健康报告。'],
			markdown:
				'## 最近 7 天健康周报\n\n统计范围：2026-03-01 至 2026-03-07\n\n当前时间范围内暂无健康记录。\n\n- 继续记录日常健康情况，便于后续生成更有参考价值的健康报告。',
		});
	});

	it('returns UPSTREAM_INVALID_PAYLOAD when report advice contains a blank string', async () => {
		vi.spyOn(globalThis, 'fetch').mockResolvedValue(
			makeDeepSeekResponse(
				'{"title":"健康周报","summary":"本周症状整体平稳。","advice":["   "],"markdown":"# 健康周报"}',
			),
		);

		const request = new IncomingRequest('https://example.com/ai/report', {
			method: 'POST',
			headers: { 'content-type': 'application/json' },
			body: JSON.stringify({
				reportType: 'week',
				rangeStart: '2026-03-01',
				rangeEnd: '2026-03-07',
				events: [
					{
						eventTime: '2026-03-02T18:30:00+08:00',
						rawText: '轻微头痛，休息后缓解。',
						symptomSummary: '头痛（2026-03-02）',
						notes: null,
					},
				],
			}),
		});
		const ctx = createExecutionContext();
		const response = await invokeWorker(request, makeEnv(), ctx);
		await waitOnExecutionContext(ctx);

		expect(response.status).toBe(502);
		await expect(response.json()).resolves.toEqual({
			error: {
				code: 'UPSTREAM_INVALID_PAYLOAD',
				message: '"advice" must be an array of strings.',
			},
		});
	});

	it('returns INVALID_INPUT when report event uses old eventStartTime and eventEndTime fields', async () => {
		const fetchSpy = vi.spyOn(globalThis, 'fetch');
		const request = new IncomingRequest('https://example.com/ai/report', {
			method: 'POST',
			headers: { 'content-type': 'application/json' },
			body: JSON.stringify({
				reportType: 'week',
				rangeStart: '2026-03-01',
				rangeEnd: '2026-03-07',
				events: [
					{
						eventStartTime: '2026-03-02T10:00:00Z',
						eventEndTime: '2026-03-02T11:00:00Z',
						rawText: '轻微头痛',
						symptomSummary: '轻微头痛',
						notes: null,
					},
				],
			}),
		});
		const ctx = createExecutionContext();
		const response = await invokeWorker(request, makeEnv(), ctx);
		await waitOnExecutionContext(ctx);

		expect(response.status).toBe(400);
		expect(fetchSpy).not.toHaveBeenCalled();
		await expect(response.json()).resolves.toEqual({
			error: {
				code: 'INVALID_INPUT',
				message: '"events[0].eventTime" must be a string or null.',
			},
		});
	});
});
