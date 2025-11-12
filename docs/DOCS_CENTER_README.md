# 📚 開發文檔中心

> **歡迎來到包車系統開發文檔中心！**
> 
> 本文檔中心包含所有開發所需的架構說明、開發指南、快速參考和檢查清單。

**最後更新**：2025-01-12  
**版本**：v2.0

---

## 🎯 文檔導航

### 🚀 新手入門

如果您是第一次接觸本專案，請按以下順序閱讀：

1. **[QUICK_START_GUIDE.md](./QUICK_START_GUIDE.md)** - 快速啟動指南（30 分鐘）
   - 環境配置
   - 安裝依賴
   - 啟動服務
   - 驗證安裝

2. **[../DOCS_README.md](../DOCS_README.md)** - 文檔說明
   - 文檔列表
   - 使用流程
   - 關鍵概念速記

3. **[../ARCHITECTURE.md](../ARCHITECTURE.md)** - 完整架構文檔
   - 核心架構原則
   - 技術分工
   - 資料庫結構
   - RLS 規則
   - Firestore 規則
   - Outbox Payload 格式
   - 環境變數配置

---

### 📖 核心文檔

#### 1. 架構與設計

- **[../ARCHITECTURE.md](../ARCHITECTURE.md)** - 完整架構文檔（1413 行）
  - ✅ CQRS 架構原則
  - ✅ Supabase 資料庫結構
  - ✅ Firestore 資料庫結構
  - ✅ 🔐 RLS 規則說明
  - ✅ 🧱 Firestore 安全規則與索引
  - ✅ 🧩 Outbox → Firestore Payload 格式契約
  - ✅ 📦 環境變數與端口固定
  - ✅ ID 映射規則
  - ✅ Backend API 規範
  - ✅ Edge Functions 說明

#### 2. 快速參考

- **[../QUICK_REFERENCE.md](../QUICK_REFERENCE.md)** - 快速參考卡片（454 行）
  - ✅ ID 使用規則表
  - ✅ 訂單狀態流程
  - ✅ 資料流向圖
  - ✅ 代碼範本
  - ✅ 📦 環境變數與端口固定
  - ✅ 🧱 Firestore 安全規則與索引
  - ✅ 🔐 RLS 規則快速參考
  - ✅ 常見錯誤示例
  - ✅ 檢查清單

#### 3. 開發指南

- **[../DEVELOPMENT_CHECKLIST.md](../DEVELOPMENT_CHECKLIST.md)** - 開發檢查清單（462 行）
  - ✅ 開發前準備檢查
  - ✅ Backend API 開發檢查
  - ✅ Edge Function 開發檢查
  - ✅ 📱 Flutter APP 開發檢查（大幅擴充）
  - ✅ 測試檢查
  - ✅ 代碼審查檢查
  - ✅ 部署前檢查
  - ✅ 常見錯誤檢查

---

### 🆕 最新更新

- **[DOCUMENTATION_UPDATES_SUMMARY.md](./DOCUMENTATION_UPDATES_SUMMARY.md)** - 文檔更新總結
  - 更新目標
  - 更新的文件清單
  - 重點補強內容總結
  - 文檔統計
  - 使用建議

- **[QUICK_START_GUIDE.md](./QUICK_START_GUIDE.md)** - 快速啟動指南
  - 前置要求
  - 30 分鐘快速啟動
  - 驗證安裝
  - 常見問題

---

## 🎯 使用場景指南

### 場景 1：我是新加入的開發者

**推薦閱讀順序**：

```
1. QUICK_START_GUIDE.md（30 分鐘）
   ↓
2. DOCS_README.md（10 分鐘）
   ↓
3. QUICK_REFERENCE.md（15 分鐘）
   ↓
4. ARCHITECTURE.md（60 分鐘）
   ↓
5. DEVELOPMENT_CHECKLIST.md（保存以備後用）
```

**總時間**：約 2 小時

---

### 場景 2：我要開發新功能

**推薦流程**：

```
1. 複製 DEVELOPMENT_CHECKLIST.md 中的相關清單
   ↓
2. 查閱 QUICK_REFERENCE.md 確認規則
   ↓
3. 檢查是否需要修改 RLS 規則或 Firestore 規則
   ↓
4. 參考 ARCHITECTURE.md 中的代碼範本
   ↓
5. 開始開發
   ↓
6. 逐項檢查清單
```

