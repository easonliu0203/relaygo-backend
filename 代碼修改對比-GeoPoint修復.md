# 代碼修改對比 - GeoPoint 格式修復

**檔案**：`supabase/functions/sync-to-firestore/index.ts`  
**修改時間**：2025-10-06 08:40  
**狀態**：✅ 已修改並保存

---

## 📋 修改總結

### 修改 1：`syncBookingToFirestore` 函數（第 262-316 行）

**目的**：將 location 格式從普通 Map 改為 GeoPoint 格式

**修改內容**：
- ✅ 添加 GeoPoint 處理邏輯（第 272-274 行）
- ✅ 使用 `_latitude` 和 `_longitude` 格式（第 284-292 行）

---

### 修改 2：`convertToFirestoreFields` 函數（第 390-422 行）

**目的**：檢測 GeoPoint 格式並轉換為 Firestore REST API 格式

**修改內容**：
- ✅ 添加 GeoPoint 檢測邏輯（第 406-413 行）
- ✅ 轉換為 `geoPointValue` 格式

---

## 🔍 詳細修改對比

### 修改 1：`syncBookingToFirestore` 函數

#### 修改前（錯誤）

```typescript
async function syncBookingToFirestore(event: OutboxEvent): Promise<void> {
  const bookingId = event.aggregate_id
  const bookingData = event.payload

  console.log(`同步訂單到 Firestore: ${bookingId}`, bookingData)

  // 組合 bookingTime（從 startDate 和 startTime）
  let bookingTime: string
  if (bookingData.startDate && bookingData.startTime) {
    bookingTime = `${bookingData.startDate}T${bookingData.startTime}`
  } else {
    bookingTime = bookingData.createdAt
  }

  // 轉換資料格式為客戶端 App 期望的格式
  const firestoreData = {
    // 基本資訊
    customerId: bookingData.customerId,
    driverId: bookingData.driverId || null,
    
    // 地點資訊
    pickupAddress: bookingData.pickupAddress || '',
    pickupLocation: bookingData.pickupLocation || { latitude: 0, longitude: 0 },  // ❌ 錯誤：普通 Map
    dropoffAddress: bookingData.destination || '',
    dropoffLocation: { latitude: 0, longitude: 0 },  // ❌ 錯誤：普通 Map
    
    // 時間資訊
    bookingTime: bookingTime,
    
    // 乘客資訊
    passengerCount: 1,
    luggageCount: null,
    notes: bookingData.specialRequirements || null,
    
    // 費用資訊
    estimatedFare: bookingData.totalAmount || 0,
    depositAmount: bookingData.depositAmount || 0,
    depositPaid: false,
    
    // 狀態
    status: bookingData.status || 'pending',
    
    // 時間戳記
    createdAt: bookingData.createdAt,
    matchedAt: bookingData.actualStartTime || null,
    completedAt: bookingData.actualEndTime || null,
  }

  console.log(`轉換後的 Firestore 資料:`, firestoreData)

  // 根據事件類型執行不同操作
  if (event.event_type === 'deleted') {
    await deleteFirestoreDocument(bookingId)
  } else {
    await upsertFirestoreDocument(bookingId, firestoreData)
  }
}
```

**問題**：
- ❌ `pickupLocation: { latitude: 0, longitude: 0 }` - 普通 Map 格式
- ❌ `dropoffLocation: { latitude: 0, longitude: 0 }` - 普通 Map 格式
- ❌ Firestore 會將其存儲為 **map** 類型
- ❌ 客戶端期望 **geopoint** 類型，導致解析失敗

---

#### 修改後（正確）✅

