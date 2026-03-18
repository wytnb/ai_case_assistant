const Duration _eventTimeOffset = Duration(hours: 8);

String formatEventTimeForApi(DateTime value) {
  final DateTime chinaTime = (value.isUtc ? value : value.toUtc()).add(
    _eventTimeOffset,
  );

  return '${_fourDigits(chinaTime.year)}-${_twoDigits(chinaTime.month)}-${_twoDigits(chinaTime.day)}'
      'T${_twoDigits(chinaTime.hour)}:${_twoDigits(chinaTime.minute)}:${_twoDigits(chinaTime.second)}'
      '+08:00';
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

String _fourDigits(int value) => value.toString().padLeft(4, '0');
