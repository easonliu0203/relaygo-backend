# Edge Functions 完整代碼

**更新日期**：2025-10-04  
**狀態**：✅ 已部署

---

## 📝 sync-to-firestore/index.ts

**功能**：消費 outbox 事件佇列，將訂單變更推送到 Firestore

**修復內容**：
- ✅ aggregate_type 從 'order' 改為 'booking'
- ✅ 函數重命名為 syncBookingToFirestore
- ✅ payload 欄位映射更新以匹配 Trigger
- ✅ 增強日誌記錄

**完整代碼**：

```typescript
/**
 * Supabase Edge Function: sync-to-firestore
 *
 * 功能：消費 outbox 事件佇列，將訂單變更推送到 Firestore
 * 架構：Outbox Pattern / CDC (Change Data Capture)
 *
 * 資料流：
 * 1. Supabase Trigger 監聽 bookings 表變更
 * 2. 寫入 outbox 表（事件佇列）
 * 3. 本 Edge Function 消費 outbox 事件
 * 4. 推送到 Firestore orders_rt/{bookingId} 集合
 * 5. 標記事件為已處理
 *
 * 修復日期：2025-10-04
 * 修復內容：
 * - aggregate_type 從 'order' 改為 'booking'
 * - 函數重命名為 syncBookingToFirestore
 * - payload 欄位映射更新以匹配 Trigger
 * - 增強日誌記錄
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Firebase Admin SDK（使用 REST API）
const FIREBASE_PROJECT_ID = Deno.env.get('FIREBASE_PROJECT_ID')!
const FIREBASE_API_KEY = Deno.env.get('FIREBASE_API_KEY')!

// Supabase 配置
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

interface OutboxEvent {
  id: string
  aggregate_type: string
  aggregate_id: string
  event_type: 'created' | 'updated' | 'deleted'
  payload: any
  created_at: string
  retry_count: number
}

serve(async (req) => {
  try {
    // 創建 Supabase 客戶端
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

    // 1. 查詢未處理的事件（批次處理，每次最多 10 個）
    const { data: events, error: fetchError } = await supabase
      .from('outbox')
      .select('*')
      .is('processed_at', null)
      .lt('retry_count', 3) // 最多重試 3 次
      .order('created_at', { ascending: true })
      .limit(10)

    if (fetchError) {
      throw new Error(`查詢 outbox 失敗: ${fetchError.message}`)
    }

    if (!events || events.length === 0) {
      return new Response(
        JSON.stringify({ message: '沒有待處理的事件', processed: 0 }),
        { headers: { 'Content-Type': 'application/json' }, status: 200 }
      )
    }

    console.log(`找到 ${events.length} 個待處理事件`)

    // 2. 處理每個事件
    const results = await Promise.allSettled(
      events.map((event: OutboxEvent) => processEvent(event, supabase))
    )

    // 3. 統計處理結果
    const successCount = results.filter(r => r.status === 'fulfilled').length
    const failureCount = results.filter(r => r.status === 'rejected').length

    console.log(`處理完成: 成功 ${successCount}, 失敗 ${failureCount}`)

    return new Response(
      JSON.stringify({
        message: '事件處理完成',
        total: events.length,
        success: successCount,
        failure: failureCount,
      }),
      { headers: { 'Content-Type': 'application/json' }, status: 200 }
    )
  } catch (error) {
    console.error('Edge Function 錯誤:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { 'Content-Type': 'application/json' }, status: 500 }
    )
  }
})

/**
 * 處理單個 outbox 事件
 */
async function processEvent(event: OutboxEvent, supabase: any): Promise<void> {
  try {
    console.log(`處理事件: ${event.id}, 類型: ${event.event_type}, 聚合: ${event.aggregate_id}`)

    // 根據事件類型處理
    if (event.aggregate_type === 'booking') {
      await syncBookingToFirestore(event)
    } else {
      console.warn(`未知的聚合類型: ${event.aggregate_type}`)
    }

    // 標記為已處理
    await supabase
      .from('outbox')
      .update({ processed_at: new Date().toISOString() })
      .eq('id', event.id)

    console.log(`事件 ${event.id} 處理成功`)
  } catch (error) {
    console.error(`事件 ${event.id} 處理失敗:`, error)

    // 更新重試次數和錯誤訊息
    await supabase
      .from('outbox')
      .update({
        retry_count: event.retry_count + 1,
        error_message: error.message,
      })
      .eq('id', event.id)

    throw error
  }
}

/**
 * 同步訂單到 Firestore
 */
async function syncBookingToFirestore(event: OutboxEvent): Promise<void> {
  const bookingId = event.aggregate_id
  const bookingData = event.payload

  console.log(`同步訂單到 Firestore: ${bookingId}`, bookingData)

  // 轉換資料格式為 Firestore 格式（匹配 Trigger payload 格式）
  const firestoreData = {
    id: bookingData.id,
    bookingNumber: bookingData.bookingNumber,
    customerId: bookingData.customerId,
    status: bookingData.status,
    pickupAddress: bookingData.pickupAddress || '',
    destination: bookingData.destination || '',
    startDate: bookingData.startDate,
    startTime: bookingData.startTime,
    durationHours: bookingData.durationHours,
    vehicleType: bookingData.vehicleType,
    specialRequirements: bookingData.specialRequirements || '',
    requiresForeignLanguage: bookingData.requiresForeignLanguage || false,
    basePrice: bookingData.basePrice,
    foreignLanguageSurcharge: bookingData.foreignLanguageSurcharge || 0,
    overtimeFee: bookingData.overtimeFee || 0,
    tipAmount: bookingData.tipAmount || 0,
    totalAmount: bookingData.totalAmount,
    depositAmount: bookingData.depositAmount,
    pickupLocation: bookingData.pickupLocation || { latitude: 0, longitude: 0 },
    createdAt: bookingData.createdAt,
    updatedAt: bookingData.updatedAt,
    driverId: bookingData.driverId || null,
    actualStartTime: bookingData.actualStartTime || null,
    actualEndTime: bookingData.actualEndTime || null,
  }

  // 根據事件類型執行不同操作
  if (event.event_type === 'deleted') {
    // 刪除 Firestore 文檔
    await deleteFirestoreDocument(bookingId)
  } else {
    // 創建或更新 Firestore 文檔
    await upsertFirestoreDocument(bookingId, firestoreData)
  }
}

/**
 * 創建或更新 Firestore 文檔
 */
async function upsertFirestoreDocument(bookingId: string, data: any): Promise<void> {
  // 使用 Firestore REST API
  const url = `https://firestore.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/databases/(default)/documents/orders_rt/${bookingId}`

  // 轉換為 Firestore 格式
  const firestoreFields = convertToFirestoreFields(data)

  console.log(`準備更新 Firestore: orders_rt/${bookingId}`)

  const response = await fetch(url, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${FIREBASE_API_KEY}`,
    },
    body: JSON.stringify({
      fields: firestoreFields,
    }),
  })

  if (!response.ok) {
    const errorText = await response.text()
    console.error(`Firestore 更新失敗 (${response.status}):`, errorText)
    throw new Error(`Firestore 更新失敗 (${response.status}): ${errorText}`)
  }

  console.log(`✅ Firestore 文檔已更新: orders_rt/${bookingId}`)
}

/**
 * 刪除 Firestore 文檔
 */
async function deleteFirestoreDocument(bookingId: string): Promise<void> {
  const url = `https://firestore.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/databases/(default)/documents/orders_rt/${bookingId}`

  console.log(`準備刪除 Firestore: orders_rt/${bookingId}`)

  const response = await fetch(url, {
    method: 'DELETE',
    headers: {
      'Authorization': `Bearer ${FIREBASE_API_KEY}`,
    },
  })

  if (!response.ok && response.status !== 404) {
    const errorText = await response.text()
    console.error(`Firestore 刪除失敗 (${response.status}):`, errorText)
    throw new Error(`Firestore 刪除失敗 (${response.status}): ${errorText}`)
  }

  console.log(`✅ Firestore 文檔已刪除: orders_rt/${bookingId}`)
}

