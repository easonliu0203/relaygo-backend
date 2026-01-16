/**
 * 測試郵件發送功能
 * 
 * 使用方法：
 * 1. 確保 .env 文件中設置了 RESEND_API_KEY
 * 2. 運行：node test-email.js
 */

require('dotenv').config();
const { Resend } = require('resend');

async function testEmail() {
  console.log('開始測試郵件發送...\n');

  // 檢查 API Key
  const apiKey = process.env.RESEND_API_KEY;
  if (!apiKey) {
    console.error('❌ 錯誤：未設置 RESEND_API_KEY 環境變數');
    console.log('請在 .env 文件中添加：');
    console.log('RESEND_API_KEY=re_xxxxxxxxxxxxxxxxxxxxxxxxxx\n');
    process.exit(1);
  }

  console.log('✅ 找到 RESEND_API_KEY');
  console.log(`   Key 前綴: ${apiKey.substring(0, 10)}...\n`);

  // 初始化 Resend
  const resend = new Resend(apiKey);

  // 測試郵件內容
  const testEmail = {
    from: 'RelayGo <send@relaygo.pro>',
    to: 'dev@relaygo.com', // 修改為您的測試郵箱
    subject: 'RelayGo 郵件服務測試',
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <style>
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
          }
          .container {
            background-color: #ffffff;
            border-radius: 8px;
            padding: 30px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
          }
          .header {
            text-align: center;
            border-bottom: 3px solid #4CAF50;
            padding-bottom: 20px;
            margin-bottom: 30px;
          }
          h1 {
            color: #4CAF50;
            margin: 0;
          }
          .content {
            margin: 20px 0;
          }
          .footer {
            text-align: center;
            margin-top: 30px;
            padding-top: 20px;
            border-top: 2px solid #e0e0e0;
            color: #666;
            font-size: 14px;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>RelayGo 郵件服務測試</h1>
          </div>
          <div class="content">
            <p>您好，</p>
            <p>這是一封測試郵件，用於驗證 RelayGo 電子收據郵件功能是否正常運作。</p>
            <p>如果您收到這封郵件，表示郵件服務配置成功！</p>
            <p><strong>測試時間：</strong> ${new Date().toLocaleString('zh-TW', { timeZone: 'Asia/Taipei' })}</p>
          </div>
          <div class="footer">
            <p>RelayGo - 您的專業包車服務平台</p>
            <p>support@relaygo.pro</p>
          </div>
        </div>
      </body>
      </html>
    `
  };

  console.log('發送測試郵件...');
  console.log(`收件人: ${testEmail.to}\n`);

  try {
    const { data, error } = await resend.emails.send(testEmail);

    if (error) {
      console.error('❌ 發送失敗:', error);
      process.exit(1);
    }

    console.log('✅ 郵件發送成功！');
    console.log(`   Message ID: ${data.id}\n`);
    console.log('請檢查您的郵箱（包括垃圾郵件資料夾）');
  } catch (error) {
    console.error('❌ 發送異常:', error.message);
    process.exit(1);
  }
}

// 執行測試
testEmail();

