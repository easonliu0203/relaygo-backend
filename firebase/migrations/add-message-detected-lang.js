/**
 * 數據遷移腳本：為現有訊息添加 detectedLang 欄位（可選）
 * 
 * 階段 1: 多語言翻譯系統
 * 
 * 此腳本為所有現有訊息添加以下欄位：
 * - detectedLang: 'zh-TW' (默認繁體中文)
 * 
 * 注意：這個遷移是可選的，因為舊訊息可以在客戶端動態偵測語言。
 * 如果訊息數量很大，建議跳過此遷移，讓客戶端動態偵測語言。
 * 
 * 執行方式：
 * cd firebase
 * node migrations/add-message-detected-lang.js
 */

const admin = require('firebase-admin');
const path = require('path');

// 初始化 Firebase Admin SDK
const serviceAccountPath = path.join(__dirname, '../service-account-key.json');

try {
  const serviceAccount = require(serviceAccountPath);
  
  // 檢查是否已經初始化
  if (admin.apps.length === 0) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
  }
  console.log('✅ Firebase Admin SDK 初始化成功');
} catch (error) {
  console.error('❌ Firebase Admin SDK 初始化失敗:', error.message);
  console.error('請確保 service-account-key.json 文件存在於 firebase/ 目錄中');
  process.exit(1);
}

const db = admin.firestore();

// 配置
const BATCH_SIZE = 500;  // 每批處理的文檔數量
const DEFAULT_LANG = 'zh-TW';  // 默認語言
const MAX_ROOMS_TO_PROCESS = 100;  // 最多處理的聊天室數量（避免處理過多數據）

/**
 * 主函數：遷移訊息 detectedLang
 */
async function migrateMessageDetectedLang() {
  console.log('\n🚀 開始遷移訊息 detectedLang...\n');
  console.log('⚠️  注意：這是一個可選的遷移，如果訊息數量很大，建議跳過此遷移\n');

  try {
    // 查詢所有聊天室
    const chatRoomsRef = db.collection('chat_rooms');
    const chatRoomsSnapshot = await chatRoomsRef.limit(MAX_ROOMS_TO_PROCESS).get();

    if (chatRoomsSnapshot.empty) {
      console.log('⚠️  沒有找到任何聊天室文檔');
      return;
    }

    console.log(`📊 找到 ${chatRoomsSnapshot.size} 個聊天室（最多處理 ${MAX_ROOMS_TO_PROCESS} 個）\n`);

    let totalUpdatedCount = 0;
    let totalSkippedCount = 0;
    let totalErrorCount = 0;
    let totalMessagesCount = 0;

    // 遍歷每個聊天室
    for (const chatRoomDoc of chatRoomsSnapshot.docs) {
      console.log(`\n📂 處理聊天室 ${chatRoomDoc.id}...`);

      // 查詢聊天室的所有訊息
      const messagesRef = chatRoomDoc.ref.collection('messages');
      const messagesSnapshot = await messagesRef.get();

      if (messagesSnapshot.empty) {
        console.log(`  ⏭️  聊天室 ${chatRoomDoc.id} 沒有訊息，跳過`);
        continue;
      }

      console.log(`  📊 找到 ${messagesSnapshot.size} 條訊息`);
      totalMessagesCount += messagesSnapshot.size;

      let updatedCount = 0;
      let skippedCount = 0;
      let batch = db.batch();
      let batchCount = 0;

      for (const messageDoc of messagesSnapshot.docs) {
        const data = messageDoc.data();

        // 檢查是否已經有 detectedLang
        if (data.detectedLang) {
          skippedCount++;
          totalSkippedCount++;
          continue;
        }

        // 準備更新數據
        const updateData = {
          detectedLang: DEFAULT_LANG,
        };

        // 添加到批次
        batch.update(messageDoc.ref, updateData);
        batchCount++;
        updatedCount++;
        totalUpdatedCount++;

        // 如果批次達到限制，提交批次
        if (batchCount >= BATCH_SIZE) {
          console.log(`  📦 提交批次（${batchCount} 條訊息）...`);
          await batch.commit();
          batch = db.batch();
          batchCount = 0;
        }
      }

      // 提交剩餘的批次
      if (batchCount > 0) {
        console.log(`  📦 提交最後一批（${batchCount} 條訊息）...`);
        await batch.commit();
      }

      console.log(`  ✅ 聊天室 ${chatRoomDoc.id} 完成：更新 ${updatedCount} 條，跳過 ${skippedCount} 條`);
    }

    // 輸出統計
    console.log('\n' + '='.repeat(60));
    console.log('📊 遷移統計：');
    console.log('='.repeat(60));
    console.log(`✅ 成功更新：${totalUpdatedCount} 條訊息`);
    console.log(`⏭️  跳過：${totalSkippedCount} 條訊息`);
    console.log(`❌ 錯誤：${totalErrorCount} 條訊息`);
    console.log(`📊 總計：${totalMessagesCount} 條訊息`);
    console.log(`📂 處理聊天室：${chatRoomsSnapshot.size} 個`);
    console.log('='.repeat(60) + '\n');

    console.log('🎉 遷移完成！\n');

  } catch (error) {
    console.error('\n❌ 遷移失敗:', error);
    throw error;
  }
}

