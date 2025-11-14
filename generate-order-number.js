// 生成訂單編號用於測試
const bookingId = '9144d669-8c84-4484-8be1-cced0040a32b';
const paymentType = 'B'; // B = Balance (尾款)

// 移除 UUID 中的連字符，取前 16 個字符
const bookingIdClean = bookingId.replace(/-/g, '').substring(0, 16);

// 生成時間戳（取最後 8 位數字）
const timestamp = Date.now().toString().slice(-8);

// 組合訂單編號：{16字符bookingId}{1字符類型}{8字符時間戳}
const orderNumber = `${bookingIdClean}${paymentType}${timestamp}`;

console.log('========================================');
console.log('生成 GOMYPAY 訂單編號');
console.log('========================================');
console.log('訂單 ID:', bookingId);
console.log('支付類型:', paymentType === 'D' ? 'Deposit (訂金)' : 'Balance (尾款)');
console.log('');
console.log('訂單編號:', orderNumber);
console.log('長度:', orderNumber.length, '字符');
console.log('');
console.log('組成部分:');
console.log('  - bookingId (16字符):', bookingIdClean);
console.log('  - 類型 (1字符):', paymentType);
console.log('  - 時間戳 (8字符):', timestamp);
console.log('========================================');

