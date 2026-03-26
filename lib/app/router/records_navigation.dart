enum HealthRecordListTab {
  records,
  drafts;

  static HealthRecordListTab fromQueryValue(String? value) {
    return switch (value) {
      'drafts' => HealthRecordListTab.drafts,
      _ => HealthRecordListTab.records,
    };
  }

  String get queryValue {
    return switch (this) {
      HealthRecordListTab.records => 'records',
      HealthRecordListTab.drafts => 'drafts',
    };
  }
}

String buildRecordsLocation({
  HealthRecordListTab tab = HealthRecordListTab.records,
}) {
  return '/records?tab=${tab.queryValue}';
}
