/**
 * 數據遷移腳本：為現有用戶添加語言偏好設定
 * 
 * 階段 1: 多語言翻譯系統
 * 
 * 此腳本為所有現有用戶添加以下欄位：
 * - preferredLang: 'zh-TW' (默認繁體中文)
 * - inputLangHint: 'zh-TW' (默認繁體中文)
 * - hasCompletedLanguageWizard: false (未完成語言精靈)
 * 
 * 執行方式：
 * cd firebase
 * node migrations/add-user-language-preferences.js
 */

const admin = require('firebase-admin');
const path = require('path');

// 初始化 Firebase Admin SDK
const serviceAccountPath = path.join(__dirname, '../service-account-key.json');

try {
  const serviceAccount = require(serviceAccountPath);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
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

/**
 * 主函數：遷移用戶語言偏好設定
 */
async function migrateUserLanguagePreferences() {
  console.log('\n🚀 開始遷移用戶語言偏好設定...\n');

  try {
    // 查詢所有用戶
    const usersRef = db.collection('users');
    const snapshot = await usersRef.get();

    if (snapshot.empty) {
      console.log('⚠️  沒有找到任何用戶文檔');
      return;
    }

    console.log(`📊 找到 ${snapshot.size} 個用戶文檔\n`);

    let updatedCount = 0;
    let skippedCount = 0;
    let errorCount = 0;
    let batch = db.batch();
    let batchCount = 0;

    for (const doc of snapshot.docs) {
      const data = doc.data();

      // 檢查是否已經有語言偏好設定
      if (data.preferredLang && data.inputLangHint && data.hasCompletedLanguageWizard !== undefined) {
        console.log(`⏭️  跳過用戶 ${doc.id}（已有語言設定）`);
        skippedCount++;
        continue;
      }

      // 準備更新數據
      const updateData = {};

      if (!data.preferredLang) {
        updateData.preferredLang = DEFAULT_LANG;
      }

      if (!data.inputLangHint) {
        updateData.inputLangHint = DEFAULT_LANG;
      }

      if (data.hasCompletedLanguageWizard === undefined) {
        updateData.hasCompletedLanguageWizard = false;
      }

      // 如果沒有需要更新的欄位，跳過
      if (Object.keys(updateData).length === 0) {
        console.log(`⏭️  跳過用戶 ${doc.id}（無需更新）`);
        skippedCount++;
        continue;
      }

      // 添加更新時間
      updateData.updatedAt = admin.firestore.FieldValue.serverTimestamp();

      // 添加到批次
      batch.update(doc.ref, updateData);
      batchCount++;
      updatedCount++;

      console.log(`✅ 準備更新用戶 ${doc.id}:`, updateData);

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
    console.log(`✅ 成功更新：${updatedCount} 個用戶`);
    console.log(`⏭️  跳過：${skippedCount} 個用戶`);
    console.log(`❌ 錯誤：${errorCount} 個用戶`);
    console.log(`📊 總計：${snapshot.size} 個用戶`);
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
    const usersRef = db.collection('users');
    const snapshot = await usersRef.get();

    let successCount = 0;
    let missingCount = 0;

    for (const doc of snapshot.docs) {
      const data = doc.data();

      if (data.preferredLang && data.inputLangHint && data.hasCompletedLanguageWizard !== undefined) {
        successCount++;
      } else {
        missingCount++;
        console.log(`⚠️  用戶 ${doc.id} 缺少語言設定:`, {
          preferredLang: data.preferredLang,
          inputLangHint: data.inputLangHint,
          hasCompletedLanguageWizard: data.hasCompletedLanguageWizard,
        });
      }
    }

    console.log('\n' + '='.repeat(60));
    console.log('📊 驗證結果：');
    console.log('='.repeat(60));
    console.log(`✅ 成功：${successCount} 個用戶`);
    console.log(`❌ 缺少語言設定：${missingCount} 個用戶`);
    console.log(`📊 總計：${snapshot.size} 個用戶`);
    console.log('='.repeat(60) + '\n');

    if (missingCount === 0) {
      console.log('🎉 所有用戶都已成功設置語言偏好！\n');
    } else {
      console.log('⚠️  部分用戶缺少語言設定，請檢查日誌\n');
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
    await migrateUserLanguagePreferences();

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

