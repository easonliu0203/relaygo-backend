#!/usr/bin/env node

/**
 * OpenAI API 配額測試腳本
 * 
 * 用途：
 * 1. 測試 OpenAI API 連線狀態
 * 2. 檢查配額是否可用
 * 3. 診斷錯誤類型
 * 
 * 使用方式：
 * node test-openai-quota.js
 * 
 * 或使用環境變數：
 * OPENAI_API_KEY=sk-xxx node test-openai-quota.js
 */

const OpenAI = require('openai');

// 顏色輸出
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

async function testOpenAIQuota() {
  log('\n🧪 OpenAI API 配額測試', 'bright');
  log('='.repeat(60), 'cyan');
  
  // 1. 檢查 API 金鑰
  const apiKey = process.env.OPENAI_API_KEY;
  
  if (!apiKey) {
    log('\n❌ 錯誤：未設定 OPENAI_API_KEY 環境變數', 'red');
    log('\n請執行以下指令之一：', 'yellow');
    log('  export OPENAI_API_KEY="sk-proj-xxx..."', 'cyan');
    log('  或', 'yellow');
    log('  OPENAI_API_KEY="sk-proj-xxx..." node test-openai-quota.js', 'cyan');
    process.exit(1);
  }
  
  log(`\n✅ API 金鑰已設定 (${apiKey.substring(0, 20)}...)`, 'green');
  
  // 2. 創建 OpenAI 客戶端
  const client = new OpenAI({ apiKey });
  
  log('\n📡 正在測試 OpenAI API 連線...', 'blue');
  
  try {
    const startTime = Date.now();
    
    // 3. 發送測試請求
    const response = await client.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'user',
          content: 'Translate to English: 你好',
        },
      ],
      max_tokens: 50,
    });
    
    const duration = Date.now() - startTime;
    
    // 4. 顯示成功結果
    log('\n✅ OpenAI API 連線成功！', 'green');
    log('='.repeat(60), 'cyan');
    
    log('\n📊 測試結果：', 'bright');
    log(`  ⏱️  回應時間: ${duration}ms`, 'cyan');
    log(`  🔤 翻譯結果: ${response.choices[0].message.content}`, 'cyan');
    log(`  🎯 模型: ${response.model}`, 'cyan');
    log(`  📈 Token 使用:`, 'cyan');
    log(`     - 輸入: ${response.usage.prompt_tokens} tokens`, 'cyan');
    log(`     - 輸出: ${response.usage.completion_tokens} tokens`, 'cyan');
    log(`     - 總計: ${response.usage.total_tokens} tokens`, 'cyan');
    
    // 5. 成本估算
    const inputCost = (response.usage.prompt_tokens / 1000000) * 0.150;
    const outputCost = (response.usage.completion_tokens / 1000000) * 0.600;
    const totalCost = inputCost + outputCost;
    
    log(`\n💰 成本估算：`, 'bright');
    log(`  - 輸入成本: $${inputCost.toFixed(6)} USD`, 'cyan');
    log(`  - 輸出成本: $${outputCost.toFixed(6)} USD`, 'cyan');
    log(`  - 總成本: $${totalCost.toFixed(6)} USD`, 'cyan');
    
    log('\n✅ 配額狀態：正常', 'green');
    log('='.repeat(60), 'cyan');
    
    log('\n🎉 測試完成！翻譯功能可以正常使用。', 'green');
    
  } catch (error) {
    // 6. 錯誤處理
    log('\n❌ OpenAI API 測試失敗', 'red');
    log('='.repeat(60), 'cyan');
    
    log('\n📋 錯誤詳情：', 'bright');
    log(`  狀態碼: ${error.status || 'N/A'}`, 'yellow');
    log(`  錯誤代碼: ${error.code || 'N/A'}`, 'yellow');
    log(`  錯誤類型: ${error.type || 'N/A'}`, 'yellow');
    log(`  錯誤訊息: ${error.message}`, 'yellow');
    
    // 7. 診斷和建議
    log('\n🔍 診斷結果：', 'bright');
    
    if (error.status === 429) {
      log('  ⚠️  配額已用盡（HTTP 429）', 'red');
      log('\n💡 解決方案：', 'bright');
      log('  1. 前往 OpenAI Platform 檢查帳單狀態', 'cyan');
      log('     https://platform.openai.com/account/billing', 'blue');
      log('  2. 充值帳戶（建議 $10 USD）', 'cyan');
      log('  3. 設定自動充值和使用限制', 'cyan');
      log('  4. 等待 5-10 分鐘後重試', 'cyan');
      
      log('\n📊 成本參考：', 'bright');
      log('  - gpt-4o-mini 輸入: $0.150 / 1M tokens', 'cyan');
      log('  - gpt-4o-mini 輸出: $0.600 / 1M tokens', 'cyan');
      log('  - 每則訊息約: $0.0001 USD (0.01 台幣)', 'cyan');
      log('  - 1000 則訊息/天 × 30 天 ≈ $3 USD/月', 'cyan');
      
    } else if (error.status === 401 || error.status === 403) {
      log('  ⚠️  API 金鑰無效或未授權（HTTP 401/403）', 'red');
      log('\n💡 解決方案：', 'bright');
      log('  1. 檢查 API 金鑰是否正確', 'cyan');
      log('  2. 前往 OpenAI Platform 重新生成金鑰', 'cyan');
      log('     https://platform.openai.com/api-keys', 'blue');
      log('  3. 更新 Secret Manager 中的金鑰', 'cyan');
      log('     echo "新金鑰" | firebase functions:secrets:set OPENAI_API_KEY', 'blue');
      
    } else if (error.status === 503 || error.status === 500) {
      log('  ⚠️  OpenAI API 暫時無法使用（HTTP 500/503）', 'red');
      log('\n💡 解決方案：', 'bright');
      log('  1. 這是 OpenAI 伺服器端問題', 'cyan');
      log('  2. 等待幾分鐘後重試', 'cyan');
      log('  3. 檢查 OpenAI 狀態頁面', 'cyan');
      log('     https://status.openai.com/', 'blue');
      
    } else if (error.code === 'ENOTFOUND') {
      log('  ⚠️  DNS 解析失敗', 'red');
      log('\n💡 解決方案：', 'bright');
      log('  1. 檢查網路連線', 'cyan');
      log('  2. 檢查 DNS 設定', 'cyan');
      log('  3. 嘗試使用其他網路', 'cyan');
      
    } else if (error.code === 'ECONNREFUSED') {
      log('  ⚠️  連線被拒絕', 'red');
      log('\n💡 解決方案：', 'bright');
      log('  1. 檢查防火牆設定', 'cyan');
      log('  2. 檢查代理設定', 'cyan');
      log('  3. 確認 OpenAI API 是否正常運作', 'cyan');
      
    } else if (error.code === 'ETIMEDOUT') {
      log('  ⚠️  請求逾時', 'red');
      log('\n💡 解決方案：', 'bright');
      log('  1. 檢查網路速度', 'cyan');
      log('  2. 重試請求', 'cyan');
      log('  3. 考慮增加逾時時間', 'cyan');
      
    } else {
      log('  ⚠️  未知錯誤', 'red');
      log('\n💡 建議：', 'bright');
      log('  1. 查看完整錯誤訊息', 'cyan');
      log('  2. 檢查 OpenAI API 文檔', 'cyan');
      log('     https://platform.openai.com/docs/guides/error-codes', 'blue');
      log('  3. 聯繫技術支援', 'cyan');
    }
    
    log('\n='.repeat(60), 'cyan');
    process.exit(1);
  }
}

// 執行測試
testOpenAIQuota().catch(error => {
  log(`\n❌ 測試腳本執行失敗: ${error.message}`, 'red');
  process.exit(1);
});

