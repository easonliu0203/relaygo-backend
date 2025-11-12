const { assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { initializeTestEnvironment } = require('@firebase/rules-unit-testing');
const fs = require('fs');
const path = require('path');

let testEnv;

beforeAll(async () => {
  // 讀取 Firestore 規則檔案
  const rulesPath = path.join(__dirname, '..', 'firestore.rules');
  const rules = fs.readFileSync(rulesPath, 'utf8');

  testEnv = await initializeTestEnvironment({
    projectId: 'test-project-phase1',
    firestore: {
      rules: rules,
      host: 'localhost',
      port: 8080,
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

afterEach(async () => {
  await testEnv.clearFirestore();
});

describe('Phase 1: Firestore Security Rules Tests - User Language Preferences', () => {
  test('User can read their own language preferences', async () => {
    const alice = testEnv.authenticatedContext('alice');
    
    // 使用 withSecurityRulesDisabled 創建測試數據
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('users').doc('alice').set({
        id: 'alice',
        userId: 'alice',
        preferredLang: 'zh-TW',
        inputLangHint: 'zh-TW',
        hasCompletedLanguageWizard: false,
        createdAt: new Date(),
        updatedAt: new Date(),
      });
    });

    // 測試讀取權限
    await assertSucceeds(alice.firestore().collection('users').doc('alice').get());
  });

  test('User can update their own language preferences', async () => {
    const alice = testEnv.authenticatedContext('alice');
    
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('users').doc('alice').set({
        id: 'alice',
        userId: 'alice',
        preferredLang: 'zh-TW',
        inputLangHint: 'zh-TW',
        hasCompletedLanguageWizard: false,
        createdAt: new Date(),
        updatedAt: new Date(),
      });
    });

    // 測試更新語言偏好
    await assertSucceeds(
      alice.firestore().collection('users').doc('alice').update({
        preferredLang: 'en',
        inputLangHint: 'en',
        hasCompletedLanguageWizard: true,
        updatedAt: new Date(),
      })
    );
  });

  test('User cannot read other users language preferences', async () => {
    const alice = testEnv.authenticatedContext('alice');
    
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('users').doc('bob').set({
        id: 'bob',
        userId: 'bob',
        preferredLang: 'zh-TW',
        createdAt: new Date(),
        updatedAt: new Date(),
      });
    });

    // 測試無法讀取其他用戶的資料
    await assertFails(alice.firestore().collection('users').doc('bob').get());
  });

  test('User cannot update other users language preferences', async () => {
    const alice = testEnv.authenticatedContext('alice');
    
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('users').doc('bob').set({
        id: 'bob',
        userId: 'bob',
        preferredLang: 'zh-TW',
        createdAt: new Date(),
        updatedAt: new Date(),
      });
    });

    // 測試無法更新其他用戶的資料
    await assertFails(
      alice.firestore().collection('users').doc('bob').update({
        preferredLang: 'en',
      })
    );
  });

  test('User cannot create new user documents', async () => {
    const alice = testEnv.authenticatedContext('alice');

    // 測試無法創建新用戶文檔
    await assertFails(
      alice.firestore().collection('users').doc('alice').set({
        id: 'alice',
        userId: 'alice',
        preferredLang: 'zh-TW',
        createdAt: new Date(),
        updatedAt: new Date(),
      })
    );
  });

  test('User cannot delete user documents', async () => {
    const alice = testEnv.authenticatedContext('alice');
    
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('users').doc('alice').set({
        id: 'alice',
        userId: 'alice',
        preferredLang: 'zh-TW',
        createdAt: new Date(),
        updatedAt: new Date(),
      });
    });

    // 測試無法刪除用戶文檔
    await assertFails(alice.firestore().collection('users').doc('alice').delete());
  });
});

