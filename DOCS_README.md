# 📚 系統架構文檔說明

> **⚠️ 重要提示**：在開始任何開發工作之前，請先閱讀這些文檔！
>
> **AI 助理注意**：本文檔包含關鍵的架構約束和配置規範，請務必遵守以避免重複錯誤！

---

## 📚 文檔列表

### 1. [ARCHITECTURE.md](./ARCHITECTURE.md) - 完整架構文檔

**用途**：系統架構的完整參考指南

**包含內容**：
- 核心架構原則（CQRS、Outbox Pattern）
- 技術分工（Firebase vs Supabase）
- 資料流向（寫入/讀取流程）
- Supabase 資料庫結構（所有表格和欄位）
- Firestore 資料庫結構（所有 collection 和欄位）
- ID 映射規則（`firebase_uid` vs `users.id`）
- Backend API 規範
- Edge Functions 說明
- **🔐 RLS（Row Level Security）規則說明**
- **🧩 Outbox → Firestore Payload 格式契約**
- 開發規範
- 常見錯誤示例

**何時閱讀**：
- ✅ 第一次接觸專案時
- ✅ 不確定架構原則時
- ✅ 需要查詢資料庫結構時
- ✅ 遇到 ID 類型問題時
- ✅ 需要了解 RLS 保護機制時

---

### 2. [QUICK_REFERENCE.md](./QUICK_REFERENCE.md) - 快速參考卡片

**用途**：最常用規則的速查表

**包含內容**：
- ID 使用規則（表格形式）
- 訂單狀態流程
- 資料流向（簡化版）
- 代碼範本（Backend API、Edge Function、Flutter APP）
- **📦 環境變數與端口固定**
- **🧱 Firestore 安全規則與索引**
- 常見錯誤示例
- 檢查清單

**何時閱讀**：
- ✅ 開發前快速確認規則
- ✅ 不確定應該使用哪個 ID
- ✅ 需要代碼範本時
- ✅ 需要快速檢查時
- ✅ 配置環境變數時

---

### 3. [DEVELOPMENT_CHECKLIST.md](./DEVELOPMENT_CHECKLIST.md) - 開發檢查清單

**用途**：開發過程中的逐項檢查清單

**包含內容**：
- 開發前準備檢查
- Backend API 開發檢查
- Edge Function 開發檢查
- Flutter APP 開發檢查
- **📱 Flutter 開發注意事項**
- 測試檢查
- 代碼審查檢查
- 部署前檢查
- 常見錯誤檢查

**何時使用**：
- ✅ 開始新功能開發時
- ✅ 代碼審查時
- ✅ 部署前檢查時
- ✅ 遇到問題時自我檢查
- ✅ Flutter 專案配置時

---

## 🎯 使用流程

### 第一次接觸專案

```
1. 閱讀 ARCHITECTURE.md（完整理解架構）
   ↓
2. 閱讀 QUICK_REFERENCE.md（記住關鍵規則）
   ↓
3. 保存 DEVELOPMENT_CHECKLIST.md（開發時使用）
   ↓
4. 確認環境變數配置（.env 文件）
```

### 開始新功能開發

```
1. 複製 DEVELOPMENT_CHECKLIST.md 中的相關清單
   ↓
2. 查閱 QUICK_REFERENCE.md 確認規則
   ↓
3. 檢查是否需要修改 RLS 規則或 Firestore 規則
   ↓
4. 參考代碼範本開始開發
   ↓
5. 逐項檢查清單
   ↓
6. 如有疑問，查閱 ARCHITECTURE.md
```

### 遇到問題時

```
1. 查閱 QUICK_REFERENCE.md 的「常見錯誤」章節
   ↓
2. 使用 DEVELOPMENT_CHECKLIST.md 自我檢查
   ↓
3. 檢查環境變數和端口配置
   ↓
4. 查閱 ARCHITECTURE.md 的詳細說明
```

### AI 助理開發時

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

---

## ⚠️ 最常見的錯誤

### 錯誤 1：ID 類型混用

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

### 錯誤 2：違反 CQRS 架構

```dart
// ❌ 錯誤：直接寫入 Firestore
await FirebaseFirestore.instance.collection('orders_rt').add({...});

// ✅ 正確：通過 Backend API
await http.post(Uri.parse('$_baseUrl/bookings'), body: {...});
```

