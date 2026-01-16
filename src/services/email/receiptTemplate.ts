import moment from 'moment-timezone';

/**
 * 收據資料介面
 */
export interface ReceiptData {
  // 訂單資訊
  bookingNumber: string;
  bookingDate: string;
  bookingTime: string;
  
  // 客戶資訊
  customerName: string;
  customerEmail: string;
  customerPhone?: string;
  
  // 服務詳情
  pickupLocation: string;
  dropoffLocation?: string;
  vehicleType: string;
  durationHours: number;
  
  // 司機資訊（如果已分配）
  driverName?: string;
  driverPhone?: string;
  vehiclePlate?: string;
  
  // 費用明細
  paymentType: 'deposit' | 'balance';
  basePrice: number;
  depositAmount?: number;
  balanceAmount?: number;
  overtimeFee?: number;
  tipAmount?: number;
  totalAmount: number;
  paidAmount: number;
  
  // 支付資訊
  transactionId: string;
  paymentMethod: string;
  paymentDate: string;
  
  // 語言
  language: string;
}

/**
 * 多語言文字
 */
const translations: Record<string, any> = {
  'zh-TW': {
    title: '電子收據',
    receiptFor: '收據類型',
    depositReceipt: '訂金收據',
    fullReceipt: '完整收據',
    orderInfo: '訂單資訊',
    bookingNumber: '訂單編號',
    bookingDate: '預約日期',
    bookingTime: '預約時間',
    customerInfo: '客戶資訊',
    name: '姓名',
    email: '電子郵件',
    phone: '聯絡電話',
    serviceDetails: '服務詳情',
    pickupLocation: '上車地點',
    dropoffLocation: '下車地點',
    vehicleType: '車型',
    duration: '時長',
    hours: '小時',
    driverInfo: '司機資訊',
    driverName: '司機姓名',
    driverPhone: '司機電話',
    vehiclePlate: '車牌號碼',
    feeBreakdown: '費用明細',
    basePrice: '基本費用',
    depositAmount: '訂金金額',
    balanceAmount: '尾款金額',
    overtimeFee: '超時費用',
    tipAmount: '小費',
    totalAmount: '總金額',
    paidAmount: '已支付金額',
    paymentInfo: '支付資訊',
    transactionId: '交易編號',
    paymentMethod: '支付方式',
    paymentDate: '支付日期',
    footer: '感謝您使用 RelayGo 服務',
    contact: '如有任何問題，請聯繫我們：support@relaygo.pro',
    companyInfo: 'RelayGo - 您的專業包車服務平台'
  },
  'zh-CN': {
    title: '电子收据',
    receiptFor: '收据类型',
    depositReceipt: '订金收据',
    fullReceipt: '完整收据',
    orderInfo: '订单信息',
    bookingNumber: '订单编号',
    bookingDate: '预约日期',
    bookingTime: '预约时间',
    customerInfo: '客户信息',
    name: '姓名',
    email: '电子邮件',
    phone: '联系电话',
    serviceDetails: '服务详情',
    pickupLocation: '上车地点',
    dropoffLocation: '下车地点',
    vehicleType: '车型',
    duration: '时长',
    hours: '小时',
    driverInfo: '司机信息',
    driverName: '司机姓名',
    driverPhone: '司机电话',
    vehiclePlate: '车牌号码',
    feeBreakdown: '费用明细',
    basePrice: '基本费用',
    depositAmount: '订金金额',
    balanceAmount: '尾款金额',
    overtimeFee: '超时费用',
    tipAmount: '小费',
    totalAmount: '总金额',
    paidAmount: '已支付金额',
    paymentInfo: '支付信息',
    transactionId: '交易编号',
    paymentMethod: '支付方式',
    paymentDate: '支付日期',
    footer: '感谢您使用 RelayGo 服务',
    contact: '如有任何问题，请联系我们：support@relaygo.pro',
    companyInfo: 'RelayGo - 您的专业包车服务平台'
  },
  'en': {
    title: 'Electronic Receipt',
    receiptFor: 'Receipt Type',
    depositReceipt: 'Deposit Receipt',
    fullReceipt: 'Full Receipt',
    orderInfo: 'Order Information',
    bookingNumber: 'Booking Number',
    bookingDate: 'Booking Date',
    bookingTime: 'Booking Time',
    customerInfo: 'Customer Information',
    name: 'Name',
    email: 'Email',
    phone: 'Phone',
    serviceDetails: 'Service Details',
    pickupLocation: 'Pickup Location',
    dropoffLocation: 'Dropoff Location',
    vehicleType: 'Vehicle Type',
    duration: 'Duration',
    hours: 'hours',
    driverInfo: 'Driver Information',
    driverName: 'Driver Name',
    driverPhone: 'Driver Phone',
    vehiclePlate: 'Vehicle Plate',
    feeBreakdown: 'Fee Breakdown',
    basePrice: 'Base Price',
    depositAmount: 'Deposit Amount',
    balanceAmount: 'Balance Amount',
    overtimeFee: 'Overtime Fee',
    tipAmount: 'Tip',
    totalAmount: 'Total Amount',
    paidAmount: 'Paid Amount',
    paymentInfo: 'Payment Information',
    transactionId: 'Transaction ID',
    paymentMethod: 'Payment Method',
    paymentDate: 'Payment Date',
    footer: 'Thank you for using RelayGo',
    contact: 'For any questions, please contact us: support@relaygo.pro',
    companyInfo: 'RelayGo - Your Professional Charter Service Platform'
  }
};

