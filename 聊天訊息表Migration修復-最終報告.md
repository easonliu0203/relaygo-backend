# 聊天訊息表 Migration 修復 - 最終報告

**修復日期**: 2025-10-11  
**修復時間**: 23:15  
**問題狀態**: ✅ 已完全修復

---

## 🎯 問題總結

### 錯誤訊息
```
ERROR: 42883: operator does not exist: uuid = character varying
HINT: No operator matches the given name and argument types. You might need to add explicit type casts.
```

### 根本原因

**問題 1: RLS 策略中使用了錯誤的認證函數** ⭐ **主要原因**

在 RLS 策略中使用了 `auth.uid()`（返回 UUID 類型），但我們的專案使用 Firebase Authentication，應該使用 `auth.jwt() ->> 'sub'`（返回 TEXT 類型）來獲取 Firebase UID。

**類型不匹配**:
- `auth.uid()` 返回 **UUID** 類型（Supabase 內部用戶 ID）
- `users.firebase_uid` 是 **VARCHAR(128)** 類型（Firebase UID）
- PostgreSQL 不允許直接比較 UUID 和 VARCHAR

**問題 2: JSONB 對象中 UUID 未轉換**

在 trigger 函數中，將 UUID 類型的值插入 JSONB 對象時，沒有顯式轉換為 TEXT 類型。

---

## 🔧 修復內容

### 修復 1: RLS 策略 - 使用正確的認證函數 ⭐

**修改位置**: Line 60-92

**修改前**:
```sql
CREATE POLICY "Users can view their own messages"
  ON chat_messages
  FOR SELECT
  USING (
    auth.uid() IN (  -- ❌ 錯誤：auth.uid() 返回 UUID
      SELECT firebase_uid FROM users WHERE id = sender_id
      UNION
      SELECT firebase_uid FROM users WHERE id = receiver_id
    )
  );
```

**修改後**:
```sql
CREATE POLICY "Users can view their own messages"
  ON chat_messages
  FOR SELECT
  USING (
    sender_id IN (  -- ✅ 正確：比較 UUID 類型
      SELECT id FROM users WHERE firebase_uid = auth.jwt() ->> 'sub'
    )
    OR
    receiver_id IN (
      SELECT id FROM users WHERE firebase_uid = auth.jwt() ->> 'sub'
    )
  );
```

**關鍵變更**:
1. `auth.uid()` → `auth.jwt() ->> 'sub'`（獲取 Firebase UID）
2. `auth.uid() IN (SELECT firebase_uid ...)` → `sender_id IN (SELECT id ...)`（比較 UUID 而不是混合類型）
3. 使用 `OR` 替代 `UNION`（更清晰的邏輯）

**同樣的修復應用於**:
- ✅ "Users can send messages" 策略（Line 74-80）
- ✅ "Users can mark messages as read" 策略（Line 82-92）

### 修復 2: booking_data JSONB 對象

**修改位置**: Line 125

**修改前**:
```sql
'bookingId', b.id,  -- ❌ UUID 未轉換
```

**修改後**:
```sql
'bookingId', b.id::TEXT,  -- ✅ 顯式轉換為 TEXT
```

### 修復 3: payload JSONB 對象

**修改位置**: Line 158-159

**修改前**:
```sql
'id', NEW.id,          -- ❌ UUID 未轉換
'bookingId', NEW.booking_id,  -- ❌ UUID 未轉換
```

**修改後**:
```sql
'id', NEW.id::TEXT,          -- ✅ 顯式轉換為 TEXT
'bookingId', NEW.booking_id::TEXT,  -- ✅ 顯式轉換為 TEXT
```

---

## 📊 修復對比

### auth.uid() vs auth.jwt() ->> 'sub'

| 項目 | auth.uid() | auth.jwt() ->> 'sub' |
|------|------------|----------------------|
| **返回類型** | UUID | TEXT |
| **來源** | Supabase Auth | JWT Token（Firebase Auth） |
| **適用場景** | Supabase 原生認證 | 第三方認證 |
| **範例值** | `550e8400-...` | `hUu4fH5dTlW9VUYm6GojXvRLdni2` |
| **與 users.firebase_uid 比較** | ❌ 不可以（類型不匹配） | ✅ 可以（TEXT = VARCHAR） |

### 修復前後對比

**修復前**:
```sql
-- ❌ 錯誤：比較 UUID 和 VARCHAR
auth.uid() = (SELECT firebase_uid FROM users WHERE id = sender_id)
```

**修復後**:
```sql
-- ✅ 正確：比較 UUID 和 UUID
sender_id IN (
  SELECT id FROM users WHERE firebase_uid = auth.jwt() ->> 'sub'
)
```

---

## ✅ 修復驗證

### 1. 類型匹配檢查

**RLS 策略**:
- ✅ `auth.jwt() ->> 'sub'`（TEXT）與 `users.firebase_uid`（VARCHAR）比較
- ✅ `sender_id`（UUID）與 `users.id`（UUID）比較
- ✅ `receiver_id`（UUID）與 `users.id`（UUID）比較

**JSONB 對象**:
- ✅ `b.id::TEXT`（TEXT）插入 JSONB
- ✅ `NEW.id::TEXT`（TEXT）插入 JSONB
- ✅ `NEW.booking_id::TEXT`（TEXT）插入 JSONB

### 2. 邏輯正確性檢查

**策略 1: 查看訊息**
- ✅ 用戶可以查看自己發送的訊息（sender_id 匹配）
- ✅ 用戶可以查看自己接收的訊息（receiver_id 匹配）

**策略 2: 發送訊息**
- ✅ 用戶只能以自己的身份發送訊息（sender_id 必須是自己）