describe('Phase 1: Firestore Security Rules Tests - Chat Room Language Override', () => {
  test('Chat room members can read roomLangOverride', async () => {
    const alice = testEnv.authenticatedContext('alice');
    
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('chat_rooms').doc('room1').set({
        bookingId: 'booking1',
        customerId: 'alice',
        driverId: 'bob',
        memberIds: ['alice', 'bob'],
        roomLangOverride: 'en',
        createdAt: new Date(),
      });
    });

    // 測試讀取權限
    await assertSucceeds(alice.firestore().collection('chat_rooms').doc('room1').get());
  });

  test('Chat room members can update roomLangOverride', async () => {
    const alice = testEnv.authenticatedContext('alice');
    
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('chat_rooms').doc('room1').set({
        bookingId: 'booking1',
        customerId: 'alice',
        driverId: 'bob',
        memberIds: ['alice', 'bob'],
        roomLangOverride: 'zh-TW',
        createdAt: new Date(),
      });
    });

    // 測試更新 roomLangOverride
    await assertSucceeds(
      alice.firestore().collection('chat_rooms').doc('room1').update({
        roomLangOverride: 'en',
        updatedAt: new Date(),
      })
    );
  });

  test('Non-members cannot read chat room', async () => {
    const charlie = testEnv.authenticatedContext('charlie');
    
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('chat_rooms').doc('room1').set({
        bookingId: 'booking1',
        customerId: 'alice',
        driverId: 'bob',
        memberIds: ['alice', 'bob'],
        roomLangOverride: 'en',
        createdAt: new Date(),
      });
    });

    // 測試非成員無法讀取
    await assertFails(charlie.firestore().collection('chat_rooms').doc('room1').get());
  });

  test('Non-members cannot update roomLangOverride', async () => {
    const charlie = testEnv.authenticatedContext('charlie');
    
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('chat_rooms').doc('room1').set({
        bookingId: 'booking1',
        customerId: 'alice',
        driverId: 'bob',
        memberIds: ['alice', 'bob'],
        roomLangOverride: 'zh-TW',
        createdAt: new Date(),
      });
    });

    // 測試非成員無法更新
    await assertFails(
      charlie.firestore().collection('chat_rooms').doc('room1').update({
        roomLangOverride: 'en',
      })
    );
  });

  test('Members cannot create chat rooms', async () => {
    const alice = testEnv.authenticatedContext('alice');

    // 測試無法創建聊天室
    await assertFails(
      alice.firestore().collection('chat_rooms').doc('room1').set({
        bookingId: 'booking1',
        customerId: 'alice',
        driverId: 'bob',
        memberIds: ['alice', 'bob'],
        createdAt: new Date(),
      })
    );
  });

  test('Members cannot delete chat rooms', async () => {
    const alice = testEnv.authenticatedContext('alice');
    
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('chat_rooms').doc('room1').set({
        bookingId: 'booking1',
        customerId: 'alice',
        driverId: 'bob',
        memberIds: ['alice', 'bob'],
        createdAt: new Date(),
      });
    });

    // 測試無法刪除聊天室
    await assertFails(alice.firestore().collection('chat_rooms').doc('room1').delete());
  });
});

describe('Phase 1: Firestore Security Rules Tests - Message Language Detection', () => {
  test('New messages must include detectedLang field', async () => {
    const alice = testEnv.authenticatedContext('alice');
    
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('chat_rooms').doc('room1').set({
        bookingId: 'booking1',
        customerId: 'alice',
        driverId: 'bob',
        memberIds: ['alice', 'bob'],
      });
    });

    // 測試沒有 detectedLang 會失敗
    await assertFails(
      alice.firestore()
        .collection('chat_rooms').doc('room1')
        .collection('messages').add({
          senderId: 'alice',
          receiverId: 'bob',
          messageText: 'Hello',
          createdAt: new Date(),
        })
    );

    // 測試有 detectedLang 會成功
    await assertSucceeds(
      alice.firestore()
        .collection('chat_rooms').doc('room1')
        .collection('messages').add({
          senderId: 'alice',
          receiverId: 'bob',
          messageText: 'Hello',
          detectedLang: 'en',
          createdAt: new Date(),
        })
    );
  });

  test('Messages can have different detectedLang values', async () => {
    const alice = testEnv.authenticatedContext('alice');
    
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('chat_rooms').doc('room1').set({
        bookingId: 'booking1',
        customerId: 'alice',
        driverId: 'bob',
        memberIds: ['alice', 'bob'],
      });
    });

    // 測試中文訊息
    await assertSucceeds(
      alice.firestore()
        .collection('chat_rooms').doc('room1')
        .collection('messages').add({
          senderId: 'alice',
          receiverId: 'bob',
          messageText: '你好',
          detectedLang: 'zh-TW',
          createdAt: new Date(),
        })
    );

    // 測試英文訊息
    await assertSucceeds(
      alice.firestore()
        .collection('chat_rooms').doc('room1')
        .collection('messages').add({
          senderId: 'alice',
          receiverId: 'bob',
          messageText: 'Hello',
          detectedLang: 'en',
          createdAt: new Date(),
        })
    );

    // 測試日文訊息
    await assertSucceeds(
      alice.firestore()
        .collection('chat_rooms').doc('room1')
        .collection('messages').add({
          senderId: 'alice',
          receiverId: 'bob',
          messageText: 'こんにちは',
          detectedLang: 'ja',
          createdAt: new Date(),
        })
    );
  });

  test('Non-members cannot send messages', async () => {
    const charlie = testEnv.authenticatedContext('charlie');
    
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('chat_rooms').doc('room1').set({
        bookingId: 'booking1',
        customerId: 'alice',
        driverId: 'bob',
        memberIds: ['alice', 'bob'],
      });
    });

    // 測試非成員無法發送訊息
    await assertFails(
      charlie.firestore()
        .collection('chat_rooms').doc('room1')
        .collection('messages').add({
          senderId: 'charlie',
          receiverId: 'alice',
          messageText: 'Hello',
          detectedLang: 'en',
          createdAt: new Date(),
        })
    );
  });
});

