import { describe, expect, it } from 'vitest';
import { env, SELF } from 'cloudflare:test';

type LiveEnv = {
	DEEPSEEK_API_KEY?: string;
	DEEPSEEK_MODEL?: string;
};

function getLiveEnv(): LiveEnv {
	return env as unknown as LiveEnv;
}

async function withRequestRetries<T>(attempts: number, run: () => Promise<T>): Promise<T> {
	let lastError: unknown;

	for (let attempt = 1; attempt <= attempts; attempt += 1) {
		try {
			return await run();
		} catch (error) {
			lastError = error;
			if (attempt < attempts) {
				await new Promise((resolve) => setTimeout(resolve, attempt * 1000));
			}
		}
	}

	throw lastError;
}

async function runLiveReport(body: Record<string, unknown>) {
	const liveEnv = getLiveEnv();
	if (!liveEnv.DEEPSEEK_API_KEY) {
		throw new Error('Missing DEEPSEEK_API_KEY for live DeepSeek tests.');
	}

	const response = await SELF.fetch('https://example.com/ai/report', {
		method: 'POST',
		headers: { 'content-type': 'application/json' },
		body: JSON.stringify(body),
	});
	const finalResponse = (await response.json()) as Record<string, unknown>;

	return {
		status: response.status,
		finalResponse,
	};
}

async function runLiveIntake(body: Record<string, unknown>) {
	const liveEnv = getLiveEnv();
	if (!liveEnv.DEEPSEEK_API_KEY) {
		throw new Error('Missing DEEPSEEK_API_KEY for live DeepSeek tests.');
	}

	const response = await SELF.fetch('https://example.com/ai/intake', {
		method: 'POST',
		headers: { 'content-type': 'application/json' },
		body: JSON.stringify(body),
	});
	const finalResponse = (await response.json()) as Record<string, unknown>;

	return {
		status: response.status,
		finalResponse,
	};
}

describe('/ai/intake live DeepSeek integration', () => {
	it(
		'returns needs_followup with multi-line questions for vague health-record input when follow-up is allowed',
		async () => {
			const requestBody = {
				followUpMode: true,
				forceFinalize: false,
				eventTime: '2026-03-18T18:00:00+08:00',
				messages: [{ role: 'user', content: '不太舒服。' }],
			};

			const result = await withRequestRetries(3, () => runLiveIntake(requestBody));
			expect(result.status).toBe(200);
			expect(result.finalResponse.status).toBe('needs_followup');
			expect(typeof result.finalResponse.question).toBe('string');

			const question = result.finalResponse.question as string;
			expect(question.trim().length).toBeGreaterThan(0);
			expect(question.split('\n').filter((line) => line.trim().length > 0).length).toBeGreaterThanOrEqual(1);

			expect(result.finalResponse.draft).toBeTruthy();
			const draft = result.finalResponse.draft as Record<string, unknown>;
			expect(draft.mergedRawText).toBe('不太舒服。');
			expect(typeof draft.symptomSummary).toBe('string');
			expect(typeof draft.notes).toBe('string');
			expect(typeof draft.actionAdvice).toBe('string');
		},
		90000,
	);

	it(
		'forces final when forceFinalize is true for the same vague intake input',
		async () => {
			const requestBody = {
				followUpMode: true,
				forceFinalize: true,
				eventTime: '2026-03-18T18:00:00+08:00',
				messages: [{ role: 'user', content: '不太舒服。' }],
			};

			const result = await withRequestRetries(3, () => runLiveIntake(requestBody));
			expect(result.status).toBe(200);
			expect(result.finalResponse.status).toBe('final');
			expect(result.finalResponse.question).toBeNull();

			const draft = result.finalResponse.draft as Record<string, unknown>;
			expect(draft).toBeTruthy();
			expect(draft.mergedRawText).toBe('不太舒服。');
			expect(typeof draft.symptomSummary).toBe('string');
			expect(typeof draft.notes).toBe('string');
			expect(typeof draft.actionAdvice).toBe('string');
		},
		90000,
	);

	it(
		'uses the internal symptomSummary formatter when intake is force-finalized',
		async () => {
			const requestBody = {
				followUpMode: true,
				forceFinalize: true,
				eventTime: '2026-03-18T18:00:00+08:00',
				messages: [{ role: 'user', content: '最近三天心脏不舒服。' }],
			};

			const result = await withRequestRetries(3, () => runLiveIntake(requestBody));
			expect(result.status).toBe(200);
			expect(result.finalResponse.status).toBe('final');
			expect(result.finalResponse.question).toBeNull();

			const draft = result.finalResponse.draft as Record<string, unknown>;
			expect(draft.mergedRawText).toBe('最近三天心脏不舒服。');
			expect(typeof draft.symptomSummary).toBe('string');
			expect(draft.symptomSummary).toMatch(/^.+（\d{4}-\d{2}-\d{2} 至 \d{4}-\d{2}-\d{2}）$/);
			expect(typeof draft.notes).toBe('string');
			expect(typeof draft.actionAdvice).toBe('string');
		},
		90000,
	);
});

describe('/ai/report live DeepSeek integration', () => {
	it(
		'returns actionable advice sentences instead of slogan-like short phrases',
		async () => {
			const requestBody = {
				reportType: 'week',
				rangeStart: '2026-03-01',
				rangeEnd: '2026-03-07',
				events: [
					{
						eventTime: '2026-03-02T18:30:00+08:00',
						rawText: '这周有两次喉咙痛，晚上更明显。',
						symptomSummary: '喉咙痛（2026-03-02）\n喉咙痛（2026-03-05）',
						notes: '晚上更明显。',
					},
				],
			};

			const result = await withRequestRetries(3, () => runLiveReport(requestBody));
			expect(result.status).toBe(200);
			expect(typeof result.finalResponse.title).toBe('string');
			expect(typeof result.finalResponse.summary).toBe('string');
			expect(typeof result.finalResponse.markdown).toBe('string');
			expect(Array.isArray(result.finalResponse.advice)).toBe(true);

			const advice = result.finalResponse.advice as string[];
			expect(advice.length).toBeGreaterThan(0);
			expect(advice[0]?.trim().length).toBeGreaterThanOrEqual(16);
			expect(advice.some((item) => item.includes('建议') || item.includes('请'))).toBe(true);
		},
		90000,
	);
});

describe('/ai/extract retirement', () => {
	it('returns NOT_FOUND for retired POST /ai/extract', async () => {
		const response = await SELF.fetch('https://example.com/ai/extract', {
			method: 'POST',
			headers: { 'content-type': 'application/json' },
			body: JSON.stringify({
				rawText: '最近三天心脏不舒服。',
				eventTime: '2026-03-18T18:00:00+08:00',
			}),
		});

		expect(response.status).toBe(404);
		await expect(response.json()).resolves.toEqual({
			error: {
				code: 'NOT_FOUND',
				message: 'Route not found.',
			},
		});
	});
});