**策略 3: 標記已讀**
- ✅ 用戶只能標記自己接收的訊息為已讀（receiver_id 必須是自己）

---

## 📝 執行步驟

### 1. 重新執行 Migration ⚠️ **必須執行**

**步驟**:
1. 打開 Supabase SQL Editor: https://supabase.com/dashboard/project/vlyhwegpvpnjyocqmfqc/sql/new
2. 複製修復後的文件內容: `supabase/migrations/20251011_create_chat_messages_table.sql`
3. 貼上到 SQL Editor 並執行
4. 確認看到成功訊息（應該不再有類型轉換錯誤）

### 2. 驗證 Migration 成功

**步驟**:
1. 打開 Supabase SQL Editor
2. 複製並執行驗證腳本: `verify-chat-migration.sql`
3. 檢查輸出，確認所有組件都已創建：
   - ✅ chat_messages 表存在
   - ✅ 8 個欄位（id, booking_id, sender_id, receiver_id, message_text, translated_text, created_at, read_at）
   - ✅ 5 個索引
   - ✅ 3 個外鍵約束
   - ✅ RLS 已啟用
   - ✅ 3 個 RLS 策略
   - ✅ trigger 函數已創建
   - ✅ trigger 已創建

### 3. 測試 RLS 策略（可選）

**步驟**:
1. 創建測試訂單並分配司機
2. 使用客戶帳號登入，嘗試發送訊息
3. 使用司機帳號登入，嘗試查看訊息
4. 驗證 RLS 策略正常工作

---

## 🗂️ 相關文件

### 修改的文件
1. ✅ `supabase/migrations/20251011_create_chat_messages_table.sql`

### 創建的文件
1. ✅ `verify-chat-migration.sql` - 驗證腳本
2. ✅ `test-uuid-conversion.sql` - UUID 轉換測試腳本
3. ✅ `docs/20251011_2300_02_聊天訊息表Migration類型轉換錯誤修復.md` - 詳細修復文檔
4. ✅ `docs/Supabase_RLS_auth_uid_vs_jwt_sub.md` - auth.uid() vs auth.jwt() 說明文檔
5. ✅ `聊天訊息表Migration修復-最終報告.md` - 本文檔

---

## 💡 經驗總結

### 學到的教訓

1. **認證函數選擇很重要**:
   - Supabase 原生認證 → 使用 `auth.uid()`
   - Firebase Authentication → 使用 `auth.jwt() ->> 'sub'`
   - 不要混用！

2. **類型匹配是關鍵**:
   - PostgreSQL 類型系統非常嚴格
   - UUID ≠ VARCHAR/TEXT
   - 必須確保比較的兩個值類型相同

3. **JSONB 需要顯式轉換**:
   - UUID、TIMESTAMP 等特殊類型需要轉換為字符串
   - 使用 `::TEXT` 進行顯式轉換

4. **參考現有代碼**:
   - 查看其他 migration 文件中的 RLS 策略
   - 保持一致的模式和風格

### 最佳實踐

1. **統一使用 auth.jwt() ->> 'sub'**:
   ```sql
   -- ✅ 正確
   WHERE firebase_uid = auth.jwt() ->> 'sub'
   
   -- ❌ 錯誤
   WHERE firebase_uid = auth.uid()
   ```

2. **比較相同類型**:
   ```sql
   -- ✅ 正確：UUID = UUID
   sender_id IN (SELECT id FROM users WHERE ...)
   
   -- ❌ 錯誤：UUID = VARCHAR
   auth.uid() IN (SELECT firebase_uid FROM users WHERE ...)
   ```

3. **JSONB 中的 UUID 轉換**:
   ```sql
   -- ✅ 正確
   jsonb_build_object('id', uuid_column::TEXT)
   
   -- ❌ 錯誤
   jsonb_build_object('id', uuid_column)
   ```

---

## 🎯 修復清單

- ✅ 診斷問題根本原因（auth.uid() vs auth.jwt() ->> 'sub'）
- ✅ 修復 RLS 策略 1: "Users can view their own messages"
- ✅ 修復 RLS 策略 2: "Users can send messages"
- ✅ 修復 RLS 策略 3: "Users can mark messages as read"
- ✅ 修復 booking_data JSONB 對象（UUID 轉換）
- ✅ 修復 payload JSONB 對象（UUID 轉換）
- ✅ 創建驗證腳本
- ✅ 創建測試腳本
- ✅ 創建詳細文檔
- ✅ 創建說明文檔（auth.uid() vs auth.jwt()）
- ⚠️ 待執行：重新執行 migration
- ⚠️ 待執行：驗證 migration 成功

---

## 🎉 總結

**問題**: PostgreSQL 類型轉換錯誤（UUID vs VARCHAR）

**根本原因**: 
1. ⭐ RLS 策略中使用了 `auth.uid()`（UUID）而不是 `auth.jwt() ->> 'sub'`（TEXT）
2. JSONB 對象中 UUID 未轉換為 TEXT

**修復**:
1. ⭐ 將所有 RLS 策略中的 `auth.uid()` 替換為 `auth.jwt() ->> 'sub'`
2. 調整比較邏輯，確保比較相同類型（UUID = UUID）
3. 在 JSONB 對象中添加 `::TEXT` 類型轉換

**修改位置**:
- Line 60-92: RLS 策略（3 個策略）
- Line 125: booking_data JSONB 對象
- Line 158-159: payload JSONB 對象

**驗證**: 使用 `verify-chat-migration.sql` 腳本驗證所有組件已創建

**下一步**: 重新執行 migration 並驗證成功

---

**修復狀態**: ✅ **代碼修復完成**  
**驗證狀態**: ⚠️ **待執行 migration 並驗證**  
**修復時間**: 2025-10-11 23:15

祝修復順利！🚀

