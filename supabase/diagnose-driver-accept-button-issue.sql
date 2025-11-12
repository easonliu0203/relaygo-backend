-- ========================================
-- 診斷司機端「確認接單」按鈕不顯示問題
-- ========================================

-- 步驟 1：檢查最近的訂單（最近 10 筆）
SELECT 
    '步驟 1：檢查最近的訂單' AS "診斷步驟";

SELECT 
    id AS "訂單 ID",
    booking_number AS "訂單編號",
    status AS "Supabase 狀態",
    customer_id AS "客戶 ID",
    driver_id AS "司機 ID",
    created_at AS "創建時間",
    updated_at AS "更新時間",
    CASE 
        WHEN driver_id IS NULL THEN '❌ 未分配司機'
        WHEN status = 'matched' THEN '⚠️ 已派單（matched），需要司機確認'
        WHEN status = 'driver_confirmed' THEN '✅ 司機已確認'
        ELSE '📋 其他狀態'
    END AS "分析"
FROM bookings
ORDER BY created_at DESC
LIMIT 10;

-- 步驟 2：檢查已派單但司機尚未確認的訂單
SELECT 
    '步驟 2：檢查已派單但司機尚未確認的訂單' AS "診斷步驟";

SELECT
    b.id AS "訂單 ID",
    b.booking_number AS "訂單編號",
    b.status AS "Supabase 狀態",
    b.driver_id AS "司機 ID (users.id)",
    u.firebase_uid AS "司機 Firebase UID",
    u.email AS "司機 Email",
    COALESCE(up.first_name || ' ' || up.last_name, u.email) AS "司機姓名",
    b.created_at AS "創建時間",
    b.updated_at AS "更新時間",
    CASE
        WHEN b.status = 'matched' THEN '⚠️ 等待司機確認接單'
        WHEN b.status = 'assigned' THEN '⚠️ 等待司機確認接單'
        ELSE '✅ 已確認或其他狀態'
    END AS "狀態說明"
FROM bookings b
LEFT JOIN users u ON b.driver_id = u.id
LEFT JOIN user_profiles up ON u.id = up.user_id
WHERE b.driver_id IS NOT NULL
  AND b.status IN ('matched', 'assigned')
ORDER BY b.created_at DESC
LIMIT 10;

-- 步驟 3：檢查 outbox 記錄（最近 10 筆）
SELECT 
    '步驟 3：檢查 outbox 記錄' AS "診斷步驟";

SELECT 
    id AS "Outbox ID",
    aggregate_id AS "訂單 ID",
    event_type AS "事件類型",
    payload->>'status' AS "訂單狀態",
    payload->>'driverId' AS "司機 ID",
    created_at AS "創建時間",
    processed_at AS "處理時間",
    CASE 
        WHEN processed_at IS NULL THEN '⚠️ 尚未處理'
        ELSE '✅ 已處理'
    END AS "處理狀態"
FROM outbox
WHERE aggregate_type = 'booking'
ORDER BY created_at DESC
LIMIT 10;

-- 步驟 4：檢查特定訂單的詳細資訊
SELECT 
    '步驟 4：檢查特定訂單的詳細資訊' AS "診斷步驟";

-- ⚠️ 請將下面的訂單 ID 替換為您要檢查的實際訂單 ID
-- 例如：WHERE b.id = 'aed42235-451d-4ece-ac4a-ce8267c16e4f'

SELECT 
    b.id AS "訂單 ID",
    b.booking_number AS "訂單編號",
    b.status AS "Supabase 狀態",
    b.customer_id AS "客戶 ID (users.id)",
    cu.firebase_uid AS "客戶 Firebase UID",
    cu.email AS "客戶 Email",
    b.driver_id AS "司機 ID (users.id)",
    du.firebase_uid AS "司機 Firebase UID",
    du.email AS "司機 Email",
    b.created_at AS "創建時間",
    b.updated_at AS "更新時間",
    CASE 
        WHEN b.driver_id IS NULL THEN '❌ 未分配司機'
        WHEN b.status = 'matched' THEN '⚠️ 已派單（matched），Firestore 應該是 pending'
        WHEN b.status = 'driver_confirmed' THEN '✅ 司機已確認，Firestore 應該是 matched'
        ELSE '📋 其他狀態'
    END AS "預期 Firestore 狀態"
