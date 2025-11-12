/**
 * 數據遷移腳本：為現有聊天室添加 memberIds 欄位
 * 
 * 階段 1: 多語言翻譯系統
 * 
 * 此腳本為所有現有聊天室添加以下欄位：
 * - memberIds: [customerId, driverId]
 * 
 * 執行方式：
 * cd firebase
 * node migrations/add-chat-room-member-ids.js
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

/**
 * 主函數：遷移聊天室 memberIds
 */
async function migrateChatRoomMemberIds() {
  console.log('\n🚀 開始遷移聊天室 memberIds...\n');

  try {
    // 查詢所有聊天室
    const chatRoomsRef = db.collection('chat_rooms');
    const snapshot = await chatRoomsRef.get();

    if (snapshot.empty) {
      console.log('⚠️  沒有找到任何聊天室文檔');
      return;
    }

    console.log(`📊 找到 ${snapshot.size} 個聊天室文檔\n`);

    let updatedCount = 0;
    let skippedCount = 0;
    let errorCount = 0;
    let batch = db.batch();
    let batchCount = 0;

    for (const doc of snapshot.docs) {
      const data = doc.data();

      // 檢查是否已經有 memberIds
      if (data.memberIds && Array.isArray(data.memberIds) && data.memberIds.length > 0) {
        console.log(`⏭️  跳過聊天室 ${doc.id}（已有 memberIds）`);
        skippedCount++;
        continue;
      }

      // 檢查是否有 customerId 和 driverId
      if (!data.customerId || !data.driverId) {
        console.log(`⚠️  聊天室 ${doc.id} 缺少 customerId 或 driverId，跳過`);
        errorCount++;
        continue;
      }

      // 準備更新數據
      const updateData = {
        memberIds: [data.customerId, data.driverId],
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      // 添加到批次
      batch.update(doc.ref, updateData);
      batchCount++;
      updatedCount++;

      console.log(`✅ 準備更新聊天室 ${doc.id}:`, {
        memberIds: updateData.memberIds,
      });

      // 如果批次達到限制，提交批次
      if (batchCount >= BATCH_SIZE) {
        console.log(`\n📦 提交批次（${batchCount} 個文檔）...\n`);
        await batch.commit();
        batch = db.batch();
        batchCount = 0;
      }
    }

    // 提交剩餘的批次
    if (batchCount > 0) {
      console.log(`\n📦 提交最後一批（${batchCount} 個文檔）...\n`);
      await batch.commit();
    }

    // 輸出統計
    console.log('\n' + '='.repeat(60));
    console.log('📊 遷移統計：');
    console.log('='.repeat(60));
    console.log(`✅ 成功更新：${updatedCount} 個聊天室`);
    console.log(`⏭️  跳過：${skippedCount} 個聊天室`);
    console.log(`❌ 錯誤：${errorCount} 個聊天室`);
    console.log(`📊 總計：${snapshot.size} 個聊天室`);
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
    const snapshot = await chatRoomsRef.get();

    let successCount = 0;
    let missingCount = 0;

    for (const doc of snapshot.docs) {
      const data = doc.data();

      if (data.memberIds && Array.isArray(data.memberIds) && data.memberIds.length > 0) {
        successCount++;
      } else {
        missingCount++;
        console.log(`⚠️  聊天室 ${doc.id} 缺少 memberIds:`, {
          customerId: data.customerId,
          driverId: data.driverId,
          memberIds: data.memberIds,
        });
      }
    }

    console.log('\n' + '='.repeat(60));
    console.log('📊 驗證結果：');
    console.log('='.repeat(60));
    console.log(`✅ 成功：${successCount} 個聊天室`);
    console.log(`❌ 缺少 memberIds：${missingCount} 個聊天室`);
    console.log(`📊 總計：${snapshot.size} 個聊天室`);
    console.log('='.repeat(60) + '\n');

    if (missingCount === 0) {
      console.log('🎉 所有聊天室都已成功設置 memberIds！\n');
    } else {
      console.log('⚠️  部分聊天室缺少 memberIds，請檢查日誌\n');
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
    // 執行遷移
    await migrateChatRoomMemberIds();

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

