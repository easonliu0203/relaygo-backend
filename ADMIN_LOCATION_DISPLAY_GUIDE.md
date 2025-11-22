# 公司端定位顯示功能 - 實作建議

**目標**: 在公司端（Web Admin）訂單詳情頁面顯示司機定位歷史

---

## 📋 功能需求

### 1. 顯示定位歷史（2 筆）
在訂單詳情頁面顯示：
- **司機出發時的定位**（`driver_departed`）
- **司機到達時的定位**（`driver_arrived`）

### 2. 顯示即時定位（未來功能）
- 當司機 APP 在前景使用時，每分鐘更新一次當前位置
- 顯示司機當前位置和最後更新時間

---

## 🏗️ 資料來源

### Firestore 資料結構

#### 定位歷史
```
/bookings/{bookingId}/location_history
```

**查詢方式**：
```typescript
const locationHistory = await firestore
  .collection('bookings')
  .doc(bookingId)
  .collection('location_history')
  .orderBy('timestamp', 'desc')
  .limit(2)
  .get();
```

**資料格式**：
```typescript
{
  id: string,
  bookingId: string,
  driverId: string,
  status: 'driver_departed' | 'driver_arrived',
  latitude: number,
  longitude: number,
  googleMapsUrl: string,
  appleMapsUrl: string,
  timestamp: Timestamp,
  createdAt: Timestamp
}
```

#### 即時定位（未來）
```
/bookings/{bookingId}/realtime_location
```

**資料格式**：
```typescript
{
  latitude: number,
  longitude: number,
  timestamp: Timestamp,
  isActive: boolean  // 司機 APP 是否在前景
}
```

---

## 🎨 UI 設計建議

### 訂單詳情頁面 - 定位區塊

```
┌─────────────────────────────────────────────┐
│ 📍 司機定位資訊                              │
├─────────────────────────────────────────────┤
│                                             │
│ 🚗 司機出發                                  │
│ 時間：2025-11-22 14:30:00                   │
│ 位置：25.0330, 121.5654                     │
│ [Google Maps] [Apple Maps]                 │
│                                             │
│ ─────────────────────────────────────────   │
│                                             │
│ 📍 司機到達                                  │
│ 時間：2025-11-22 14:45:00                   │
│ 位置：25.0340, 121.5660                     │
│ [Google Maps] [Apple Maps]                 │
│                                             │
└─────────────────────────────────────────────┘
```

### 進階版：嵌入地圖

```
┌─────────────────────────────────────────────┐
│ 📍 司機定位資訊                              │
├─────────────────────────────────────────────┤
│                                             │
│ ┌─────────────────────────────────────┐    │
│ │                                     │    │
│ │         [地圖顯示區域]               │    │
│ │                                     │    │
│ │  📍 出發點                           │    │
│ │  📍 到達點                           │    │
│ │                                     │    │
│ └─────────────────────────────────────┘    │
│                                             │
│ 定位歷史：                                   │
│ • 出發：2025-11-22 14:30:00                 │
│ • 到達：2025-11-22 14:45:00                 │
│                                             │
└─────────────────────────────────────────────┘
```

---

## 💻 實作範例（React + TypeScript）

### 1. 定義資料型別

```typescript
// types/location.ts
export interface DriverLocation {
  id: string;
  bookingId: string;
  driverId: string;
  status: 'driver_departed' | 'driver_arrived';
  latitude: number;
  longitude: number;
  googleMapsUrl: string;
  appleMapsUrl: string;
  timestamp: Date;
  createdAt: Date;
}
```

### 2. 獲取定位資料

```typescript
// services/locationService.ts
import { collection, query, orderBy, limit, getDocs } from 'firebase/firestore';
import { db } from '@/config/firebase';

export async function getDriverLocationHistory(
  bookingId: string
): Promise<DriverLocation[]> {
  try {
    const locationsRef = collection(db, 'bookings', bookingId, 'location_history');
    const q = query(locationsRef, orderBy('timestamp', 'desc'), limit(2));
    const snapshot = await getDocs(q);
    
    return snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      timestamp: doc.data().timestamp?.toDate(),
      createdAt: doc.data().createdAt?.toDate()
    })) as DriverLocation[];
  } catch (error) {
    console.error('獲取定位歷史失敗:', error);
    return [];
  }
}
```

