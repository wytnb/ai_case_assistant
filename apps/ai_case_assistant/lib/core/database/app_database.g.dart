// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $HealthEventsTable extends HealthEvents
    with TableInfo<$HealthEventsTable, HealthEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HealthEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  static const VerificationMeta _rawTextMeta = const VerificationMeta(
    'rawText',
  );
  @override
  late final GeneratedColumn<String> rawText = GeneratedColumn<String>(
    'raw_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _symptomSummaryMeta = const VerificationMeta(
    'symptomSummary',
  );
  @override
  late final GeneratedColumn<String> symptomSummary = GeneratedColumn<String>(
    'symptom_summary',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actionAdviceMeta = const VerificationMeta(
    'actionAdvice',
  );
  @override
  late final GeneratedColumn<String> actionAdvice = GeneratedColumn<String>(
    'action_advice',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceType,
    status,
    rawText,
    symptomSummary,
    notes,
    actionAdvice,
    deletedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'health_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<HealthEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceTypeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('raw_text')) {
      context.handle(
        _rawTextMeta,
        rawText.isAcceptableOrUnknown(data['raw_text']!, _rawTextMeta),
      );
    }
    if (data.containsKey('symptom_summary')) {
      context.handle(
        _symptomSummaryMeta,
        symptomSummary.isAcceptableOrUnknown(
          data['symptom_summary']!,
          _symptomSummaryMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('action_advice')) {
      context.handle(
        _actionAdviceMeta,
        actionAdvice.isAcceptableOrUnknown(
          data['action_advice']!,
          _actionAdviceMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HealthEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HealthEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      rawText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_text'],
      ),
      symptomSummary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}symptom_summary'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      actionAdvice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action_advice'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $HealthEventsTable createAlias(String alias) {
    return $HealthEventsTable(attachedDatabase, alias);
  }
}

class HealthEvent extends DataClass implements Insertable<HealthEvent> {
  final String id;
  final String sourceType;
  final String status;
  final String? rawText;
  final String? symptomSummary;
  final String? notes;
  final String? actionAdvice;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const HealthEvent({
    required this.id,
    required this.sourceType,
    required this.status,
    this.rawText,
    this.symptomSummary,
    this.notes,
    this.actionAdvice,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source_type'] = Variable<String>(sourceType);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || rawText != null) {
      map['raw_text'] = Variable<String>(rawText);
    }
    if (!nullToAbsent || symptomSummary != null) {
      map['symptom_summary'] = Variable<String>(symptomSummary);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || actionAdvice != null) {
      map['action_advice'] = Variable<String>(actionAdvice);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  HealthEventsCompanion toCompanion(bool nullToAbsent) {
    return HealthEventsCompanion(
      id: Value(id),
      sourceType: Value(sourceType),
      status: Value(status),
      rawText: rawText == null && nullToAbsent
          ? const Value.absent()
          : Value(rawText),
      symptomSummary: symptomSummary == null && nullToAbsent
          ? const Value.absent()
          : Value(symptomSummary),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      actionAdvice: actionAdvice == null && nullToAbsent
          ? const Value.absent()
          : Value(actionAdvice),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory HealthEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HealthEvent(
      id: serializer.fromJson<String>(json['id']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      status: serializer.fromJson<String>(json['status']),
      rawText: serializer.fromJson<String?>(json['rawText']),
      symptomSummary: serializer.fromJson<String?>(json['symptomSummary']),
      notes: serializer.fromJson<String?>(json['notes']),
      actionAdvice: serializer.fromJson<String?>(json['actionAdvice']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourceType': serializer.toJson<String>(sourceType),
      'status': serializer.toJson<String>(status),
      'rawText': serializer.toJson<String?>(rawText),
      'symptomSummary': serializer.toJson<String?>(symptomSummary),
      'notes': serializer.toJson<String?>(notes),
      'actionAdvice': serializer.toJson<String?>(actionAdvice),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  HealthEvent copyWith({
    String? id,
    String? sourceType,
    String? status,
    Value<String?> rawText = const Value.absent(),
    Value<String?> symptomSummary = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> actionAdvice = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => HealthEvent(
    id: id ?? this.id,
    sourceType: sourceType ?? this.sourceType,
    status: status ?? this.status,
    rawText: rawText.present ? rawText.value : this.rawText,
    symptomSummary: symptomSummary.present
        ? symptomSummary.value
        : this.symptomSummary,
    notes: notes.present ? notes.value : this.notes,
    actionAdvice: actionAdvice.present ? actionAdvice.value : this.actionAdvice,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  HealthEvent copyWithCompanion(HealthEventsCompanion data) {
    return HealthEvent(
      id: data.id.present ? data.id.value : this.id,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      status: data.status.present ? data.status.value : this.status,
      rawText: data.rawText.present ? data.rawText.value : this.rawText,
      symptomSummary: data.symptomSummary.present
          ? data.symptomSummary.value
          : this.symptomSummary,
      notes: data.notes.present ? data.notes.value : this.notes,
      actionAdvice: data.actionAdvice.present
          ? data.actionAdvice.value
          : this.actionAdvice,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HealthEvent(')
          ..write('id: $id, ')
          ..write('sourceType: $sourceType, ')
          ..write('status: $status, ')
          ..write('rawText: $rawText, ')
          ..write('symptomSummary: $symptomSummary, ')
          ..write('notes: $notes, ')
          ..write('actionAdvice: $actionAdvice, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceType,
    status,
    rawText,
    symptomSummary,
    notes,
    actionAdvice,
    deletedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HealthEvent &&
          other.id == this.id &&
          other.sourceType == this.sourceType &&
          other.status == this.status &&
          other.rawText == this.rawText &&
          other.symptomSummary == this.symptomSummary &&
          other.notes == this.notes &&
          other.actionAdvice == this.actionAdvice &&
          other.deletedAt == this.deletedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class HealthEventsCompanion extends UpdateCompanion<HealthEvent> {
  final Value<String> id;
  final Value<String> sourceType;
  final Value<String> status;
  final Value<String?> rawText;
  final Value<String?> symptomSummary;
  final Value<String?> notes;
  final Value<String?> actionAdvice;
  final Value<DateTime?> deletedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const HealthEventsCompanion({
    this.id = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.status = const Value.absent(),
    this.rawText = const Value.absent(),
    this.symptomSummary = const Value.absent(),
    this.notes = const Value.absent(),
    this.actionAdvice = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HealthEventsCompanion.insert({
    required String id,
    required String sourceType,
    this.status = const Value.absent(),
    this.rawText = const Value.absent(),
    this.symptomSummary = const Value.absent(),
    this.notes = const Value.absent(),
    this.actionAdvice = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sourceType = Value(sourceType),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<HealthEvent> custom({
    Expression<String>? id,
    Expression<String>? sourceType,
    Expression<String>? status,
    Expression<String>? rawText,
    Expression<String>? symptomSummary,
    Expression<String>? notes,
    Expression<String>? actionAdvice,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceType != null) 'source_type': sourceType,
      if (status != null) 'status': status,
      if (rawText != null) 'raw_text': rawText,
      if (symptomSummary != null) 'symptom_summary': symptomSummary,
      if (notes != null) 'notes': notes,
      if (actionAdvice != null) 'action_advice': actionAdvice,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HealthEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? sourceType,
    Value<String>? status,
    Value<String?>? rawText,
    Value<String?>? symptomSummary,
    Value<String?>? notes,
    Value<String?>? actionAdvice,
    Value<DateTime?>? deletedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return HealthEventsCompanion(
      id: id ?? this.id,
      sourceType: sourceType ?? this.sourceType,
      status: status ?? this.status,
      rawText: rawText ?? this.rawText,
      symptomSummary: symptomSummary ?? this.symptomSummary,
      notes: notes ?? this.notes,
      actionAdvice: actionAdvice ?? this.actionAdvice,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rawText.present) {
      map['raw_text'] = Variable<String>(rawText.value);
    }
    if (symptomSummary.present) {
      map['symptom_summary'] = Variable<String>(symptomSummary.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (actionAdvice.present) {
      map['action_advice'] = Variable<String>(actionAdvice.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HealthEventsCompanion(')
          ..write('id: $id, ')
          ..write('sourceType: $sourceType, ')
          ..write('status: $status, ')
          ..write('rawText: $rawText, ')
          ..write('symptomSummary: $symptomSummary, ')
          ..write('notes: $notes, ')
          ..write('actionAdvice: $actionAdvice, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttachmentsTable extends Attachments
    with TableInfo<$AttachmentsTable, Attachment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _healthEventIdMeta = const VerificationMeta(
    'healthEventId',
  );
  @override
  late final GeneratedColumn<String> healthEventId = GeneratedColumn<String>(
    'health_event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES health_events (id)',
    ),
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileTypeMeta = const VerificationMeta(
    'fileType',
  );
  @override
  late final GeneratedColumn<String> fileType = GeneratedColumn<String>(
    'file_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    healthEventId,
    filePath,
    fileType,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attachments';
  @override
  VerificationContext validateIntegrity(
    Insertable<Attachment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('health_event_id')) {
      context.handle(
        _healthEventIdMeta,
        healthEventId.isAcceptableOrUnknown(
          data['health_event_id']!,
          _healthEventIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_healthEventIdMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('file_type')) {
      context.handle(
        _fileTypeMeta,
        fileType.isAcceptableOrUnknown(data['file_type']!, _fileTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_fileTypeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Attachment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Attachment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      healthEventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}health_event_id'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      fileType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_type'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AttachmentsTable createAlias(String alias) {
    return $AttachmentsTable(attachedDatabase, alias);
  }
}

class Attachment extends DataClass implements Insertable<Attachment> {
  final String id;
  final String healthEventId;
  final String filePath;
  final String fileType;
  final DateTime createdAt;
  const Attachment({
    required this.id,
    required this.healthEventId,
    required this.filePath,
    required this.fileType,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['health_event_id'] = Variable<String>(healthEventId);
    map['file_path'] = Variable<String>(filePath);
    map['file_type'] = Variable<String>(fileType);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AttachmentsCompanion toCompanion(bool nullToAbsent) {
    return AttachmentsCompanion(
      id: Value(id),
      healthEventId: Value(healthEventId),
      filePath: Value(filePath),
      fileType: Value(fileType),
      createdAt: Value(createdAt),
    );
  }

  factory Attachment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Attachment(
      id: serializer.fromJson<String>(json['id']),
      healthEventId: serializer.fromJson<String>(json['healthEventId']),
      filePath: serializer.fromJson<String>(json['filePath']),
      fileType: serializer.fromJson<String>(json['fileType']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'healthEventId': serializer.toJson<String>(healthEventId),
      'filePath': serializer.toJson<String>(filePath),
      'fileType': serializer.toJson<String>(fileType),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Attachment copyWith({
    String? id,
    String? healthEventId,
    String? filePath,
    String? fileType,
    DateTime? createdAt,
  }) => Attachment(
    id: id ?? this.id,
    healthEventId: healthEventId ?? this.healthEventId,
    filePath: filePath ?? this.filePath,
    fileType: fileType ?? this.fileType,
    createdAt: createdAt ?? this.createdAt,
  );
  Attachment copyWithCompanion(AttachmentsCompanion data) {
    return Attachment(
      id: data.id.present ? data.id.value : this.id,
      healthEventId: data.healthEventId.present
          ? data.healthEventId.value
          : this.healthEventId,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      fileType: data.fileType.present ? data.fileType.value : this.fileType,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Attachment(')
          ..write('id: $id, ')
          ..write('healthEventId: $healthEventId, ')
          ..write('filePath: $filePath, ')
          ..write('fileType: $fileType, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, healthEventId, filePath, fileType, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Attachment &&
          other.id == this.id &&
          other.healthEventId == this.healthEventId &&
          other.filePath == this.filePath &&
          other.fileType == this.fileType &&
          other.createdAt == this.createdAt);
}

class AttachmentsCompanion extends UpdateCompanion<Attachment> {
  final Value<String> id;
  final Value<String> healthEventId;
  final Value<String> filePath;
  final Value<String> fileType;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AttachmentsCompanion({
    this.id = const Value.absent(),
    this.healthEventId = const Value.absent(),
    this.filePath = const Value.absent(),
    this.fileType = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttachmentsCompanion.insert({
    required String id,
    required String healthEventId,
    required String filePath,
    required String fileType,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       healthEventId = Value(healthEventId),
       filePath = Value(filePath),
       fileType = Value(fileType),
       createdAt = Value(createdAt);
  static Insertable<Attachment> custom({
    Expression<String>? id,
    Expression<String>? healthEventId,
    Expression<String>? filePath,
    Expression<String>? fileType,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (healthEventId != null) 'health_event_id': healthEventId,
      if (filePath != null) 'file_path': filePath,
      if (fileType != null) 'file_type': fileType,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttachmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? healthEventId,
    Value<String>? filePath,
    Value<String>? fileType,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return AttachmentsCompanion(
      id: id ?? this.id,
      healthEventId: healthEventId ?? this.healthEventId,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (healthEventId.present) {
      map['health_event_id'] = Variable<String>(healthEventId.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (fileType.present) {
      map['file_type'] = Variable<String>(fileType.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentsCompanion(')
          ..write('id: $id, ')
          ..write('healthEventId: $healthEventId, ')
          ..write('filePath: $filePath, ')
          ..write('fileType: $fileType, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReportsTable extends Reports with TableInfo<$ReportsTable, Report> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReportsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reportTypeMeta = const VerificationMeta(
    'reportType',
  );
  @override
  late final GeneratedColumn<String> reportType = GeneratedColumn<String>(
    'report_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rangeStartMeta = const VerificationMeta(
    'rangeStart',
  );
  @override
  late final GeneratedColumn<DateTime> rangeStart = GeneratedColumn<DateTime>(
    'range_start',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rangeEndMeta = const VerificationMeta(
    'rangeEnd',
  );
  @override
  late final GeneratedColumn<DateTime> rangeEnd = GeneratedColumn<DateTime>(
    'range_end',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _adviceJsonMeta = const VerificationMeta(
    'adviceJson',
  );
  @override
  late final GeneratedColumn<String> adviceJson = GeneratedColumn<String>(
    'advice_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _markdownMeta = const VerificationMeta(
    'markdown',
  );
  @override
  late final GeneratedColumn<String> markdown = GeneratedColumn<String>(
    'markdown',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _generatedAtMeta = const VerificationMeta(
    'generatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> generatedAt = GeneratedColumn<DateTime>(
    'generated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    reportType,
    rangeStart,
    rangeEnd,
    title,
    summary,
    adviceJson,
    markdown,
    generatedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reports';
  @override
  VerificationContext validateIntegrity(
    Insertable<Report> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('report_type')) {
      context.handle(
        _reportTypeMeta,
        reportType.isAcceptableOrUnknown(data['report_type']!, _reportTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_reportTypeMeta);
    }
    if (data.containsKey('range_start')) {
      context.handle(
        _rangeStartMeta,
        rangeStart.isAcceptableOrUnknown(data['range_start']!, _rangeStartMeta),
      );
    } else if (isInserting) {
      context.missing(_rangeStartMeta);
    }
    if (data.containsKey('range_end')) {
      context.handle(
        _rangeEndMeta,
        rangeEnd.isAcceptableOrUnknown(data['range_end']!, _rangeEndMeta),
      );
    } else if (isInserting) {
      context.missing(_rangeEndMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    } else if (isInserting) {
      context.missing(_summaryMeta);
    }
    if (data.containsKey('advice_json')) {
      context.handle(
        _adviceJsonMeta,
        adviceJson.isAcceptableOrUnknown(data['advice_json']!, _adviceJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_adviceJsonMeta);
    }
    if (data.containsKey('markdown')) {
      context.handle(
        _markdownMeta,
        markdown.isAcceptableOrUnknown(data['markdown']!, _markdownMeta),
      );
    } else if (isInserting) {
      context.missing(_markdownMeta);
    }
    if (data.containsKey('generated_at')) {
      context.handle(
        _generatedAtMeta,
        generatedAt.isAcceptableOrUnknown(
          data['generated_at']!,
          _generatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_generatedAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Report map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Report(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      reportType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}report_type'],
      )!,
      rangeStart: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}range_start'],
      )!,
      rangeEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}range_end'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      )!,
      adviceJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}advice_json'],
      )!,
      markdown: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}markdown'],
      )!,
      generatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}generated_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ReportsTable createAlias(String alias) {
    return $ReportsTable(attachedDatabase, alias);
  }
}

class Report extends DataClass implements Insertable<Report> {
  final String id;
  final String reportType;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final String title;
  final String summary;
  final String adviceJson;
  final String markdown;
  final DateTime generatedAt;
  final DateTime createdAt;
  const Report({
    required this.id,
    required this.reportType,
    required this.rangeStart,
    required this.rangeEnd,
    required this.title,
    required this.summary,
    required this.adviceJson,
    required this.markdown,
    required this.generatedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['report_type'] = Variable<String>(reportType);
    map['range_start'] = Variable<DateTime>(rangeStart);
    map['range_end'] = Variable<DateTime>(rangeEnd);
    map['title'] = Variable<String>(title);
    map['summary'] = Variable<String>(summary);
    map['advice_json'] = Variable<String>(adviceJson);
    map['markdown'] = Variable<String>(markdown);
    map['generated_at'] = Variable<DateTime>(generatedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ReportsCompanion toCompanion(bool nullToAbsent) {
    return ReportsCompanion(
      id: Value(id),
      reportType: Value(reportType),
      rangeStart: Value(rangeStart),
      rangeEnd: Value(rangeEnd),
      title: Value(title),
      summary: Value(summary),
      adviceJson: Value(adviceJson),
      markdown: Value(markdown),
      generatedAt: Value(generatedAt),
      createdAt: Value(createdAt),
    );
  }

  factory Report.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Report(
      id: serializer.fromJson<String>(json['id']),
      reportType: serializer.fromJson<String>(json['reportType']),
      rangeStart: serializer.fromJson<DateTime>(json['rangeStart']),
      rangeEnd: serializer.fromJson<DateTime>(json['rangeEnd']),
      title: serializer.fromJson<String>(json['title']),
      summary: serializer.fromJson<String>(json['summary']),
      adviceJson: serializer.fromJson<String>(json['adviceJson']),
      markdown: serializer.fromJson<String>(json['markdown']),
      generatedAt: serializer.fromJson<DateTime>(json['generatedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'reportType': serializer.toJson<String>(reportType),
      'rangeStart': serializer.toJson<DateTime>(rangeStart),
      'rangeEnd': serializer.toJson<DateTime>(rangeEnd),
      'title': serializer.toJson<String>(title),
      'summary': serializer.toJson<String>(summary),
      'adviceJson': serializer.toJson<String>(adviceJson),
      'markdown': serializer.toJson<String>(markdown),
      'generatedAt': serializer.toJson<DateTime>(generatedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Report copyWith({
    String? id,
    String? reportType,
    DateTime? rangeStart,
    DateTime? rangeEnd,
    String? title,
    String? summary,
    String? adviceJson,
    String? markdown,
    DateTime? generatedAt,
    DateTime? createdAt,
  }) => Report(
    id: id ?? this.id,
    reportType: reportType ?? this.reportType,
    rangeStart: rangeStart ?? this.rangeStart,
    rangeEnd: rangeEnd ?? this.rangeEnd,
    title: title ?? this.title,
    summary: summary ?? this.summary,
    adviceJson: adviceJson ?? this.adviceJson,
    markdown: markdown ?? this.markdown,
    generatedAt: generatedAt ?? this.generatedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  Report copyWithCompanion(ReportsCompanion data) {
    return Report(
      id: data.id.present ? data.id.value : this.id,
      reportType: data.reportType.present
          ? data.reportType.value
          : this.reportType,
      rangeStart: data.rangeStart.present
          ? data.rangeStart.value
          : this.rangeStart,
      rangeEnd: data.rangeEnd.present ? data.rangeEnd.value : this.rangeEnd,
      title: data.title.present ? data.title.value : this.title,
      summary: data.summary.present ? data.summary.value : this.summary,
      adviceJson: data.adviceJson.present
          ? data.adviceJson.value
          : this.adviceJson,
      markdown: data.markdown.present ? data.markdown.value : this.markdown,
      generatedAt: data.generatedAt.present
          ? data.generatedAt.value
          : this.generatedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Report(')
          ..write('id: $id, ')
          ..write('reportType: $reportType, ')
          ..write('rangeStart: $rangeStart, ')
          ..write('rangeEnd: $rangeEnd, ')
          ..write('title: $title, ')
          ..write('summary: $summary, ')
          ..write('adviceJson: $adviceJson, ')
          ..write('markdown: $markdown, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    reportType,
    rangeStart,
    rangeEnd,
    title,
    summary,
    adviceJson,
    markdown,
    generatedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Report &&
          other.id == this.id &&
          other.reportType == this.reportType &&
          other.rangeStart == this.rangeStart &&
          other.rangeEnd == this.rangeEnd &&
          other.title == this.title &&
          other.summary == this.summary &&
          other.adviceJson == this.adviceJson &&
          other.markdown == this.markdown &&
          other.generatedAt == this.generatedAt &&
          other.createdAt == this.createdAt);
}

class ReportsCompanion extends UpdateCompanion<Report> {
  final Value<String> id;
  final Value<String> reportType;
  final Value<DateTime> rangeStart;
  final Value<DateTime> rangeEnd;
  final Value<String> title;
  final Value<String> summary;
  final Value<String> adviceJson;
  final Value<String> markdown;
  final Value<DateTime> generatedAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ReportsCompanion({
    this.id = const Value.absent(),
    this.reportType = const Value.absent(),
    this.rangeStart = const Value.absent(),
    this.rangeEnd = const Value.absent(),
    this.title = const Value.absent(),
    this.summary = const Value.absent(),
    this.adviceJson = const Value.absent(),
    this.markdown = const Value.absent(),
    this.generatedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReportsCompanion.insert({
    required String id,
    required String reportType,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required String title,
    required String summary,
    required String adviceJson,
    required String markdown,
    required DateTime generatedAt,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       reportType = Value(reportType),
       rangeStart = Value(rangeStart),
       rangeEnd = Value(rangeEnd),
       title = Value(title),
       summary = Value(summary),
       adviceJson = Value(adviceJson),
       markdown = Value(markdown),
       generatedAt = Value(generatedAt),
       createdAt = Value(createdAt);
  static Insertable<Report> custom({
    Expression<String>? id,
    Expression<String>? reportType,
    Expression<DateTime>? rangeStart,
    Expression<DateTime>? rangeEnd,
    Expression<String>? title,
    Expression<String>? summary,
    Expression<String>? adviceJson,
    Expression<String>? markdown,
    Expression<DateTime>? generatedAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (reportType != null) 'report_type': reportType,
      if (rangeStart != null) 'range_start': rangeStart,
      if (rangeEnd != null) 'range_end': rangeEnd,
      if (title != null) 'title': title,
      if (summary != null) 'summary': summary,
      if (adviceJson != null) 'advice_json': adviceJson,
      if (markdown != null) 'markdown': markdown,
      if (generatedAt != null) 'generated_at': generatedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReportsCompanion copyWith({
    Value<String>? id,
    Value<String>? reportType,
    Value<DateTime>? rangeStart,
    Value<DateTime>? rangeEnd,
    Value<String>? title,
    Value<String>? summary,
    Value<String>? adviceJson,
    Value<String>? markdown,
    Value<DateTime>? generatedAt,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ReportsCompanion(
      id: id ?? this.id,
      reportType: reportType ?? this.reportType,
      rangeStart: rangeStart ?? this.rangeStart,
      rangeEnd: rangeEnd ?? this.rangeEnd,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      adviceJson: adviceJson ?? this.adviceJson,
      markdown: markdown ?? this.markdown,
      generatedAt: generatedAt ?? this.generatedAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (reportType.present) {
      map['report_type'] = Variable<String>(reportType.value);
    }
    if (rangeStart.present) {
      map['range_start'] = Variable<DateTime>(rangeStart.value);
    }
    if (rangeEnd.present) {
      map['range_end'] = Variable<DateTime>(rangeEnd.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (adviceJson.present) {
      map['advice_json'] = Variable<String>(adviceJson.value);
    }
    if (markdown.present) {
      map['markdown'] = Variable<String>(markdown.value);
    }
    if (generatedAt.present) {
      map['generated_at'] = Variable<DateTime>(generatedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReportsCompanion(')
          ..write('id: $id, ')
          ..write('reportType: $reportType, ')
          ..write('rangeStart: $rangeStart, ')
          ..write('rangeEnd: $rangeEnd, ')
          ..write('title: $title, ')
          ..write('summary: $summary, ')
          ..write('adviceJson: $adviceJson, ')
          ..write('markdown: $markdown, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueTypeMeta = const VerificationMeta(
    'valueType',
  );
  @override
  late final GeneratedColumn<String> valueType = GeneratedColumn<String>(
    'value_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boolValueMeta = const VerificationMeta(
    'boolValue',
  );
  @override
  late final GeneratedColumn<bool> boolValue = GeneratedColumn<bool>(
    'bool_value',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("bool_value" IN (0, 1))',
    ),
  );
  static const VerificationMeta _intValueMeta = const VerificationMeta(
    'intValue',
  );
  @override
  late final GeneratedColumn<int> intValue = GeneratedColumn<int>(
    'int_value',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _doubleValueMeta = const VerificationMeta(
    'doubleValue',
  );
  @override
  late final GeneratedColumn<double> doubleValue = GeneratedColumn<double>(
    'double_value',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stringValueMeta = const VerificationMeta(
    'stringValue',
  );
  @override
  late final GeneratedColumn<String> stringValue = GeneratedColumn<String>(
    'string_value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jsonValueMeta = const VerificationMeta(
    'jsonValue',
  );
  @override
  late final GeneratedColumn<String> jsonValue = GeneratedColumn<String>(
    'json_value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    key,
    valueType,
    boolValue,
    intValue,
    doubleValue,
    stringValue,
    jsonValue,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value_type')) {
      context.handle(
        _valueTypeMeta,
        valueType.isAcceptableOrUnknown(data['value_type']!, _valueTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_valueTypeMeta);
    }
    if (data.containsKey('bool_value')) {
      context.handle(
        _boolValueMeta,
        boolValue.isAcceptableOrUnknown(data['bool_value']!, _boolValueMeta),
      );
    }
    if (data.containsKey('int_value')) {
      context.handle(
        _intValueMeta,
        intValue.isAcceptableOrUnknown(data['int_value']!, _intValueMeta),
      );
    }
    if (data.containsKey('double_value')) {
      context.handle(
        _doubleValueMeta,
        doubleValue.isAcceptableOrUnknown(
          data['double_value']!,
          _doubleValueMeta,
        ),
      );
    }
    if (data.containsKey('string_value')) {
      context.handle(
        _stringValueMeta,
        stringValue.isAcceptableOrUnknown(
          data['string_value']!,
          _stringValueMeta,
        ),
      );
    }
    if (data.containsKey('json_value')) {
      context.handle(
        _jsonValueMeta,
        jsonValue.isAcceptableOrUnknown(data['json_value']!, _jsonValueMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      valueType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_type'],
      )!,
      boolValue: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}bool_value'],
      ),
      intValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}int_value'],
      ),
      doubleValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}double_value'],
      ),
      stringValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}string_value'],
      ),
      jsonValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json_value'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String valueType;
  final bool? boolValue;
  final int? intValue;
  final double? doubleValue;
  final String? stringValue;
  final String? jsonValue;
  final DateTime createdAt;
  final DateTime updatedAt;
  const AppSetting({
    required this.key,
    required this.valueType,
    this.boolValue,
    this.intValue,
    this.doubleValue,
    this.stringValue,
    this.jsonValue,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value_type'] = Variable<String>(valueType);
    if (!nullToAbsent || boolValue != null) {
      map['bool_value'] = Variable<bool>(boolValue);
    }
    if (!nullToAbsent || intValue != null) {
      map['int_value'] = Variable<int>(intValue);
    }
    if (!nullToAbsent || doubleValue != null) {
      map['double_value'] = Variable<double>(doubleValue);
    }
    if (!nullToAbsent || stringValue != null) {
      map['string_value'] = Variable<String>(stringValue);
    }
    if (!nullToAbsent || jsonValue != null) {
      map['json_value'] = Variable<String>(jsonValue);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      key: Value(key),
      valueType: Value(valueType),
      boolValue: boolValue == null && nullToAbsent
          ? const Value.absent()
          : Value(boolValue),
      intValue: intValue == null && nullToAbsent
          ? const Value.absent()
          : Value(intValue),
      doubleValue: doubleValue == null && nullToAbsent
          ? const Value.absent()
          : Value(doubleValue),
      stringValue: stringValue == null && nullToAbsent
          ? const Value.absent()
          : Value(stringValue),
      jsonValue: jsonValue == null && nullToAbsent
          ? const Value.absent()
          : Value(jsonValue),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      valueType: serializer.fromJson<String>(json['valueType']),
      boolValue: serializer.fromJson<bool?>(json['boolValue']),
      intValue: serializer.fromJson<int?>(json['intValue']),
      doubleValue: serializer.fromJson<double?>(json['doubleValue']),
      stringValue: serializer.fromJson<String?>(json['stringValue']),
      jsonValue: serializer.fromJson<String?>(json['jsonValue']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'valueType': serializer.toJson<String>(valueType),
      'boolValue': serializer.toJson<bool?>(boolValue),
      'intValue': serializer.toJson<int?>(intValue),
      'doubleValue': serializer.toJson<double?>(doubleValue),
      'stringValue': serializer.toJson<String?>(stringValue),
      'jsonValue': serializer.toJson<String?>(jsonValue),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppSetting copyWith({
    String? key,
    String? valueType,
    Value<bool?> boolValue = const Value.absent(),
    Value<int?> intValue = const Value.absent(),
    Value<double?> doubleValue = const Value.absent(),
    Value<String?> stringValue = const Value.absent(),
    Value<String?> jsonValue = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AppSetting(
    key: key ?? this.key,
    valueType: valueType ?? this.valueType,
    boolValue: boolValue.present ? boolValue.value : this.boolValue,
    intValue: intValue.present ? intValue.value : this.intValue,
    doubleValue: doubleValue.present ? doubleValue.value : this.doubleValue,
    stringValue: stringValue.present ? stringValue.value : this.stringValue,
    jsonValue: jsonValue.present ? jsonValue.value : this.jsonValue,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      valueType: data.valueType.present ? data.valueType.value : this.valueType,
      boolValue: data.boolValue.present ? data.boolValue.value : this.boolValue,
      intValue: data.intValue.present ? data.intValue.value : this.intValue,
      doubleValue: data.doubleValue.present
          ? data.doubleValue.value
          : this.doubleValue,
      stringValue: data.stringValue.present
          ? data.stringValue.value
          : this.stringValue,
      jsonValue: data.jsonValue.present ? data.jsonValue.value : this.jsonValue,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('valueType: $valueType, ')
          ..write('boolValue: $boolValue, ')
          ..write('intValue: $intValue, ')
          ..write('doubleValue: $doubleValue, ')
          ..write('stringValue: $stringValue, ')
          ..write('jsonValue: $jsonValue, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    key,
    valueType,
    boolValue,
    intValue,
    doubleValue,
    stringValue,
    jsonValue,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.valueType == this.valueType &&
          other.boolValue == this.boolValue &&
          other.intValue == this.intValue &&
          other.doubleValue == this.doubleValue &&
          other.stringValue == this.stringValue &&
          other.jsonValue == this.jsonValue &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> valueType;
  final Value<bool?> boolValue;
  final Value<int?> intValue;
  final Value<double?> doubleValue;
  final Value<String?> stringValue;
  final Value<String?> jsonValue;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.valueType = const Value.absent(),
    this.boolValue = const Value.absent(),
    this.intValue = const Value.absent(),
    this.doubleValue = const Value.absent(),
    this.stringValue = const Value.absent(),
    this.jsonValue = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String valueType,
    this.boolValue = const Value.absent(),
    this.intValue = const Value.absent(),
    this.doubleValue = const Value.absent(),
    this.stringValue = const Value.absent(),
    this.jsonValue = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       valueType = Value(valueType),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? valueType,
    Expression<bool>? boolValue,
    Expression<int>? intValue,
    Expression<double>? doubleValue,
    Expression<String>? stringValue,
    Expression<String>? jsonValue,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (valueType != null) 'value_type': valueType,
      if (boolValue != null) 'bool_value': boolValue,
      if (intValue != null) 'int_value': intValue,
      if (doubleValue != null) 'double_value': doubleValue,
      if (stringValue != null) 'string_value': stringValue,
      if (jsonValue != null) 'json_value': jsonValue,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? valueType,
    Value<bool?>? boolValue,
    Value<int?>? intValue,
    Value<double?>? doubleValue,
    Value<String?>? stringValue,
    Value<String?>? jsonValue,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      valueType: valueType ?? this.valueType,
      boolValue: boolValue ?? this.boolValue,
      intValue: intValue ?? this.intValue,
      doubleValue: doubleValue ?? this.doubleValue,
      stringValue: stringValue ?? this.stringValue,
      jsonValue: jsonValue ?? this.jsonValue,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (valueType.present) {
      map['value_type'] = Variable<String>(valueType.value);
    }
    if (boolValue.present) {
      map['bool_value'] = Variable<bool>(boolValue.value);
    }
    if (intValue.present) {
      map['int_value'] = Variable<int>(intValue.value);
    }
    if (doubleValue.present) {
      map['double_value'] = Variable<double>(doubleValue.value);
    }
    if (stringValue.present) {
      map['string_value'] = Variable<String>(stringValue.value);
    }
    if (jsonValue.present) {
      map['json_value'] = Variable<String>(jsonValue.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('valueType: $valueType, ')
          ..write('boolValue: $boolValue, ')
          ..write('intValue: $intValue, ')
          ..write('doubleValue: $doubleValue, ')
          ..write('stringValue: $stringValue, ')
          ..write('jsonValue: $jsonValue, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IntakeSessionsTable extends IntakeSessions
    with TableInfo<$IntakeSessionsTable, IntakeSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IntakeSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _healthEventIdMeta = const VerificationMeta(
    'healthEventId',
  );
  @override
  late final GeneratedColumn<String> healthEventId = GeneratedColumn<String>(
    'health_event_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _eventTimeMeta = const VerificationMeta(
    'eventTime',
  );
  @override
  late final GeneratedColumn<DateTime> eventTime = GeneratedColumn<DateTime>(
    'event_time',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _followUpModeSnapshotMeta =
      const VerificationMeta('followUpModeSnapshot');
  @override
  late final GeneratedColumn<bool> followUpModeSnapshot = GeneratedColumn<bool>(
    'follow_up_mode_snapshot',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("follow_up_mode_snapshot" IN (0, 1))',
    ),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _initialRawTextMeta = const VerificationMeta(
    'initialRawText',
  );
  @override
  late final GeneratedColumn<String> initialRawText = GeneratedColumn<String>(
    'initial_raw_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mergedRawTextMeta = const VerificationMeta(
    'mergedRawText',
  );
  @override
  late final GeneratedColumn<String> mergedRawText = GeneratedColumn<String>(
    'merged_raw_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latestQuestionMeta = const VerificationMeta(
    'latestQuestion',
  );
  @override
  late final GeneratedColumn<String> latestQuestion = GeneratedColumn<String>(
    'latest_question',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _draftSymptomSummaryMeta =
      const VerificationMeta('draftSymptomSummary');
  @override
  late final GeneratedColumn<String> draftSymptomSummary =
      GeneratedColumn<String>(
        'draft_symptom_summary',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _draftNotesMeta = const VerificationMeta(
    'draftNotes',
  );
  @override
  late final GeneratedColumn<String> draftNotes = GeneratedColumn<String>(
    'draft_notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _draftActionAdviceMeta = const VerificationMeta(
    'draftActionAdvice',
  );
  @override
  late final GeneratedColumn<String> draftActionAdvice =
      GeneratedColumn<String>(
        'draft_action_advice',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    healthEventId,
    eventTime,
    followUpModeSnapshot,
    status,
    initialRawText,
    mergedRawText,
    latestQuestion,
    draftSymptomSummary,
    draftNotes,
    draftActionAdvice,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'intake_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<IntakeSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('health_event_id')) {
      context.handle(
        _healthEventIdMeta,
        healthEventId.isAcceptableOrUnknown(
          data['health_event_id']!,
          _healthEventIdMeta,
        ),
      );
    }
    if (data.containsKey('event_time')) {
      context.handle(
        _eventTimeMeta,
        eventTime.isAcceptableOrUnknown(data['event_time']!, _eventTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTimeMeta);
    }
    if (data.containsKey('follow_up_mode_snapshot')) {
      context.handle(
        _followUpModeSnapshotMeta,
        followUpModeSnapshot.isAcceptableOrUnknown(
          data['follow_up_mode_snapshot']!,
          _followUpModeSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_followUpModeSnapshotMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('initial_raw_text')) {
      context.handle(
        _initialRawTextMeta,
        initialRawText.isAcceptableOrUnknown(
          data['initial_raw_text']!,
          _initialRawTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_initialRawTextMeta);
    }
    if (data.containsKey('merged_raw_text')) {
      context.handle(
        _mergedRawTextMeta,
        mergedRawText.isAcceptableOrUnknown(
          data['merged_raw_text']!,
          _mergedRawTextMeta,
        ),
      );
    }
    if (data.containsKey('latest_question')) {
      context.handle(
        _latestQuestionMeta,
        latestQuestion.isAcceptableOrUnknown(
          data['latest_question']!,
          _latestQuestionMeta,
        ),
      );
    }
    if (data.containsKey('draft_symptom_summary')) {
      context.handle(
        _draftSymptomSummaryMeta,
        draftSymptomSummary.isAcceptableOrUnknown(
          data['draft_symptom_summary']!,
          _draftSymptomSummaryMeta,
        ),
      );
    }
    if (data.containsKey('draft_notes')) {
      context.handle(
        _draftNotesMeta,
        draftNotes.isAcceptableOrUnknown(data['draft_notes']!, _draftNotesMeta),
      );
    }
    if (data.containsKey('draft_action_advice')) {
      context.handle(
        _draftActionAdviceMeta,
        draftActionAdvice.isAcceptableOrUnknown(
          data['draft_action_advice']!,
          _draftActionAdviceMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IntakeSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IntakeSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      healthEventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}health_event_id'],
      ),
      eventTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}event_time'],
      )!,
      followUpModeSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}follow_up_mode_snapshot'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      initialRawText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}initial_raw_text'],
      )!,
      mergedRawText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merged_raw_text'],
      ),
      latestQuestion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}latest_question'],
      ),
      draftSymptomSummary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}draft_symptom_summary'],
      ),
      draftNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}draft_notes'],
      ),
      draftActionAdvice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}draft_action_advice'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $IntakeSessionsTable createAlias(String alias) {
    return $IntakeSessionsTable(attachedDatabase, alias);
  }
}

class IntakeSession extends DataClass implements Insertable<IntakeSession> {
  final String id;
  final String? healthEventId;
  final DateTime eventTime;
  final bool followUpModeSnapshot;
  final String status;
  final String initialRawText;
  final String? mergedRawText;
  final String? latestQuestion;
  final String? draftSymptomSummary;
  final String? draftNotes;
  final String? draftActionAdvice;
  final DateTime createdAt;
  final DateTime updatedAt;
  const IntakeSession({
    required this.id,
    this.healthEventId,
    required this.eventTime,
    required this.followUpModeSnapshot,
    required this.status,
    required this.initialRawText,
    this.mergedRawText,
    this.latestQuestion,
    this.draftSymptomSummary,
    this.draftNotes,
    this.draftActionAdvice,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || healthEventId != null) {
      map['health_event_id'] = Variable<String>(healthEventId);
    }
    map['event_time'] = Variable<DateTime>(eventTime);
    map['follow_up_mode_snapshot'] = Variable<bool>(followUpModeSnapshot);
    map['status'] = Variable<String>(status);
    map['initial_raw_text'] = Variable<String>(initialRawText);
    if (!nullToAbsent || mergedRawText != null) {
      map['merged_raw_text'] = Variable<String>(mergedRawText);
    }
    if (!nullToAbsent || latestQuestion != null) {
      map['latest_question'] = Variable<String>(latestQuestion);
    }
    if (!nullToAbsent || draftSymptomSummary != null) {
      map['draft_symptom_summary'] = Variable<String>(draftSymptomSummary);
    }
    if (!nullToAbsent || draftNotes != null) {
      map['draft_notes'] = Variable<String>(draftNotes);
    }
    if (!nullToAbsent || draftActionAdvice != null) {
      map['draft_action_advice'] = Variable<String>(draftActionAdvice);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  IntakeSessionsCompanion toCompanion(bool nullToAbsent) {
    return IntakeSessionsCompanion(
      id: Value(id),
      healthEventId: healthEventId == null && nullToAbsent
          ? const Value.absent()
          : Value(healthEventId),
      eventTime: Value(eventTime),
      followUpModeSnapshot: Value(followUpModeSnapshot),
      status: Value(status),
      initialRawText: Value(initialRawText),
      mergedRawText: mergedRawText == null && nullToAbsent
          ? const Value.absent()
          : Value(mergedRawText),
      latestQuestion: latestQuestion == null && nullToAbsent
          ? const Value.absent()
          : Value(latestQuestion),
      draftSymptomSummary: draftSymptomSummary == null && nullToAbsent
          ? const Value.absent()
          : Value(draftSymptomSummary),
      draftNotes: draftNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(draftNotes),
      draftActionAdvice: draftActionAdvice == null && nullToAbsent
          ? const Value.absent()
          : Value(draftActionAdvice),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory IntakeSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IntakeSession(
      id: serializer.fromJson<String>(json['id']),
      healthEventId: serializer.fromJson<String?>(json['healthEventId']),
      eventTime: serializer.fromJson<DateTime>(json['eventTime']),
      followUpModeSnapshot: serializer.fromJson<bool>(
        json['followUpModeSnapshot'],
      ),
      status: serializer.fromJson<String>(json['status']),
      initialRawText: serializer.fromJson<String>(json['initialRawText']),
      mergedRawText: serializer.fromJson<String?>(json['mergedRawText']),
      latestQuestion: serializer.fromJson<String?>(json['latestQuestion']),
      draftSymptomSummary: serializer.fromJson<String?>(
        json['draftSymptomSummary'],
      ),
      draftNotes: serializer.fromJson<String?>(json['draftNotes']),
      draftActionAdvice: serializer.fromJson<String?>(
        json['draftActionAdvice'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'healthEventId': serializer.toJson<String?>(healthEventId),
      'eventTime': serializer.toJson<DateTime>(eventTime),
      'followUpModeSnapshot': serializer.toJson<bool>(followUpModeSnapshot),
      'status': serializer.toJson<String>(status),
      'initialRawText': serializer.toJson<String>(initialRawText),
      'mergedRawText': serializer.toJson<String?>(mergedRawText),
      'latestQuestion': serializer.toJson<String?>(latestQuestion),
      'draftSymptomSummary': serializer.toJson<String?>(draftSymptomSummary),
      'draftNotes': serializer.toJson<String?>(draftNotes),
      'draftActionAdvice': serializer.toJson<String?>(draftActionAdvice),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  IntakeSession copyWith({
    String? id,
    Value<String?> healthEventId = const Value.absent(),
    DateTime? eventTime,
    bool? followUpModeSnapshot,
    String? status,
    String? initialRawText,
    Value<String?> mergedRawText = const Value.absent(),
    Value<String?> latestQuestion = const Value.absent(),
    Value<String?> draftSymptomSummary = const Value.absent(),
    Value<String?> draftNotes = const Value.absent(),
    Value<String?> draftActionAdvice = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => IntakeSession(
    id: id ?? this.id,
    healthEventId: healthEventId.present
        ? healthEventId.value
        : this.healthEventId,
    eventTime: eventTime ?? this.eventTime,
    followUpModeSnapshot: followUpModeSnapshot ?? this.followUpModeSnapshot,
    status: status ?? this.status,
    initialRawText: initialRawText ?? this.initialRawText,
    mergedRawText: mergedRawText.present
        ? mergedRawText.value
        : this.mergedRawText,
    latestQuestion: latestQuestion.present
        ? latestQuestion.value
        : this.latestQuestion,
    draftSymptomSummary: draftSymptomSummary.present
        ? draftSymptomSummary.value
        : this.draftSymptomSummary,
    draftNotes: draftNotes.present ? draftNotes.value : this.draftNotes,
    draftActionAdvice: draftActionAdvice.present
        ? draftActionAdvice.value
        : this.draftActionAdvice,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  IntakeSession copyWithCompanion(IntakeSessionsCompanion data) {
    return IntakeSession(
      id: data.id.present ? data.id.value : this.id,
      healthEventId: data.healthEventId.present
          ? data.healthEventId.value
          : this.healthEventId,
      eventTime: data.eventTime.present ? data.eventTime.value : this.eventTime,
      followUpModeSnapshot: data.followUpModeSnapshot.present
          ? data.followUpModeSnapshot.value
          : this.followUpModeSnapshot,
      status: data.status.present ? data.status.value : this.status,
      initialRawText: data.initialRawText.present
          ? data.initialRawText.value
          : this.initialRawText,
      mergedRawText: data.mergedRawText.present
          ? data.mergedRawText.value
          : this.mergedRawText,
      latestQuestion: data.latestQuestion.present
          ? data.latestQuestion.value
          : this.latestQuestion,
      draftSymptomSummary: data.draftSymptomSummary.present
          ? data.draftSymptomSummary.value
          : this.draftSymptomSummary,
      draftNotes: data.draftNotes.present
          ? data.draftNotes.value
          : this.draftNotes,
      draftActionAdvice: data.draftActionAdvice.present
          ? data.draftActionAdvice.value
          : this.draftActionAdvice,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IntakeSession(')
          ..write('id: $id, ')
          ..write('healthEventId: $healthEventId, ')
          ..write('eventTime: $eventTime, ')
          ..write('followUpModeSnapshot: $followUpModeSnapshot, ')
          ..write('status: $status, ')
          ..write('initialRawText: $initialRawText, ')
          ..write('mergedRawText: $mergedRawText, ')
          ..write('latestQuestion: $latestQuestion, ')
          ..write('draftSymptomSummary: $draftSymptomSummary, ')
          ..write('draftNotes: $draftNotes, ')
          ..write('draftActionAdvice: $draftActionAdvice, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    healthEventId,
    eventTime,
    followUpModeSnapshot,
    status,
    initialRawText,
    mergedRawText,
    latestQuestion,
    draftSymptomSummary,
    draftNotes,
    draftActionAdvice,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IntakeSession &&
          other.id == this.id &&
          other.healthEventId == this.healthEventId &&
          other.eventTime == this.eventTime &&
          other.followUpModeSnapshot == this.followUpModeSnapshot &&
          other.status == this.status &&
          other.initialRawText == this.initialRawText &&
          other.mergedRawText == this.mergedRawText &&
          other.latestQuestion == this.latestQuestion &&
          other.draftSymptomSummary == this.draftSymptomSummary &&
          other.draftNotes == this.draftNotes &&
          other.draftActionAdvice == this.draftActionAdvice &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class IntakeSessionsCompanion extends UpdateCompanion<IntakeSession> {
  final Value<String> id;
  final Value<String?> healthEventId;
  final Value<DateTime> eventTime;
  final Value<bool> followUpModeSnapshot;
  final Value<String> status;
  final Value<String> initialRawText;
  final Value<String?> mergedRawText;
  final Value<String?> latestQuestion;
  final Value<String?> draftSymptomSummary;
  final Value<String?> draftNotes;
  final Value<String?> draftActionAdvice;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const IntakeSessionsCompanion({
    this.id = const Value.absent(),
    this.healthEventId = const Value.absent(),
    this.eventTime = const Value.absent(),
    this.followUpModeSnapshot = const Value.absent(),
    this.status = const Value.absent(),
    this.initialRawText = const Value.absent(),
    this.mergedRawText = const Value.absent(),
    this.latestQuestion = const Value.absent(),
    this.draftSymptomSummary = const Value.absent(),
    this.draftNotes = const Value.absent(),
    this.draftActionAdvice = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IntakeSessionsCompanion.insert({
    required String id,
    this.healthEventId = const Value.absent(),
    required DateTime eventTime,
    required bool followUpModeSnapshot,
    required String status,
    required String initialRawText,
    this.mergedRawText = const Value.absent(),
    this.latestQuestion = const Value.absent(),
    this.draftSymptomSummary = const Value.absent(),
    this.draftNotes = const Value.absent(),
    this.draftActionAdvice = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       eventTime = Value(eventTime),
       followUpModeSnapshot = Value(followUpModeSnapshot),
       status = Value(status),
       initialRawText = Value(initialRawText),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<IntakeSession> custom({
    Expression<String>? id,
    Expression<String>? healthEventId,
    Expression<DateTime>? eventTime,
    Expression<bool>? followUpModeSnapshot,
    Expression<String>? status,
    Expression<String>? initialRawText,
    Expression<String>? mergedRawText,
    Expression<String>? latestQuestion,
    Expression<String>? draftSymptomSummary,
    Expression<String>? draftNotes,
    Expression<String>? draftActionAdvice,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (healthEventId != null) 'health_event_id': healthEventId,
      if (eventTime != null) 'event_time': eventTime,
      if (followUpModeSnapshot != null)
        'follow_up_mode_snapshot': followUpModeSnapshot,
      if (status != null) 'status': status,
      if (initialRawText != null) 'initial_raw_text': initialRawText,
      if (mergedRawText != null) 'merged_raw_text': mergedRawText,
      if (latestQuestion != null) 'latest_question': latestQuestion,
      if (draftSymptomSummary != null)
        'draft_symptom_summary': draftSymptomSummary,
      if (draftNotes != null) 'draft_notes': draftNotes,
      if (draftActionAdvice != null) 'draft_action_advice': draftActionAdvice,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IntakeSessionsCompanion copyWith({
    Value<String>? id,
    Value<String?>? healthEventId,
    Value<DateTime>? eventTime,
    Value<bool>? followUpModeSnapshot,
    Value<String>? status,
    Value<String>? initialRawText,
    Value<String?>? mergedRawText,
    Value<String?>? latestQuestion,
    Value<String?>? draftSymptomSummary,
    Value<String?>? draftNotes,
    Value<String?>? draftActionAdvice,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return IntakeSessionsCompanion(
      id: id ?? this.id,
      healthEventId: healthEventId ?? this.healthEventId,
      eventTime: eventTime ?? this.eventTime,
      followUpModeSnapshot: followUpModeSnapshot ?? this.followUpModeSnapshot,
      status: status ?? this.status,
      initialRawText: initialRawText ?? this.initialRawText,
      mergedRawText: mergedRawText ?? this.mergedRawText,
      latestQuestion: latestQuestion ?? this.latestQuestion,
      draftSymptomSummary: draftSymptomSummary ?? this.draftSymptomSummary,
      draftNotes: draftNotes ?? this.draftNotes,
      draftActionAdvice: draftActionAdvice ?? this.draftActionAdvice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (healthEventId.present) {
      map['health_event_id'] = Variable<String>(healthEventId.value);
    }
    if (eventTime.present) {
      map['event_time'] = Variable<DateTime>(eventTime.value);
    }
    if (followUpModeSnapshot.present) {
      map['follow_up_mode_snapshot'] = Variable<bool>(
        followUpModeSnapshot.value,
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (initialRawText.present) {
      map['initial_raw_text'] = Variable<String>(initialRawText.value);
    }
    if (mergedRawText.present) {
      map['merged_raw_text'] = Variable<String>(mergedRawText.value);
    }
    if (latestQuestion.present) {
      map['latest_question'] = Variable<String>(latestQuestion.value);
    }
    if (draftSymptomSummary.present) {
      map['draft_symptom_summary'] = Variable<String>(
        draftSymptomSummary.value,
      );
    }
    if (draftNotes.present) {
      map['draft_notes'] = Variable<String>(draftNotes.value);
    }
    if (draftActionAdvice.present) {
      map['draft_action_advice'] = Variable<String>(draftActionAdvice.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IntakeSessionsCompanion(')
          ..write('id: $id, ')
          ..write('healthEventId: $healthEventId, ')
          ..write('eventTime: $eventTime, ')
          ..write('followUpModeSnapshot: $followUpModeSnapshot, ')
          ..write('status: $status, ')
          ..write('initialRawText: $initialRawText, ')
          ..write('mergedRawText: $mergedRawText, ')
          ..write('latestQuestion: $latestQuestion, ')
          ..write('draftSymptomSummary: $draftSymptomSummary, ')
          ..write('draftNotes: $draftNotes, ')
          ..write('draftActionAdvice: $draftActionAdvice, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IntakeMessagesTable extends IntakeMessages
    with TableInfo<$IntakeMessagesTable, IntakeMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IntakeMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES intake_sessions (id)',
    ),
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    seq,
    role,
    content,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'intake_messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<IntakeMessage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {sessionId, seq},
  ];
  @override
  IntakeMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IntakeMessage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $IntakeMessagesTable createAlias(String alias) {
    return $IntakeMessagesTable(attachedDatabase, alias);
  }
}

class IntakeMessage extends DataClass implements Insertable<IntakeMessage> {
  final String id;
  final String sessionId;
  final int seq;
  final String role;
  final String content;
  final DateTime createdAt;
  const IntakeMessage({
    required this.id,
    required this.sessionId,
    required this.seq,
    required this.role,
    required this.content,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['seq'] = Variable<int>(seq);
    map['role'] = Variable<String>(role);
    map['content'] = Variable<String>(content);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  IntakeMessagesCompanion toCompanion(bool nullToAbsent) {
    return IntakeMessagesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      seq: Value(seq),
      role: Value(role),
      content: Value(content),
      createdAt: Value(createdAt),
    );
  }

  factory IntakeMessage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IntakeMessage(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      seq: serializer.fromJson<int>(json['seq']),
      role: serializer.fromJson<String>(json['role']),
      content: serializer.fromJson<String>(json['content']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'seq': serializer.toJson<int>(seq),
      'role': serializer.toJson<String>(role),
      'content': serializer.toJson<String>(content),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  IntakeMessage copyWith({
    String? id,
    String? sessionId,
    int? seq,
    String? role,
    String? content,
    DateTime? createdAt,
  }) => IntakeMessage(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    seq: seq ?? this.seq,
    role: role ?? this.role,
    content: content ?? this.content,
    createdAt: createdAt ?? this.createdAt,
  );
  IntakeMessage copyWithCompanion(IntakeMessagesCompanion data) {
    return IntakeMessage(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      seq: data.seq.present ? data.seq.value : this.seq,
      role: data.role.present ? data.role.value : this.role,
      content: data.content.present ? data.content.value : this.content,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IntakeMessage(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('seq: $seq, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sessionId, seq, role, content, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IntakeMessage &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.seq == this.seq &&
          other.role == this.role &&
          other.content == this.content &&
          other.createdAt == this.createdAt);
}

class IntakeMessagesCompanion extends UpdateCompanion<IntakeMessage> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<int> seq;
  final Value<String> role;
  final Value<String> content;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const IntakeMessagesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.seq = const Value.absent(),
    this.role = const Value.absent(),
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IntakeMessagesCompanion.insert({
    required String id,
    required String sessionId,
    required int seq,
    required String role,
    required String content,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       seq = Value(seq),
       role = Value(role),
       content = Value(content),
       createdAt = Value(createdAt);
  static Insertable<IntakeMessage> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<int>? seq,
    Expression<String>? role,
    Expression<String>? content,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (seq != null) 'seq': seq,
      if (role != null) 'role': role,
      if (content != null) 'content': content,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IntakeMessagesCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<int>? seq,
    Value<String>? role,
    Value<String>? content,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return IntakeMessagesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      seq: seq ?? this.seq,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IntakeMessagesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('seq: $seq, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IntakeSessionAttachmentsTable extends IntakeSessionAttachments
    with TableInfo<$IntakeSessionAttachmentsTable, IntakeSessionAttachment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IntakeSessionAttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES intake_sessions (id)',
    ),
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileTypeMeta = const VerificationMeta(
    'fileType',
  );
  @override
  late final GeneratedColumn<String> fileType = GeneratedColumn<String>(
    'file_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    filePath,
    fileType,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'intake_session_attachments';
  @override
  VerificationContext validateIntegrity(
    Insertable<IntakeSessionAttachment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('file_type')) {
      context.handle(
        _fileTypeMeta,
        fileType.isAcceptableOrUnknown(data['file_type']!, _fileTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_fileTypeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IntakeSessionAttachment map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IntakeSessionAttachment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      fileType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_type'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $IntakeSessionAttachmentsTable createAlias(String alias) {
    return $IntakeSessionAttachmentsTable(attachedDatabase, alias);
  }
}

class IntakeSessionAttachment extends DataClass
    implements Insertable<IntakeSessionAttachment> {
  final String id;
  final String sessionId;
  final String filePath;
  final String fileType;
  final DateTime createdAt;
  const IntakeSessionAttachment({
    required this.id,
    required this.sessionId,
    required this.filePath,
    required this.fileType,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['file_path'] = Variable<String>(filePath);
    map['file_type'] = Variable<String>(fileType);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  IntakeSessionAttachmentsCompanion toCompanion(bool nullToAbsent) {
    return IntakeSessionAttachmentsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      filePath: Value(filePath),
      fileType: Value(fileType),
      createdAt: Value(createdAt),
    );
  }

  factory IntakeSessionAttachment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IntakeSessionAttachment(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      filePath: serializer.fromJson<String>(json['filePath']),
      fileType: serializer.fromJson<String>(json['fileType']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'filePath': serializer.toJson<String>(filePath),
      'fileType': serializer.toJson<String>(fileType),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  IntakeSessionAttachment copyWith({
    String? id,
    String? sessionId,
    String? filePath,
    String? fileType,
    DateTime? createdAt,
  }) => IntakeSessionAttachment(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    filePath: filePath ?? this.filePath,
    fileType: fileType ?? this.fileType,
    createdAt: createdAt ?? this.createdAt,
  );
  IntakeSessionAttachment copyWithCompanion(
    IntakeSessionAttachmentsCompanion data,
  ) {
    return IntakeSessionAttachment(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      fileType: data.fileType.present ? data.fileType.value : this.fileType,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IntakeSessionAttachment(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('filePath: $filePath, ')
          ..write('fileType: $fileType, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sessionId, filePath, fileType, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IntakeSessionAttachment &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.filePath == this.filePath &&
          other.fileType == this.fileType &&
          other.createdAt == this.createdAt);
}

class IntakeSessionAttachmentsCompanion
    extends UpdateCompanion<IntakeSessionAttachment> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String> filePath;
  final Value<String> fileType;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const IntakeSessionAttachmentsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.filePath = const Value.absent(),
    this.fileType = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IntakeSessionAttachmentsCompanion.insert({
    required String id,
    required String sessionId,
    required String filePath,
    required String fileType,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       filePath = Value(filePath),
       fileType = Value(fileType),
       createdAt = Value(createdAt);
  static Insertable<IntakeSessionAttachment> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? filePath,
    Expression<String>? fileType,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (filePath != null) 'file_path': filePath,
      if (fileType != null) 'file_type': fileType,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IntakeSessionAttachmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<String>? filePath,
    Value<String>? fileType,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return IntakeSessionAttachmentsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (fileType.present) {
      map['file_type'] = Variable<String>(fileType.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IntakeSessionAttachmentsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('filePath: $filePath, ')
          ..write('fileType: $fileType, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $HealthEventsTable healthEvents = $HealthEventsTable(this);
  late final $AttachmentsTable attachments = $AttachmentsTable(this);
  late final $ReportsTable reports = $ReportsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $IntakeSessionsTable intakeSessions = $IntakeSessionsTable(this);
  late final $IntakeMessagesTable intakeMessages = $IntakeMessagesTable(this);
  late final $IntakeSessionAttachmentsTable intakeSessionAttachments =
      $IntakeSessionAttachmentsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    healthEvents,
    attachments,
    reports,
    appSettings,
    intakeSessions,
    intakeMessages,
    intakeSessionAttachments,
  ];
}

typedef $$HealthEventsTableCreateCompanionBuilder =
    HealthEventsCompanion Function({
      required String id,
      required String sourceType,
      Value<String> status,
      Value<String?> rawText,
      Value<String?> symptomSummary,
      Value<String?> notes,
      Value<String?> actionAdvice,
      Value<DateTime?> deletedAt,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$HealthEventsTableUpdateCompanionBuilder =
    HealthEventsCompanion Function({
      Value<String> id,
      Value<String> sourceType,
      Value<String> status,
      Value<String?> rawText,
      Value<String?> symptomSummary,
      Value<String?> notes,
      Value<String?> actionAdvice,
      Value<DateTime?> deletedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$HealthEventsTableReferences
    extends BaseReferences<_$AppDatabase, $HealthEventsTable, HealthEvent> {
  $$HealthEventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AttachmentsTable, List<Attachment>>
  _attachmentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.attachments,
    aliasName: $_aliasNameGenerator(
      db.healthEvents.id,
      db.attachments.healthEventId,
    ),
  );

  $$AttachmentsTableProcessedTableManager get attachmentsRefs {
    final manager = $$AttachmentsTableTableManager(
      $_db,
      $_db.attachments,
    ).filter((f) => f.healthEventId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_attachmentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$HealthEventsTableFilterComposer
    extends Composer<_$AppDatabase, $HealthEventsTable> {
  $$HealthEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get symptomSummary => $composableBuilder(
    column: $table.symptomSummary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actionAdvice => $composableBuilder(
    column: $table.actionAdvice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> attachmentsRefs(
    Expression<bool> Function($$AttachmentsTableFilterComposer f) f,
  ) {
    final $$AttachmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attachments,
      getReferencedColumn: (t) => t.healthEventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttachmentsTableFilterComposer(
            $db: $db,
            $table: $db.attachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HealthEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $HealthEventsTable> {
  $$HealthEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get symptomSummary => $composableBuilder(
    column: $table.symptomSummary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actionAdvice => $composableBuilder(
    column: $table.actionAdvice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HealthEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HealthEventsTable> {
  $$HealthEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get rawText =>
      $composableBuilder(column: $table.rawText, builder: (column) => column);

  GeneratedColumn<String> get symptomSummary => $composableBuilder(
    column: $table.symptomSummary,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get actionAdvice => $composableBuilder(
    column: $table.actionAdvice,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> attachmentsRefs<T extends Object>(
    Expression<T> Function($$AttachmentsTableAnnotationComposer a) f,
  ) {
    final $$AttachmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attachments,
      getReferencedColumn: (t) => t.healthEventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttachmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.attachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HealthEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HealthEventsTable,
          HealthEvent,
          $$HealthEventsTableFilterComposer,
          $$HealthEventsTableOrderingComposer,
          $$HealthEventsTableAnnotationComposer,
          $$HealthEventsTableCreateCompanionBuilder,
          $$HealthEventsTableUpdateCompanionBuilder,
          (HealthEvent, $$HealthEventsTableReferences),
          HealthEvent,
          PrefetchHooks Function({bool attachmentsRefs})
        > {
  $$HealthEventsTableTableManager(_$AppDatabase db, $HealthEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HealthEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HealthEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HealthEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> rawText = const Value.absent(),
                Value<String?> symptomSummary = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> actionAdvice = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HealthEventsCompanion(
                id: id,
                sourceType: sourceType,
                status: status,
                rawText: rawText,
                symptomSummary: symptomSummary,
                notes: notes,
                actionAdvice: actionAdvice,
                deletedAt: deletedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sourceType,
                Value<String> status = const Value.absent(),
                Value<String?> rawText = const Value.absent(),
                Value<String?> symptomSummary = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> actionAdvice = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => HealthEventsCompanion.insert(
                id: id,
                sourceType: sourceType,
                status: status,
                rawText: rawText,
                symptomSummary: symptomSummary,
                notes: notes,
                actionAdvice: actionAdvice,
                deletedAt: deletedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$HealthEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({attachmentsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (attachmentsRefs) db.attachments],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (attachmentsRefs)
                    await $_getPrefetchedData<
                      HealthEvent,
                      $HealthEventsTable,
                      Attachment
                    >(
                      currentTable: table,
                      referencedTable: $$HealthEventsTableReferences
                          ._attachmentsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$HealthEventsTableReferences(
                            db,
                            table,
                            p0,
                          ).attachmentsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.healthEventId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$HealthEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HealthEventsTable,
      HealthEvent,
      $$HealthEventsTableFilterComposer,
      $$HealthEventsTableOrderingComposer,
      $$HealthEventsTableAnnotationComposer,
      $$HealthEventsTableCreateCompanionBuilder,
      $$HealthEventsTableUpdateCompanionBuilder,
      (HealthEvent, $$HealthEventsTableReferences),
      HealthEvent,
      PrefetchHooks Function({bool attachmentsRefs})
    >;
typedef $$AttachmentsTableCreateCompanionBuilder =
    AttachmentsCompanion Function({
      required String id,
      required String healthEventId,
      required String filePath,
      required String fileType,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$AttachmentsTableUpdateCompanionBuilder =
    AttachmentsCompanion Function({
      Value<String> id,
      Value<String> healthEventId,
      Value<String> filePath,
      Value<String> fileType,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$AttachmentsTableReferences
    extends BaseReferences<_$AppDatabase, $AttachmentsTable, Attachment> {
  $$AttachmentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $HealthEventsTable _healthEventIdTable(_$AppDatabase db) =>
      db.healthEvents.createAlias(
        $_aliasNameGenerator(db.attachments.healthEventId, db.healthEvents.id),
      );

  $$HealthEventsTableProcessedTableManager get healthEventId {
    final $_column = $_itemColumn<String>('health_event_id')!;

    final manager = $$HealthEventsTableTableManager(
      $_db,
      $_db.healthEvents,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_healthEventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AttachmentsTableFilterComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileType => $composableBuilder(
    column: $table.fileType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$HealthEventsTableFilterComposer get healthEventId {
    final $$HealthEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.healthEventId,
      referencedTable: $db.healthEvents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HealthEventsTableFilterComposer(
            $db: $db,
            $table: $db.healthEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttachmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileType => $composableBuilder(
    column: $table.fileType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$HealthEventsTableOrderingComposer get healthEventId {
    final $$HealthEventsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.healthEventId,
      referencedTable: $db.healthEvents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HealthEventsTableOrderingComposer(
            $db: $db,
            $table: $db.healthEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttachmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get fileType =>
      $composableBuilder(column: $table.fileType, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$HealthEventsTableAnnotationComposer get healthEventId {
    final $$HealthEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.healthEventId,
      referencedTable: $db.healthEvents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HealthEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.healthEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttachmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttachmentsTable,
          Attachment,
          $$AttachmentsTableFilterComposer,
          $$AttachmentsTableOrderingComposer,
          $$AttachmentsTableAnnotationComposer,
          $$AttachmentsTableCreateCompanionBuilder,
          $$AttachmentsTableUpdateCompanionBuilder,
          (Attachment, $$AttachmentsTableReferences),
          Attachment,
          PrefetchHooks Function({bool healthEventId})
        > {
  $$AttachmentsTableTableManager(_$AppDatabase db, $AttachmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttachmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttachmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttachmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> healthEventId = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<String> fileType = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttachmentsCompanion(
                id: id,
                healthEventId: healthEventId,
                filePath: filePath,
                fileType: fileType,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String healthEventId,
                required String filePath,
                required String fileType,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => AttachmentsCompanion.insert(
                id: id,
                healthEventId: healthEventId,
                filePath: filePath,
                fileType: fileType,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AttachmentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({healthEventId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (healthEventId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.healthEventId,
                                referencedTable: $$AttachmentsTableReferences
                                    ._healthEventIdTable(db),
                                referencedColumn: $$AttachmentsTableReferences
                                    ._healthEventIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AttachmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttachmentsTable,
      Attachment,
      $$AttachmentsTableFilterComposer,
      $$AttachmentsTableOrderingComposer,
      $$AttachmentsTableAnnotationComposer,
      $$AttachmentsTableCreateCompanionBuilder,
      $$AttachmentsTableUpdateCompanionBuilder,
      (Attachment, $$AttachmentsTableReferences),
      Attachment,
      PrefetchHooks Function({bool healthEventId})
    >;
typedef $$ReportsTableCreateCompanionBuilder =
    ReportsCompanion Function({
      required String id,
      required String reportType,
      required DateTime rangeStart,
      required DateTime rangeEnd,
      required String title,
      required String summary,
      required String adviceJson,
      required String markdown,
      required DateTime generatedAt,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$ReportsTableUpdateCompanionBuilder =
    ReportsCompanion Function({
      Value<String> id,
      Value<String> reportType,
      Value<DateTime> rangeStart,
      Value<DateTime> rangeEnd,
      Value<String> title,
      Value<String> summary,
      Value<String> adviceJson,
      Value<String> markdown,
      Value<DateTime> generatedAt,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$ReportsTableFilterComposer
    extends Composer<_$AppDatabase, $ReportsTable> {
  $$ReportsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reportType => $composableBuilder(
    column: $table.reportType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get rangeStart => $composableBuilder(
    column: $table.rangeStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get rangeEnd => $composableBuilder(
    column: $table.rangeEnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get adviceJson => $composableBuilder(
    column: $table.adviceJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get markdown => $composableBuilder(
    column: $table.markdown,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get generatedAt => $composableBuilder(
    column: $table.generatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReportsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReportsTable> {
  $$ReportsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reportType => $composableBuilder(
    column: $table.reportType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get rangeStart => $composableBuilder(
    column: $table.rangeStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get rangeEnd => $composableBuilder(
    column: $table.rangeEnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get adviceJson => $composableBuilder(
    column: $table.adviceJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get markdown => $composableBuilder(
    column: $table.markdown,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get generatedAt => $composableBuilder(
    column: $table.generatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReportsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReportsTable> {
  $$ReportsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get reportType => $composableBuilder(
    column: $table.reportType,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get rangeStart => $composableBuilder(
    column: $table.rangeStart,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get rangeEnd =>
      $composableBuilder(column: $table.rangeEnd, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get adviceJson => $composableBuilder(
    column: $table.adviceJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get markdown =>
      $composableBuilder(column: $table.markdown, builder: (column) => column);

  GeneratedColumn<DateTime> get generatedAt => $composableBuilder(
    column: $table.generatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ReportsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReportsTable,
          Report,
          $$ReportsTableFilterComposer,
          $$ReportsTableOrderingComposer,
          $$ReportsTableAnnotationComposer,
          $$ReportsTableCreateCompanionBuilder,
          $$ReportsTableUpdateCompanionBuilder,
          (Report, BaseReferences<_$AppDatabase, $ReportsTable, Report>),
          Report,
          PrefetchHooks Function()
        > {
  $$ReportsTableTableManager(_$AppDatabase db, $ReportsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReportsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReportsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReportsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> reportType = const Value.absent(),
                Value<DateTime> rangeStart = const Value.absent(),
                Value<DateTime> rangeEnd = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> summary = const Value.absent(),
                Value<String> adviceJson = const Value.absent(),
                Value<String> markdown = const Value.absent(),
                Value<DateTime> generatedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReportsCompanion(
                id: id,
                reportType: reportType,
                rangeStart: rangeStart,
                rangeEnd: rangeEnd,
                title: title,
                summary: summary,
                adviceJson: adviceJson,
                markdown: markdown,
                generatedAt: generatedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String reportType,
                required DateTime rangeStart,
                required DateTime rangeEnd,
                required String title,
                required String summary,
                required String adviceJson,
                required String markdown,
                required DateTime generatedAt,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ReportsCompanion.insert(
                id: id,
                reportType: reportType,
                rangeStart: rangeStart,
                rangeEnd: rangeEnd,
                title: title,
                summary: summary,
                adviceJson: adviceJson,
                markdown: markdown,
                generatedAt: generatedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReportsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReportsTable,
      Report,
      $$ReportsTableFilterComposer,
      $$ReportsTableOrderingComposer,
      $$ReportsTableAnnotationComposer,
      $$ReportsTableCreateCompanionBuilder,
      $$ReportsTableUpdateCompanionBuilder,
      (Report, BaseReferences<_$AppDatabase, $ReportsTable, Report>),
      Report,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String valueType,
      Value<bool?> boolValue,
      Value<int?> intValue,
      Value<double?> doubleValue,
      Value<String?> stringValue,
      Value<String?> jsonValue,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> valueType,
      Value<bool?> boolValue,
      Value<int?> intValue,
      Value<double?> doubleValue,
      Value<String?> stringValue,
      Value<String?> jsonValue,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valueType => $composableBuilder(
    column: $table.valueType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get boolValue => $composableBuilder(
    column: $table.boolValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intValue => $composableBuilder(
    column: $table.intValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get doubleValue => $composableBuilder(
    column: $table.doubleValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stringValue => $composableBuilder(
    column: $table.stringValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jsonValue => $composableBuilder(
    column: $table.jsonValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valueType => $composableBuilder(
    column: $table.valueType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get boolValue => $composableBuilder(
    column: $table.boolValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intValue => $composableBuilder(
    column: $table.intValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get doubleValue => $composableBuilder(
    column: $table.doubleValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stringValue => $composableBuilder(
    column: $table.stringValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jsonValue => $composableBuilder(
    column: $table.jsonValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get valueType =>
      $composableBuilder(column: $table.valueType, builder: (column) => column);

  GeneratedColumn<bool> get boolValue =>
      $composableBuilder(column: $table.boolValue, builder: (column) => column);

  GeneratedColumn<int> get intValue =>
      $composableBuilder(column: $table.intValue, builder: (column) => column);

  GeneratedColumn<double> get doubleValue => $composableBuilder(
    column: $table.doubleValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get stringValue => $composableBuilder(
    column: $table.stringValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get jsonValue =>
      $composableBuilder(column: $table.jsonValue, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> valueType = const Value.absent(),
                Value<bool?> boolValue = const Value.absent(),
                Value<int?> intValue = const Value.absent(),
                Value<double?> doubleValue = const Value.absent(),
                Value<String?> stringValue = const Value.absent(),
                Value<String?> jsonValue = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(
                key: key,
                valueType: valueType,
                boolValue: boolValue,
                intValue: intValue,
                doubleValue: doubleValue,
                stringValue: stringValue,
                jsonValue: jsonValue,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String valueType,
                Value<bool?> boolValue = const Value.absent(),
                Value<int?> intValue = const Value.absent(),
                Value<double?> doubleValue = const Value.absent(),
                Value<String?> stringValue = const Value.absent(),
                Value<String?> jsonValue = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                valueType: valueType,
                boolValue: boolValue,
                intValue: intValue,
                doubleValue: doubleValue,
                stringValue: stringValue,
                jsonValue: jsonValue,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $$IntakeSessionsTableCreateCompanionBuilder =
    IntakeSessionsCompanion Function({
      required String id,
      Value<String?> healthEventId,
      required DateTime eventTime,
      required bool followUpModeSnapshot,
      required String status,
      required String initialRawText,
      Value<String?> mergedRawText,
      Value<String?> latestQuestion,
      Value<String?> draftSymptomSummary,
      Value<String?> draftNotes,
      Value<String?> draftActionAdvice,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$IntakeSessionsTableUpdateCompanionBuilder =
    IntakeSessionsCompanion Function({
      Value<String> id,
      Value<String?> healthEventId,
      Value<DateTime> eventTime,
      Value<bool> followUpModeSnapshot,
      Value<String> status,
      Value<String> initialRawText,
      Value<String?> mergedRawText,
      Value<String?> latestQuestion,
      Value<String?> draftSymptomSummary,
      Value<String?> draftNotes,
      Value<String?> draftActionAdvice,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$IntakeSessionsTableReferences
    extends BaseReferences<_$AppDatabase, $IntakeSessionsTable, IntakeSession> {
  $$IntakeSessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$IntakeMessagesTable, List<IntakeMessage>>
  _intakeMessagesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.intakeMessages,
    aliasName: $_aliasNameGenerator(
      db.intakeSessions.id,
      db.intakeMessages.sessionId,
    ),
  );

  $$IntakeMessagesTableProcessedTableManager get intakeMessagesRefs {
    final manager = $$IntakeMessagesTableTableManager(
      $_db,
      $_db.intakeMessages,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_intakeMessagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $IntakeSessionAttachmentsTable,
    List<IntakeSessionAttachment>
  >
  _intakeSessionAttachmentsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.intakeSessionAttachments,
        aliasName: $_aliasNameGenerator(
          db.intakeSessions.id,
          db.intakeSessionAttachments.sessionId,
        ),
      );

  $$IntakeSessionAttachmentsTableProcessedTableManager
  get intakeSessionAttachmentsRefs {
    final manager = $$IntakeSessionAttachmentsTableTableManager(
      $_db,
      $_db.intakeSessionAttachments,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _intakeSessionAttachmentsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$IntakeSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $IntakeSessionsTable> {
  $$IntakeSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get healthEventId => $composableBuilder(
    column: $table.healthEventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get eventTime => $composableBuilder(
    column: $table.eventTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get followUpModeSnapshot => $composableBuilder(
    column: $table.followUpModeSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get initialRawText => $composableBuilder(
    column: $table.initialRawText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mergedRawText => $composableBuilder(
    column: $table.mergedRawText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get latestQuestion => $composableBuilder(
    column: $table.latestQuestion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get draftSymptomSummary => $composableBuilder(
    column: $table.draftSymptomSummary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get draftNotes => $composableBuilder(
    column: $table.draftNotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get draftActionAdvice => $composableBuilder(
    column: $table.draftActionAdvice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> intakeMessagesRefs(
    Expression<bool> Function($$IntakeMessagesTableFilterComposer f) f,
  ) {
    final $$IntakeMessagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.intakeMessages,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IntakeMessagesTableFilterComposer(
            $db: $db,
            $table: $db.intakeMessages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> intakeSessionAttachmentsRefs(
    Expression<bool> Function($$IntakeSessionAttachmentsTableFilterComposer f)
    f,
  ) {
    final $$IntakeSessionAttachmentsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.intakeSessionAttachments,
          getReferencedColumn: (t) => t.sessionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$IntakeSessionAttachmentsTableFilterComposer(
                $db: $db,
                $table: $db.intakeSessionAttachments,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$IntakeSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $IntakeSessionsTable> {
  $$IntakeSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get healthEventId => $composableBuilder(
    column: $table.healthEventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get eventTime => $composableBuilder(
    column: $table.eventTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get followUpModeSnapshot => $composableBuilder(
    column: $table.followUpModeSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get initialRawText => $composableBuilder(
    column: $table.initialRawText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mergedRawText => $composableBuilder(
    column: $table.mergedRawText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get latestQuestion => $composableBuilder(
    column: $table.latestQuestion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get draftSymptomSummary => $composableBuilder(
    column: $table.draftSymptomSummary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get draftNotes => $composableBuilder(
    column: $table.draftNotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get draftActionAdvice => $composableBuilder(
    column: $table.draftActionAdvice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IntakeSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $IntakeSessionsTable> {
  $$IntakeSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get healthEventId => $composableBuilder(
    column: $table.healthEventId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get eventTime =>
      $composableBuilder(column: $table.eventTime, builder: (column) => column);

  GeneratedColumn<bool> get followUpModeSnapshot => $composableBuilder(
    column: $table.followUpModeSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get initialRawText => $composableBuilder(
    column: $table.initialRawText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mergedRawText => $composableBuilder(
    column: $table.mergedRawText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get latestQuestion => $composableBuilder(
    column: $table.latestQuestion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get draftSymptomSummary => $composableBuilder(
    column: $table.draftSymptomSummary,
    builder: (column) => column,
  );

  GeneratedColumn<String> get draftNotes => $composableBuilder(
    column: $table.draftNotes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get draftActionAdvice => $composableBuilder(
    column: $table.draftActionAdvice,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> intakeMessagesRefs<T extends Object>(
    Expression<T> Function($$IntakeMessagesTableAnnotationComposer a) f,
  ) {
    final $$IntakeMessagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.intakeMessages,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IntakeMessagesTableAnnotationComposer(
            $db: $db,
            $table: $db.intakeMessages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> intakeSessionAttachmentsRefs<T extends Object>(
    Expression<T> Function($$IntakeSessionAttachmentsTableAnnotationComposer a)
    f,
  ) {
    final $$IntakeSessionAttachmentsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.intakeSessionAttachments,
          getReferencedColumn: (t) => t.sessionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$IntakeSessionAttachmentsTableAnnotationComposer(
                $db: $db,
                $table: $db.intakeSessionAttachments,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$IntakeSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IntakeSessionsTable,
          IntakeSession,
          $$IntakeSessionsTableFilterComposer,
          $$IntakeSessionsTableOrderingComposer,
          $$IntakeSessionsTableAnnotationComposer,
          $$IntakeSessionsTableCreateCompanionBuilder,
          $$IntakeSessionsTableUpdateCompanionBuilder,
          (IntakeSession, $$IntakeSessionsTableReferences),
          IntakeSession,
          PrefetchHooks Function({
            bool intakeMessagesRefs,
            bool intakeSessionAttachmentsRefs,
          })
        > {
  $$IntakeSessionsTableTableManager(
    _$AppDatabase db,
    $IntakeSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IntakeSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IntakeSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IntakeSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> healthEventId = const Value.absent(),
                Value<DateTime> eventTime = const Value.absent(),
                Value<bool> followUpModeSnapshot = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> initialRawText = const Value.absent(),
                Value<String?> mergedRawText = const Value.absent(),
                Value<String?> latestQuestion = const Value.absent(),
                Value<String?> draftSymptomSummary = const Value.absent(),
                Value<String?> draftNotes = const Value.absent(),
                Value<String?> draftActionAdvice = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IntakeSessionsCompanion(
                id: id,
                healthEventId: healthEventId,
                eventTime: eventTime,
                followUpModeSnapshot: followUpModeSnapshot,
                status: status,
                initialRawText: initialRawText,
                mergedRawText: mergedRawText,
                latestQuestion: latestQuestion,
                draftSymptomSummary: draftSymptomSummary,
                draftNotes: draftNotes,
                draftActionAdvice: draftActionAdvice,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> healthEventId = const Value.absent(),
                required DateTime eventTime,
                required bool followUpModeSnapshot,
                required String status,
                required String initialRawText,
                Value<String?> mergedRawText = const Value.absent(),
                Value<String?> latestQuestion = const Value.absent(),
                Value<String?> draftSymptomSummary = const Value.absent(),
                Value<String?> draftNotes = const Value.absent(),
                Value<String?> draftActionAdvice = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => IntakeSessionsCompanion.insert(
                id: id,
                healthEventId: healthEventId,
                eventTime: eventTime,
                followUpModeSnapshot: followUpModeSnapshot,
                status: status,
                initialRawText: initialRawText,
                mergedRawText: mergedRawText,
                latestQuestion: latestQuestion,
                draftSymptomSummary: draftSymptomSummary,
                draftNotes: draftNotes,
                draftActionAdvice: draftActionAdvice,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$IntakeSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                intakeMessagesRefs = false,
                intakeSessionAttachmentsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (intakeMessagesRefs) db.intakeMessages,
                    if (intakeSessionAttachmentsRefs)
                      db.intakeSessionAttachments,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (intakeMessagesRefs)
                        await $_getPrefetchedData<
                          IntakeSession,
                          $IntakeSessionsTable,
                          IntakeMessage
                        >(
                          currentTable: table,
                          referencedTable: $$IntakeSessionsTableReferences
                              ._intakeMessagesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$IntakeSessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).intakeMessagesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (intakeSessionAttachmentsRefs)
                        await $_getPrefetchedData<
                          IntakeSession,
                          $IntakeSessionsTable,
                          IntakeSessionAttachment
                        >(
                          currentTable: table,
                          referencedTable: $$IntakeSessionsTableReferences
                              ._intakeSessionAttachmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$IntakeSessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).intakeSessionAttachmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$IntakeSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IntakeSessionsTable,
      IntakeSession,
      $$IntakeSessionsTableFilterComposer,
      $$IntakeSessionsTableOrderingComposer,
      $$IntakeSessionsTableAnnotationComposer,
      $$IntakeSessionsTableCreateCompanionBuilder,
      $$IntakeSessionsTableUpdateCompanionBuilder,
      (IntakeSession, $$IntakeSessionsTableReferences),
      IntakeSession,
      PrefetchHooks Function({
        bool intakeMessagesRefs,
        bool intakeSessionAttachmentsRefs,
      })
    >;
typedef $$IntakeMessagesTableCreateCompanionBuilder =
    IntakeMessagesCompanion Function({
      required String id,
      required String sessionId,
      required int seq,
      required String role,
      required String content,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$IntakeMessagesTableUpdateCompanionBuilder =
    IntakeMessagesCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<int> seq,
      Value<String> role,
      Value<String> content,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$IntakeMessagesTableReferences
    extends BaseReferences<_$AppDatabase, $IntakeMessagesTable, IntakeMessage> {
  $$IntakeMessagesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $IntakeSessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.intakeSessions.createAlias(
        $_aliasNameGenerator(db.intakeMessages.sessionId, db.intakeSessions.id),
      );

  $$IntakeSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$IntakeSessionsTableTableManager(
      $_db,
      $_db.intakeSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$IntakeMessagesTableFilterComposer
    extends Composer<_$AppDatabase, $IntakeMessagesTable> {
  $$IntakeMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$IntakeSessionsTableFilterComposer get sessionId {
    final $$IntakeSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.intakeSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IntakeSessionsTableFilterComposer(
            $db: $db,
            $table: $db.intakeSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IntakeMessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $IntakeMessagesTable> {
  $$IntakeMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$IntakeSessionsTableOrderingComposer get sessionId {
    final $$IntakeSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.intakeSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IntakeSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.intakeSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IntakeMessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $IntakeMessagesTable> {
  $$IntakeMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$IntakeSessionsTableAnnotationComposer get sessionId {
    final $$IntakeSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.intakeSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IntakeSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.intakeSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IntakeMessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IntakeMessagesTable,
          IntakeMessage,
          $$IntakeMessagesTableFilterComposer,
          $$IntakeMessagesTableOrderingComposer,
          $$IntakeMessagesTableAnnotationComposer,
          $$IntakeMessagesTableCreateCompanionBuilder,
          $$IntakeMessagesTableUpdateCompanionBuilder,
          (IntakeMessage, $$IntakeMessagesTableReferences),
          IntakeMessage,
          PrefetchHooks Function({bool sessionId})
        > {
  $$IntakeMessagesTableTableManager(
    _$AppDatabase db,
    $IntakeMessagesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IntakeMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IntakeMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IntakeMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IntakeMessagesCompanion(
                id: id,
                sessionId: sessionId,
                seq: seq,
                role: role,
                content: content,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required int seq,
                required String role,
                required String content,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => IntakeMessagesCompanion.insert(
                id: id,
                sessionId: sessionId,
                seq: seq,
                role: role,
                content: content,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$IntakeMessagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sessionId,
                                referencedTable: $$IntakeMessagesTableReferences
                                    ._sessionIdTable(db),
                                referencedColumn:
                                    $$IntakeMessagesTableReferences
                                        ._sessionIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$IntakeMessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IntakeMessagesTable,
      IntakeMessage,
      $$IntakeMessagesTableFilterComposer,
      $$IntakeMessagesTableOrderingComposer,
      $$IntakeMessagesTableAnnotationComposer,
      $$IntakeMessagesTableCreateCompanionBuilder,
      $$IntakeMessagesTableUpdateCompanionBuilder,
      (IntakeMessage, $$IntakeMessagesTableReferences),
      IntakeMessage,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$IntakeSessionAttachmentsTableCreateCompanionBuilder =
    IntakeSessionAttachmentsCompanion Function({
      required String id,
      required String sessionId,
      required String filePath,
      required String fileType,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$IntakeSessionAttachmentsTableUpdateCompanionBuilder =
    IntakeSessionAttachmentsCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<String> filePath,
      Value<String> fileType,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$IntakeSessionAttachmentsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $IntakeSessionAttachmentsTable,
          IntakeSessionAttachment
        > {
  $$IntakeSessionAttachmentsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $IntakeSessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.intakeSessions.createAlias(
        $_aliasNameGenerator(
          db.intakeSessionAttachments.sessionId,
          db.intakeSessions.id,
        ),
      );

  $$IntakeSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$IntakeSessionsTableTableManager(
      $_db,
      $_db.intakeSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$IntakeSessionAttachmentsTableFilterComposer
    extends Composer<_$AppDatabase, $IntakeSessionAttachmentsTable> {
  $$IntakeSessionAttachmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileType => $composableBuilder(
    column: $table.fileType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$IntakeSessionsTableFilterComposer get sessionId {
    final $$IntakeSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.intakeSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IntakeSessionsTableFilterComposer(
            $db: $db,
            $table: $db.intakeSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IntakeSessionAttachmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $IntakeSessionAttachmentsTable> {
  $$IntakeSessionAttachmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileType => $composableBuilder(
    column: $table.fileType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$IntakeSessionsTableOrderingComposer get sessionId {
    final $$IntakeSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.intakeSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IntakeSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.intakeSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IntakeSessionAttachmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $IntakeSessionAttachmentsTable> {
  $$IntakeSessionAttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get fileType =>
      $composableBuilder(column: $table.fileType, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$IntakeSessionsTableAnnotationComposer get sessionId {
    final $$IntakeSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.intakeSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IntakeSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.intakeSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IntakeSessionAttachmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IntakeSessionAttachmentsTable,
          IntakeSessionAttachment,
          $$IntakeSessionAttachmentsTableFilterComposer,
          $$IntakeSessionAttachmentsTableOrderingComposer,
          $$IntakeSessionAttachmentsTableAnnotationComposer,
          $$IntakeSessionAttachmentsTableCreateCompanionBuilder,
          $$IntakeSessionAttachmentsTableUpdateCompanionBuilder,
          (IntakeSessionAttachment, $$IntakeSessionAttachmentsTableReferences),
          IntakeSessionAttachment,
          PrefetchHooks Function({bool sessionId})
        > {
  $$IntakeSessionAttachmentsTableTableManager(
    _$AppDatabase db,
    $IntakeSessionAttachmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IntakeSessionAttachmentsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$IntakeSessionAttachmentsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$IntakeSessionAttachmentsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<String> fileType = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IntakeSessionAttachmentsCompanion(
                id: id,
                sessionId: sessionId,
                filePath: filePath,
                fileType: fileType,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required String filePath,
                required String fileType,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => IntakeSessionAttachmentsCompanion.insert(
                id: id,
                sessionId: sessionId,
                filePath: filePath,
                fileType: fileType,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$IntakeSessionAttachmentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sessionId,
                                referencedTable:
                                    $$IntakeSessionAttachmentsTableReferences
                                        ._sessionIdTable(db),
                                referencedColumn:
                                    $$IntakeSessionAttachmentsTableReferences
                                        ._sessionIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$IntakeSessionAttachmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IntakeSessionAttachmentsTable,
      IntakeSessionAttachment,
      $$IntakeSessionAttachmentsTableFilterComposer,
      $$IntakeSessionAttachmentsTableOrderingComposer,
      $$IntakeSessionAttachmentsTableAnnotationComposer,
      $$IntakeSessionAttachmentsTableCreateCompanionBuilder,
      $$IntakeSessionAttachmentsTableUpdateCompanionBuilder,
      (IntakeSessionAttachment, $$IntakeSessionAttachmentsTableReferences),
      IntakeSessionAttachment,
      PrefetchHooks Function({bool sessionId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$HealthEventsTableTableManager get healthEvents =>
      $$HealthEventsTableTableManager(_db, _db.healthEvents);
  $$AttachmentsTableTableManager get attachments =>
      $$AttachmentsTableTableManager(_db, _db.attachments);
  $$ReportsTableTableManager get reports =>
      $$ReportsTableTableManager(_db, _db.reports);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$IntakeSessionsTableTableManager get intakeSessions =>
      $$IntakeSessionsTableTableManager(_db, _db.intakeSessions);
  $$IntakeMessagesTableTableManager get intakeMessages =>
      $$IntakeMessagesTableTableManager(_db, _db.intakeMessages);
  $$IntakeSessionAttachmentsTableTableManager get intakeSessionAttachments =>
      $$IntakeSessionAttachmentsTableTableManager(
        _db,
        _db.intakeSessionAttachments,
      );
}
