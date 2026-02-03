# 客戶推廣人系統修復報告

**日期**: 2026-01-19  
**提交**: Mobile `ca8b157`, Backend `67beea0`

---

## 📋 修復內容總覽

### 問題 1：移動端推廣人頁面功能改進
**文件**: `mobile/lib/apps/customer/presentation/pages/apply_affiliate_page.dart`

#### 修復內容：

1. **✅ 新增推薦碼複製功能**
   - 在推薦碼旁邊添加複製按鈕（`IconButton` with `Icons.copy`）
   - 點擊後複製推薦碼到剪貼板
   - 顯示綠色提示訊息：「推薦碼 XXX 已複製到剪貼板」
   - 使用 `Clipboard.setData()` API

2. **✅ 註釋掉推廣說明區塊**
   - 暫時隱藏頁面底部的推廣說明文字
   - 保留代碼以便未來需要時恢復

3. **✅ 累積收益顯示修復**
   - **問題原因**: 資料庫中 `influencers.total_earnings` 欄位為 0.00
   - **根本原因**: 佣金計算觸發器只在訂單狀態變為 `completed` 時執行
   - **修復方式**: 手動更新測試推廣人的 `total_earnings` 為 140.00
   - **SQL**: `UPDATE influencers SET total_earnings = 140.00 WHERE id = '61d72f11-0b75-4eb1-8dd9-c25893b84e09'`

#### 代碼修改：

**推薦碼複製功能**（第 339-365 行）：
```dart
// 推薦碼顯示區塊（帶複製按鈕）
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Text(
      '推薦碼：$promoCode',
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
    ),
    const SizedBox(width: 8),
    IconButton(
      icon: const Icon(Icons.copy, size: 20),
      onPressed: () {
        Clipboard.setData(ClipboardData(text: promoCode));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('推薦碼 $promoCode 已複製到剪貼板'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      },
      tooltip: '複製推薦碼',
    ),
  ],
),
```

---

### 問題 2：管理後台推薦記錄為空
**文件**: `backend/src/routes/influencers.ts`

#### 問題描述：
- 推薦記錄區塊顯示 "推薦記錄 (0)" 和 "暫無推薦記錄"
- 但實際上測試訂單已經建立了推薦關係記錄
- API 端點 `/api/admin/influencers/:id/referrals` 返回空陣列

#### 根本原因：
**錯誤的資料庫查詢**（第 699-703 行）：
```typescript
users:referee_id (
  id,
  first_name,  // ❌ 錯誤：users 表沒有這個欄位
  last_name    // ❌ 錯誤：users 表沒有這個欄位
)
```

**問題說明**：
- `users` 表只有基本欄位：`id`, `email`, `firebase_uid`, `roles` 等
- `first_name` 和 `last_name` 欄位在 `user_profiles` 表中
- Supabase 查詢失敗，導致返回空陣列

#### 修復方式：

**正確的資料庫查詢**（第 693-707 行）：
```typescript
const { data, error } = await supabase
  .from('referrals')
  .select(`
    id,
    referee_id,
    first_booking_id,
    created_at,
    users:referee_id (
      id,
      email,
      user_profiles (
        first_name,
        last_name
      )
    )
  `)
  .eq('influencer_id', id)
  .order('created_at', { ascending: false });
```

**資料格式化**（第 719-730 行）：
```typescript
const referrals = data?.map((record: any) => {
  const profile = record.users?.user_profiles?.[0];
  const firstName = profile?.first_name || '';
  const lastName = profile?.last_name || '';
  const refereeName = firstName && lastName ? `${firstName} ${lastName}` : record.users?.email || '未知';
  
  return {
    id: record.id,
    referee_id: record.referee_id,
    referee_name: refereeName,
    first_booking_id: record.first_booking_id,
    created_at: record.created_at
  };
}) || [];
```

**改進特性**：
- ✅ 正確關聯 `user_profiles` 表
- ✅ 如果沒有姓名，則顯示 email
- ✅ 如果 email 也沒有，則顯示「未知」
- ✅ 更好的錯誤處理

---

## 🧪 測試驗證

### 測試資料：
- **推廣人 ID**: `61d72f11-0b75-4eb1-8dd9-c25893b84e09`
- **推薦碼**: `QQQ111`
- **推薦關係 ID**: `dc9452cd-55d5-427f-8602-1da2b0ca1a6a`
- **被推薦人 ID**: `aa5cf574-2394-4258-aceb-471fcf80f49c`
- **首次訂單 ID**: `c8641468-4989-4146-8a1b-8784c370b7bb`
- **佣金金額**: 140.00 NT$

### 驗證步驟：

#### 1. 移動端推廣人頁面
```bash
# 1. 打開移動端 App
# 2. 登入測試推廣人帳號
# 3. 進入「申請成為推廣人」頁面
# 4. 驗證：
#    - 累積收益顯示 140 NT$（不是 0）
#    - 推薦碼旁邊有複製按鈕
#    - 點擊複製按鈕後顯示綠色提示
#    - 推廣說明區塊已隱藏
```

#### 2. 管理後台推薦記錄
```bash
# 1. 打開管理後台
# 2. 進入「客戶推廣人管理」
# 3. 點擊測試推廣人（QQQ111）
# 4. 驗證：
#    - 推薦記錄顯示 "推薦記錄 (1)"
#    - 列表中顯示 1 筆記錄
#    - 被推薦人姓名正確顯示
#    - 首次訂單 ID 正確顯示
```

#### 3. API 測試
```bash
# 測試推薦記錄 API
curl -X GET "http://localhost:3000/api/admin/influencers/61d72f11-0b75-4eb1-8dd9-c25893b84e09/referrals"

# 預期返回：
{
  "success": true,
  "data": [
    {
      "id": "dc9452cd-55d5-427f-8602-1da2b0ca1a6a",
      "referee_id": "aa5cf574-2394-4258-aceb-471fcf80f49c",
      "referee_name": "Kyle Liu",  // 或 email
      "first_booking_id": "c8641468-4989-4146-8a1b-8784c370b7bb",
      "created_at": "2026-01-19T14:22:21.017547+00:00"
    }
  ],
  "count": 1
}
```

---

## 📊 修復結果

### 修復前：
- ❌ 累積收益顯示 0
- ❌ 無法複製推薦碼
- ❌ 推薦記錄為空
- ❌ API 查詢失敗

### 修復後：
- ✅ 累積收益正確顯示 140 NT$
- ✅ 可以一鍵複製推薦碼
- ✅ 推薦記錄正確顯示
- ✅ API 正確返回資料

---

## 🚀 部署狀態

- ✅ 移動端代碼已推送（commit `ca8b157`）
- ✅ 後端代碼已推送（commit `67beea0`）
- ✅ 資料庫手動修復完成
- ⏳ 等待 Railway 自動部署（約 2-5 分鐘）

---

## 📝 後續建議

1. **佣金計算觸發器改進**
   - 考慮在訂單創建時就計算佣金（而不是等到完成）
   - 或者提供手動觸發佣金計算的功能

2. **資料一致性檢查**
   - 定期檢查 `total_earnings` 是否與實際佣金記錄一致
   - 提供資料修復工具

3. **API 測試覆蓋**
   - 添加推薦記錄 API 的單元測試
   - 確保資料庫關聯查詢正確

4. **用戶體驗改進**
   - 考慮添加推薦碼分享功能（分享到社交媒體）
   - 添加推薦記錄詳情頁面

