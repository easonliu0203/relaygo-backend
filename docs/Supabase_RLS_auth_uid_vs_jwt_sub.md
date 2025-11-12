# Supabase RLS: auth.uid() vs auth.jwt() ->> 'sub'

**文檔目的**: 說明在 Supabase RLS 策略中使用 `auth.uid()` 和 `auth.jwt() ->> 'sub'` 的區別

---

## 📋 核心概念

### auth.uid()

**定義**: Supabase 內部的用戶 ID  
**類型**: UUID  
**來源**: Supabase Auth 系統自動生成  
**用途**: 用於 Supabase 原生認證系統

**範例**:
```
auth.uid() = '550e8400-e29b-41d4-a716-446655440000'
```

### auth.jwt() ->> 'sub'

**定義**: JWT Token 中的 subject（主體）欄位  
**類型**: TEXT  
**來源**: 認證提供者（Firebase Auth、Auth0 等）  
**用途**: 用於第三方認證系統（如 Firebase Authentication）

**範例**:
```
auth.jwt() ->> 'sub' = 'hUu4fH5dTlW9VUYm6GojXvRLdni2'
```

---

## 🔍 使用場景對比

### 場景 1: Supabase 原生認證

**資料庫結構**:
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),  -- Supabase 內部 ID
  email VARCHAR(255) UNIQUE NOT NULL,
  -- ...
);
```

**RLS 策略**:
```sql
CREATE POLICY "Users can view their own data"
  ON users
  FOR SELECT
  USING (
    id = auth.uid()  -- ✅ 正確：比較兩個 UUID
  );
```

**說明**: 當使用 Supabase 原生認證時，`auth.uid()` 直接對應 users 表的 `id` 欄位。

---

### 場景 2: Firebase Authentication（我們的專案）

**資料庫結構**:
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),  -- Supabase 內部 ID
  firebase_uid VARCHAR(128) UNIQUE NOT NULL,      -- Firebase UID
  email VARCHAR(255) UNIQUE NOT NULL,
  -- ...
);
```

**❌ 錯誤的 RLS 策略**:
```sql
CREATE POLICY "Users can view their own data"
  ON users
  FOR SELECT
  USING (
    firebase_uid = auth.uid()  -- ❌ 錯誤：比較 VARCHAR 和 UUID
  );
```

**錯誤訊息**:
```
ERROR: 42883: operator does not exist: uuid = character varying
```

**✅ 正確的 RLS 策略**:
```sql
CREATE POLICY "Users can view their own data"
  ON users
  FOR SELECT
  USING (
    firebase_uid = auth.jwt() ->> 'sub'  -- ✅ 正確：比較兩個 TEXT/VARCHAR
  );
```

**說明**: 當使用 Firebase Authentication 時，需要使用 `auth.jwt() ->> 'sub'` 來獲取 Firebase UID（TEXT 類型），然後與 `firebase_uid` 欄位（VARCHAR 類型）比較。

---

## 🎯 我們專案中的正確用法

### 模式 1: 直接比較 firebase_uid

**適用場景**: 當表中有 `firebase_uid` 欄位時

```sql
CREATE POLICY "Users can view their own profile"
  ON user_profiles
  FOR SELECT
  USING (
    user_id IN (
      SELECT id FROM users WHERE firebase_uid = auth.jwt() ->> 'sub'
    )
  );
```

**說明**:
1. `auth.jwt() ->> 'sub'` 獲取 Firebase UID（TEXT）
2. 與 `users.firebase_uid`（VARCHAR）比較
3. 返回對應的 `users.id`（UUID）
4. 與 `user_profiles.user_id`（UUID）比較

### 模式 2: 使用輔助函數

**創建輔助函數**:
```sql
CREATE OR REPLACE FUNCTION get_user_id_by_firebase_uid(firebase_uid_param TEXT)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  user_id_result UUID;
BEGIN
  SELECT id INTO user_id_result
  FROM users
  WHERE firebase_uid = firebase_uid_param;
  
  RETURN user_id_result;
END;
$$;
```

**使用輔助函數**:
```sql
CREATE POLICY "Users can view their own profile"
  ON user_profiles
  FOR SELECT
  USING (
    user_id = get_user_id_by_firebase_uid(auth.jwt() ->> 'sub')
  );
```

