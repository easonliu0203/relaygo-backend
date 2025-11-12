# CQRS 架構修復計劃

**日期**：2025-10-07  
**目標**：修復所有違反「單一真實源」原則的問題  
**預計時間**：2-3 小時

---

## 📋 問題總結

### 🚨 發現的問題

1. **舊版 Firestore 直接寫入方法仍然存在**（高風險）
   - `createBooking()` - 直接寫入 Firestore
   - `payDeposit()` - 直接更新 Firestore
   - `cancelBooking()` - 直接更新 Firestore

2. **Firestore 規則允許客戶端寫入 `bookings` 集合**（高風險）
   - 允許 `create` 操作
   - 允許 `update` 操作

3. **取消訂單功能缺少 Supabase API**（中風險）
   - 必須使用舊版方法
   - 無法完全遵循 CQRS

---

## 🎯 修復目標

### 預期的正確架構

```
客戶端 App
    ↓ (寫入) POST /api/bookings
Supabase/PostgreSQL ← 單一真實源（Single Source of Truth）
    ↓ (Trigger)
Outbox 表
    ↓ (Cron Job 每 30 秒)
Edge Function (sync-to-firestore)
    ↓ (雙寫)
Firestore (orders_rt + bookings) ← 讀模型（Read Model）
    ↑ (讀取)
客戶端 App
```

**關鍵原則**：
- ✅ 所有寫入操作都通過 Supabase API
- ✅ Firestore 只作為 Read Model（只讀）
- ✅ Firestore 規則禁止客戶端寫入
- ✅ Edge Function 是唯一寫入 Firestore 的機制

---

## 🛠️ 修復步驟

### 步驟 1：修改 Firestore 規則（優先級 1）⭐

**目標**：禁止客戶端寫入 `bookings` 集合

**檔案**：`firebase/firestore.rules`

**修改前**（錯誤）：
```javascript
match /bookings/{bookingId} {
  allow read: if request.auth != null &&
    (request.auth.uid == resource.data.customerId ||
     request.auth.uid == resource.data.driverId);
  allow create: if request.auth != null &&
    request.auth.uid == request.resource.data.customerId;  // ❌
  allow update: if request.auth != null &&
    (request.auth.uid == resource.data.customerId ||
     request.auth.uid == resource.data.driverId);  // ❌
}
```

**修改後**（正確）：
```javascript
match /bookings/{bookingId} {
  // 允許用戶讀取自己的訂單
  allow read: if request.auth != null &&
    (request.auth.uid == resource.data.customerId ||
     request.auth.uid == resource.data.driverId);

  // 禁止客戶端寫入（由 Supabase Edge Function 寫入）
  allow write: if false;  // ✅ 強制使用 Supabase API
}
```

**部署**：
```bash
firebase deploy --only firestore:rules
```

**驗證**：
- 嘗試從客戶端寫入 `bookings` 集合
- 應該收到權限錯誤

---

### 步驟 2：刪除舊版 Firestore 直接寫入方法（優先級 1）⭐

**目標**：移除所有直接寫入 Firestore 的方法

**檔案**：`mobile/lib/core/services/booking_service.dart`

#### 2.1 刪除 `createBooking()` 方法

**原因**：
- 已有 `createBookingWithSupabase()` 替代
- 客戶端已使用新版方法
- 保留會造成混淆和誤用

**操作**：
- 刪除整個方法（第 26-67 行）
- 或標記為 `@Deprecated` 並內部調用 `createBookingWithSupabase()`

---

#### 2.2 刪除 `payDeposit()` 方法

**原因**：
- 已有 `payDepositWithSupabase()` 替代
- 客戶端已使用新版方法
- 保留會造成混淆和誤用

**操作**：
- 刪除整個方法（第 172-182 行）
- 或標記為 `@Deprecated` 並拋出錯誤

---

#### 2.3 重構 `cancelBooking()` 方法

**原因**：
- 目前直接寫入 Firestore
- 需要改為調用 Supabase API
- 但 Supabase API 尚未實現

**操作**：
- 暫時保留方法
- 添加 TODO 註釋
- 等待步驟 3 完成後重構

---

### 步驟 3：實現取消訂單的 Supabase API（優先級 2）

