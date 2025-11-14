// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'translation_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TranslationRecordAdapter extends TypeAdapter<_$TranslationRecordImpl> {
  @override
  final int typeId = 2;

  @override
  _$TranslationRecordImpl read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return _$TranslationRecordImpl(
      id: fields[0] as String,
      sourceText: fields[1] as String,
      translatedText: fields[2] as String,
      sourceLang: fields[3] as String,
      targetLang: fields[4] as String,
      createdAt: fields[5] as DateTime,
      userId: fields[6] as String,
      isFavorite: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, _$TranslationRecordImpl obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.sourceText)
      ..writeByte(2)
      ..write(obj.translatedText)
      ..writeByte(3)
      ..write(obj.sourceLang)
      ..writeByte(4)
      ..write(obj.targetLang)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.userId)
      ..writeByte(7)
      ..write(obj.isFavorite);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TranslationRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TranslationRecordImpl _$$TranslationRecordImplFromJson(
        Map<String, dynamic> json) =>
    _$TranslationRecordImpl(
      id: json['id'] as String,
      sourceText: json['sourceText'] as String,
      translatedText: json['translatedText'] as String,
      sourceLang: json['sourceLang'] as String,
      targetLang: json['targetLang'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      userId: json['userId'] as String,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );

Map<String, dynamic> _$$TranslationRecordImplToJson(
        _$TranslationRecordImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sourceText': instance.sourceText,
      'translatedText': instance.translatedText,
      'sourceLang': instance.sourceLang,
      'targetLang': instance.targetLang,
      'createdAt': instance.createdAt.toIso8601String(),
      'userId': instance.userId,
      'isFavorite': instance.isFavorite,
    };
