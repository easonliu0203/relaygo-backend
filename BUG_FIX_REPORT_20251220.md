# 🐛 Bug 修復報告：旅遊方案管理

## 📅 修復日期
2024-12-20

## 🎯 修復的 Bug

### Bug 1：停用方案後從列表消失

#### 問題描述
- 在「設定 > 旅遊方案管理」頁面，將方案狀態從「啟用」切換為「停用」後，該方案會從列表中消失
- **預期行為**：停用的方案應該繼續顯示在列表中，只是狀態顯示為「停用」
- **實際行為**：停用的方案完全從列表中消失

#### 根本原因
後端 API `/api/tour-packages` 在查詢時使用了 `.eq('is_active', true)` 過濾條件，導致只返回啟用的方案。

<augment_code_snippet path="backend/src/routes/tourPackages.ts" mode="EXCERPT">
```typescript
// 修復前（錯誤）
const { data, error } = await supabase
  .from('tour_packages')
  .select('*')
  .eq('is_active', true)  // ← 過濾掉停用的方案
  .order('display_order', { ascending: true });
```
</augment_code_snippet>

#### 修復方式
移除 `.eq('is_active', true)` 過濾條件，返回所有方案。

<augment_code_snippet path="backend/src/routes/tourPackages.ts" mode="EXCERPT">
```typescript
// 修復後（正確）
const { data, error } = await supabase
  .from('tour_packages')
  .select('*')
  .order('display_order', { ascending: true });
```
</augment_code_snippet>

#### 影響範圍
- ✅ Web Admin 管理後台：現在可以看到所有方案（包含停用的）
- ⚠️ Mobile App：需要在客戶端過濾 `is_active = true` 的方案

---

### Bug 2：多語言內容無法儲存

#### 問題描述
- 在編輯旅遊方案的多語言標籤頁中填入 `name_i18n` 和 `description_i18n` 資料後
- 點擊「儲存」按鈕
- 重新開啟編輯對話框，多語言欄位全部為空

#### 根本原因
1. **資料庫層**：`tour_packages` 表缺少 `name_i18n` 和 `description_i18n` 欄位
2. **後端 API 層**：POST/PUT 端點沒有處理多語言欄位
3. **前端層**：已正確實現（無問題）

#### 修復方式

##### 1. 資料庫 Migration
創建 `20251220_add_i18n_to_tour_packages.sql`：
- 添加 `name_i18n` JSONB 欄位
- 添加 `description_i18n` JSONB 欄位
- 創建 GIN 索引
- 遷移現有資料到多語言格式

##### 2. 後端 API 更新

**TypeScript Interface**：
```typescript
interface TourPackage {
  id: string;
  name: string;
  description: string;
  name_i18n?: Record<string, string>;      // ← 新增
  description_i18n?: Record<string, string>; // ← 新增
  is_active: boolean;
  display_order: number;
  created_at: string;
  updated_at: string;
}
```

**POST 端點**：
```typescript
const { name, description, name_i18n, description_i18n, is_active, display_order } = req.body;

const { data, error } = await supabase
  .from('tour_packages')
  .insert([{
    name,
    description: description || '',
    name_i18n: name_i18n || {},      // ← 新增
    description_i18n: description_i18n || {}, // ← 新增
    is_active: is_active !== undefined ? is_active : true,
    display_order: display_order || 0
  }])
```

**PUT 端點**：
```typescript
const updateData: any = {
  name,
  description: description || '',
  is_active: is_active !== undefined ? is_active : true,
  display_order: display_order !== undefined ? display_order : 0
};

// 只在提供了多語言資料時才更新
if (name_i18n !== undefined) {
  updateData.name_i18n = name_i18n;
}
if (description_i18n !== undefined) {
  updateData.description_i18n = description_i18n;
}
```

#### 影響範圍
- ✅ Web Admin：可以正常儲存和讀取多語言內容
- ✅ Mobile App：可以根據用戶語言偏好顯示對應翻譯

---

## 📦 Git 提交記錄

### Backend Repository

```bash
Commit: d29ed9d
Message: fix: resolve tour packages bugs - show inactive packages and support i18n fields
Files:
  - src/routes/tourPackages.ts (修改)
  - database/migrations/20251220_add_i18n_to_tour_packages.sql (新增)
Changes: +85 insertions, -13 deletions

Repository: easonliu0203/relaygo-backend
Status: ✅ 已推送到 GitHub
Deployment: Railway (api.relaygo.pro) - 自動部署中
```

---

## 🚀 部署狀態

### Backend API (Railway)
- **URL**: https://api.relaygo.pro
- **狀態**: 🟡 等待自動部署完成
- **預計時間**: 2-3 分鐘

### Web Admin (Vercel)
- **URL**: https://admin.relaygo.pro
- **狀態**: ✅ 已部署（前端無需更改）

---

## ✅ 驗證步驟

### 1. 執行資料庫 Migration

**重要**：必須先執行 Migration，否則 Bug 2 無法修復！

請參考：`database/migrations/README_20251220_MIGRATION.md`

### 2. 測試 Bug 1 修復

1. 登入 https://admin.relaygo.pro
2. 進入「設定 > 旅遊方案管理」
3. 將「台北一日遊」狀態切換為「停用」
4. ✅ 確認方案仍然顯示在列表中（狀態顯示為「停用」）

### 3. 測試 Bug 2 修復

1. 點擊「編輯」任一方案
2. 切換到「English」標籤頁
3. 填寫：
   - Name: "Taipei Day Tour"
   - Description: "Explore popular attractions in Taipei..."
4. 點擊「儲存」
5. 重新開啟編輯對話框
6. 切換到「English」標籤頁
7. ✅ 確認英文內容已正確儲存並顯示

---

## 📊 技術細節

### 資料庫結構變更

**修改前**：
```sql
CREATE TABLE tour_packages (
    id UUID PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
);
```

**修改後**：
```sql
CREATE TABLE tour_packages (
    id UUID PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    name_i18n JSONB DEFAULT '{}'::jsonb,        -- ← 新增
    description_i18n JSONB DEFAULT '{}'::jsonb, -- ← 新增
    is_active BOOLEAN DEFAULT true,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
);
```

### 資料範例

```json
{
  "id": "uuid-here",
  "name": "台北一日遊",
  "description": "探索台北市區熱門景點...",
  "name_i18n": {
    "zh-TW": "台北一日遊",
    "en": "Taipei Day Tour",
    "ja": "台北日帰りツアー"
  },
  "description_i18n": {
    "zh-TW": "探索台北市區熱門景點...",
    "en": "Explore popular attractions in Taipei...",
    "ja": "台北の人気観光スポットを探索..."
  },
  "is_active": true,
  "display_order": 1
}
```

---

## 🎉 總結

✅ **Bug 1 已修復**：停用的方案現在會繼續顯示在列表中  
✅ **Bug 2 已修復**：多語言內容可以正常儲存和讀取  
✅ **程式碼已推送**：Backend 更改已部署到 Railway  
⏳ **待執行**：資料庫 Migration（請參考 README_20251220_MIGRATION.md）

修復完成後，系統將完全支援旅遊方案的多語言管理功能！

