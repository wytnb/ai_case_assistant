enum AiIntakeExceptionType {
  network,
  upstreamHttpError,
  invalidRequestPayload,
  invalidResponsePayload,
  unknown,
}

class AiIntakeException implements Exception {
  const AiIntakeException({
    required this.type,
    required this.message,
    this.statusCode,
  });

  final AiIntakeExceptionType type;
  final String message;
  final int? statusCode;
}