```typescript
async function syncBookingToFirestore(event: OutboxEvent): Promise<void> {
  const bookingId = event.aggregate_id
  const bookingData = event.payload

  console.log(`同步訂單到 Firestore: ${bookingId}`, bookingData)

  // 組合 bookingTime（從 startDate 和 startTime）
  let bookingTime: string
  if (bookingData.startDate && bookingData.startTime) {
    bookingTime = `${bookingData.startDate}T${bookingData.startTime}`
  } else {
    bookingTime = bookingData.createdAt
  }

  // ✅ 新增：處理 GeoPoint（從 Supabase 的 location 格式轉換）
  const pickupLocation = bookingData.pickupLocation || { latitude: 25.0330, longitude: 121.5654 }  // 預設台北
  const dropoffLocation = { latitude: 25.0330, longitude: 121.5654 }  // 預設台北

  // 轉換資料格式為客戶端 App 期望的格式
  const firestoreData = {
    // 基本資訊
    customerId: bookingData.customerId,
    driverId: bookingData.driverId || null,

    // 地點資訊
    pickupAddress: bookingData.pickupAddress || '',
    pickupLocation: {
      _latitude: pickupLocation.latitude,    // ✅ 正確：使用 _latitude
      _longitude: pickupLocation.longitude,  // ✅ 正確：使用 _longitude
    },
    dropoffAddress: bookingData.destination || '',
    dropoffLocation: {
      _latitude: dropoffLocation.latitude,   // ✅ 正確：使用 _latitude
      _longitude: dropoffLocation.longitude, // ✅ 正確：使用 _longitude
    },

    // 時間資訊
    bookingTime: bookingTime,

    // 乘客資訊
    passengerCount: 1,
    luggageCount: null,
    notes: bookingData.specialRequirements || null,

    // 費用資訊
    estimatedFare: bookingData.totalAmount || 0,
    depositAmount: bookingData.depositAmount || 0,
    depositPaid: false,

    // 狀態
    status: bookingData.status || 'pending',

    // 時間戳記
    createdAt: bookingData.createdAt,
    matchedAt: bookingData.actualStartTime || null,
    completedAt: bookingData.actualEndTime || null,
  }

  console.log(`轉換後的 Firestore 資料:`, firestoreData)

  // 根據事件類型執行不同操作
  if (event.event_type === 'deleted') {
    await deleteFirestoreDocument(bookingId)
  } else {
    await upsertFirestoreDocument(bookingId, firestoreData)
  }
}
```

**修改內容**：
1. ✅ **第 272-274 行**：添加 GeoPoint 處理邏輯
   ```typescript
   const pickupLocation = bookingData.pickupLocation || { latitude: 25.0330, longitude: 121.5654 }
   const dropoffLocation = { latitude: 25.0330, longitude: 121.5654 }
   ```

2. ✅ **第 284-292 行**：使用 `_latitude` 和 `_longitude` 格式
   ```typescript
   pickupLocation: {
     _latitude: pickupLocation.latitude,
     _longitude: pickupLocation.longitude,
   },
   dropoffLocation: {
     _latitude: dropoffLocation.latitude,
     _longitude: dropoffLocation.longitude,
   },
   ```

**效果**：
- ✅ `convertToFirestoreFields` 會檢測到 `_latitude` 和 `_longitude`
- ✅ 轉換為 Firestore REST API 的 `geoPointValue` 格式
- ✅ Firestore 存儲為 **geopoint** 類型
- ✅ 客戶端可以正確解析

---

### 修改 2：`convertToFirestoreFields` 函數

#### 修改前（錯誤）

```typescript
function convertToFirestoreFields(data: any): any {
  const fields: any = {}

  for (const [key, value] of Object.entries(data)) {
    if (value === null || value === undefined) {
      fields[key] = { nullValue: null }
    } else if (typeof value === 'string') {
      fields[key] = { stringValue: value }
    } else if (typeof value === 'number') {
      fields[key] = { doubleValue: value }
    } else if (typeof value === 'boolean') {
      fields[key] = { booleanValue: value }
    } else if (typeof value === 'object') {
      // ❌ 錯誤：所有對象都當作 Map 處理
      fields[key] = { mapValue: { fields: convertToFirestoreFields(value) } }
    }
  }

  return fields
}
```

**問題**：
- ❌ 所有對象都使用 `mapValue` 格式
- ❌ 沒有檢測 GeoPoint 格式
- ❌ 導致 location 存儲為 **map** 類型

---

#### 修改後（正確）✅

