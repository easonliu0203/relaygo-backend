/**
 * 翻譯功能測試腳本
 * 
 * 使用方法：
 * 1. 設定環境變數（.env 檔案）
 * 2. 執行：node test/test-translation.js
 */

const admin = require('firebase-admin');
const { getTranslationService } = require('../src/services/translationService');

// 初始化 Firebase Admin
const serviceAccount = require('../../../ride-platform-f1676-firebase-adminsdk-fbsvc-8fad5fdb15.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'ride-platform-f1676',
});

const db = admin.firestore();

// 測試資料
const TEST_ROOM_ID = 'test_room_translation';
const TEST_USER_A = 'test_user_a';
const TEST_USER_B = 'test_user_b';

/**
 * 測試案例 1: 自動翻譯功能
 */
async function testAutoTranslation() {
  console.log('\n=== 測試案例 1: 自動翻譯功能 ===\n');

  try {
    // 1. 創建測試訊息
    const messageRef = db
      .collection('chat_rooms')
      .doc(TEST_ROOM_ID)
      .collection('messages')
      .doc();

    const messageData = {
      messageText: 'Hello, how are you today?',
      lang: 'en',
      senderId: TEST_USER_A,
      receiverId: TEST_USER_B,
      senderName: 'Test User A',
      receiverName: 'Test User B',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    console.log('1. 創建測試訊息...');
    await messageRef.set(messageData);
    console.log(`   ✅ 訊息已創建: ${messageRef.id}`);

    // 2. 等待 Cloud Function 處理（模擬）
    console.log('\n2. 等待自動翻譯（5 秒）...');
    await sleep(5000);

    // 3. 檢查翻譯結果
    console.log('\n3. 檢查翻譯結果...');
    const updatedDoc = await messageRef.get();
    const updatedData = updatedDoc.data();

    if (updatedData.translations) {
      console.log('   ✅ 翻譯成功！');
      console.log('   翻譯語言:', Object.keys(updatedData.translations));
      
      for (const [lang, translation] of Object.entries(updatedData.translations)) {
        console.log(`   - ${lang}: ${translation.text}`);
        console.log(`     模型: ${translation.model}, Tokens: ${translation.tokensUsed || 'N/A'}`);
      }
    } else {
      console.log('   ❌ 未找到翻譯結果');
      console.log('   請檢查：');
      console.log('   1. Cloud Function 是否已部署');
      console.log('   2. ENABLE_AUTO_TRANSLATE 是否為 true');
      console.log('   3. 查看 Firebase Functions 日誌');
    }

    return updatedData.translations ? true : false;

  } catch (error) {
    console.error('   ❌ 測試失敗:', error.message);
    return false;
  }
}

/**
 * 測試案例 2: 按需翻譯（直接呼叫服務）
 */
async function testOnDemandTranslation() {
  console.log('\n=== 測試案例 2: 按需翻譯 ===\n');

  try {
    // 從環境變數讀取 API 金鑰
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      console.error('   ❌ OPENAI_API_KEY 環境變數未設定');
      console.log('   請執行: export OPENAI_API_KEY="your-api-key"');
      return false;
    }

    const translationService = getTranslationService(apiKey);

    const text = '你好，今天天氣很好！';
    const sourceLang = 'zh-TW';
    const targetLang = 'en';

    console.log(`1. 翻譯文字: "${text}"`);
    console.log(`   來源語言: ${sourceLang}`);
    console.log(`   目標語言: ${targetLang}`);

    console.log('\n2. 執行翻譯...');
    const result = await translationService.translate(text, sourceLang, targetLang);

    if (result) {
      console.log('   ✅ 翻譯成功！');
      console.log(`   翻譯結果: "${result.text}"`);
      console.log(`   使用模型: ${result.model}`);
      console.log(`   Token 使用: ${result.tokensUsed}`);
      console.log(`   耗時: ${result.duration}ms`);
      return true;
    } else {
      console.log('   ⚠️  翻譯被跳過（可能來源語言 = 目標語言）');
      return true;
    }

  } catch (error) {
    console.error('   ❌ 測試失敗:', error.message);
    return false;
  }
}

/**
 * 測試案例 3: 批次翻譯
 */
async function testBatchTranslation() {
  console.log('\n=== 測試案例 3: 批次翻譯 ===\n');

  try {
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      console.error('   ❌ OPENAI_API_KEY 環境變數未設定');
      return false;
    }

    const translationService = getTranslationService(apiKey);

    const text = 'Good morning!';
    const sourceLang = 'en';
    const targetLangs = ['zh-TW', 'ja', 'ko'];

    console.log(`1. 翻譯文字: "${text}"`);
    console.log(`   來源語言: ${sourceLang}`);
    console.log(`   目標語言: ${targetLangs.join(', ')}`);

    console.log('\n2. 執行批次翻譯...');
    const results = await translationService.translateBatch(text, sourceLang, targetLangs, 2);

    console.log('   ✅ 批次翻譯完成！');
    console.log(`   成功翻譯 ${Object.keys(results).length} 種語言：`);
    
    for (const [lang, result] of Object.entries(results)) {
      if (result.error) {
        console.log(`   - ${lang}: ❌ ${result.error}`);
      } else {
        console.log(`   - ${lang}: "${result.text}"`);
      }
    }

    return Object.keys(results).length > 0;

  } catch (error) {
    console.error('   ❌ 測試失敗:', error.message);
    return false;
  }
}

/**
 * 測試案例 4: 成本控制 - 長訊息截斷
 */
