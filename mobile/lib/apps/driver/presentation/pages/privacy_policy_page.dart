import 'package:flutter/material.dart';

/// 司機端隱私權政策頁面
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('隱私權政策'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題
            const Text(
              'RELAY GO 司機端隱私權政策 (草案範本)',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4CAF50),
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
              '歡迎您申請加入 RELAY GO 司機夥伴（以下簡稱「本平台」）。我們致力於保護您的個人隱私權。本隱私權政策旨在說明當您註冊及使用 RELAY GO 司機端 App 及其相關服務（以下簡稱「本服務」）時，我們如何收集、使用、處理及保護您的個人資訊。\n在您註冊成為司機夥伴前，請務必詳細閱讀並同意本政策。',
            ),

            // 2. 我們收集的資訊
            _buildSectionTitle('2. 我們收集的資訊'),
            _buildParagraph(
              '為遵守台灣交通法規對包車司機資格的規範，並為您提供接單及帳務服務，我們需要您提供以下「必填」資訊：',
            ),
            _buildSubsectionTitle('A. 身份驗證與合法資格審核資料：'),
            _buildBulletPoint('姓名、身分證字號及影像：用於核實您的真實身份。'),
            _buildBulletPoint('職業駕照影像：用於確認您具備合法的駕駛資格。'),
            _buildBulletPoint('良民證（警察刑事紀錄證明書）：依據法規要求，確認您符合職業駕駛的無犯罪紀錄標準。'),
            _buildBulletPoint('無肇事紀錄（駕駛執照經歷證明書）：用於確認您的駕駛安全紀錄。'),
            _buildBulletPoint(
              '車輛資料：車輛行照、汽車保險（強制險及乘客責任險）證明，以確保車輛符合營運標準及乘客安全保障。',
            ),
            _buildBulletPoint('靠行公司資訊（如適用）：包含公司名稱與統一編號，用於確認車輛歸屬及營運合法性。'),
            const SizedBox(height: 12),

            _buildSubsectionTitle('B. 帳務與聯絡資料：'),
            _buildBulletPoint(
              '銀行收款帳戶：包含銀行名稱、分行代碼及帳號，僅用於向您轉帳支付您的服務款項（車資）。',
            ),
            _buildBulletPoint('電話號碼：用於帳號驗證、接收訂單通知、乘客聯繫及平台重要聯絡。'),
            _buildBulletPoint('電子信箱：用於帳號管理、接收帳務報表及重要通知。'),
            _buildBulletPoint('住址：用於文件寄送及確認營運區域。'),
            const SizedBox(height: 12),

            _buildSubsectionTitle('C. 自動收集的資訊（使用服務期間）：'),
            _buildBulletPoint(
              '精確地理位置：我們會在您上線接單期間，持續收集您的精確地理位置，用於派發訂單、行程導航、計算費用及確保行程安全。',
            ),
            _buildBulletPoint('行程與交易資訊：您完成的訂單記錄、行程時間、路線、收款金額及乘客評價。'),
            _buildBulletPoint(
              'App 使用資訊：您的裝置型號、作業系統、IP 位址及 App 操作日誌，用於優化服務及排除錯誤。',
            ),

            // 3. 資訊的使用目的
            _buildSectionTitle('3. 資訊的使用目的'),
            _buildParagraph('我們承諾僅將您的資訊用於以下特定目的：'),
            _buildSubsectionTitle('A. 合法司機資格核對（主要目的）：'),
            _buildParagraph(
              '將您提供的身分證、駕照、良民證、無肇事紀錄等文件，用於內部審核及（必要時）提交給主管機關，以驗證您在台灣作為包車服務司機的合法性與合規性。',
            ),
            _buildSubsectionTitle('B. 轉帳給司機（主要目的）：'),
            _buildParagraph('使用您提供的收款帳戶資訊，定期將您應得的車資結算並轉帳給您。'),
            _buildParagraph('製作並寄送帳務報表或年度扣繳憑單。'),
            const SizedBox(height: 12),

            _buildSubsectionTitle('C. 營運與派單：'),
            _buildBulletPoint('根據您的即時位置，向您派發最合適的乘客訂單。'),
            _buildBulletPoint('向乘客顯示您的姓名、車輛資訊（車型、車號）及預計抵達時間。'),
            const SizedBox(height: 12),

            _buildSubsectionTitle('D. 安全與客服：'),
            _buildBulletPoint('在行程中監控位置以保障司機與乘客安全。'),
            _buildBulletPoint('處理乘客的客訴或行程爭議。'),
            _buildBulletPoint('回應您的客服請求。'),

            // 4. 資訊的分享與揭露
            _buildSectionTitle('4. 資訊的分享與揭露'),
            _buildParagraph('我們對您的敏感資料（特別是身份文件）採取最高級別的保護，僅在必要時分享：'),
            _buildSubsectionTitle('A. 分享給乘客：'),
            _buildParagraph(
              '當您接單後，乘客將能看到您的姓名（或暱稱）、駕駛照片、車輛型號及車牌號碼，以便乘客辨識及安心上車。您的電話號碼將被遮罩，乘客僅能透過 App 內建通訊功能聯繫您。',
            ),
            _buildSubsectionTitle('B. 主管機關要求：'),
            _buildParagraph(
              '依據台灣法律或交通主管機關（如交通部、監理所）的合法要求，我們可能需要提供您的身份及營運資料以供查核。',
            ),
            _buildSubsectionTitle('C. 帳務處理：'),
            _buildParagraph('您的收款帳戶資訊僅會分享給執行轉帳作業的金融機構（銀行）。'),

            // 5. 資料安全與儲存
            _buildSectionTitle('5. 資料安全與儲存'),
            _buildParagraph('我們理解司機身份文件的敏感性。'),
            _buildSubsectionTitle('A. 存取限制：'),
            _buildParagraph(
              '您所提供的所有身份驗證文件（身分證、駕照、良民證等）將被儲存在受高度安全管制的伺服器（如 Firebase Storage / Supabase Storage）中，並採用嚴格的存取控制，僅有經授權的營運審核人員才能在必要時（例如首次審核或年度複查）存取。',
            ),
            _buildSubsectionTitle('B. 加密保護：'),
            _buildParagraph('所有資料在傳輸及儲存過程中均使用 SSL 及伺服器端加密技術保護。'),

            // 6. 您的權利
            _buildSectionTitle('6. 您的權利'),
            _buildSubsectionTitle('A. 存取與修改：'),
            _buildParagraph('您可以隨時登入 App 查看您的個人檔案、收款帳戶及車輛資訊，並可請求修改錯誤的資料。'),
            _buildSubsectionTitle('B. 刪除帳號（結束合作）：'),
            _buildParagraph(
              '當您決定不再與本平台合作時，您可以請求刪除您的帳號。依據法規，我們可能需要在特定期限內（例如帳務或稅務規定）保留您的部分交易及身份資料備查，待期限屆滿後將予以刪除。',
            ),

            // 7. 隱私權政策變更
            _buildSectionTitle('7. 隱私權政策變更'),
            _buildParagraph(
              '我們可能隨時修訂本政策。若有重大變更，我們將透過 App 推播通知或您註冊的電子信箱通知您。',
            ),

            // 8. 聯絡我們
            _buildSectionTitle('8. 聯絡我們'),
            _buildParagraph('若您對本隱私權政策或您的資料處理有任何疑問，請透過以下方式與我們聯繫：'),
            _buildParagraph('RELAY GO 司機夥伴營運團隊'),
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
          color: Color(0xFF4CAF50),
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