/**
 * 轉換為 Firestore 欄位格式
 */
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
      // 處理嵌套對象（例如 location）
      fields[key] = { mapValue: { fields: convertToFirestoreFields(value) } }
    }
  }

  return fields
}
```

---

## 📝 cleanup-outbox/index.ts

**功能**：清理舊的 outbox 事件（保留最近 7 天的已處理事件）

**狀態**：✅ 無需修改（代碼正確）

**完整代碼**：

```typescript
/**
 * Supabase Edge Function: cleanup-outbox
 * 
 * 功能：清理舊的 outbox 事件（保留最近 7 天的已處理事件）
 * 執行頻率：每天凌晨 2 點
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

serve(async (req) => {
  try {
    console.log('開始清理舊的 outbox 事件...')

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

    // 計算 7 天前的時間
    const sevenDaysAgo = new Date()
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7)

    // 刪除 7 天前的已處理事件
    const { data, error } = await supabase
      .from('outbox')
      .delete()
      .not('processed_at', 'is', null)
      .lt('processed_at', sevenDaysAgo.toISOString())

    if (error) {
      throw new Error(`清理失敗: ${error.message}`)
    }

    const deletedCount = data?.length || 0
    console.log(`清理完成，刪除了 ${deletedCount} 個舊事件`)

    return new Response(
      JSON.stringify({
        message: '清理完成',
        deleted: deletedCount,
        cutoffDate: sevenDaysAgo.toISOString(),
      }),
      { headers: { 'Content-Type': 'application/json' }, status: 200 }
    )
  } catch (error) {
    console.error('清理錯誤:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { 'Content-Type': 'application/json' }, status: 500 }
    )
  }
})
```

---

## ✅ 部署狀態

### sync-to-firestore
- **狀態**：✅ 已部署
- **部署時間**：2025-10-04
- **版本**：修復版本（aggregate_type = 'booking'）

### cleanup-outbox
- **狀態**：✅ 已部署
- **部署時間**：2025-10-04
- **版本**：原始版本（無需修改）

---

## 🔍 關鍵修復點

### 修復前（錯誤）
```typescript
if (event.aggregate_type === 'order') {  // ❌
  await syncOrderToFirestore(event)
}
```

### 修復後（正確）
```typescript
if (event.aggregate_type === 'booking') {  // ✅
  await syncBookingToFirestore(event)
}
```

---

## 📊 Payload 欄位映射

### Trigger 提供的欄位
```typescript
{
  id, bookingNumber, customerId, status,
  pickupAddress, destination,
  startDate, startTime, durationHours,
  vehicleType, specialRequirements,
  basePrice, totalAmount, depositAmount,
  pickupLocation, createdAt, updatedAt,
  driverId, actualStartTime, actualEndTime
}
```

### Edge Function 使用的欄位
```typescript
const firestoreData = {
  id: bookingData.id,
  bookingNumber: bookingData.bookingNumber,  // ✅ 匹配
  destination: bookingData.destination,      // ✅ 匹配
  startDate: bookingData.startDate,          // ✅ 匹配
  startTime: bookingData.startTime,          // ✅ 匹配
  // ... 所有欄位都匹配
}
```

---

## 🎯 驗證步驟

1. **手動觸發測試**
   - Supabase Dashboard → Functions → sync-to-firestore → Invoke

2. **檢查日誌**
   - 查找：`✅ Firestore 文檔已更新`

3. **驗證同步狀態**
   - 執行：`supabase/quick-verify.sql`

4. **檢查 Firestore**
   - Firebase Console → Firestore → orders_rt

5. **測試 App**
   - 查看訂單詳情
   - 確認不再顯示「訂單不存在」

---

**最後更新**：2025-10-04  
**狀態**：✅ 完成並已部署

