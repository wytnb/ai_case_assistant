enum AiReportExceptionType {
  invalidRequestPayload,
  timeout,
  network,
  upstreamHttpError,
  invalidResponsePayload,
  unknown,
}

class AiReportException implements Exception {
  const AiReportException({
    required this.type,
    required this.message,
    this.statusCode,
  });

  final AiReportExceptionType type;
  final String message;
  final int? statusCode;
}