**優點**:
- 代碼更簡潔
- 邏輯更清晰
- 可重用

---

## 📊 類型對比表

| 項目 | auth.uid() | auth.jwt() ->> 'sub' |
|------|------------|----------------------|
| **返回類型** | UUID | TEXT |
| **來源** | Supabase Auth | JWT Token |
| **適用場景** | Supabase 原生認證 | 第三方認證（Firebase、Auth0 等） |
| **範例值** | `550e8400-e29b-41d4-a716-446655440000` | `hUu4fH5dTlW9VUYm6GojXvRLdni2` |
| **與 users.id 比較** | ✅ 可以（UUID = UUID） | ❌ 不可以（UUID ≠ TEXT） |
| **與 users.firebase_uid 比較** | ❌ 不可以（VARCHAR ≠ UUID） | ✅ 可以（VARCHAR = TEXT） |

---

## 🔧 常見錯誤和修復

### 錯誤 1: 直接比較 auth.uid() 和 firebase_uid

**錯誤代碼**:
```sql
USING (
  auth.uid() = (SELECT firebase_uid FROM users WHERE id = sender_id)
)
```

**錯誤訊息**:
```
ERROR: operator does not exist: uuid = character varying
```

**修復**:
```sql
USING (
  sender_id IN (
    SELECT id FROM users WHERE firebase_uid = auth.jwt() ->> 'sub'
  )
)
```

### 錯誤 2: 使用 IN 子句但類型不匹配

**錯誤代碼**:
```sql
USING (
  auth.uid() IN (
    SELECT firebase_uid FROM users WHERE id = sender_id
  )
)
```

**錯誤訊息**:
```
ERROR: operator does not exist: uuid = character varying
```

**修復**:
```sql
USING (
  sender_id IN (
    SELECT id FROM users WHERE firebase_uid = auth.jwt() ->> 'sub'
  )
)
```

---

## 💡 最佳實踐

### 1. 統一使用 auth.jwt() ->> 'sub'

在使用 Firebase Authentication 的專案中，**始終使用** `auth.jwt() ->> 'sub'` 來獲取用戶身份。

### 2. 比較相同類型

確保比較的兩個值類型相同：
- UUID 與 UUID 比較
- TEXT/VARCHAR 與 TEXT/VARCHAR 比較

### 3. 使用子查詢轉換類型

當需要從 Firebase UID 轉換為 Supabase user_id 時，使用子查詢：

```sql
user_id IN (
  SELECT id FROM users WHERE firebase_uid = auth.jwt() ->> 'sub'
)
```

### 4. 考慮使用輔助函數

對於複雜的 RLS 策略，考慮創建輔助函數來簡化邏輯。

---

## 📚 參考資料

### Supabase 官方文檔

- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)
- [Auth Helpers](https://supabase.com/docs/guides/auth/auth-helpers)

### JWT Token 結構

```json
{
  "sub": "hUu4fH5dTlW9VUYm6GojXvRLdni2",  // Firebase UID
  "aud": "authenticated",
  "role": "authenticated",
  "email": "customer.test@relaygo.com",
  "iat": 1697000000,
  "exp": 1697003600
}
```

**獲取方式**:
- `auth.jwt() ->> 'sub'`: 獲取 Firebase UID
- `auth.jwt() ->> 'email'`: 獲取 Email
- `auth.jwt() ->> 'role'`: 獲取角色

---

## 🎉 總結

**關鍵要點**:

1. ✅ **使用 Firebase Auth**: 使用 `auth.jwt() ->> 'sub'` 獲取 Firebase UID
2. ✅ **類型匹配**: 確保比較的兩個值類型相同
3. ✅ **子查詢轉換**: 使用子查詢從 Firebase UID 轉換為 Supabase user_id
4. ❌ **避免混合類型**: 不要直接比較 UUID 和 VARCHAR

**記住**:
- `auth.uid()` = Supabase 內部 ID（UUID）
- `auth.jwt() ->> 'sub'` = Firebase UID（TEXT）
- 我們的專案使用 Firebase Authentication，所以**始終使用** `auth.jwt() ->> 'sub'`

---

**文檔版本**: 1.0  
**最後更新**: 2025-10-11  
**適用專案**: RelayGO（使用 Firebase Authentication）

