interface WorkerEnv {
	DEEPSEEK_API_KEY: string;
	DEEPSEEK_MODEL?: string;
}

type ErrorCode =
	| 'INVALID_JSON'
	| 'INVALID_INPUT'
	| 'UPSTREAM_HTTP_ERROR'
	| 'UPSTREAM_INVALID_JSON'
	| 'UPSTREAM_INVALID_PAYLOAD'
	| 'INTERNAL_ERROR'
	| 'NOT_FOUND';

type SymptomTimePrecision = 'date' | 'datetime';
type IntakeStatus = 'needs_followup' | 'final';
type IntakeMessageRole = 'user' | 'assistant';
type ReportType = 'week' | 'month' | 'quarter';

interface StructuredSymptom {
	name: string;
	startTime: string | null;
	endTime: string | null;
	precision: SymptomTimePrecision;
}

interface StructuredSymptomsPayload {
	symptoms: StructuredSymptom[];
	notes: string;
}

interface IntakeMessage {
	role: IntakeMessageRole;
	content: string;
}

interface IntakeRequest {
	followUpMode: boolean;
	forceFinalize: boolean;
	eventTime: string;
	messages: IntakeMessage[];
}

interface IntakeDraft {
	mergedRawText: string;
	symptomSummary: string;
	notes: string;
	actionAdvice: string;
}

interface IntakeResponse {
	status: IntakeStatus;
	question: string | null;
	draft: IntakeDraft;
}

interface IntakeModelResult {
	status: IntakeStatus;
	question: string | null;
	symptoms: StructuredSymptom[];
	notes: string;
	actionAdvice: string;
}

interface ReportEvent {
	eventTime: string | null;
	rawText: string | null;
	symptomSummary: string | null;
	notes: string | null;
}

interface ReportRequest {
	reportType: ReportType;
	rangeStart: string;
	rangeEnd: string;
	events: ReportEvent[];
}

interface ReportResult {
	title: string;
	summary: string;
	advice: string[];
	markdown: string;
}

interface DeepSeekChatCompletionResponse {
	choices?: Array<{
		message?: {
			content?:
				| string
				| Array<{
						type?: string;
						text?: string;
				  }>;
		};
	}>;
}

const INTAKE_MAX_TEXT_CHARACTERS = 6000;
const REPORT_MAX_TEXT_CHARACTERS = 10000;
const INTAKE_MAX_TOKENS = 1024;
const REPORT_MAX_TOKENS = 5120;
const CHINA_TIME_ZONE = 'Asia/Shanghai';
const CHINA_UTC_OFFSET = '+08:00';
const REQUEST_EVENT_TIME_PATTERN = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\+08:00$/;
const EVENT_TIME_ERROR_MESSAGE =
	'"eventTime" is required and must be an ISO 8601 string with +08:00 offset.';

const JSON_HEADERS = {
	'content-type': 'application/json; charset=utf-8',
	'access-control-allow-origin': '*',
	'access-control-allow-headers': 'content-type',
	'access-control-allow-methods': 'POST, OPTIONS',
} as const;

class ApiError extends Error {
	constructor(
		public readonly status: number,
		public readonly code: ErrorCode,
		message: string,
	) {
		super(message);
		this.name = 'ApiError';
	}
}

function jsonResponse(data: unknown, status = 200): Response {
	return new Response(JSON.stringify(data), {
		status,
		headers: JSON_HEADERS,
	});
}

function errorResponse(status: number, code: ErrorCode, message: string): Response {
	return jsonResponse(
		{
			error: {
				code,
				message,
			},
		},
		status,
	);
}

function isRecord(value: unknown): value is Record<string, unknown> {
	return typeof value === 'object' && value !== null;
}

function isNonEmptyString(value: unknown): value is string {
	return typeof value === 'string' && value.trim().length > 0;
}

function isNullableString(value: unknown): value is string | null {
	return typeof value === 'string' || value === null;
}

function countCodePoints(value: string): number {
	return [...value].length;
}

function containsChinese(text: string): boolean {
	return /[\u3400-\u9FFF]/.test(text);
}

