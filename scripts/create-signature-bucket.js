/**
 * 創建 Supabase Storage bucket 用於儲存支付簽名圖片
 * 
 * 執行方式：
 * node scripts/create-signature-bucket.js
 */

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL || '',
  process.env.SUPABASE_SERVICE_ROLE_KEY || ''
);

async function createSignatureBucket() {
  console.log('🚀 開始創建 Supabase Storage bucket...\n');

  try {
    // 1. 檢查 bucket 是否已存在
    const { data: buckets, error: listError } = await supabase.storage.listBuckets();
    
    if (listError) {
      console.error('❌ 列出 buckets 失敗:', listError);
      return;
    }

    const bucketName = 'payment-signatures';
    const existingBucket = buckets?.find(b => b.name === bucketName);

    if (existingBucket) {
      console.log(`✅ Bucket "${bucketName}" 已存在`);
      console.log(`   ID: ${existingBucket.id}`);
      console.log(`   公開: ${existingBucket.public}`);
      console.log(`   創建時間: ${existingBucket.created_at}\n`);
      return;
    }

    // 2. 創建新 bucket
    console.log(`📦 創建新 bucket "${bucketName}"...`);
    
    const { data: newBucket, error: createError } = await supabase.storage.createBucket(bucketName, {
      public: true,
      fileSizeLimit: 5242880,  // 5MB
      allowedMimeTypes: ['image/png', 'image/jpeg', 'image/jpg']
    });

    if (createError) {
      console.error('❌ 創建 bucket 失敗:', createError);
      return;
    }

    console.log(`✅ Bucket "${bucketName}" 創建成功！\n`);

    // 3. 測試上傳功能
    console.log('🧪 測試上傳功能...');
    
    const testImageBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
    const testImageBuffer = Buffer.from(testImageBase64, 'base64');
    const testFileName = `test-${Date.now()}.png`;

    const { data: uploadData, error: uploadError } = await supabase.storage
      .from(bucketName)
      .upload(testFileName, testImageBuffer, {
        contentType: 'image/png',
        cacheControl: '3600',
        upsert: false
      });

    if (uploadError) {
      console.error('❌ 測試上傳失敗:', uploadError);
      return;
    }

    console.log(`✅ 測試上傳成功！`);
    console.log(`   文件路徑: ${uploadData.path}\n`);

    // 4. 獲取公開 URL
    const { data: publicUrlData } = supabase.storage
      .from(bucketName)
      .getPublicUrl(testFileName);

    console.log(`🔗 公開 URL: ${publicUrlData.publicUrl}\n`);

    // 5. 刪除測試文件
    console.log('🧹 清理測試文件...');
    const { error: deleteError } = await supabase.storage
      .from(bucketName)
      .remove([testFileName]);

    if (deleteError) {
      console.error('⚠️  刪除測試文件失敗:', deleteError);
    } else {
      console.log('✅ 測試文件已刪除\n');
    }

    // 6. 顯示配置摘要
    console.log('📋 配置摘要:');
    console.log('─────────────────────────────────────');
    console.log(`Bucket 名稱: ${bucketName}`);
    console.log(`公開訪問: 是`);
    console.log(`文件大小限制: 5MB`);
    console.log(`允許的文件類型: image/png, image/jpeg, image/jpg`);
    console.log(`公開 URL 格式: ${process.env.SUPABASE_URL}/storage/v1/object/public/${bucketName}/{filename}`);
    console.log('─────────────────────────────────────\n');

    console.log('✅ Supabase Storage 設置完成！');

  } catch (error) {
    console.error('❌ 設置過程中發生錯誤:', error);
  }
}

// 執行設置
createSignatureBucket();

