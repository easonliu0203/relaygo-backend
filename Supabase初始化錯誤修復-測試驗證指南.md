# Supabase 初始化錯誤修復 - 測試驗證指南

**日期**: 2025-10-10 10:30  
**問題**: Supabase 未初始化錯誤  
**狀態**: ✅ 已修復

---

## 📋 問題描述

### 錯誤訊息

```
'package:supabase_flutter/src/supabase.dart': Failed assertion: line 45 pos 7: 
'_instance._isInitialized': You must initialize the supabase instance before calling Supabase.instance
```

### 根本原因

客戶端和司機端應用使用的是 `main_customer.dart` 和 `main_driver.dart` 入口文件，但這兩個文件中**沒有初始化 Supabase**，導致在訪問個人資料頁面時出現錯誤。

---

## 🔧 修復內容

### 1. 修改客戶端入口文件

**文件**: `mobile/lib/apps/customer/main_customer.dart`

**修改內容**:
- 添加 `supabase_flutter` 導入
- 在 Firebase 初始化之前初始化 Supabase
- 添加配置檢查和錯誤處理
- 添加調試日誌輸出

### 2. 修改司機端入口文件

**文件**: `mobile/lib/apps/driver/main_driver.dart`

**修改內容**:
- 添加 `supabase_flutter` 導入
- 在 Firebase 初始化之前初始化 Supabase
- 添加配置檢查和錯誤處理
- 添加調試日誌輸出

### 3. 改進 SupabaseService

**文件**: `mobile/lib/core/services/supabase_service.dart`

**修改內容**:
- 改進錯誤處理
- 提供更清晰的錯誤訊息
- 使用 `late` 關鍵字延遲初始化

### 4. 創建配置檢查腳本

**文件**: `mobile/scripts/check-supabase-config.bat`

**功能**:
- 檢查 `.env` 文件是否存在
- 檢查 Supabase 配置是否完整
- 提供清晰的錯誤訊息

---

## 🧪 測試步驟

### 前置準備

#### 1. 檢查 Supabase 配置

```bash
cd d:\repo\mobile
scripts\check-supabase-config.bat
```

**預期輸出**:
```
========================================
檢查 Supabase 配置
========================================

[1/2] 檢查 .env 文件是否存在...
✅ .env 文件存在

[2/2] 檢查 Supabase 配置...
✅ Supabase 配置完整

========================================
配置檢查完成！
========================================
```

#### 2. 確認 .env 文件內容

打開 `mobile/.env` 文件，確認包含以下內容：

```env
# Supabase 配置
SUPABASE_URL=https://vlyhwegpvpnjyocqmfqc.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZseWh3ZWdwdnBuanlvY3FtZnFjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg5Nzc5OTYsImV4cCI6MjA3NDU1Mzk5Nn0.qnQBjvLm3IoXvJ0IptfMvPYRni1_7Den3iE9hFj-FYY
```

### 客戶端測試

#### 步驟 1: 清理並重新編譯

```bash
cd d:\repo\mobile
flutter clean
flutter pub get
```

#### 步驟 2: 啟動客戶端應用

```bash
scripts\run-customer.bat
```

**或手動執行**:
```bash
flutter run --flavor customer --target lib/apps/customer/main_customer.dart
```

#### 步驟 3: 檢查初始化日誌

在控制台中查找以下日誌：

```
✅ Supabase 初始化成功
```

**如果看到警告**:
```
⚠️ Supabase 配置不完整，跳過初始化
```
請檢查 `.env` 文件配置。

**如果看到錯誤**:
```
❌ 初始化過程中發生錯誤: ...
```
請查看錯誤詳情並修復。

#### 步驟 4: 登入測試帳號

- Email: `customer.test@relaygo.com`
- Password: `RelayGO2024!Customer`

#### 步驟 5: 訪問個人資料頁面

1. 點擊底部導航欄的「個人資料」標籤
2. **確認沒有出現 Supabase 未初始化錯誤**
3. 確認頁面正常顯示

#### 步驟 6: 測試編輯個人資料

1. 點擊「編輯個人資料」
2. **確認沒有出現錯誤**
3. 填寫資料並保存
4. 確認顯示「個人資料已更新」訊息

### 司機端測試

#### 步驟 1: 清理並重新編譯

```bash
cd d:\repo\mobile
flutter clean
flutter pub get
```

#### 步驟 2: 啟動司機端應用

```bash
scripts\run-driver.bat
```

**或手動執行**:
```bash
flutter run --flavor driver --target lib/apps/driver/main_driver.dart
```

#### 步驟 3: 檢查初始化日誌

在控制台中查找以下日誌：

```
✅ Supabase 初始化成功
```

#### 步驟 4: 登入測試帳號

- Email: `driver.test@relaygo.com`
- Password: `RelayGO2024!Driver`

#### 步驟 5: 訪問個人資料頁面

1. 點擊底部導航欄的「個人資料」標籤
2. **確認沒有出現 Supabase 未初始化錯誤**
3. 確認頁面正常顯示

#### 步驟 6: 測試編輯個人資料

1. 點擊「編輯個人資料」
2. **確認沒有出現錯誤**
3. 填寫資料並保存
4. 確認顯示「個人資料已更新」訊息

---

## ✅ 預期結果

### 客戶端