**目標**：提供符合 CQRS 的取消訂單功能

#### 3.1 實現後端 API

**檔案**：`web-admin/src/app/api/bookings/[id]/cancel/route.ts`（新增）

**API 規格**：
```typescript
POST /api/bookings/:id/cancel
Content-Type: application/json

{
  "customerUid": "hUu4fH5dTlW9VUYm6GojXvRLdni2",
  "reason": "客戶取消"
}

Response:
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "status": "cancelled",
    "cancelledAt": "2025-10-07T08:47:00Z"
  }
}
```

**實現邏輯**：
1. 驗證用戶權限（只能取消自己的訂單）
2. 檢查訂單狀態（只能取消 pending 或 matched 狀態）
3. 更新 Supabase `bookings` 表
4. Trigger 自動寫入 `outbox` 表
5. Edge Function 自動同步到 Firestore

---

#### 3.2 實現客戶端方法

**檔案**：`mobile/lib/core/services/booking_service.dart`

**新增方法**：
```dart
/// 取消訂單（使用 Supabase API）
Future<Map<String, dynamic>> cancelBookingWithSupabase(
  String bookingId,
  String reason,
) async {
  try {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('用戶未登入');
    }

    debugPrint('[BookingService] 開始取消訂單: $bookingId');

    final requestBody = {
      'customerUid': user.uid,
      'reason': reason,
    };

    final response = await http.post(
      Uri.parse('$_baseUrl/bookings/$bookingId/cancel'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(requestBody),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        debugPrint('[BookingService] 取消成功');

        // 資料將由 Supabase Trigger 自動鏡像到 Firestore
        // 不再從客戶端直接寫入 Firebase

        return data['data'];
      } else {
        throw Exception(data['error'] ?? '取消訂單失敗');
      }
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? '取消訂單失敗');
    }
  } catch (e) {
    debugPrint('[BookingService] 取消訂單失敗: $e');
    throw Exception('取消訂單失敗: $e');
  }
}
```

---

#### 3.3 重構舊版 `cancelBooking()` 方法

**修改前**（錯誤）：
```dart
Future<void> cancelBooking(String orderId) async {
  await _firestore
      .collection('bookings')
      .doc(orderId)
      .update({
        'status': BookingStatus.cancelled.name,
        'completedAt': Timestamp.now(),
      });
}
```

**修改後**（正確）：
```dart
/// 取消訂單（已棄用，請使用 cancelBookingWithSupabase）
@Deprecated('請使用 cancelBookingWithSupabase 方法')
Future<void> cancelBooking(String orderId) async {
  throw Exception('此方法已棄用，請使用 cancelBookingWithSupabase');
}
```

---

### 步驟 4：更新客戶端調用（優先級 3）

**目標**：確保所有地方都使用新版 Supabase API 方法

**檢查項目**：
- [ ] 搜索所有調用 `createBooking()` 的地方
- [ ] 搜索所有調用 `payDeposit()` 的地方
- [ ] 搜索所有調用 `cancelBooking()` 的地方
- [ ] 替換為對應的 `*WithSupabase()` 方法

**搜索命令**：
```bash
# 搜索 createBooking 調用
grep -r "createBooking(" mobile/lib/

# 搜索 payDeposit 調用
grep -r "payDeposit(" mobile/lib/

# 搜索 cancelBooking 調用
grep -r "cancelBooking(" mobile/lib/
```

---

### 步驟 5：測試驗證（優先級 1）⭐

**目標**：確認所有修復都正確實施

#### 5.1 測試 Firestore 規則

**測試 1：嘗試創建訂單**
```dart
// 應該失敗（權限錯誤）
await FirebaseFirestore.instance
    .collection('bookings')
    .add({...});
```

**預期結果**：❌ 權限錯誤

---

**測試 2：嘗試更新訂單**
```dart
// 應該失敗（權限錯誤）
await FirebaseFirestore.instance
    .collection('bookings')
    .doc('some-id')
    .update({...});
```

**預期結果**：❌ 權限錯誤

---

#### 5.2 測試 Supabase API 流程