/**
 * 格式化金額
 */
function formatCurrency(amount: number, language: string): string {
  if (language.startsWith('zh')) {
    return `NT$ ${amount.toLocaleString('zh-TW')}`;
  }
  return `NT$ ${amount.toLocaleString('en-US')}`;
}

/**
 * 生成收據 HTML
 */
export function generateReceiptHtml(data: ReceiptData): string {
  const lang = data.language || 'zh-TW';
  const t = translations[lang] || translations['zh-TW'];

  const receiptType = data.paymentType === 'deposit' ? t.depositReceipt : t.fullReceipt;

  return `
<!DOCTYPE html>
<html lang="${lang}">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${t.title} - ${data.bookingNumber}</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'PingFang TC', 'Microsoft JhengHei', sans-serif;
      line-height: 1.6;
      color: #333;
      max-width: 600px;
      margin: 0 auto;
      padding: 20px;
      background-color: #f5f5f5;
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
    .header h1 {
      color: #4CAF50;
      margin: 0;
      font-size: 28px;
    }
    .header p {
      color: #666;
      margin: 10px 0 0 0;
      font-size: 16px;
    }
    .section {
      margin-bottom: 25px;
    }
    .section-title {
      font-size: 18px;
      font-weight: bold;
      color: #4CAF50;
      margin-bottom: 12px;
      padding-bottom: 8px;
      border-bottom: 2px solid #e0e0e0;
    }
    .info-row {
      display: flex;
      justify-content: space-between;
      padding: 8px 0;
      border-bottom: 1px solid #f0f0f0;
    }
    .info-label {
      color: #666;
      font-weight: 500;
    }
    .info-value {
      color: #333;
      font-weight: 600;
      text-align: right;
    }
    .total-row {
      background-color: #f9f9f9;
      padding: 12px;
      margin-top: 10px;
      border-radius: 4px;
      font-size: 18px;
      font-weight: bold;
    }
    .footer {
      text-align: center;
      margin-top: 30px;
      padding-top: 20px;
      border-top: 2px solid #e0e0e0;
      color: #666;
      font-size: 14px;
    }
    .footer p {
      margin: 8px 0;
    }
    @media (max-width: 600px) {
      body {
        padding: 10px;
      }
      .container {
        padding: 20px;
      }
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>${t.title}</h1>
      <p>${t.receiptFor}: ${receiptType}</p>
    </div>

    <!-- 訂單資訊 -->
    <div class="section">
      <div class="section-title">${t.orderInfo}</div>
      <div class="info-row">
        <span class="info-label">${t.bookingNumber}</span>
        <span class="info-value">${data.bookingNumber}</span>
      </div>
      <div class="info-row">
        <span class="info-label">${t.bookingDate}</span>
        <span class="info-value">${data.bookingDate}</span>
      </div>
      <div class="info-row">
        <span class="info-label">${t.bookingTime}</span>
        <span class="info-value">${data.bookingTime}</span>
      </div>
    </div>

    <!-- 客戶資訊 -->
    <div class="section">
      <div class="section-title">${t.customerInfo}</div>
      <div class="info-row">
        <span class="info-label">${t.name}</span>
        <span class="info-value">${data.customerName}</span>
      </div>
      <div class="info-row">
        <span class="info-label">${t.email}</span>
        <span class="info-value">${data.customerEmail}</span>
      </div>
      ${data.customerPhone ? `
      <div class="info-row">
        <span class="info-label">${t.phone}</span>
        <span class="info-value">${data.customerPhone}</span>
      </div>
      ` : ''}
    </div>

    <!-- 服務詳情 -->
    <div class="section">
      <div class="section-title">${t.serviceDetails}</div>
      <div class="info-row">
        <span class="info-label">${t.pickupLocation}</span>
        <span class="info-value">${data.pickupLocation}</span>
      </div>
      ${data.dropoffLocation ? `
      <div class="info-row">
        <span class="info-label">${t.dropoffLocation}</span>
        <span class="info-value">${data.dropoffLocation}</span>
      </div>
      ` : ''}
      <div class="info-row">
        <span class="info-label">${t.vehicleType}</span>
        <span class="info-value">${data.vehicleType}</span>
      </div>
      <div class="info-row">
        <span class="info-label">${t.duration}</span>
        <span class="info-value">${data.durationHours} ${t.hours}</span>
      </div>
    </div>

    ${data.driverName ? `
    <!-- 司機資訊 -->
    <div class="section">
      <div class="section-title">${t.driverInfo}</div>
      <div class="info-row">
        <span class="info-label">${t.driverName}</span>
        <span class="info-value">${data.driverName}</span>
      </div>
      ${data.driverPhone ? `
      <div class="info-row">
        <span class="info-label">${t.driverPhone}</span>
        <span class="info-value">${data.driverPhone}</span>
      </div>
      ` : ''}
      ${data.vehiclePlate ? `
      <div class="info-row">
        <span class="info-label">${t.vehiclePlate}</span>
        <span class="info-value">${data.vehiclePlate}</span>
      </div>
      ` : ''}
    </div>
    ` : ''}

    <!-- 費用明細 -->
    <div class="section">
      <div class="section-title">${t.feeBreakdown}</div>
      <div class="info-row">
        <span class="info-label">${t.basePrice}</span>
        <span class="info-value">${formatCurrency(data.basePrice, lang)}</span>
      </div>
      ${data.depositAmount ? `
      <div class="info-row">
        <span class="info-label">${t.depositAmount}</span>
        <span class="info-value">${formatCurrency(data.depositAmount, lang)}</span>
      </div>
      ` : ''}
      ${data.balanceAmount ? `
      <div class="info-row">
        <span class="info-label">${t.balanceAmount}</span>
        <span class="info-value">${formatCurrency(data.balanceAmount, lang)}</span>
      </div>
      ` : ''}
      ${data.overtimeFee && data.overtimeFee > 0 ? `
      <div class="info-row">
        <span class="info-label">${t.overtimeFee}</span>
        <span class="info-value">${formatCurrency(data.overtimeFee, lang)}</span>
      </div>
      ` : ''}
      ${data.tipAmount && data.tipAmount > 0 ? `
      <div class="info-row">
        <span class="info-label">${t.tipAmount}</span>
        <span class="info-value">${formatCurrency(data.tipAmount, lang)}</span>
      </div>
      ` : ''}
      <div class="info-row total-row">
        <span class="info-label">${t.paidAmount}</span>
        <span class="info-value">${formatCurrency(data.paidAmount, lang)}</span>
      </div>
    </div>

    <!-- 支付資訊 -->
    <div class="section">
      <div class="section-title">${t.paymentInfo}</div>
      <div class="info-row">
        <span class="info-label">${t.transactionId}</span>
        <span class="info-value">${data.transactionId}</span>
      </div>
      <div class="info-row">
        <span class="info-label">${t.paymentMethod}</span>
        <span class="info-value">${data.paymentMethod}</span>
      </div>
      <div class="info-row">
        <span class="info-label">${t.paymentDate}</span>
        <span class="info-value">${data.paymentDate}</span>
      </div>
    </div>

    <!-- 頁尾 -->
    <div class="footer">
      <p><strong>${t.footer}</strong></p>
      <p>${t.contact}</p>
      <p>${t.companyInfo}</p>
    </div>
  </div>
</body>
</html>
  `.trim();
}