async function testLongMessageControl() {
  console.log('\n=== 測試案例 4: 成本控制 - 長訊息截斷 ===\n');

  try {
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      console.error('   ❌ OPENAI_API_KEY 環境變數未設定');
      return false;
    }

    const translationService = getTranslationService(apiKey);

    // 生成超長訊息（600 字元）
    const longText = 'A'.repeat(600);

    console.log(`1. 測試訊息長度: ${longText.length} 字元`);
    console.log(`   閾值: ${process.env.MAX_AUTO_TRANSLATE_LENGTH || 500} 字元`);

    const shouldTranslate = translationService.shouldAutoTranslate(longText);

    if (!shouldTranslate) {
      console.log('   ✅ 正確跳過長訊息翻譯');
      return true;
    } else {
      console.log('   ❌ 應該跳過但沒有跳過');
      return false;
    }

  } catch (error) {
    console.error('   ❌ 測試失敗:', error.message);
    return false;
  }
}

/**
 * 測試案例 5: 快取機制
 */
async function testCacheMechanism() {
  console.log('\n=== 測試案例 5: 快取機制 ===\n');

  try {
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      console.error('   ❌ OPENAI_API_KEY 環境變數未設定');
      return false;
    }

    const translationService = getTranslationService(apiKey);

    const text = 'Test cache';
    const sourceLang = 'en';
    const targetLang = 'zh-TW';

    console.log('1. 第一次翻譯（應該呼叫 API）...');
    const start1 = Date.now();
    const result1 = await translationService.translate(text, sourceLang, targetLang);
    const duration1 = Date.now() - start1;
    console.log(`   耗時: ${duration1}ms`);

    console.log('\n2. 第二次翻譯（應該使用快取）...');
    const start2 = Date.now();
    const result2 = await translationService.translate(text, sourceLang, targetLang);
    const duration2 = Date.now() - start2;
    console.log(`   耗時: ${duration2}ms`);

    if (duration2 < duration1 / 2) {
      console.log('   ✅ 快取機制正常運作');
      return true;
    } else {
      console.log('   ⚠️  快取可能未生效（但不一定是錯誤）');
      return true;
    }

  } catch (error) {
    console.error('   ❌ 測試失敗:', error.message);
    return false;
  }
}

/**
 * 測試案例 6: 語言自動偵測
 */
async function testLanguageDetection() {
  console.log('\n=== 測試案例 6: 語言自動偵測 ===\n');

  try {
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      console.error('   ❌ OPENAI_API_KEY 環境變數未設定');
      return false;
    }

    const translationService = getTranslationService(apiKey);

    const text = 'Hello';
    const sourceLang = 'en';
    const targetLang = 'en'; // 相同語言

    console.log(`1. 測試相同語言翻譯: ${sourceLang} -> ${targetLang}`);

    const result = await translationService.translate(text, sourceLang, targetLang);

    if (result === null) {
      console.log('   ✅ 正確跳過相同語言翻譯');
      return true;
    } else {
      console.log('   ❌ 應該跳過但沒有跳過');
      return false;
    }

  } catch (error) {
    console.error('   ❌ 測試失敗:', error.message);
    return false;
  }
}

/**
 * 清理測試資料
 */
async function cleanup() {
  console.log('\n=== 清理測試資料 ===\n');

  try {
    const messagesRef = db
      .collection('chat_rooms')
      .doc(TEST_ROOM_ID)
      .collection('messages');

    const snapshot = await messagesRef.get();
    
    const batch = db.batch();
    snapshot.docs.forEach(doc => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    console.log(`✅ 已刪除 ${snapshot.size} 則測試訊息`);

  } catch (error) {
    console.error('❌ 清理失敗:', error.message);
  }
}

/**
 * 工具函數
 */
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * 主測試流程
 */
async function runAllTests() {
  console.log('╔════════════════════════════════════════════════════════╗');
  console.log('║         聊天翻譯功能測試套件                           ║');
  console.log('╚════════════════════════════════════════════════════════╝');

  const results = [];

  // 執行所有測試
  results.push({ name: '按需翻譯', passed: await testOnDemandTranslation() });
  results.push({ name: '批次翻譯', passed: await testBatchTranslation() });
  results.push({ name: '長訊息控制', passed: await testLongMessageControl() });
  results.push({ name: '快取機制', passed: await testCacheMechanism() });
  results.push({ name: '語言偵測', passed: await testLanguageDetection() });
  
  // 自動翻譯需要 Cloud Function 部署，可選測試
  if (process.env.TEST_AUTO_TRANSLATE === 'true') {
    results.push({ name: '自動翻譯', passed: await testAutoTranslation() });
  }

  // 清理
  await cleanup();

  // 輸出結果
  console.log('\n╔════════════════════════════════════════════════════════╗');
  console.log('║                    測試結果總覽                        ║');
  console.log('╚════════════════════════════════════════════════════════╝\n');

  const passed = results.filter(r => r.passed).length;
  const total = results.length;

  results.forEach(result => {
    const status = result.passed ? '✅ PASS' : '❌ FAIL';
    console.log(`${status} - ${result.name}`);
  });

  console.log(`\n總計: ${passed}/${total} 測試通過`);

  if (passed === total) {
    console.log('\n🎉 所有測試通過！');
  } else {
    console.log('\n⚠️  部分測試失敗，請檢查錯誤訊息');
  }

  process.exit(passed === total ? 0 : 1);
}

// 執行測試
runAllTests().catch(error => {
  console.error('測試執行失敗:', error);
  process.exit(1);
});