---

### 場景 3：我遇到問題了

**推薦流程**：

```
1. 查閱 QUICK_REFERENCE.md 的「常見錯誤」章節
   ↓
2. 使用 DEVELOPMENT_CHECKLIST.md 自我檢查
   ↓
3. 檢查環境變數和端口配置
   ↓
4. 查閱 ARCHITECTURE.md 的詳細說明
   ↓
5. 如果仍無法解決，聯絡團隊
```

---

### 場景 4：我是 AI 助理

**推薦流程**：

```
1. 首先閱讀 ARCHITECTURE.md 了解架構約束
   ↓
2. 檢查 QUICK_REFERENCE.md 中的固定配置
   ↓
3. 確認不會修改關鍵環境變數（PORT、API URL 等）
   ↓
4. 確認不會違反 RLS 規則（不直接操作資料表）
   ↓
5. 確認不會違反 Firestore 安全規則（不直接寫入）
   ↓
6. 使用 DEVELOPMENT_CHECKLIST.md 逐項檢查
```

---

## 🔑 關鍵概念速記

### CQRS 架構

```
寫入：Flutter APP → Backend API → Supabase
讀取：Flutter APP → Firestore
同步：Supabase → Outbox → Edge Function → Firestore
```

### ID 映射規則

```
Supabase 用 UUID (users.id)
Firestore 用 Firebase UID
Backend API 要轉換！
```

### 技術分工

```
Firebase：登入、推播、聊天、檔案、定位
Supabase：訂單、支付、報表（唯一真實數據源）
Firestore：訂單列表、聊天室列表（Supabase 的鏡像）
```

### 固定端口

```
Backend API：3000（不可更改）
Web Admin：3001（不可更改）
Supabase Local DB：54322
Supabase Studio：54323
```

### RLS 規則

```
App 端不可直接操作資料表
必須透過 Backend API（使用 service_role_key）
只有 Edge Functions 和管理員可以繞過 RLS
```

### Firestore 安全規則

```
所有寫入操作禁止（allow write: if false）
只有 Edge Function 可以寫入
App 端只能讀取自己的資料
```

---

## ⚠️ 最常見的錯誤

### ❌ 錯誤 1：ID 類型混用

```typescript
// ❌ 錯誤
await supabase.from('bookings').insert({
  customer_id: 'hUu4fH5dTIW9VUYm6GojXvRLdni2', // Firebase UID
});

// ✅ 正確
const { data: user } = await supabase
  .from('users')
  .select('id')
  .eq('firebase_uid', 'hUu4fH5dTIW9VUYm6GojXvRLdni2')
  .single();

await supabase.from('bookings').insert({
  customer_id: user.id, // Supabase UUID
});
```

### ❌ 錯誤 2：違反 CQRS 架構

```dart
// ❌ 錯誤：直接寫入 Firestore
await FirebaseFirestore.instance.collection('orders_rt').add({...});

// ✅ 正確：通過 Backend API
await http.post(Uri.parse('$_baseUrl/bookings'), body: {...});
```

### ❌ 錯誤 3：隨意更改端口

```bash
# ❌ 錯誤
PORT=3001  # Backend API 改為 3001

# ✅ 正確
PORT=3000  # 保持固定端口
```

### ❌ 錯誤 4：違反 RLS 規則

```dart
// ❌ 錯誤：直接從 App 操作 Supabase
final response = await Supabase.instance.client
  .from('bookings')
  .insert({...});

// ✅ 正確：通過 Backend API
final response = await http.post(
  Uri.parse('$_baseUrl/bookings'),
  body: json.encode({...}),
);
```

---

## 📊 文檔統計

| 文件 | 行數 | 主要內容 |
|------|------|---------|
| ARCHITECTURE.md | 1413 | 完整架構文檔 |
| QUICK_REFERENCE.md | 454 | 快速參考卡片 |
| DEVELOPMENT_CHECKLIST.md | 462 | 開發檢查清單 |
| DOCS_README.md | 383 | 文檔說明 |
| QUICK_START_GUIDE.md | 300 | 快速啟動指南 |
| DOCUMENTATION_UPDATES_SUMMARY.md | 300 | 文檔更新總結 |
| **總計** | **3312** | **6 個核心文檔** |

---

**最後更新**：2025-01-12  
**維護者**：開發團隊

