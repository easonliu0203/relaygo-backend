# 🚨 Supabase 外鍵關聯錯誤 - 快速修復

**錯誤**: PGRST200 - Could not find a relationship between 'users' and 'user_profiles'  
**狀態**: ✅ 已修復

---

## ⚡ 立即執行步驟

### 步驟 1: 應用資料庫 Migration

**選項 A: 使用 Supabase Dashboard（推薦）**

1. 訪問 Supabase Dashboard SQL Editor
2. 複製並執行 `supabase/apply-user-profiles-migration.sql` 的內容
3. 確認看到成功訊息：
   ```
   ✅ user_profiles 表已創建
   ✅ drivers 表已創建
   ```

**選項 B: 使用 Supabase CLI**

```bash
cd supabase
supabase db push
```

### 步驟 2: 重新啟動管理後台

```bash
cd web-admin
npm run dev
```

### 步驟 3: 測試訂單管理頁面

**訪問**: http://localhost:3001/orders

**預期結果**:
- ✅ 頁面正常載入
- ✅ 不出現 PGRST200 錯誤
- ✅ 訂單列表正常顯示
- ✅ 客戶和司機資訊正確顯示

---

## 🔧 已完成的修復

### 問題根源

**錯誤的資料庫狀態**:
```
✅ users 表存在
❌ user_profiles 表不存在
❌ drivers 表不存在
```

**錯誤的 API 查詢**:
```typescript
// ❌ 錯誤: 嘗試關聯不存在的表
customer:customer_id (
  id,
  email,
  user_profiles (first_name, last_name, phone)  // 表不存在！
)
```

### 修復內容

#### 1. 創建缺少的資料表 ✅

**文件**: `supabase/migrations/20250104_create_user_profiles_and_drivers.sql`

**創建的表**:

**user_profiles 表**:
```sql
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id),  -- 關聯到 users
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    phone VARCHAR(20),
    avatar_url TEXT,
    ...
    UNIQUE(user_id)  -- 一對一關聯
);
```

**drivers 表**:
```sql
CREATE TABLE drivers (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id),  -- 關聯到 users
    license_number VARCHAR(50) UNIQUE NOT NULL,
    vehicle_type VARCHAR(10) NOT NULL,
    vehicle_plate VARCHAR(20) UNIQUE NOT NULL,
    ...
    UNIQUE(user_id)  -- 一對一關聯
);
```

#### 2. 修改 API 查詢語法 ✅

**文件**: `web-admin/src/app/api/admin/bookings/route.ts`

**修改前**:
```typescript
customer:customer_id (
  id,
  email,
  user_profiles (first_name, last_name, phone)  // ❌ 錯誤
)
```

**修改後**:
```typescript
customer:customer_id (
  id,
  email,
  user_profiles!user_id (first_name, last_name, phone)  // ✅ 正確
)
```

**語法說明**:
- `user_profiles!user_id` - 使用 `user_id` 欄位進行反向關聯
- `!` 符號明確指定關聯欄位
- 告訴 PostgREST 使用 `user_profiles.user_id = users.id` 進行關聯

---

## 🔍 問題診斷

### 為什麼會出現 PGRST200 錯誤?

**PostgREST 錯誤碼 PGRST200**:
- 表示無法找到表之間的外鍵關聯
- 通常是因為表不存在或查詢語法錯誤

**本次問題的原因**:
1. **缺少資料表** - `user_profiles` 和 `drivers` 表沒有創建
2. **查詢語法不正確** - 沒有明確指定反向關聯的欄位

**關聯關係**:
```
bookings → users (customer_id)
users ← user_profiles (user_id)  // 反向關聯

bookings → users (driver_id)
users ← drivers (user_id)  // 反向關聯
```

### 如何驗證修復?

**方法 1: 檢查表是否存在**

在 Supabase Dashboard SQL Editor 中執行:
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('user_profiles', 'drivers');
```

**預期結果**:
```
table_name
--------------
user_profiles
drivers
```

**方法 2: 測試 API**

```bash
curl -X GET "http://localhost:3001/api/admin/bookings?limit=1" \
  -H "Content-Type: application/json" | jq '.'