### 錯誤 3：跳過 ID 轉換

```typescript
// ❌ 錯誤：直接使用 firebase_uid
const { customerUid } = req.body;
await supabase.from('bookings').insert({
  customer_id: customerUid, // 錯誤！
});

// ✅ 正確：先轉換 ID
const { data: user } = await supabase
  .from('users')
  .select('id')
  .eq('firebase_uid', customerUid)
  .single();

await supabase.from('bookings').insert({
  customer_id: user.id, // 正確！
});
```

---

## 📊 架構圖

### CQRS 資料流向

```
┌─────────────┐
│ Flutter APP │
└──────┬──────┘
       │ HTTP POST (firebase_uid)
       ↓
┌─────────────┐
│ Backend API │
└──────┬──────┘
       │ 1. 查詢 users 表 (firebase_uid → users.id)
       │ 2. 寫入 Supabase (使用 users.id)
       ↓
┌─────────────┐
│  Supabase   │ ← 唯一真實數據源
└──────┬──────┘
       │ Trigger
       ↓
┌─────────────┐
│ Outbox 表   │
└──────┬──────┘
       │ Edge Function 輪詢
       ↓
┌─────────────┐
│ Edge Func   │
└──────┬──────┘
       │ 1. 查詢 users 表 (users.id → firebase_uid)
       │ 2. 寫入 Firestore (使用 firebase_uid)
       ↓
┌─────────────┐
│  Firestore  │ ← Supabase 的鏡像
└──────┬──────┘
       │ 即時查詢 (where customerId == firebase_uid)
       ↓
┌─────────────┐
│ Flutter APP │
└─────────────┘
```

---

## 🛠️ 開發工具

### 推薦的 IDE 擴展

- **TypeScript**: ESLint, Prettier
- **Dart/Flutter**: Dart, Flutter
- **資料庫**: PostgreSQL, Firestore

### 推薦的調試工具

- **Backend API**: Postman, Thunder Client
- **Supabase**: Supabase Studio
- **Firestore**: Firebase Console
- **Flutter**: Flutter DevTools

---

## 📞 需要幫助？

### 常見問題

1. **Q: 我應該使用哪個 ID？**
   - A: 查閱 [QUICK_REFERENCE.md](./QUICK_REFERENCE.md) 的「ID 使用規則」章節

2. **Q: 我應該從哪裡讀取資料？**
   - A: Flutter APP 從 Firestore 讀取，Backend API 從 Supabase 讀取

3. **Q: 我應該往哪裡寫入資料？**
   - A: 所有寫入都通過 Backend API 寫入 Supabase

4. **Q: 為什麼不能直接從 Flutter APP 寫入 Firestore？**
   - A: 違反 CQRS 架構，Firestore 是只讀的鏡像

5. **Q: Edge Function 什麼時候運行？**
   - A: 定時輪詢 Outbox 表（每分鐘），或手動觸發

### 聯絡方式

- **技術問題**: [待補充]
- **架構問題**: [待補充]
- **緊急問題**: [待補充]

---

## 📝 文檔維護

### 更新頻率

- **ARCHITECTURE.md**: 架構變更時更新
- **QUICK_REFERENCE.md**: 規則變更時更新
- **DEVELOPMENT_CHECKLIST.md**: 流程變更時更新

### 貢獻指南

如果您發現文檔有誤或需要補充：

1. 創建 Issue 描述問題
2. 提交 Pull Request 修改文檔
3. 通知團隊成員審查

---

## 🎓 學習路徑

### 新手開發者

```
Day 1: 閱讀 ARCHITECTURE.md（理解整體架構）
Day 2: 閱讀 QUICK_REFERENCE.md（記住關鍵規則）
Day 3: 使用 DEVELOPMENT_CHECKLIST.md 開發第一個功能
Day 4-7: 實踐並熟悉流程
```

### 有經驗的開發者

```
1. 快速瀏覽 ARCHITECTURE.md（了解架構差異）
2. 重點閱讀「ID 映射規則」章節
3. 參考代碼範本開始開發
4. 遇到問題時查閱文檔
```

---

**最後更新**: 2025-01-12
**維護者**: 開發團隊