### 3. 顯示定位資訊組件

```typescript
// components/DriverLocationInfo.tsx
import React, { useEffect, useState } from 'react';
import { getDriverLocationHistory } from '@/services/locationService';
import type { DriverLocation } from '@/types/location';

interface Props {
  bookingId: string;
}

export function DriverLocationInfo({ bookingId }: Props) {
  const [locations, setLocations] = useState<DriverLocation[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadLocations();
  }, [bookingId]);

  async function loadLocations() {
    setLoading(true);
    const data = await getDriverLocationHistory(bookingId);
    setLocations(data);
    setLoading(false);
  }

  if (loading) {
    return <div>載入中...</div>;
  }

  if (locations.length === 0) {
    return <div>暫無定位資訊</div>;
  }

  return (
    <div className="driver-location-info">
      <h3>📍 司機定位資訊</h3>
      
      {locations.map((location) => (
        <div key={location.id} className="location-item">
          <div className="location-header">
            {location.status === 'driver_departed' ? '🚗 司機出發' : '📍 司機到達'}
          </div>
          
          <div className="location-details">
            <p>時間：{location.timestamp?.toLocaleString('zh-TW')}</p>
            <p>位置：{location.latitude}, {location.longitude}</p>
            
            <div className="map-links">
              <a 
                href={location.googleMapsUrl} 
                target="_blank" 
                rel="noopener noreferrer"
                className="btn btn-primary"
              >
                Google Maps
              </a>
              <a 
                href={location.appleMapsUrl} 
                target="_blank" 
                rel="noopener noreferrer"
                className="btn btn-secondary"
              >
                Apple Maps
              </a>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}
```

### 4. 在訂單詳情頁面使用

```typescript
// pages/BookingDetail.tsx
import { DriverLocationInfo } from '@/components/DriverLocationInfo';

export function BookingDetailPage({ bookingId }: { bookingId: string }) {
  return (
    <div className="booking-detail">
      {/* 其他訂單資訊 */}
      
      {/* 定位資訊 */}
      <DriverLocationInfo bookingId={bookingId} />
      
      {/* 其他內容 */}
    </div>
  );
}
```

---

## 🎨 CSS 樣式建議

```css
/* styles/DriverLocationInfo.css */
.driver-location-info {
  background: #fff;
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  padding: 20px;
  margin: 20px 0;
}

.driver-location-info h3 {
  margin: 0 0 20px 0;
  font-size: 18px;
  font-weight: 600;
}

.location-item {
  border-bottom: 1px solid #f0f0f0;
  padding: 15px 0;
}

.location-item:last-child {
  border-bottom: none;
}

.location-header {
  font-size: 16px;
  font-weight: 500;
  margin-bottom: 10px;
}

.location-details p {
  margin: 5px 0;
  color: #666;
  font-size: 14px;
}

.map-links {
  display: flex;
  gap: 10px;
  margin-top: 10px;
}

.map-links .btn {
  padding: 8px 16px;
  border-radius: 4px;
  text-decoration: none;
  font-size: 14px;
  transition: all 0.2s;
}

.map-links .btn-primary {
  background: #4285f4;
  color: white;
}

.map-links .btn-primary:hover {
  background: #357ae8;
}

.map-links .btn-secondary {
  background: #f5f5f5;
  color: #333;
  border: 1px solid #ddd;
}

.map-links .btn-secondary:hover {
  background: #e8e8e8;
}
```

---

## 🚀 部署步驟

### 1. 修改 Web Admin 專案
```bash
cd web-admin
# 新增上述檔案
# 修改訂單詳情頁面
```

### 2. 提交並推送
```bash
git add .
git commit -m "Add driver location display in admin panel"
git push origin main
```

### 3. Vercel 自動部署
- Vercel 會自動檢測到新的 commit
- 自動部署到 `admin.relaygo.pro`

---

## ✅ 驗證清單

- [ ] 定位資料可以從 Firestore 正確讀取
- [ ] 定位資訊在訂單詳情頁面正確顯示
- [ ] Google Maps 連結可以正常開啟
- [ ] Apple Maps 連結可以正常開啟
- [ ] 時間格式正確顯示
- [ ] 樣式符合設計規範

---

**文檔版本**: 1.0  
**最後更新**: 2025-11-22

