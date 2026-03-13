enum AiExtractExceptionType {
  network,
  upstreamHttpError,
  invalidResponsePayload,
  unknown,
}

class AiExtractException implements Exception {
  const AiExtractException({
    required this.type,
    required this.message,
    this.statusCode,
  });

  final AiExtractExceptionType type;
  final String message;
  final int? statusCode;
}