- ✅ 應用啟動時顯示「✅ Supabase 初始化成功」
- ✅ 個人資料頁面正常顯示，無錯誤
- ✅ 編輯個人資料功能正常工作
- ✅ 資料成功保存到 Supabase

### 司機端

- ✅ 應用啟動時顯示「✅ Supabase 初始化成功」
- ✅ 個人資料頁面正常顯示，無錯誤
- ✅ 編輯個人資料功能正常工作
- ✅ 資料成功保存到 Supabase

---

## 🔍 故障排除

### 問題 1: 仍然出現 Supabase 未初始化錯誤

**症狀**:
```
'_instance._isInitialized': You must initialize the supabase instance before calling Supabase.instance
```

**檢查**:
1. 確認使用正確的入口文件啟動應用
   - 客戶端: `lib/apps/customer/main_customer.dart`
   - 司機端: `lib/apps/driver/main_driver.dart`
2. 確認 `.env` 文件存在且配置正確
3. 確認控制台顯示「✅ Supabase 初始化成功」

**解決方案**:
```bash
# 1. 檢查配置
cd d:\repo\mobile
scripts\check-supabase-config.bat

# 2. 清理並重新編譯
flutter clean
flutter pub get

# 3. 重新啟動應用
scripts\run-customer.bat  # 或 scripts\run-driver.bat
```

### 問題 2: 顯示「⚠️ Supabase 配置不完整」

**症狀**:
```
⚠️ Supabase 配置不完整，跳過初始化
```

**原因**: `.env` 文件中缺少 `SUPABASE_URL` 或 `SUPABASE_ANON_KEY`

**解決方案**:
1. 打開 `mobile/.env` 文件
2. 確認包含以下內容：
   ```env
   SUPABASE_URL=https://vlyhwegpvpnjyocqmfqc.supabase.co
   SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   ```
3. 重新啟動應用

### 問題 3: .env 文件不存在

**症狀**:
```
❌ .env 文件不存在！
```

**解決方案**:
1. 在 `mobile` 目錄下創建 `.env` 文件
2. 添加 Supabase 配置（參考上面的內容）
3. 重新啟動應用

### 問題 4: 初始化過程中發生其他錯誤

**症狀**:
```
❌ 初始化過程中發生錯誤: ...
```

**檢查**:
1. 查看完整的錯誤訊息和堆疊追蹤
2. 確認網路連接正常
3. 確認 Supabase 專案正常運行

**解決方案**:
```bash
# 查看詳細日誌
flutter run --verbose --flavor customer --target lib/apps/customer/main_customer.dart
```

---

## 📊 測試檢查清單

### 配置檢查

- [ ] `.env` 文件存在
- [ ] `SUPABASE_URL` 配置正確
- [ ] `SUPABASE_ANON_KEY` 配置正確
- [ ] 配置檢查腳本通過

### 客戶端

- [ ] 應用成功啟動
- [ ] 控制台顯示「✅ Supabase 初始化成功」
- [ ] 成功登入測試帳號
- [ ] 個人資料頁面正常顯示
- [ ] 沒有 Supabase 未初始化錯誤
- [ ] 編輯個人資料功能正常
- [ ] 資料成功保存

### 司機端

- [ ] 應用成功啟動
- [ ] 控制台顯示「✅ Supabase 初始化成功」
- [ ] 成功登入測試帳號
- [ ] 個人資料頁面正常顯示
- [ ] 沒有 Supabase 未初始化錯誤
- [ ] 編輯個人資料功能正常
- [ ] 資料成功保存

---

## 📝 修復總結

### 修改的文件

| 文件 | 修改內容 |
|------|----------|
| `mobile/lib/apps/customer/main_customer.dart` | 添加 Supabase 初始化 |
| `mobile/lib/apps/driver/main_driver.dart` | 添加 Supabase 初始化 |
| `mobile/lib/core/services/supabase_service.dart` | 改進錯誤處理 |

### 創建的文件

| 文件 | 說明 |
|------|------|
| `mobile/scripts/check-supabase-config.bat` | 配置檢查腳本 |
| `Supabase初始化錯誤修復-測試驗證指南.md` | 測試指南 |

---

## 🎯 成功標準

測試通過的標準：

1. ✅ 客戶端和司機端應用都能成功啟動
2. ✅ 控制台顯示「✅ Supabase 初始化成功」
3. ✅ 個人資料頁面正常顯示，無錯誤
4. ✅ 編輯個人資料功能正常工作
5. ✅ 資料成功保存到 Supabase

---

## 📞 需要幫助？

### 查看文檔
- 修復文檔: `docs/20251010_1030_41_Supabase初始化錯誤修復.md`
- 個人資料功能文檔: `docs/20251010_1000_40_客戶端和司機端個人資料編輯功能實作.md`

### 執行腳本
```bash
# 檢查配置
cd d:\repo\mobile
scripts\check-supabase-config.bat

# 啟動客戶端
scripts\run-customer.bat

# 啟動司機端
scripts\run-driver.bat
```

### 檢查控制台
- Supabase 控制台: https://supabase.com/dashboard/project/vlyhwegpvpnjyocqmfqc
- Firebase 控制台: https://console.firebase.google.com/project/ride-platform-f1676

---

**祝測試順利！** 🚀

