enum IntakeMessageRole {
  user('user'),
  assistant('assistant');

  const IntakeMessageRole(this.wireValue);

  final String wireValue;

  static IntakeMessageRole fromWireValue(String value) {
    switch (value) {
      case 'user':
        return IntakeMessageRole.user;
      case 'assistant':
        return IntakeMessageRole.assistant;
      default:
        throw ArgumentError.value(value, 'value', 'Unsupported role');
    }
  }
}

enum IntakeResponseStatus {
  needsFollowup('needs_followup'),
  finalResult('final');

  const IntakeResponseStatus(this.wireValue);

  final String wireValue;

  static IntakeResponseStatus fromWireValue(String value) {
    switch (value) {
      case 'needs_followup':
        return IntakeResponseStatus.needsFollowup;
      case 'final':
        return IntakeResponseStatus.finalResult;
      default:
        throw ArgumentError.value(value, 'value', 'Unsupported intake status');
    }
  }
}

class IntakeRequestMessage {
  const IntakeRequestMessage({required this.role, required this.content});

  final IntakeMessageRole role;
  final String content;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'role': role.wireValue, 'content': content};
  }
}

class IntakeDraft {
  const IntakeDraft({
    required this.mergedRawText,
    required this.symptomSummary,
    required this.notes,
    required this.actionAdvice,
  });

  final String mergedRawText;
  final String symptomSummary;
  final String notes;
  final String actionAdvice;
}

class IntakeResponse {
  const IntakeResponse({
    required this.status,
    required this.question,
    required this.draft,
  });

  final IntakeResponseStatus status;
  final String? question;
  final IntakeDraft draft;
}

abstract class AiIntakeService {
  Future<IntakeResponse> submitIntake({
    required bool followUpMode,
    required bool forceFinalize,
    required DateTime eventTime,
    required List<IntakeRequestMessage> messages,
  });
}