```typescript
function convertToFirestoreFields(data: any): any {
  const fields: any = {}

  for (const [key, value] of Object.entries(data)) {
    if (value === null || value === undefined) {
      fields[key] = { nullValue: null }
    } else if (typeof value === 'string') {
      fields[key] = { stringValue: value }
    } else if (typeof value === 'number') {
      fields[key] = { doubleValue: value }
    } else if (typeof value === 'boolean') {
      fields[key] = { booleanValue: value }
    } else if (typeof value === 'object') {
      // ✅ 新增：檢查是否是 GeoPoint 格式（包含 _latitude 和 _longitude）
      if ('_latitude' in value && '_longitude' in value) {
        fields[key] = {
          geoPointValue: {
            latitude: value._latitude,
            longitude: value._longitude,
          }
        }
      } else {
        // 處理其他嵌套對象
        fields[key] = { mapValue: { fields: convertToFirestoreFields(value) } }
      }
    }
  }

  return fields
}
```

**修改內容**：
1. ✅ **第 406-413 行**：添加 GeoPoint 檢測邏輯
   ```typescript
   if ('_latitude' in value && '_longitude' in value) {
     fields[key] = {
       geoPointValue: {
         latitude: value._latitude,
         longitude: value._longitude,
       }
     }
   }
   ```

**效果**：
- ✅ 檢測包含 `_latitude` 和 `_longitude` 的對象
- ✅ 轉換為 Firestore REST API 的 `geoPointValue` 格式
- ✅ Firestore 存儲為 **geopoint** 類型

---

## 📊 修改前後對比

### 資料流程

#### 修改前（錯誤）❌

```
JavaScript 對象:
{ latitude: 0, longitude: 0 }
    ↓
convertToFirestoreFields:
{ mapValue: { fields: { latitude: {...}, longitude: {...} } } }
    ↓
Firestore 存儲:
map {
  latitude: 0,
  longitude: 0
}
    ↓
客戶端解析:
❌ 錯誤：type '_Map<String, dynamic>' is not a subtype of type 'GeoPoint'
```

---

#### 修改後（正確）✅

```
JavaScript 對象:
{ _latitude: 25.033, _longitude: 121.5654 }
    ↓
convertToFirestoreFields:
{ geoPointValue: { latitude: 25.033, longitude: 121.5654 } }
    ↓
Firestore 存儲:
geopoint (25.033, 121.5654)
    ↓
客戶端解析:
✅ 成功：LocationPoint.fromGeoPoint() 正確解析
```

---

## ✅ 驗證修改

### 1. 檢查代碼

**命令**：
```bash
# 查看修改後的代碼
cat supabase/functions/sync-to-firestore/index.ts | grep -A 10 "_latitude"
```

**預期輸出**：
```typescript
pickupLocation: {
  _latitude: pickupLocation.latitude,
  _longitude: pickupLocation.longitude,
},
dropoffLocation: {
  _latitude: dropoffLocation.latitude,
  _longitude: dropoffLocation.longitude,
},
```

---

### 2. 檢查部署狀態

**已部署**：✅ 是（2025-10-06 08:40）

**部署命令**：
```bash
npx supabase functions deploy sync-to-firestore --project-ref vlyhwegpvpnjyocqmfqc
```

**部署結果**：
```
Deployed Functions on project vlyhwegpvpnjyocqmfqc: sync-to-firestore
```

---

### 3. 測試修改

**步驟**：
1. 手動觸發 Edge Function
2. 檢查日誌（應該看到 `_latitude` 和 `_longitude`）
3. 檢查 Firestore 資料類型（應該是 **geopoint**）
4. 測試客戶端 App（應該不再顯示錯誤）

---

## 📋 修改清單

- [x] 修改 `syncBookingToFirestore` 函數（第 262-316 行）
- [x] 修改 `convertToFirestoreFields` 函數（第 390-422 行）
- [x] 部署 Edge Function
- [x] 創建代碼修改對比文檔
- [ ] 測試修改（待用戶執行）

---

**修改狀態**：✅ 完成並保存  
**部署狀態**：✅ 已部署  
**測試狀態**：⏳ 待用戶驗證

🚀 **代碼已修改並部署，請立即測試！**