FROM bookings b
LEFT JOIN users cu ON b.customer_id = cu.id
LEFT JOIN users du ON b.driver_id = du.id
-- WHERE b.id = 'YOUR_BOOKING_ID_HERE'  -- ⚠️ 取消註解並替換訂單 ID
ORDER BY b.created_at DESC
LIMIT 1;

-- 步驟 5：檢查 Edge Function 是否正確處理了訂單
SELECT 
    '步驟 5：檢查 Edge Function 是否正確處理了訂單' AS "診斷步驟";

-- 檢查最近的 outbox 記錄是否已處理
SELECT 
    o.id AS "Outbox ID",
    o.aggregate_id AS "訂單 ID",
    o.event_type AS "事件類型",
    o.payload->>'status' AS "Supabase 狀態",
    o.created_at AS "創建時間",
    o.processed_at AS "處理時間",
    EXTRACT(EPOCH FROM (o.processed_at - o.created_at)) AS "處理延遲（秒）",
    CASE 
        WHEN o.processed_at IS NULL THEN '❌ 尚未處理（Edge Function 可能未運行）'
        WHEN EXTRACT(EPOCH FROM (o.processed_at - o.created_at)) > 60 THEN '⚠️ 處理延遲過長'
        ELSE '✅ 已正常處理'
    END AS "處理狀態分析"
FROM outbox o
WHERE o.aggregate_type = 'booking'
ORDER BY o.created_at DESC
LIMIT 10;

-- 步驟 6：檢查司機資訊
SELECT 
    '步驟 6：檢查司機資訊' AS "診斷步驟";

SELECT
    u.id AS "司機 ID (users.id)",
    u.firebase_uid AS "司機 Firebase UID",
    u.email AS "司機 Email",
    COALESCE(up.first_name || ' ' || up.last_name, u.email) AS "司機姓名",
    u.phone AS "司機電話",
    u.status AS "司機狀態",
    COUNT(b.id) AS "已分配訂單數",
    COUNT(CASE WHEN b.status = 'matched' THEN 1 END) AS "等待確認訂單數",
    COUNT(CASE WHEN b.status = 'driver_confirmed' THEN 1 END) AS "已確認訂單數"
FROM users u
LEFT JOIN user_profiles up ON u.id = up.user_id
LEFT JOIN bookings b ON u.id = b.driver_id
WHERE u.role = 'driver'
GROUP BY u.id, u.firebase_uid, u.email, up.first_name, up.last_name, u.phone, u.status
ORDER BY "等待確認訂單數" DESC, u.email;

-- ========================================
-- 診斷結論和建議
-- ========================================

SELECT '========================================' AS "步驟";
SELECT '診斷結論' AS "步驟";
SELECT '========================================' AS "步驟";

SELECT 
    '根據診斷結果，請檢查以下項目：' AS "建議",
    '' AS "空行",
    '1. 步驟 2：確認訂單狀態是否為 matched 或 assigned' AS "檢查項目 1",
    '2. 步驟 2：確認訂單已分配給司機（driver_id 不為 NULL）' AS "檢查項目 2",
    '3. 步驟 2：記下司機的 Firebase UID，用於 Flutter APP 測試' AS "檢查項目 3",
    '4. 步驟 3：確認 outbox 記錄已被處理（processed_at 不為 NULL）' AS "檢查項目 4",
    '5. 步驟 5：確認 Edge Function 處理延遲是否正常（< 60 秒）' AS "檢查項目 5",
    '' AS "空行2",
    '如果 outbox 記錄尚未處理，可能的原因：' AS "可能原因",
    '  - Edge Function 未部署或未啟用' AS "原因 1",
    '  - Edge Function 執行失敗（檢查日誌）' AS "原因 2",
    '  - Trigger 未正確觸發' AS "原因 3",
    '' AS "空行3",
    '下一步：' AS "下一步",
    '  1. 部署 Edge Function（如果尚未部署）' AS "步驟 1",
    '  2. 手動觸發 Edge Function 處理 outbox 記錄' AS "步驟 2",
    '  3. 檢查 Firestore 中的訂單狀態是否為 pending' AS "步驟 3",
    '  4. 在 Flutter APP 中測試「確認接單」按鈕是否顯示' AS "步驟 4";