```

**預期結果**:
```json
{
  "success": true,
  "data": [...]
}
```

**方法 3: 使用測試腳本**

```bash
chmod +x test-supabase-schema.sh
./test-supabase-schema.sh
```

---

## 📊 修復對比

### 修復前

**資料庫狀態**:
- ✅ users 表存在
- ❌ user_profiles 表不存在
- ❌ drivers 表不存在

**API 查詢**:
```typescript
user_profiles (first_name, last_name, phone)  // ❌ 表不存在
```

**錯誤訊息**:
```
PGRST200: Could not find a relationship between 'users' and 'user_profiles'
```

**頁面狀態**:
- ❌ 顯示錯誤訊息
- ❌ 訂單列表無法載入
- ❌ 客戶和司機資訊無法顯示

### 修復後

**資料庫狀態**:
- ✅ users 表存在
- ✅ user_profiles 表存在
- ✅ drivers 表存在

**API 查詢**:
```typescript
user_profiles!user_id (first_name, last_name, phone)  // ✅ 正確語法
```

**錯誤訊息**:
- ✅ 無錯誤

**頁面狀態**:
- ✅ 正常載入
- ✅ 訂單列表正常顯示
- ✅ 客戶和司機資訊正確顯示

---

## 🔍 如果仍有問題

### 問題 1: 表創建失敗

**可能原因**: SQL 語法錯誤或權限問題

**解決**:
1. 檢查 Supabase Dashboard 的錯誤訊息
2. 確認有足夠的權限執行 DDL 語句
3. 手動執行 SQL 語句，逐步創建

### 問題 2: 仍然出現 PGRST200 錯誤

**可能原因**: Schema cache 未刷新

**解決**:
1. 重新啟動 web-admin 服務
2. 在 Supabase Dashboard 中刷新 schema
3. 清除瀏覽器快取

### 問題 3: user_profiles 表為空

**這是正常的！**

**原因**:
- user_profiles 表剛創建，沒有資料
- 用戶資料會在用戶更新個人資料時創建

**驗證**:
- 查詢使用 LEFT JOIN，即使 user_profiles 為空也不會報錯
- 客戶姓名會顯示為「未知客戶」（這是正常的）

### 問題 4: 需要為現有用戶創建 profiles

**可選操作**:

```sql
-- 為所有現有用戶創建空的 user_profiles 記錄
INSERT INTO user_profiles (user_id)
SELECT id FROM users
WHERE NOT EXISTS (
    SELECT 1 FROM user_profiles WHERE user_profiles.user_id = users.id
);
```

---

## 💡 PostgREST 關聯語法速查

### 正向關聯（表 A 有外鍵指向表 B）

```typescript
// bookings.customer_id → users.id
bookings.select('*, customer:customer_id(*)')
```

### 反向關聯（表 B 有外鍵指向表 A）

```typescript
// users.id ← user_profiles.user_id
users.select('*, user_profiles!user_id(*)')
```

### 多層關聯

```typescript
bookings.select(`
  *,
  customer:customer_id (
    *,
    user_profiles!user_id (*)
  )
`)
```

---

## 📚 相關文件

| 文件 | 用途 |
|------|------|
| `supabase/migrations/20250104_create_user_profiles_and_drivers.sql` | Migration 文件 |
| `supabase/apply-user-profiles-migration.sql` | 手動應用腳本 |
| `web-admin/src/app/api/admin/bookings/route.ts` | 訂單 API（已修改） |
| `test-supabase-schema.sh` | Schema 測試腳本 |
| `docs/20251009_0300_22_Supabase外鍵關聯錯誤修復.md` | 詳細開發歷程 |

---

## 🎯 驗證清單

完成修復後，請確認以下項目：

- [ ] user_profiles 表已創建
- [ ] drivers 表已創建
- [ ] 外鍵關聯正確設置
- [ ] API 查詢語法已修改
- [ ] web-admin 服務已重新啟動
- [ ] 訪問 http://localhost:3001/orders 正常
- [ ] 不出現 PGRST200 錯誤
- [ ] 訂單列表正常顯示
- [ ] 客戶資訊正常顯示（或顯示「未知客戶」）
- [ ] 司機資訊正常顯示（如果有司機）

---

## 🎉 預期效果

1. ✅ **資料庫 Schema 完整**
   - users, user_profiles, drivers, bookings 表都存在
   - 外鍵關聯正確設置

2. ✅ **API 查詢正常**
   - 不再出現 PGRST200 錯誤
   - 關聯查詢正確執行

3. ✅ **訂單管理頁面正常**
   - 訂單列表正常顯示
   - 客戶和司機資訊正確顯示

4. ✅ **資料完整性**
   - 一對一關聯正確實現
   - 資料一致性得到保證

---

**需要幫助?** 查看 `docs/20251009_0300_22_Supabase外鍵關聯錯誤修復.md` 獲取詳細說明!

