# Supabase 即時同步 401 錯誤 - 診斷與修復指南

> **問題**: Database Trigger 調用 Edge Function 時返回 401 Unauthorized  
> **影響**: 即時同步功能無法運作（Cron Job 補償機制仍正常）  
> **修復時間**: 約 5 分鐘

---

## 🔍 問題診斷

### 錯誤詳情

**HTTP 狀態碼**: 401 (Unauthorized)

**錯誤日誌**:
```json
{
  "event_message": "POST | 401 | https://vlyhwegpvpnjyocqmfqc.supabase.co/functions/v1/sync-to-firestore",
  "metadata": [{
    "request": [{
      "headers": [{
        "user_agent": "pg_net/0.19.5",
        "content_length": "102"
      }]
    }],
    "response": [{
      "status_code": 401
    }]
  }]
}
```

---

### 根本原因

**問題**: Database Trigger 無法獲取 `service_role_key`

**證據**:
1. ✅ Trigger 函數嘗試從 `current_setting('app.settings.service_role_key', true)` 獲取 key
2. ❌ 這個設置**沒有在 Supabase 中配置**
3. ❌ 導致 `service_role_key` 為 NULL 或空字符串
4. ❌ HTTP 請求的 `Authorization` header 變成 `Bearer ` 或 `Bearer null`
5. ❌ Edge Function 收到無效的認證 token，返回 401

**相關代碼** (`supabase/migrations/20251016_create_realtime_sync_trigger.sql`):
```sql
-- 從環境變數獲取 Service Role Key
BEGIN
  service_role_key := current_setting('app.settings.service_role_key', true);
EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING 'Unable to get service_role_key: %', SQLERRM;
    RETURN NEW;
END;
```

---

## 🔧 修復方案

### 方案 1: 配置 Service Role Key（推薦）✅

**優點**:
- ✅ 最安全
- ✅ 符合最佳實踐
- ✅ 易於管理

**步驟**:

#### 1. 獲取 Service Role Key