function resolveDeepSeekModel(env: WorkerEnv): string {
	const cleaned = (env.DEEPSEEK_MODEL ?? '')
		.trim()
		.replace(/^['"]+|['"]+$/g, '')
		.trim();

	if (cleaned.length === 0) {
		return 'deepseek-chat';
	}

	return /chat/i.test(cleaned) ? cleaned : 'deepseek-chat';
}

function parseUpstreamContent(payload: DeepSeekChatCompletionResponse): string {
	const content = payload.choices?.[0]?.message?.content;

	if (typeof content === 'string') {
		const trimmed = content.trim();
		if (trimmed.length > 0) {
			return trimmed;
		}
	}

	if (Array.isArray(content)) {
		const mergedText = content
			.map((part) => (part && typeof part.text === 'string' ? part.text : ''))
			.join('')
			.trim();

		if (mergedText.length > 0) {
			return mergedText;
		}
	}

	throw new ApiError(
		502,
		'UPSTREAM_INVALID_PAYLOAD',
		'DeepSeek response is missing a valid JSON content string.',
	);
}

function stripCodeFence(content: string): string {
	const trimmed = content.trim();
	const fencedMatch = trimmed.match(/^```(?:json)?\s*([\s\S]*?)\s*```$/i);
	return fencedMatch ? fencedMatch[1].trim() : trimmed;
}

function pad2(value: number): string {
	return String(value).padStart(2, '0');
}

function buildChinaIsoString(
	year: number,
	month: number,
	day: number,
	hour: number,
	minute: number,
	second: number,
): string {
	return `${year}-${pad2(month)}-${pad2(day)}T${pad2(hour)}:${pad2(minute)}:${pad2(second)}${CHINA_UTC_OFFSET}`;
}

function buildChinaDateString(year: number, month: number, day: number): string {
	return `${year}-${pad2(month)}-${pad2(day)}`;
}

function getChinaDateParts(inputDate: Date): {
	year: number;
	month: number;
	day: number;
	hour: number;
	minute: number;
	second: number;
} {
	const formatter = new Intl.DateTimeFormat('en-CA', {
		timeZone: CHINA_TIME_ZONE,
		year: 'numeric',
		month: '2-digit',
		day: '2-digit',
		hour: '2-digit',
		minute: '2-digit',
		second: '2-digit',
		hourCycle: 'h23',
	});
	const parts = formatter.formatToParts(inputDate);
	const result = {
		year: 0,
		month: 0,
		day: 0,
		hour: 0,
		minute: 0,
		second: 0,
	};

	for (const part of parts) {
		if (part.type === 'year') result.year = Number(part.value);
		if (part.type === 'month') result.month = Number(part.value);
		if (part.type === 'day') result.day = Number(part.value);
		if (part.type === 'hour') result.hour = Number(part.value);
		if (part.type === 'minute') result.minute = Number(part.value);
		if (part.type === 'second') result.second = Number(part.value);
	}

	return result;
}

function formatDateAsChinaIsoString(inputDate: Date): string {
	const parts = getChinaDateParts(inputDate);
	return buildChinaIsoString(
		parts.year,
		parts.month,
		parts.day,
		parts.hour,
		parts.minute,
		parts.second,
	);
}

function formatDateAsChinaDateString(inputDate: Date): string {
	const parts = getChinaDateParts(inputDate);
	return buildChinaDateString(parts.year, parts.month, parts.day);
}

function normalizeChinaLocalTextDate(value: string): string | null {
	const dashMatch = value.match(/^(\d{4})-(\d{2})-(\d{2})$/);
	if (dashMatch) {
		return `${dashMatch[1]}-${dashMatch[2]}-${dashMatch[3]}`;
	}

	const slashMatch = value.match(/^(\d{4})\/(\d{2})\/(\d{2})$/);
	if (slashMatch) {
		return `${slashMatch[1]}-${slashMatch[2]}-${slashMatch[3]}`;
	}

	return null;
}

function normalizeChinaLocalTextDateTime(value: string): string | null {
	const dateOnly = normalizeChinaLocalTextDate(value);
	if (dateOnly) {
		return `${dateOnly}T00:00:00${CHINA_UTC_OFFSET}`;
	}

	const dateTimeMatch = value.match(/^(\d{4}-\d{2}-\d{2})[ T](\d{2}):(\d{2})(?::(\d{2}))?$/);
	if (dateTimeMatch) {
		const [, datePart, hourPart, minutePart, secondPart] = dateTimeMatch;
		return `${datePart}T${hourPart}:${minutePart}:${secondPart ?? '00'}${CHINA_UTC_OFFSET}`;
	}

	const slashDateTimeMatch = value.match(
		/^(\d{4})\/(\d{2})\/(\d{2})[ T](\d{2}):(\d{2})(?::(\d{2}))?$/,
	);
	if (slashDateTimeMatch) {
		const [, year, month, day, hour, minute, second] = slashDateTimeMatch;
		return `${year}-${month}-${day}T${hour}:${minute}:${second ?? '00'}${CHINA_UTC_OFFSET}`;
	}

	return null;
}

function normalizeRequestEventTime(value: unknown): string {
	if (typeof value !== 'string') {
		throw new ApiError(400, 'INVALID_INPUT', EVENT_TIME_ERROR_MESSAGE);
	}

	const trimmed = value.trim();
	if (!REQUEST_EVENT_TIME_PATTERN.test(trimmed)) {
		throw new ApiError(400, 'INVALID_INPUT', EVENT_TIME_ERROR_MESSAGE);
	}

	const parsedDate = new Date(trimmed);
	if (Number.isNaN(parsedDate.getTime())) {
		throw new ApiError(400, 'INVALID_INPUT', EVENT_TIME_ERROR_MESSAGE);
	}

	return formatDateAsChinaIsoString(parsedDate);
}

function normalizeModelDate(value: unknown): string | null {
	if (typeof value !== 'string') {
		return null;
	}

	const trimmed = value.trim();
	if (trimmed.length === 0) {
		return null;
	}

	const normalizedDate = normalizeChinaLocalTextDate(trimmed);
	if (normalizedDate) {
		return normalizedDate;
	}

	const normalizedLocalDateTime = normalizeChinaLocalTextDateTime(trimmed);
	const parseTarget = normalizedLocalDateTime ?? trimmed;
	const parsedDate = new Date(parseTarget);
	if (Number.isNaN(parsedDate.getTime())) {
		return null;
	}

	return formatDateAsChinaDateString(parsedDate);
}

function normalizeModelDateTime(value: unknown): string | null {
	if (typeof value !== 'string') {
		return null;
	}

	const trimmed = value.trim();
	if (trimmed.length === 0) {
		return null;
	}

	const normalizedLocalDateTime = normalizeChinaLocalTextDateTime(trimmed);
	const parseTarget = normalizedLocalDateTime ?? trimmed;
	const parsedDate = new Date(parseTarget);
	if (Number.isNaN(parsedDate.getTime())) {
		return null;
	}

	return formatDateAsChinaIsoString(parsedDate);
}

function validateStructuredSymptomsPayload(payload: unknown): StructuredSymptomsPayload {
	if (!isRecord(payload)) {
		throw new ApiError(502, 'UPSTREAM_INVALID_PAYLOAD', 'DeepSeek returned an invalid JSON object.');
	}

	if (!Array.isArray(payload.symptoms) || typeof payload.notes !== 'string') {
		throw new ApiError(
			502,
			'UPSTREAM_INVALID_PAYLOAD',
			'DeepSeek JSON must contain "symptoms" array and "notes" string.',
		);
	}

	const symptoms = payload.symptoms.map((item, index) => {
		if (!isRecord(item)) {
			throw new ApiError(
				502,
				'UPSTREAM_INVALID_PAYLOAD',
				`DeepSeek JSON "symptoms[${index}]" must be an object.`,
			);
		}

		const name = typeof item.name === 'string' ? item.name.trim() : '';
		const precision = item.precision;
		const hasValidPrecision = precision === 'date' || precision === 'datetime';

		if (!name || !hasValidPrecision || !isNullableString(item.startTime) || !isNullableString(item.endTime)) {
			throw new ApiError(
				502,
				'UPSTREAM_INVALID_PAYLOAD',
				`DeepSeek JSON "symptoms[${index}]" must contain non-empty "name", nullable "startTime"/"endTime", and "precision" of "date" or "datetime".`,
			);
		}

		return {
			name,
			startTime:
				precision === 'date'
					? normalizeModelDate(item.startTime)
					: normalizeModelDateTime(item.startTime),
			endTime:
				precision === 'date'
					? normalizeModelDate(item.endTime)
					: normalizeModelDateTime(item.endTime),
			precision,
		} satisfies StructuredSymptom;
	});

	return {
		symptoms,
		notes: payload.notes.trim(),
	};
}

function formatDateTimeForSummary(value: string): string {
	const normalized = normalizeModelDateTime(value);
	if (!normalized) {
		return value.trim();
	}

	return `${normalized.slice(0, 10)} ${normalized.slice(11, 16)}`;
}

function getUnknownBoundaryPlaceholder(precision: SymptomTimePrecision): string {
	return precision === 'datetime' ? '不明时间' : '不明日期';
}

function formatTimeDescription(symptom: StructuredSymptom): string {
	const start =
		symptom.precision === 'datetime' && symptom.startTime
			? formatDateTimeForSummary(symptom.startTime)
			: symptom.startTime;
	const end =
		symptom.precision === 'datetime' && symptom.endTime
			? formatDateTimeForSummary(symptom.endTime)
			: symptom.endTime;

	if (start && end) {
		return start === end ? start : `${start} 至 ${end}`;
	}

	if (start) {
		return `${start} 至 ${getUnknownBoundaryPlaceholder(symptom.precision)}`;
	}

	if (end) {
		return `${getUnknownBoundaryPlaceholder(symptom.precision)} 至 ${end}`;
	}

	return '时间未说明';
}

function buildSymptomSummary(symptoms: StructuredSymptom[]): string {
	const items = symptoms
		.map((symptom) => `${symptom.name}（${formatTimeDescription(symptom)}）`)
		.filter((item) => item.trim().length > 0);

	return Array.from(new Set(items)).join('\n');
}

function normalizeFollowUpQuestion(value: string): string {
	return value
		.split(/\r?\n/)
		.map((line) => line.trim())
		.filter((line) => line.length > 0)
		.join('\n');
}

function buildMergedRawText(messages: IntakeMessage[]): string {
	return messages
		.filter((message) => message.role === 'user')
		.map((message) => message.content)
		.join('\n');
}

function buildIntakeDraft(mergedRawText: string, modelResult: IntakeModelResult): IntakeDraft {
	return {
		mergedRawText,
		symptomSummary: buildSymptomSummary(modelResult.symptoms),
		notes: modelResult.notes,
		actionAdvice: modelResult.actionAdvice,
	};
}

function parseIntakeRequest(payload: unknown): IntakeRequest {
	if (!isRecord(payload)) {
		throw new ApiError(400, 'INVALID_INPUT', 'Request body must be a JSON object.');
	}

	if (typeof payload.followUpMode !== 'boolean') {
		throw new ApiError(
			400,
			'INVALID_INPUT',
			'"followUpMode" is required and must be a boolean.',
		);
	}

	if (typeof payload.forceFinalize !== 'boolean') {
		throw new ApiError(
			400,
			'INVALID_INPUT',
			'"forceFinalize" is required and must be a boolean.',
		);
	}

	if (!Array.isArray(payload.messages) || payload.messages.length === 0) {
		throw new ApiError(
			400,
			'INVALID_INPUT',
			'"messages" is required and must be a non-empty array.',
		);
	}

	const messages = payload.messages.map((item, index) => {
		if (!isRecord(item)) {
			throw new ApiError(400, 'INVALID_INPUT', `"messages[${index}]" must be an object.`);
		}

		if (item.role !== 'user' && item.role !== 'assistant') {
			throw new ApiError(
				400,
				'INVALID_INPUT',
				`"messages[${index}].role" must be one of: user, assistant.`,
			);
		}

		if (!isNonEmptyString(item.content)) {
			throw new ApiError(
				400,
				'INVALID_INPUT',
				`"messages[${index}].content" must be a non-empty string.`,
			);
		}

		return {
			role: item.role,
			content: item.content.trim(),
		} satisfies IntakeMessage;
	});

	const textCharacterCount = messages.reduce(
		(total, message) => total + countCodePoints(message.content),
		0,
	);
	if (textCharacterCount > INTAKE_MAX_TEXT_CHARACTERS) {
		throw new ApiError(
			400,
			'INVALID_INPUT',
			'"messages" text content must be at most 6000 characters after trim.',
		);
	}

	return {
		followUpMode: payload.followUpMode,
		forceFinalize: payload.forceFinalize,
		eventTime: normalizeRequestEventTime(payload.eventTime),
		messages,
	};
}

function buildIntakePrompts(
	input: IntakeRequest,
	strictEmptyGuard = false,
): {
	systemPrompt: string;
	userPrompt: string;
} {
	const conversationText = input.messages.map((message) => message.content).join('\n');
	const outputLanguageRule = containsChinese(conversationText)
		? '如果消息历史包含中文，question、symptoms 中的 name、notes 和 actionAdvice 必须使用简体中文。'
		: 'question、symptoms 中的 name、notes 和 actionAdvice 必须与消息历史语言保持一致。';
	const strictGuardRules = strictEmptyGuard
		? [
				'重要补充：本次是纠偏重试。',
				'包含可读患者描述的 messages 不能再产出空 symptoms 和空 notes。',
				'如果 messages 中能看出症状、不适或身体异常，请至少返回一条 symptom。',
		  ]
		: [];

	const systemPrompt = [
		'你是一个健康记录 intake 助手。',
		'你必须返回 JSON。',
		'只能返回一个 JSON 对象。',
		'不要返回 Markdown。',
		'不要使用 ```json 或 ``` 代码围栏包裹响应。',
		'不要在 JSON 前后添加任何解释。',
		`本次相对时间锚点 eventTime 为 ${input.eventTime}（Asia/Shanghai，UTC+08:00）。`,
		'解释所有“最近三天”“昨天”“今天”“上周”“近两小时”等相对时间时，必须严格以这个 eventTime 为准，而不是使用你自己的当前时间。',
		'输入中的 messages 按顺序表示完整对话历史。',
		'其中 role 为 "user" 代表患者，role 为 "assistant" 代表 AI。',
		'每条 content 都是对应角色在当时提出的问题或给出的回答。',
		'除第 0 条外，读取第 n 条 content 时，都要结合第 n-1 条 content 所对应的问题或回答来理解其语义，并同时综合整个 messages 历史。',
		'读取 messages 中任何 content 时，都必须把内容和语义与这个 eventTime 关联起来理解。',
		`当前 followUpMode 为 ${input.followUpMode}。当 followUpMode=false 时，禁止返回 needs_followup，必须返回 final。`,
		`当前 forceFinalize 为 ${input.forceFinalize}。当 forceFinalize=true 时，禁止返回 needs_followup，必须返回 final，且优先级高于 followUpMode。`,
		'status 判定优先级：先判断 forceFinalize 与 followUpMode，再判断信息是否足够。',
		'当 forceFinalize=true 或 followUpMode=false 时，status 必须为 "final"，question 必须为 null。',
		'只有当完整消息历史仍不足以产出高质量 draft 或 actionAdvice 时，才允许返回 needs_followup。',
		'信息不足包括但不限于：只有模糊不适描述、关键症状细节缺失、时间边界无法判断、无法给出有依据的保守建议。',
		'当 status 为 "needs_followup" 时，question 必须只追问当前缺失的关键信息。',
		'needs_followup 时允许追问任意当前健康记录相关的问题，包括但不限于症状、持续时间、诱因、缓解或加重因素、否认信息、用药、就医、既往相关背景。',
		'不要追问与当前健康记录无关的问题。',
		'question 不限制问题条数；如果有多个问题，用换行分隔，每行一个可直接回答的问题。',
		'当 status 为 "needs_followup" 时，即使需要追问，也要尽量保留已确定的 symptoms 或 notes，不要默认清空。',
		'当 status 为 "final" 时，表示当前信息已足以产出可用草稿，不要为了继续追问而返回 needs_followup。',
		'输出 JSON 必须且只能包含五个字段：status、question、symptoms、notes、actionAdvice。',
		'status 只能是 "needs_followup" 或 "final"。',
		'当 status 为 "needs_followup" 时，question 必须是非空字符串。',
		'当 status 为 "final" 时，question 必须是 null。',
		'symptoms 必须是数组；数组中的每一项必须包含 name、startTime、endTime、precision。',
		'name 表示症状或不适标签，不是诊断结论。',
		'startTime 表示症状开始时间。',
		'endTime 表示症状结束时间。',
		'precision 只能是 "date" 或 "datetime"。',
		'当 precision 为 "date" 时，startTime 和 endTime 必须使用 YYYY-MM-DD。',
		'当 precision 为 "datetime" 时，startTime 和 endTime 必须使用带 +08:00 偏移量的 ISO 8601 日期时间字符串。',
		'如果未明确提及症状结束日期/时间，endTime 默认使用 eventTime（今天/eventTime 口径）。',
		'当 precision 为 "date" 且缺少明确结束时间时，endTime 必须回填为 eventTime 的日期部分（YYYY-MM-DD）。',
		'当 precision 为 "datetime" 且缺少明确结束时间时，endTime 必须回填为 eventTime 完整时间（带 +08:00 偏移量）。',
		'即使语义是“仍在持续”，也将 endTime 回填为 eventTime，作为本次记录的观察终点。',
		'如果只能推断单侧边界，startTime 允许为 null；endTime 仍按上述默认规则处理。',
		'如果无法可靠推断开始时间，startTime 返回 null。',
		'同一个症状如果在消息历史里多次出现但指向同一个持续过程，请合并为一个 symptom。',
		'symptoms 只写明确或可合理归纳的正向症状。',
		'notes 用于承载非正向症状信息与补充上下文。',
		'否认信息、诱因、缓解或加重情况、生活背景、用药或就医描述、其他补充说明，都必须放在 notes 中。',
		'如果没有补充说明，notes 返回空字符串。',
		'如果没有正向症状，symptoms 返回空数组。',
		'对于已经通过校验且包含可读患者描述的 messages，除非患者描述本身完全没有可读信息，否则不允许同时返回空的 symptoms 和空的 notes。',
		'如果 messages 中患者描述明确包含症状、不适或身体异常，symptoms 至少要有一项。',
		'如果没有正向症状，也必须把剩余可读信息写入 notes，不要把包含可读患者描述的 messages 提取成 {"symptoms":[],"notes":""}。',
		'actionAdvice 用于基于当前信息给出中性、谨慎、可执行的操作/观察建议/诊断。',
		'actionAdvice 必须是一条中性、谨慎的操作/观察建议/诊断；如果没有合适建议，返回空字符串。',
		'不要臆造消息历史中没有的信息。',
		...strictGuardRules,
		outputLanguageRule,
	].join(' ');

	const userPrompt = [
		'请根据以下输入整理当前健康记录。',
		'messages 按顺序给出完整对话历史。',
		'role 为 user 表示患者，role 为 assistant 表示 AI。',
		'content 就是该条消息中的问题或回答。',
		'除第 0 条外，第 n 条 content 都要结合第 n-1 条 content 所对应的问题或回答来理解，并同时综合整个 messages 历史。',
		'读取 messages 中任何 content 时，都必须把内容和语义与 eventTime 关联起来理解；所有相对时间都必须以 eventTime 为准。',
		'字段语义：status 表示是否继续追问`final` 表示当前信息已足以产出可用草稿；`needs_followup`表示需要继续追问。question 表示下一轮需补齐的信息；symptoms 表示已识别的正向症状；notes 表示非正向症状补充信息；actionAdvice 表示保守建议。',
		'判定规则：当 forceFinalize=true 或 followUpMode=false 时，必须返回 final。',
		'若当前信息不足以产出高质量草稿或建议，应返回 needs_followup，并只追问缺失关键信息。',
		'即使返回 needs_followup，也要尽量保留已确定的 symptoms 与 notes，不要默认清空。',
		'symptoms[*] 语义：name 是症状标签；startTime 是开始时间或下界；endTime 是结束时间或上界。若未明确提及结束时间（包括“仍在持续”），endTime 默认回填 eventTime（date 用当天，datetime 用完整时间）；precision 控制时间粒度。',
		'除非 messages 中患者描述本身完全没有可读信息，否则不要返回 {"symptoms":[],"notes":""}。',
		'如果 messages 中患者描述包含症状或不适，请至少返回 1 个 symptom；如果没有正向症状，请把剩余可读信息写入 notes。',
		...(strictEmptyGuard
			? [
					'这是一次严格重试：请纠正上一次把包含可读患者描述的 messages 提取成空 symptoms 和空 notes 的结果。',
			  ]
			: []),
		'返回格式：{"status":"needs_followup|final","question":"string|null","symptoms":[{"name":"string","startTime":"string|null","endTime":"string|null","precision":"date|datetime"}],"notes":"string","actionAdvice":"string"}',
		'needs_followup 示例：',
		'{"status":"needs_followup","question":"具体是哪里不舒服？\\n这种情况大概持续了多久？","symptoms":[],"notes":"","actionAdvice":""}',
		'final 示例：',
		'{"status":"final","question":null,"symptoms":[{"name":"头痛","startTime":"2026-03-18T14:00:00+08:00","endTime":"2026-03-18T18:00:00+08:00","precision":"datetime"}],"notes":"无发烧。","actionAdvice":"建议继续观察症状变化，如明显加重请及时就医。"}',
		`eventTime：${input.eventTime}`,
		`followUpMode：${input.followUpMode}`,
		`forceFinalize：${input.forceFinalize}`,
		'完整消息历史：',
		JSON.stringify(input.messages),
		'只返回 JSON，不要额外解释。',
	].join('\n');

	return {
		systemPrompt,
		userPrompt,
	};
}

function validateIntakePayload(
	payload: unknown,
	options: {
		ignoreNeedsFollowUpQuestion: boolean;
	},
): IntakeModelResult {
	if (!isRecord(payload)) {
		throw new ApiError(502, 'UPSTREAM_INVALID_PAYLOAD', 'DeepSeek returned an invalid JSON object.');
	}

	if (
		!Object.hasOwn(payload, 'status') ||
		!Object.hasOwn(payload, 'question') ||
		!Object.hasOwn(payload, 'symptoms') ||
		!Object.hasOwn(payload, 'notes') ||
		!Object.hasOwn(payload, 'actionAdvice')
	) {
		throw new ApiError(
			502,
			'UPSTREAM_INVALID_PAYLOAD',
			'DeepSeek JSON must contain "status", "question", "symptoms", "notes", and "actionAdvice".',
		);
	}

	if (payload.status !== 'needs_followup' && payload.status !== 'final') {
		throw new ApiError(
			502,
			'UPSTREAM_INVALID_PAYLOAD',
			'"status" must be "needs_followup" or "final".',
		);
	}

	const structuredPayload = validateStructuredSymptomsPayload({
		symptoms: payload.symptoms,
		notes: payload.notes,
	});

	if (typeof payload.actionAdvice !== 'string') {
		throw new ApiError(502, 'UPSTREAM_INVALID_PAYLOAD', '"actionAdvice" must be a string.');
	}

	if (payload.status === 'final') {
		if (payload.question !== null) {
			throw new ApiError(
				502,
				'UPSTREAM_INVALID_PAYLOAD',
				'"question" must be null when status is "final".',
			);
		}

		return {
			status: 'final',
			question: null,
			symptoms: structuredPayload.symptoms,
			notes: structuredPayload.notes,
			actionAdvice: payload.actionAdvice.trim(),
		};
	}

	if (options.ignoreNeedsFollowUpQuestion) {
		return {
			status: 'needs_followup',
			question: typeof payload.question === 'string' ? normalizeFollowUpQuestion(payload.question) : null,
			symptoms: structuredPayload.symptoms,
			notes: structuredPayload.notes,
			actionAdvice: payload.actionAdvice.trim(),
		};
	}

	if (typeof payload.question !== 'string') {
		throw new ApiError(
			502,
			'UPSTREAM_INVALID_PAYLOAD',
			'"question" must be a non-empty string when status is "needs_followup".',
		);
	}

	const question = normalizeFollowUpQuestion(payload.question);
	if (question.length === 0) {
		throw new ApiError(
			502,
			'UPSTREAM_INVALID_PAYLOAD',
			'"question" must be a non-empty string when status is "needs_followup".',
		);
	}

	return {
		status: 'needs_followup',
		question,
		symptoms: structuredPayload.symptoms,
		notes: structuredPayload.notes,
		actionAdvice: payload.actionAdvice.trim(),
	};
}

function hasMeaningfulText(value: string): boolean {
	return /[\p{L}\p{N}]/u.test(value);
}

function isEmptyFinalDraft(draft: IntakeDraft): boolean {
	return draft.symptomSummary.length === 0 && draft.notes.length === 0;
}

function shiftChinaDate(dateValue: string, dayOffset: number): string {
	const parsedDate = new Date(`${dateValue}T00:00:00${CHINA_UTC_OFFSET}`);
	return formatDateAsChinaDateString(new Date(parsedDate.getTime() + dayOffset * 24 * 60 * 60 * 1000));
}

function parseChineseDayCount(token: string): number | null {
	const normalized = token.trim();
	if (/^\d+$/.test(normalized)) {
		const parsed = Number.parseInt(normalized, 10);
		return Number.isInteger(parsed) && parsed > 0 ? parsed : null;
	}

	const lookup: Record<string, number> = {
		一: 1,
		二: 2,
		两: 2,
		三: 3,
		四: 4,
		五: 5,
		六: 6,
		七: 7,
		八: 8,
		九: 9,
		十: 10,
	};

	return lookup[normalized] ?? null;
}

function inferFallbackTimeRange(
	text: string,
	eventTime: string,
): Pick<StructuredSymptom, 'startTime' | 'endTime' | 'precision'> {
	const eventDate = eventTime.slice(0, 10);
	const recentDaysMatch = text.match(/^(最近|近)([一二两三四五六七八九十\d]+)天(?:来|内)?/u);
	if (recentDaysMatch) {
		const dayCount = parseChineseDayCount(recentDaysMatch[2]);
		if (dayCount) {
			return {
				startTime: shiftChinaDate(eventDate, -(dayCount - 1)),
				endTime: eventDate,
				precision: 'date',
			};
		}
	}

	if (/^(今天|今日)/u.test(text)) {
		return {
			startTime: eventDate,
			endTime: eventDate,
			precision: 'date',
		};
	}

	if (/^(昨天|昨晚|昨夜)/u.test(text)) {
		const targetDate = shiftChinaDate(eventDate, -1);
		return {
			startTime: targetDate,
			endTime: targetDate,
			precision: 'date',
		};
	}

	if (/^前天/u.test(text)) {
		const targetDate = shiftChinaDate(eventDate, -2);
		return {
			startTime: targetDate,
			endTime: targetDate,
			precision: 'date',
		};
	}

	return {
		startTime: null,
		endTime: null,
		precision: 'date',
	};
}

function inferFallbackSymptomName(text: string): string | null {
	const cleaned = text
		.replace(/^(最近|近)[一二两三四五六七八九十\d]+天(?:来|内)?/u, '')
		.replace(/^(今天|今日|昨天|昨晚|昨夜|前天)/u, '')
		.replace(/^(一直|总是|反复|持续|经常|开始|出现|觉得|感觉|有点|有些|有时|偶尔|最近|近来)/u, '')
		.replace(/[，。；、,;!！?？\s]+$/gu, '')
		.trim();

	if (cleaned.length === 0) {
		return null;
	}

	if (
		!/(不舒服|不适|疼|痛|胀|闷|晕|咳|喘|堵|恶心|呕|烧|热|乏力|腹泻|便秘|心慌|心悸|胸|胃|肚|头|喉|嗓|鼻|腰|背|腿|麻|痒|出血|流血)/u.test(
			cleaned,
		)
	) {
		return null;
	}

	return cleaned;
}

function inferFallbackSymptom(mergedRawText: string, eventTime: string): StructuredSymptom | null {
	const segments = mergedRawText
		.split(/[\r\n。！？!?；;]+/u)
		.map((segment) => segment.trim())
		.filter((segment) => segment.length > 0);

	for (const segment of segments) {
		const name = inferFallbackSymptomName(segment);
		if (!name) {
			continue;
		}

		return {
			name,
			...inferFallbackTimeRange(segment, eventTime),
		};
	}

	return null;
}

function buildFallbackDraftFromMergedRawText(
	mergedRawText: string,
	eventTime: string,
	actionAdvice: string,
): IntakeDraft {
	const fallbackSymptom = inferFallbackSymptom(mergedRawText, eventTime);
	if (fallbackSymptom) {
		return {
			mergedRawText,
			symptomSummary: buildSymptomSummary([fallbackSymptom]),
			notes: '',
			actionAdvice,
		};
	}

	return {
		mergedRawText,
		symptomSummary: '',
		notes: mergedRawText.trim(),
		actionAdvice,
	};
}

async function requestDeepSeekJson(
	env: WorkerEnv,
	label: 'intake' | 'report',
	requestPayload: {
		model: string;
		messages: Array<{ role: 'system' | 'user'; content: string }>;
		response_format: { type: 'json_object' };
		max_tokens: number;
	},
): Promise<unknown> {
	if (!env.DEEPSEEK_API_KEY) {
		throw new ApiError(500, 'INTERNAL_ERROR', 'DeepSeek API key is missing.');
	}

	let upstreamResponse: Response;
	try {
		upstreamResponse = await fetch('https://api.deepseek.com/chat/completions', {
			method: 'POST',
			headers: {
				'content-type': 'application/json',
				authorization: `Bearer ${env.DEEPSEEK_API_KEY}`,
			},
			body: JSON.stringify(requestPayload),
		});
	} catch {
		throw new ApiError(502, 'UPSTREAM_HTTP_ERROR', 'Failed to reach DeepSeek.');
	}

	if (!upstreamResponse.ok) {
		const upstreamErrorBody = await upstreamResponse.text();
		console.error(`[ai/${label}] DeepSeek upstream status:`, upstreamResponse.status);
		console.error(`[ai/${label}] DeepSeek upstream body:`, upstreamErrorBody);
		throw new ApiError(
			502,
			'UPSTREAM_HTTP_ERROR',
			`DeepSeek request failed with status ${upstreamResponse.status}.`,
		);
	}

	let payload: DeepSeekChatCompletionResponse;
	try {
		payload = JSON.parse(await upstreamResponse.text()) as DeepSeekChatCompletionResponse;
	} catch {
		throw new ApiError(502, 'UPSTREAM_INVALID_JSON', 'DeepSeek returned invalid JSON.');
	}

	const content = parseUpstreamContent(payload);
	const cleanedContent = stripCodeFence(content);

	try {
		return JSON.parse(cleanedContent);
	} catch {
		throw new ApiError(502, 'UPSTREAM_INVALID_PAYLOAD', 'DeepSeek content is not valid JSON.');
	}
}

async function callDeepSeekForIntake(env: WorkerEnv, input: IntakeRequest): Promise<IntakeResponse> {
	const mergedRawText = buildMergedRawText(input.messages);
	const runAttempt = async (strictEmptyGuard: boolean): Promise<{
		modelResult: IntakeModelResult;
		draft: IntakeDraft;
	}> => {
		const prompts = buildIntakePrompts(input, strictEmptyGuard);
		const parsed = await requestDeepSeekJson(env, 'intake', {
			model: resolveDeepSeekModel(env),
			messages: [
				{
					role: 'system',
					content: prompts.systemPrompt,
				},
				{
					role: 'user',
					content: prompts.userPrompt,
				},
			],
			response_format: { type: 'json_object' },
			max_tokens: INTAKE_MAX_TOKENS,
		});

		const modelResult = validateIntakePayload(parsed, {
			ignoreNeedsFollowUpQuestion: input.forceFinalize || !input.followUpMode,
		});

		return {
			modelResult,
			draft: buildIntakeDraft(mergedRawText, modelResult),
		};
	};

	let attempt = await runAttempt(false);
	if (
		attempt.modelResult.status === 'final' &&
		isEmptyFinalDraft(attempt.draft) &&
		hasMeaningfulText(mergedRawText)
	) {
		attempt = await runAttempt(true);
	}

	if (
		attempt.modelResult.status === 'final' &&
		isEmptyFinalDraft(attempt.draft) &&
		hasMeaningfulText(mergedRawText)
	) {
		attempt = {
			...attempt,
			draft: buildFallbackDraftFromMergedRawText(
				mergedRawText,
				input.eventTime,
				attempt.draft.actionAdvice,
			),
		};
	}

	if (input.forceFinalize || !input.followUpMode) {
		return {
			status: 'final',
			question: null,
			draft: attempt.draft,
		};
	}

	return {
		status: attempt.modelResult.status,
		question: attempt.modelResult.question,
		draft: attempt.draft,
	};
}

function parseReportRequest(payload: unknown): ReportRequest {
	if (!isRecord(payload)) {
		throw new ApiError(400, 'INVALID_INPUT', 'Request body must be a JSON object.');
	}

	const reportTypeRaw = typeof payload.reportType === 'string' ? payload.reportType.trim() : '';
	if (reportTypeRaw !== 'week' && reportTypeRaw !== 'month' && reportTypeRaw !== 'quarter') {
		throw new ApiError(
			400,
			'INVALID_INPUT',
			'"reportType" must be one of: week, month, quarter.',
		);
	}

	if (!isNonEmptyString(payload.rangeStart) || !isNonEmptyString(payload.rangeEnd)) {
		throw new ApiError(
			400,
			'INVALID_INPUT',
			'"rangeStart" and "rangeEnd" are required and must be non-empty strings.',
		);
	}

	if (!Array.isArray(payload.events)) {
		throw new ApiError(400, 'INVALID_INPUT', '"events" is required and must be an array.');
	}

	const events = payload.events.map((item, index) => {
		if (!isRecord(item)) {
			throw new ApiError(400, 'INVALID_INPUT', `"events[${index}]" must be an object.`);
		}

		if (!Object.hasOwn(item, 'eventTime') || !isNullableString(item.eventTime)) {
			throw new ApiError(
				400,
				'INVALID_INPUT',
				`"events[${index}].eventTime" must be a string or null.`,
			);
		}

		if (!Object.hasOwn(item, 'rawText') || !isNullableString(item.rawText)) {
			throw new ApiError(
				400,
				'INVALID_INPUT',
				`"events[${index}].rawText" must be a string or null.`,
			);
		}

		if (!Object.hasOwn(item, 'symptomSummary') || !isNullableString(item.symptomSummary)) {
			throw new ApiError(
				400,
				'INVALID_INPUT',
				`"events[${index}].symptomSummary" must be a string or null.`,
			);
		}

		if (!Object.hasOwn(item, 'notes') || !isNullableString(item.notes)) {
			throw new ApiError(
				400,
				'INVALID_INPUT',
				`"events[${index}].notes" must be a string or null.`,
			);
		}

		return {
			eventTime: typeof item.eventTime === 'string' ? item.eventTime.trim() : null,
			rawText: typeof item.rawText === 'string' ? item.rawText.trim() : null,
			symptomSummary: typeof item.symptomSummary === 'string' ? item.symptomSummary.trim() : null,
			notes: typeof item.notes === 'string' ? item.notes.trim() : null,
		};
	});

	return {
		reportType: reportTypeRaw,
		rangeStart: payload.rangeStart.trim(),
		rangeEnd: payload.rangeEnd.trim(),
		events,
	};
}

function getReportBusinessTextCharacterCount(events: ReportEvent[]): number {
	return events.reduce((total, event) => {
		return (
			total +
			countCodePoints(event.rawText ?? '') +
			countCodePoints(event.symptomSummary ?? '') +
			countCodePoints(event.notes ?? '')
		);
	}, 0);
}

function buildEmptyReport(input: Pick<ReportRequest, 'reportType' | 'rangeStart' | 'rangeEnd'>): ReportResult {
	const titleByType: Record<ReportType, string> = {
		week: '最近 7 天健康周报',
		month: '最近 30 天健康月报',
		quarter: '最近 90 天健康季报',
	};

	const title = titleByType[input.reportType];
	const summary = '当前时间范围内暂无健康记录。';
	const advice = ['当前时间范围内暂无明显健康异常记录，建议继续记录日常健康情况，便于后续生成更有参考价值的健康报告。'];
	const markdown = [
		`## ${title}`,
		'',
		`统计范围：${input.rangeStart} 至 ${input.rangeEnd}`,
		'',
		summary,
		'',
		'- 继续记录日常健康情况，便于后续生成更有参考价值的健康报告。',
	].join('\n');

	return { title, summary, advice, markdown };
}

function validateReportPayload(payload: unknown): ReportResult {
	if (!isRecord(payload)) {
		throw new ApiError(502, 'UPSTREAM_INVALID_PAYLOAD', 'DeepSeek returned an invalid JSON object.');
	}

	if (
		!Object.hasOwn(payload, 'title') ||
		!Object.hasOwn(payload, 'summary') ||
		!Object.hasOwn(payload, 'advice') ||
		!Object.hasOwn(payload, 'markdown')
	) {
		throw new ApiError(
			502,
			'UPSTREAM_INVALID_PAYLOAD',
			'DeepSeek JSON must contain "title", "summary", "advice", and "markdown".',
		);
	}

	const { title, summary, advice, markdown } = payload;
	if (!isNonEmptyString(title) || !isNonEmptyString(summary) || !isNonEmptyString(markdown)) {
		throw new ApiError(
			502,
			'UPSTREAM_INVALID_PAYLOAD',
			'"title", "summary", and "markdown" must be non-empty strings.',
		);
	}

	if (!Array.isArray(advice) || advice.some((item) => !isNonEmptyString(item))) {
		throw new ApiError(502, 'UPSTREAM_INVALID_PAYLOAD', '"advice" must be an array of strings.');
	}

	return {
		title: title.trim(),
		summary: summary.trim(),
		advice: advice.map((item) => item.trim()),
		markdown: markdown.trim(),
	};
}

async function parseJsonBody(request: Request): Promise<unknown> {
	try {
		return await request.json();
	} catch {
		throw new ApiError(400, 'INVALID_JSON', 'Request body must be valid JSON.');
	}
}

async function callDeepSeekForReport(env: WorkerEnv, input: ReportRequest): Promise<ReportResult> {
	const parsed = await requestDeepSeekJson(env, 'report', {
		model: resolveDeepSeekModel(env),
		messages: [
			{
				role: 'system',
				content: [
					'你是一个健康报告生成助手。',
					'你必须返回 JSON。',
					'只能返回一个 JSON 对象，不要输出额外文本。',
					'不要返回 Markdown 代码围栏。',
					'输出结构必须为：{"title":"string","summary":"string","advice":["string"],"markdown":"string"}。',
					'"title"、"summary" 和 "markdown" 必须是非空字符串。',
					'"title" 表示报告标题，需要与 reportType 和统计范围语义一致。',
					'"summary" 表示总体评估与趋势归纳，不要逐条复述 events 原文。',
					'"advice" 必须是由完整建议句组成的字符串数组，不要只写“保持规律作息”这类口号式短语。',
					'"advice" 需要基于 events 证据给出可执行建议，并与 summary 结论一致。',
					'"markdown" 必须是完整报告正文，并与 title、summary、advice 保持一致，不得互相矛盾。',
					'每条 advice 应优先按“评估结果 + 对应依据 + 具体建议”组织；如果没有明确依据，可只写“评估结果 + 具体建议”。',
					'只能使用提供的 events 和报告时间范围。',
				].join(' '),
			},
			{
				role: 'user',
				content: [
					'请根据输入数据生成结构化健康报告。',
					'只返回 JSON。',
					'reportType 表示报告周期类型（week/month/quarter）。',
					'rangeStart 和 rangeEnd 表示报告统计范围边界，不表示症状发生起止时间。',
					'events 表示统计范围内的记录列表。',
					'输入数据中的字段含义如下：eventTime 表示记录创建时间，rawText 表示患者原始描述，symptomSummary 表示已归一化的症状摘要，notes 表示补充说明。',
					'不要把 eventTime 理解为症状发生起止时间。',
					'输出字段语义：title 是报告标题，summary 是总体归纳，advice 是建议列表，markdown 是完整报告正文，四者必须语义一致。',
					'目标 JSON 示例：',
					'{"title":"最近 7 天健康周报","summary":"...","advice":["您本周整体健康状态良好，请继续保持规律作息。","您连续多日出现喉咙不适，结合症状描述提示可能与咽喉炎或扁桃体炎有关，建议先充分休息并观察变化，若持续两周仍未缓解请及时就医。"],"markdown":"# 健康报告\\n..."}',
					'advice 示例 1：您本周整体健康状态良好，请继续保持规律作息。',
					'advice 示例 2：您这个月经常感冒发热，结合多次发热与睡眠不足的记录，推测可能与工作压力大和免疫力下降有关，建议尽量保证每天至少 7.5 小时睡眠，若反复高热请尽快就医。',
					'输入数据：',
					JSON.stringify(input),
				].join('\n'),
			},
		],
		response_format: { type: 'json_object' },
		max_tokens: REPORT_MAX_TOKENS,
	});

	return validateReportPayload(parsed);
}

async function handleIntakeRequest(request: Request, env: WorkerEnv): Promise<Response> {
	const body = await parseJsonBody(request);
	const parsedRequest = parseIntakeRequest(body);
	const result = await callDeepSeekForIntake(env, parsedRequest);
	return jsonResponse(result);
}

async function handleReportRequest(request: Request, env: WorkerEnv): Promise<Response> {
	const body = await parseJsonBody(request);
	const parsedRequest = parseReportRequest(body);
	if (getReportBusinessTextCharacterCount(parsedRequest.events) > REPORT_MAX_TEXT_CHARACTERS) {
		throw new ApiError(
			400,
			'INVALID_INPUT',
			'"events" text content must be at most 10000 characters after trim.',
		);
	}

	if (parsedRequest.events.length === 0) {
		return jsonResponse(buildEmptyReport(parsedRequest));
	}

	const report = await callDeepSeekForReport(env, parsedRequest);
	return jsonResponse(report);
}

export default {
	async fetch(request: Request, env: WorkerEnv): Promise<Response> {
		try {
			if (request.method === 'OPTIONS') {
				return new Response(null, {
					status: 204,
					headers: JSON_HEADERS,
				});
			}

			const url = new URL(request.url);
			if (url.pathname === '/ai/intake') {
				if (request.method !== 'POST') {
					return errorResponse(404, 'NOT_FOUND', 'Route not found.');
				}

				return await handleIntakeRequest(request, env);
			}

			if (url.pathname === '/ai/report') {
				if (request.method !== 'POST') {
					return errorResponse(404, 'NOT_FOUND', 'Route not found.');
				}

				return await handleReportRequest(request, env);
			}

			return errorResponse(404, 'NOT_FOUND', 'Route not found.');
		} catch (error) {
			if (error instanceof ApiError) {
				return errorResponse(error.status, error.code, error.message);
			}

			console.error(error);
			return errorResponse(500, 'INTERNAL_ERROR', 'Internal server error.');
		}
	},
};