**測試 1：創建訂單**
1. 從客戶端調用 `createBookingWithSupabase()`
2. 檢查 Supabase `bookings` 表（應該有新訂單）
3. 檢查 Supabase `outbox` 表（應該有事件）
4. 等待 30 秒（Cron Job 執行）
5. 檢查 Firestore `orders_rt` 集合（應該有新訂單）
6. 檢查 Firestore `bookings` 集合（應該有新訂單）

**預期結果**：✅ 所有步驟成功

---

**測試 2：支付訂金**
1. 從客戶端調用 `payDepositWithSupabase()`
2. 檢查 Supabase `bookings` 表（`deposit_paid` 應該為 true）
3. 檢查 Supabase `outbox` 表（應該有更新事件）
4. 等待 30 秒（Cron Job 執行）
5. 檢查 Firestore `orders_rt` 集合（`depositPaid` 應該為 true）
6. 檢查 Firestore `bookings` 集合（`depositPaid` 應該為 true）

**預期結果**：✅ 所有步驟成功

---

**測試 3：取消訂單**
1. 從客戶端調用 `cancelBookingWithSupabase()`
2. 檢查 Supabase `bookings` 表（`status` 應該為 'cancelled'）
3. 檢查 Supabase `outbox` 表（應該有更新事件）
4. 等待 30 秒（Cron Job 執行）
5. 檢查 Firestore `orders_rt` 集合（`status` 應該為 'cancelled'）
6. 檢查 Firestore `bookings` 集合（`status` 應該為 'cancelled'）

**預期結果**：✅ 所有步驟成功

---

## 📋 修復檢查清單

### 優先級 1（立即執行）⭐

- [ ] **修改 Firestore 規則**
  - [ ] 禁止客戶端寫入 `bookings` 集合
  - [ ] 部署規則：`firebase deploy --only firestore:rules`
  - [ ] 測試規則：嘗試從客戶端寫入（應該失敗）

- [ ] **刪除舊版方法**
  - [ ] 刪除或標記 `createBooking()` 為 `@Deprecated`
  - [ ] 刪除或標記 `payDeposit()` 為 `@Deprecated`
  - [ ] 搜索並替換所有調用

- [ ] **測試驗證**
  - [ ] 測試 Firestore 規則禁止寫入
  - [ ] 測試創建訂單流程（Supabase API）
  - [ ] 測試支付訂金流程（Supabase API）

---

### 優先級 2（盡快執行）

- [ ] **實現取消訂單 API**
  - [ ] 創建後端 API：`POST /api/bookings/:id/cancel`
  - [ ] 實現客戶端方法：`cancelBookingWithSupabase()`
  - [ ] 重構舊版 `cancelBooking()` 方法
  - [ ] 測試取消訂單流程

---

### 優先級 3（後續執行）

- [ ] **代碼清理**
  - [ ] 移除所有 `@Deprecated` 方法
  - [ ] 更新文檔說明正確的架構
  - [ ] 添加代碼註釋說明 CQRS 原則

---

## 🎯 預期結果

修復完成後，系統應該：

1. ✅ **所有寫入操作都通過 Supabase API**
   - 創建訂單：`createBookingWithSupabase()`
   - 支付訂金：`payDepositWithSupabase()`
   - 取消訂單：`cancelBookingWithSupabase()`

2. ✅ **Firestore 只作為 Read Model**
   - 客戶端只能讀取 `orders_rt` 和 `bookings` 集合
   - 客戶端無法寫入任何集合（規則禁止）

3. ✅ **Edge Function 是唯一寫入 Firestore 的機制**
   - 使用 Service Account 繞過規則
   - 雙寫到 `orders_rt` 和 `bookings` 集合

4. ✅ **資料一致性保證**
   - Supabase 是單一真實源
   - Firestore 是 Supabase 的鏡像
   - 所有變更都通過 Outbox Pattern 同步

---

## 📚 相關文檔

- `docs/20251007_0847_12_CQRS架構審查報告.md` - 完整審查報告
- `docs/20251007_0022_11_Firestore雙寫策略實施.md` - 雙寫策略實施
- `立即測試-Firestore雙寫策略.md` - 測試指南

---

**修復狀態**：⏳ 待執行  
**預計時間**：2-3 小時  
**風險等級**：中（需要仔細測試）

🚀 **請按照優先級順序執行修復步驟，確保每個步驟都經過測試驗證！**

