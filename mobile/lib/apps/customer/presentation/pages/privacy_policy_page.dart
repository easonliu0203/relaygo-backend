import 'package:flutter/material.dart';

/// 客戶端隱私權政策頁面
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('隱私權政策'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題
            const Text(
              'RELAY GO 隱私權政策 (客戶端草案範本)',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2196F3),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '生效日期：[請填入您的生效日期，例如：2025 年 10 月 25 日]',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),

            // 1. 導言
            _buildSectionTitle('1. 導言'),
            _buildParagraph(
              '歡迎您使用 RELAY GO（以下簡稱「本平台」）。我們致力於保護您的個人隱私權。本隱私權政策旨在說明當您使用 RELAY GO App 及其相關服務（以下簡稱「本服務」）時，我們如何收集、使用、處理及保護您的個人資訊。\n在您使用本服務前，請務必詳細閱讀並同意本政策。',
            ),

            // 2. 我們收集的資訊
            _buildSectionTitle('2. 我們收集的資訊'),
            _buildParagraph(
              '為提供完整的包車預約、支付及客戶服務,我們需要您提供以下「必填」資訊：',
            ),
            _buildSubsectionTitle('A. 註冊與個人檔案資料：'),
            _buildBulletPoint('姓名：用於訂單建立、司機稱呼及身份核對。'),
            _buildBulletPoint('電話號碼：用於帳號驗證、訂單重要聯絡（例如司機聯繫您）。'),
            _buildBulletPoint('電子信箱：用於帳號管理、接收訂單收據及重要通知。'),
            const SizedBox(height: 12),

            _buildSubsectionTitle('B. 支付款項資料（安全處理）：'),
            _buildBulletPoint(
              '信用卡資訊：當您新增付款方式時，您的完整信用卡資料（卡號、效期、安全碼）將被直接傳送至我們符合 PCI-DSS 規範的第三方支付服務提供商（例如：[請填入您的金流商名稱，如 Stripe, 綠界, 藍新]）。',
            ),
            _buildBulletPoint(
              '重要提示：RELAY GO 不會在我們的伺服器上儲存、處理或保留您完整的信用卡號。我們僅會儲存由支付服務商提供的「支付代幣 (Token)」及卡片末四碼，以便您在未來快速支付款項。',
            ),
            const SizedBox(height: 12),

            _buildSubsectionTitle('C. 自動收集的資訊：'),
            _buildBulletPoint(
              '位置資訊：為提供包車服務，我們會在您使用 App 期間（僅限 App 開啟時）收集您的精確地理位置，用於設定上車點、行程規劃、導航及安全確認。',
            ),
            _buildBulletPoint(
              '交易資訊：您透過本服務的訂單記錄、行程時間、地點、支付金額及服務詳情。',
            ),
            _buildBulletPoint(
              '裝置與使用資訊：您的裝置型號、作業系統、IP 位址、App 版本及使用日誌，用於優化服務及排除錯誤。',
            ),

            // 3. 資訊的使用目的
            _buildSectionTitle('3. 資訊的使用目的'),
            _buildParagraph('我們收集您的資訊，主要用於以下目的：'),
            _buildSubsectionTitle('A. 訂單資料與服務提供：'),
            _buildBulletPoint('處理您的包車預約及行程安排。'),
            _buildBulletPoint('將您的上車地點和姓名資訊提供給為您服務的司機。'),
            _buildBulletPoint('計算車資及費用。'),
            const SizedBox(height: 12),

            _buildSubsectionTitle('B. 重要聯絡：'),
            _buildBulletPoint('發送帳號驗證碼。'),
            _buildBulletPoint('發送訂單狀態通知（例如：司機已接單、司機已抵達）。'),
            _buildBulletPoint('發送行程收據或重要營運公告。'),
            const SizedBox(height: 12),

            _buildSubsectionTitle('C. 支付款項：'),
            _buildBulletPoint('使用您儲存的支付代幣，向您收取行程費用。'),
            _buildBulletPoint('處理退款或支付爭議。'),
            const SizedBox(height: 12),

            _buildSubsectionTitle('D. 安全與客戶服務：'),
            _buildBulletPoint('驗證您的身份，防止詐騙或未經授權的活動。'),
            _buildBulletPoint('回應您的客服請求及爭議調解。'),

            // 4. 資訊的分享與揭露
            _buildSectionTitle('4. 資訊的分享與揭露'),
            _buildParagraph('我們不會將您的個人資訊出售給第三方。僅在以下必要情況下，我們會分享您的資訊：'),
            _buildSubsectionTitle('A. 分享給司機：'),
            _buildParagraph(
              '為完成您的預約，我們會將您的姓名、上車地點及目的地分享給接單的司機。為保護雙方隱私，我們建議您使用 App 內建的通訊功能（聊天或遮罩電話）與司機聯繫。',
            ),
            _buildSubsectionTitle('B. 支付服務商：'),
            _buildParagraph('如上所述，為處理支付，您的資訊會被分享給我們的金流合作夥伴。'),
            _buildSubsectionTitle('C. 法律要求：'),
            _buildParagraph('依據法律、法規、法院命令或政府機關的合法要求。'),

            // 5. 資料安全與儲存
            _buildSectionTitle('5. 資料安全與儲存'),
            _buildParagraph(
              '我們採用業界標準的安全措施（例如 SSL 加密傳輸）來保護您的資料，防止未經授權的存取、竄改或洩露。您的個人資料儲存於受嚴格安全控管的雲端伺服器（例如：Firebase 及 Supabase）。',
            ),

            // 6. 您的權利
            _buildSectionTitle('6. 您的權利'),
            _buildParagraph('您對您的個人資料擁有多項權利：'),
            _buildSubsectionTitle('A. 存取與修改：'),
            _buildParagraph('您可以隨時登入 App，在「個人檔案」頁面查看並修改您的姓名、電話或電子信箱。'),
            _buildSubsectionTitle('B. 刪除帳號：'),
            _buildParagraph('您可以透過 App 內的設定或聯繫客服，請求刪除您的 RELAY GO 帳號。'),
            _buildSubsectionTitle('C. 撤回同意：'),
            _buildParagraph(
              '您可以隨時透過手機的系統設定，關閉本 App 的位置資訊存取權限（但這可能導致您無法使用包車服務）。',
            ),

            // 7. 隱私權政策變更
            _buildSectionTitle('7. 隱私權政策變更'),
            _buildParagraph(
              '我們可能隨時修訂本政策。若有重大變更，我們將透過 App 推播通知或您註冊的電子信箱通知您。',
            ),

            // 8. 聯絡我們
            _buildSectionTitle('8. 聯絡我們'),
            _buildParagraph('若您對本隱私權政策有任何疑問，請透過以下方式與我們聯繫：'),
            _buildParagraph('RELAY GO 營運團隊'),
            _buildParagraph('電子信箱：[請填入客服信箱]'),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2196F3),
        ),
      ),
    );
  }

  Widget _buildSubsectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          height: 1.6,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