/**
 * 驗證遷移結果
 */
async function verifyMigration() {
  console.log('\n🔍 驗證遷移結果...\n');

  try {
    const chatRoomsRef = db.collection('chat_rooms');
    const chatRoomsSnapshot = await chatRoomsRef.limit(MAX_ROOMS_TO_PROCESS).get();

    let totalSuccessCount = 0;
    let totalMissingCount = 0;
    let totalMessagesCount = 0;

    for (const chatRoomDoc of chatRoomsSnapshot.docs) {
      const messagesRef = chatRoomDoc.ref.collection('messages');
      const messagesSnapshot = await messagesRef.get();

      if (messagesSnapshot.empty) {
        continue;
      }

      totalMessagesCount += messagesSnapshot.size;

      for (const messageDoc of messagesSnapshot.docs) {
        const data = messageDoc.data();

        if (data.detectedLang) {
          totalSuccessCount++;
        } else {
          totalMissingCount++;
        }
      }
    }

    console.log('\n' + '='.repeat(60));
    console.log('📊 驗證結果：');
    console.log('='.repeat(60));
    console.log(`✅ 成功：${totalSuccessCount} 條訊息`);
    console.log(`❌ 缺少 detectedLang：${totalMissingCount} 條訊息`);
    console.log(`📊 總計：${totalMessagesCount} 條訊息`);
    console.log('='.repeat(60) + '\n');

    if (totalMissingCount === 0) {
      console.log('🎉 所有訊息都已成功設置 detectedLang！\n');
    } else {
      console.log('⚠️  部分訊息缺少 detectedLang，這是正常的（舊訊息可以在客戶端動態偵測語言）\n');
    }

  } catch (error) {
    console.error('\n❌ 驗證失敗:', error);
    throw error;
  }
}

/**
 * 主程序
 */
async function main() {
  try {
    // 詢問用戶是否確定要執行遷移
    console.log('\n⚠️  警告：此遷移可能需要較長時間，且會消耗 Firestore 讀寫配額');
    console.log('⚠️  如果訊息數量很大，建議跳過此遷移，讓客戶端動態偵測語言\n');
    console.log('按 Ctrl+C 取消，或等待 5 秒後自動開始...\n');

    // 等待 5 秒
    await new Promise(resolve => setTimeout(resolve, 5000));

    // 執行遷移
    await migrateMessageDetectedLang();

    // 驗證遷移結果
    await verifyMigration();

    console.log('✅ 所有操作完成！\n');
    process.exit(0);

  } catch (error) {
    console.error('\n❌ 程序執行失敗:', error);
    process.exit(1);
  }
}

// 執行主程序
main();

