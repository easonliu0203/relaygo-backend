const admin = require('firebase-admin');
const TranslationCacheService = require('../src/services/translationCacheService');

describe('TranslationCacheService', () => {
  let cacheService;
  let db;

  beforeAll(async () => {
    // 初始化 Firebase Admin（測試環境）
    if (!admin.apps.length) {
      admin.initializeApp({
        projectId: 'test-project',
      });
    }
    db = admin.firestore();
    cacheService = new TranslationCacheService();
  });

  afterAll(async () => {
    // 清理測試資料
    const snapshot = await db.collection('translation_cache').get();
    const batch = db.batch();
    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });
    await batch.commit();
  });

  describe('generateCacheKey', () => {
    test('should generate consistent SHA256 hash', () => {
      const key1 = cacheService.generateCacheKey('Hello', 'zh-TW');
      const key2 = cacheService.generateCacheKey('Hello', 'zh-TW');
      expect(key1).toBe(key2);
    });

    test('should generate different hashes for different inputs', () => {
      const key1 = cacheService.generateCacheKey('Hello', 'zh-TW');
      const key2 = cacheService.generateCacheKey('Hello', 'ja');
      const key3 = cacheService.generateCacheKey('World', 'zh-TW');

      expect(key1).not.toBe(key2);
      expect(key1).not.toBe(key3);
      expect(key2).not.toBe(key3);
    });

    test('should generate 64-character hex string', () => {
      const key = cacheService.generateCacheKey('Test', 'en');
      expect(key).toHaveLength(64);
      expect(key).toMatch(/^[a-f0-9]{64}$/);
    });
  });

  describe('setTranslation and getTranslation', () => {
    test('should store and retrieve translation', async () => {
      const text = 'Hello, world!';
      const targetLang = 'zh-TW';
      const translatedText = '你好，世界！';

      await cacheService.setTranslation(text, targetLang, translatedText);
      const result = await cacheService.getTranslation(text, targetLang);

      expect(result).toBe(translatedText);
    });

    test('should return null for non-existent cache', async () => {
      const result = await cacheService.getTranslation('Non-existent text', 'en');
      expect(result).toBeNull();
    });

    test('should update access count on retrieval', async () => {
      const text = 'Test access count';
      const targetLang = 'ja';
      const translatedText = 'テストアクセスカウント';

      await cacheService.setTranslation(text, targetLang, translatedText);

      // 第一次讀取
      await cacheService.getTranslation(text, targetLang);

      // 第二次讀取
      await cacheService.getTranslation(text, targetLang);

      // 驗證 accessCount（需要直接查詢 Firestore）
      const cacheKey = cacheService.generateCacheKey(text, targetLang);
      const doc = await db.collection('translation_cache').doc(cacheKey).get();

      expect(doc.exists).toBe(true);
      expect(doc.data().accessCount).toBeGreaterThanOrEqual(2);
    });
  });

  describe('cleanupExpiredCache', () => {
    test('should delete expired cache entries', async () => {
      // 創建一個過期的快取項目（需要手動設置 createdAt）
      const text = 'Expired text';
      const targetLang = 'ko';
      const translatedText = '만료된 텍스트';
      const cacheKey = cacheService.generateCacheKey(text, targetLang);

      // 設置 31 天前的時間戳
      const expiredDate = new Date();
      expiredDate.setDate(expiredDate.getDate() - 31);

      await db.collection('translation_cache').doc(cacheKey).set({
        text,
        targetLang,
        translatedText,
        createdAt: admin.firestore.Timestamp.fromDate(expiredDate),
        lastAccessedAt: admin.firestore.Timestamp.fromDate(expiredDate),
        accessCount: 1,
      });

      // 執行清理
      const deletedCount = await cacheService.cleanupExpiredCache();

      expect(deletedCount).toBeGreaterThanOrEqual(1);

      // 驗證快取已被刪除
      const result = await cacheService.getTranslation(text, targetLang);
      expect(result).toBeNull();
    });

    test('should not delete non-expired cache entries', async () => {
      const text = 'Fresh text';
      const targetLang = 'vi';
      const translatedText = 'Văn bản mới';

      await cacheService.setTranslation(text, targetLang, translatedText);
      await cacheService.cleanupExpiredCache();

      const result = await cacheService.getTranslation(text, targetLang);
      expect(result).toBe(translatedText);
    });
  });
});

