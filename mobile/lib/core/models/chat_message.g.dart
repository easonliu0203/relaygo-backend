// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChatMessageImpl _$$ChatMessageImplFromJson(Map<String, dynamic> json) =>
    _$ChatMessageImpl(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String,
      senderName: json['senderName'] as String?,
      receiverName: json['receiverName'] as String?,
      messageText: json['messageText'] as String,
      translatedText: json['translatedText'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      readAt: json['readAt'] == null
          ? null
          : DateTime.parse(json['readAt'] as String),
      detectedLang: json['detectedLang'] as String? ?? 'zh-TW',
      translations: json['translations'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$$ChatMessageImplToJson(_$ChatMessageImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'senderId': instance.senderId,
      'receiverId': instance.receiverId,
      'senderName': instance.senderName,
      'receiverName': instance.receiverName,
      'messageText': instance.messageText,
      'translatedText': instance.translatedText,
      'createdAt': instance.createdAt.toIso8601String(),
      'readAt': instance.readAt?.toIso8601String(),
      'detectedLang': instance.detectedLang,
      'translations': instance.translations,
    };