1. 前往 [Supabase Dashboard](https://supabase.com/dashboard)
2. 選擇您的項目 (`vlyhwegpvpnjyocqmfqc`)
3. 前往 **Settings** → **API**
4. 在 **Project API keys** 區塊中，找到 **service_role** key
5. 點擊 **Reveal** 按鈕顯示 key
6. 複製整個 key（以 `eyJ` 開頭的長字符串）

#### 2. 配置 Service Role Key

**在 Supabase SQL Editor 中執行**:

```sql
-- 替換 'YOUR_SERVICE_ROLE_KEY' 為您剛才複製的 key
ALTER DATABASE postgres SET app.settings.service_role_key TO 'YOUR_SERVICE_ROLE_KEY';
```

**範例**:
```sql
ALTER DATABASE postgres SET app.settings.service_role_key TO 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

#### 3. 驗證配置

```sql
-- 檢查配置是否成功
SELECT current_setting('app.settings.service_role_key', true) AS service_role_key_configured;
```

**預期結果**: 應該顯示您的 Service Role Key（或至少顯示前幾個字符）

#### 4. 重新連接數據庫

**重要**: 配置更改後，需要重新連接數據庫才能生效。

1. 在 Supabase SQL Editor 中，點擊右上角的 **Disconnect**
2. 然後點擊 **Connect** 重新連接
3. 或者直接刷新頁面

#### 5. 測試修復

**執行測試腳本**:

```sql
-- 創建測試訂單
DO $$
DECLARE
  test_booking_id UUID;
  test_customer_id UUID;
BEGIN
  -- 獲取測試客戶
  SELECT id INTO test_customer_id
  FROM users
  WHERE role = 'customer'
  LIMIT 1;

  IF test_customer_id IS NULL THEN
    RAISE NOTICE '⚠️  沒有找到測試客戶';
    RETURN;
  END IF;

  -- 創建測試訂單
  INSERT INTO bookings (
    customer_id,
    booking_number,
    status,
    start_date,
    start_time,
    duration_hours,
    vehicle_type,
    pickup_location,
    pickup_latitude,
    pickup_longitude,
    destination,
    base_price,
    total_amount,
    deposit_amount
  ) VALUES (
    test_customer_id,
    'TEST401_' || EXTRACT(EPOCH FROM NOW())::BIGINT,
    'pending_payment',
    CURRENT_DATE + INTERVAL '1 day',
    '10:00:00',
    8,
    'small',
    '測試地點 - 401 修復',
    25.0330,
    121.5654,
    '測試目的地',
    1500.00,
    1500.00,
    450.00
  )
  RETURNING id INTO test_booking_id;

  RAISE NOTICE '✅ 測試訂單已創建: %', test_booking_id;
  
  -- 更新訂單狀態以觸發 Trigger
  UPDATE bookings
  SET status = 'paid_deposit',
      updated_at = NOW()
  WHERE id = test_booking_id;

  RAISE NOTICE '✅ 訂單狀態已更新，應該觸發即時同步';
END $$;
```

#### 6. 檢查結果

**檢查 HTTP 請求記錄**:

```sql
-- 查詢最近的 HTTP 請求
SELECT 
  id,
  status_code,
  CASE 
    WHEN status_code = 200 THEN '✅ 成功'
    WHEN status_code = 401 THEN '❌ 認證失敗'
    ELSE '⚠️  其他錯誤'
  END AS status,
  content,
  created_at
FROM net._http_response
WHERE created_at > NOW() - INTERVAL '5 minutes'
ORDER BY created_at DESC
LIMIT 5;
```

**預期結果**: 應該看到 `status_code = 200`（不是 401）

---

### 方案 2: 使用自動修復腳本（簡化版）

**如果方案 1 太複雜，可以使用自動修復腳本**:

#### 1. 執行自動修復腳本

**在 Supabase SQL Editor 中執行**:

打開文件: `d:\repo\supabase\auto_fix_401_error.sql`

複製全部內容並在 Supabase SQL Editor 中執行。

#### 2. 按照腳本提示操作

腳本會自動：
1. ✅ 檢查當前配置
2. ✅ 更新 Trigger 函數（嘗試從多個來源獲取 key）
3. ✅ 創建測試訂單
4. ✅ 檢查結果

---

### 方案 3: 手動配置腳本（需要替換 key）

**如果您想要一步到位**:

#### 1. 執行手動配置腳本

**在 Supabase SQL Editor 中執行**:

打開文件: `d:\repo\supabase\fix_401_auth_error.sql`

**重要**: 在執行前，將腳本中的 `'YOUR_SERVICE_ROLE_KEY'` 替換為您的實際 Service Role Key。

#### 2. 檢查結果

腳本會自動創建測試訂單並檢查結果。

---

## ✅ 驗證修復成功

### 1. 檢查 HTTP 請求狀態碼

**執行查詢**:
```sql
SELECT 
  status_code,
  COUNT(*) AS count
FROM net._http_response
WHERE created_at > NOW() - INTERVAL '1 hour'
GROUP BY status_code
ORDER BY status_code;
```

**預期結果**:
- ✅ `status_code = 200` 的數量應該增加
- ❌ `status_code = 401` 的數量應該停止增加

---

### 2. 檢查 Outbox 事件處理

**執行查詢**:
```sql
SELECT 
  CASE 
    WHEN processed_at IS NOT NULL THEN '✅ 已處理'
    ELSE '⏳ 待處理'
  END AS status,
  COUNT(*) AS count
FROM outbox
WHERE created_at > NOW() - INTERVAL '1 hour'
GROUP BY status;
```

**預期結果**:
- ✅ 「已處理」的數量應該增加

---

### 3. 檢查 Firestore 同步

**在 Firestore Console 中檢查**:

1. 前往 [Firebase Console](https://console.firebase.google.com/project/ride-platform-f1676/firestore)
2. 打開 `orders_rt` 集合
3. 查看最近創建的訂單
4. 確認數據已同步

**預期結果**:
- ✅ 訂單數據應該在 1-3 秒內出現在 Firestore

---

## 🎯 常見問題

### Q1: 配置後仍然看到 401 錯誤？

**A**: 請確保：
1. ✅ Service Role Key 正確（沒有多餘的空格或換行）
2. ✅ 已重新連接數據庫
3. ✅ 使用的是 **service_role** key，不是 **anon** key

**驗證 key 是否正確**:
```sql
SELECT 
  LENGTH(current_setting('app.settings.service_role_key', true)) AS key_length,
  SUBSTRING(current_setting('app.settings.service_role_key', true), 1, 10) AS key_prefix;
```

**預期結果**:
- `key_length` 應該 > 100
- `key_prefix` 應該是 `eyJhbGciOi`

---

### Q2: 如何重新配置 Service Role Key？

**A**: 執行以下命令：
```sql
ALTER DATABASE postgres SET app.settings.service_role_key TO 'YOUR_NEW_KEY';
```

然後重新連接數據庫。

---

### Q3: 如果忘記配置，會發生什麼？

**A**: 
- ❌ 即時同步功能無法運作（1-3 秒延遲）
- ✅ Cron Job 補償機制仍然正常（30 秒延遲）
- ✅ 數據不會丟失，只是同步延遲增加

---

### Q4: 可以在哪裡查看 Edge Function 日誌？

**A**: 
1. 前往 [Supabase Dashboard](https://supabase.com/dashboard)
2. 選擇您的項目
3. 前往 **Edge Functions** → **sync-to-firestore** → **Logs**
4. 查看最近的請求日誌

---

## 📊 修復前後對比

### 修復前 ❌

| 項目 | 狀態 |
|------|------|
| HTTP 狀態碼 | 401 (Unauthorized) |
| 即時同步延遲 | 無法運作 |
| Cron Job 補償 | ✅ 正常（30 秒） |
| 數據丟失風險 | ❌ 無（有補償機制） |

---

### 修復後 ✅

| 項目 | 狀態 |
|------|------|
| HTTP 狀態碼 | 200 (OK) |
| 即時同步延遲 | ✅ 1-3 秒 |
| Cron Job 補償 | ✅ 正常（30 秒） |
| 數據丟失風險 | ❌ 無 |

---

## 🚀 下一步

### 1. 啟用即時同步 Trigger

**如果尚未啟用**:

```sql
-- 檢查 Trigger 狀態
SELECT * FROM get_realtime_sync_status();

-- 如果 trigger_exists = false，執行啟用腳本
-- 文件: d:\repo\supabase\enable_realtime_sync.sql
```

---

### 2. 監控同步性能

**執行性能測試**:

```sql
-- 文件: d:\repo\supabase\test_realtime_trigger_only.sql
```

**預期結果**:
- ✅ 延遲 < 3 秒 → 即時 Trigger 正常
- ⚠️ 延遲 > 10 秒 → 可能是 Cron Job 在處理

---

### 3. 配置管理後台開關

**在管理後台的「派單設定」頁面**:

1. 找到「即時同步開關」
2. 確認開關狀態與數據庫配置一致
3. 測試開關功能

---

## 📚 相關文件

### 修復腳本
1. ✅ `supabase/fix_401_auth_error.sql` - 手動配置腳本
2. ✅ `supabase/auto_fix_401_error.sql` - 自動修復腳本

### 測試腳本
3. ✅ `supabase/test_realtime_trigger_only.sql` - 測試即時 Trigger
4. ✅ `supabase/test_status_flow.sql` - 測試完整狀態流轉

### 診斷腳本
5. ✅ `supabase/check_trigger_config.sql` - 檢查 Trigger 配置

### 文檔
6. ✅ `Supabase即時同步401錯誤_診斷與修復指南.md` - 本文檔

---

**修復日期**: 2025-10-16  
**修復人員**: AI Assistant  
**修復狀態**: ✅ 腳本已創建，等待執行  
**預計修復時間**: 5 分鐘

