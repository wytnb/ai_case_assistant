class AppConfig {
  const AppConfig._();

  static const String aiApiBaseUrl = String.fromEnvironment(
    'AI_API_BASE_URL',
    defaultValue: 'https://ai-api-worker.wytai.workers.dev',
  );

  static const bool useMockAiExtract = bool.fromEnvironment(
    'USE_MOCK_AI_EXTRACT',
    defaultValue: false,
  );
}
