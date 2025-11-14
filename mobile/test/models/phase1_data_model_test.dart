import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ride_booking_app/core/models/user_profile.dart';
import 'package:ride_booking_app/core/models/chat_room.dart';
import 'package:ride_booking_app/core/models/chat_message.dart';

void main() {
  group('Phase 1: Data Model Tests - UserProfile', () {
    test('UserProfile should have default language preferences', () {
      final now = DateTime.now();
      final user = UserProfile(
        id: 'test-id',
        userId: 'test-user-id',
        createdAt: now,
        updatedAt: now,
      );

      expect(user.preferredLang, 'zh-TW');
      expect(user.inputLangHint, 'zh-TW');
      expect(user.hasCompletedLanguageWizard, false);
    });

    test('UserProfile should accept custom language preferences', () {
      final now = DateTime.now();
      final user = UserProfile(
        id: 'test-id',
        userId: 'test-user-id',
        preferredLang: 'en',
        inputLangHint: 'ja',
        hasCompletedLanguageWizard: true,
        createdAt: now,
        updatedAt: now,
      );

      expect(user.preferredLang, 'en');
      expect(user.inputLangHint, 'ja');
      expect(user.hasCompletedLanguageWizard, true);
    });

    test('UserProfile should serialize to JSON correctly', () {
      final now = DateTime.now();
      final user = UserProfile(
        id: 'test-id',
        userId: 'test-user-id',
        firstName: 'John',
        lastName: 'Doe',
        preferredLang: 'en',
        inputLangHint: 'ja',
        hasCompletedLanguageWizard: true,
        createdAt: now,
        updatedAt: now,
      );

      final json = user.toJson();

      expect(json['id'], 'test-id');
      expect(json['userId'], 'test-user-id');
      expect(json['firstName'], 'John');
      expect(json['lastName'], 'Doe');
      expect(json['preferredLang'], 'en');
      expect(json['inputLangHint'], 'ja');
      expect(json['hasCompletedLanguageWizard'], true);
    });

    test('UserProfile should deserialize from JSON correctly', () {
      final now = DateTime.now();
      final json = {
        'id': 'test-id',
        'userId': 'test-user-id',
        'firstName': 'John',
        'lastName': 'Doe',
        'preferredLang': 'en',
        'inputLangHint': 'ja',
        'hasCompletedLanguageWizard': true,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      final user = UserProfile.fromJson(json);

      expect(user.id, 'test-id');
      expect(user.userId, 'test-user-id');
      expect(user.firstName, 'John');
      expect(user.lastName, 'Doe');
      expect(user.preferredLang, 'en');
      expect(user.inputLangHint, 'ja');
      expect(user.hasCompletedLanguageWizard, true);
    });

    test('UserProfile should handle missing language fields with defaults', () {
      final now = DateTime.now();
      final json = {
        'id': 'test-id',
        'userId': 'test-user-id',
        'firstName': 'John',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      final user = UserProfile.fromJson(json);

      expect(user.preferredLang, 'zh-TW');
      expect(user.inputLangHint, 'zh-TW');
      expect(user.hasCompletedLanguageWizard, false);
    });
  });

  group('Phase 1: Data Model Tests - ChatRoom', () {
    test('ChatRoom should have default memberIds as empty list', () {
      final room = ChatRoom(
        bookingId: 'test-booking-id',
        customerId: 'customer-id',
        driverId: 'driver-id',
      );

      expect(room.memberIds, []);
      expect(room.roomLangOverride, null);
    });

    test('ChatRoom should accept custom memberIds and roomLangOverride', () {
      final room = ChatRoom(
        bookingId: 'test-booking-id',
        customerId: 'customer-id',
        driverId: 'driver-id',
        memberIds: ['customer-id', 'driver-id'],
        roomLangOverride: 'en',
      );

      expect(room.memberIds, ['customer-id', 'driver-id']);
      expect(room.roomLangOverride, 'en');
    });

    test('ChatRoom should serialize to Firestore correctly', () {
      final now = DateTime.now();
      final room = ChatRoom(
        bookingId: 'test-booking-id',
        customerId: 'customer-id',
        driverId: 'driver-id',
        customerName: 'John Doe',
        driverName: 'Jane Smith',
        memberIds: ['customer-id', 'driver-id'],
        roomLangOverride: 'en',
        lastMessage: 'Hello',
        lastMessageTime: now,
        updatedAt: now,
      );

      final data = room.toFirestore();

      // Note: bookingId is not included in toFirestore() as it's the document ID
      expect(data['customerId'], 'customer-id');
      expect(data['driverId'], 'driver-id');
      expect(data['customerName'], 'John Doe');
      expect(data['driverName'], 'Jane Smith');
      expect(data['memberIds'], ['customer-id', 'driver-id']);
      expect(data['roomLangOverride'], 'en');
      expect(data['lastMessage'], 'Hello');
      expect(data['lastMessageTime'], isA<Timestamp>());
    });

    test('ChatRoom should deserialize from Firestore correctly with memberIds', () {
      final now = DateTime.now();
      final data = {
        'customerId': 'customer-id',
        'driverId': 'driver-id',
        'customerName': 'John Doe',
        'driverName': 'Jane Smith',
        'memberIds': ['customer-id', 'driver-id'],
        'roomLangOverride': 'en',
        'lastMessage': 'Hello',
        'lastMessageTime': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      // Mock DocumentSnapshot with custom ID
      final mockDoc = _MockDocumentSnapshot(data, id: 'test-booking-id');
      final room = ChatRoom.fromFirestore(mockDoc);

      expect(room.bookingId, 'test-booking-id');
      expect(room.customerId, 'customer-id');
      expect(room.driverId, 'driver-id');
      expect(room.memberIds, ['customer-id', 'driver-id']);
      expect(room.roomLangOverride, 'en');
    });

    test('ChatRoom should generate memberIds from customerId and driverId if missing', () {
      final data = {
        'bookingId': 'test-booking-id',
        'customerId': 'customer-id',
        'driverId': 'driver-id',
        'customerName': 'John Doe',
        'driverName': 'Jane Smith',
        // memberIds is missing
      };

      final mockDoc = _MockDocumentSnapshot(data);
      final room = ChatRoom.fromFirestore(mockDoc);

      expect(room.memberIds, ['customer-id', 'driver-id']);
    });
  });

  group('Phase 1: Data Model Tests - ChatMessage', () {
    test('ChatMessage should have default detectedLang', () {
      final now = DateTime.now();
      final message = ChatMessage(
        id: 'test-message-id',
        senderId: 'sender-id',
        receiverId: 'receiver-id',
        messageText: 'Hello',
        createdAt: now,
      );

      expect(message.detectedLang, 'zh-TW');
    });

    test('ChatMessage should accept custom detectedLang', () {
      final now = DateTime.now();
      final message = ChatMessage(
        id: 'test-message-id',
        senderId: 'sender-id',
        receiverId: 'receiver-id',
        messageText: 'Hello',
        detectedLang: 'en',
        createdAt: now,
      );

      expect(message.detectedLang, 'en');
    });

    test('ChatMessage should serialize to Firestore correctly', () {
      final now = DateTime.now();
      final message = ChatMessage(
        id: 'test-message-id',
        senderId: 'sender-id',
        receiverId: 'receiver-id',
        senderName: 'John Doe',
        receiverName: 'Jane Smith',
        messageText: 'Hello',
        translatedText: 'Hola',
        detectedLang: 'en',
        createdAt: now,
      );

      final data = message.toFirestore();

      expect(data['senderId'], 'sender-id');
      expect(data['receiverId'], 'receiver-id');
      expect(data['senderName'], 'John Doe');
      expect(data['receiverName'], 'Jane Smith');
      expect(data['messageText'], 'Hello');
      expect(data['translatedText'], 'Hola');
      expect(data['detectedLang'], 'en');
      expect(data['createdAt'], isA<Timestamp>());
    });

    test('ChatMessage should deserialize from Firestore correctly', () {
      final now = DateTime.now();
      final data = {
        'senderId': 'sender-id',
        'receiverId': 'receiver-id',
        'senderName': 'John Doe',
        'receiverName': 'Jane Smith',
        'messageText': 'Hello',
        'translatedText': 'Hola',
        'detectedLang': 'en',
        'createdAt': Timestamp.fromDate(now),
      };

      final mockDoc = _MockDocumentSnapshot(data, id: 'test-message-id');
      final message = ChatMessage.fromFirestore(mockDoc);

      expect(message.id, 'test-message-id');
      expect(message.senderId, 'sender-id');
      expect(message.receiverId, 'receiver-id');
      expect(message.messageText, 'Hello');
      expect(message.translatedText, 'Hola');
      expect(message.detectedLang, 'en');
    });

    test('ChatMessage should handle missing detectedLang with default', () {
      final now = DateTime.now();
      final data = {
        'senderId': 'sender-id',
        'receiverId': 'receiver-id',
        'messageText': 'Hello',
        'createdAt': Timestamp.fromDate(now),
        // detectedLang is missing
      };

      final mockDoc = _MockDocumentSnapshot(data, id: 'test-message-id');
      final message = ChatMessage.fromFirestore(mockDoc);

      expect(message.detectedLang, 'zh-TW');
    });
  });
}

// Mock DocumentSnapshot for testing
class _MockDocumentSnapshot implements DocumentSnapshot {
  final Map<String, dynamic> _data;
  final String _id;

  _MockDocumentSnapshot(this._data, {String? id}) : _id = id ?? 'mock-id';

  @override
  Map<String, dynamic> data() => _data;

  @override
  String get id => _id;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

