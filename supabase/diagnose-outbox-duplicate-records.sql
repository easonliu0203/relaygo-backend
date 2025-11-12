-- ========================================
-- 診斷 outbox 重複記錄問題
-- ========================================

-- 步驟 1：檢查 bookings 資料表的所有 Trigger
SELECT 
    '步驟 1：檢查 bookings 資料表的所有 Trigger' AS "診斷步驟";

SELECT 
    trigger_name AS "Trigger 名稱",
    event_manipulation AS "觸發事件",
    action_timing AS "觸發時機",
    action_statement AS "執行語句"
FROM information_schema.triggers
WHERE event_object_table = 'bookings'
  AND event_object_schema = 'public'
ORDER BY trigger_name;

-- 步驟 2：檢查 outbox 資料表的記錄（最近 10 筆）
SELECT 
    '步驟 2：檢查 outbox 資料表的記錄' AS "診斷步驟";

SELECT 
    id AS "Outbox ID",
    aggregate_id AS "訂單 ID",
    event_type AS "事件類型",
    payload->>'status' AS "訂單狀態",
    payload->>'updatedAt' AS "更新時間",
    created_at AS "創建時間",
    processed_at AS "處理時間"
FROM outbox
WHERE aggregate_type = 'booking'
ORDER BY created_at DESC
LIMIT 10;

-- 步驟 3：檢查是否有重複的 outbox 記錄（同一個訂單有多筆記錄）
SELECT 
    '步驟 3：檢查是否有重複的 outbox 記錄' AS "診斷步驟";

SELECT 
    aggregate_id AS "訂單 ID",
    COUNT(*) AS "記錄數量",
    STRING_AGG(event_type, ', ' ORDER BY created_at) AS "事件類型列表",
    STRING_AGG((payload->>'status')::TEXT, ' → ' ORDER BY created_at) AS "狀態變化",
    MIN(created_at) AS "第一筆記錄時間",
    MAX(created_at) AS "最後一筆記錄時間",
    EXTRACT(EPOCH FROM (MAX(created_at) - MIN(created_at))) AS "時間差（秒）"
FROM outbox
WHERE aggregate_type = 'booking'
GROUP BY aggregate_id
HAVING COUNT(*) > 1
ORDER BY MAX(created_at) DESC
LIMIT 10;

-- 步驟 4：檢查特定訂單的 outbox 記錄
SELECT 
    '步驟 4：檢查特定訂單的 outbox 記錄' AS "診斷步驟";

-- 請將 'YOUR_BOOKING_ID' 替換為實際的訂單 ID
-- 例如：'aed42235-451d-4ece-ac4a-ce8267c16e4f'

SELECT 
    id AS "Outbox ID",
    event_type AS "事件類型",
    payload->>'status' AS "訂單狀態",
    payload->>'bookingNumber' AS "訂單編號",
    payload->>'customerId' AS "客戶 ID",
    payload->>'driverId' AS "司機 ID",
    payload->>'updatedAt' AS "更新時間",
    created_at AS "創建時間",
    processed_at AS "處理時間"
FROM outbox
WHERE aggregate_id = 'aed42235-451d-4ece-ac4a-ce8267c16e4f'  -- ✅ 替換為實際的訂單 ID
ORDER BY created_at;

-- 步驟 5：檢查 bookings 資料表的記錄
SELECT 
    '步驟 5：檢查 bookings 資料表的記錄' AS "診斷步驟";

SELECT 
    id AS "訂單 ID",
    booking_number AS "訂單編號",
    status AS "狀態",
    customer_id AS "客戶 ID",
    driver_id AS "司機 ID",
    created_at AS "創建時間",
    updated_at AS "更新時間"
FROM bookings
WHERE id = 'aed42235-451d-4ece-ac4a-ce8267c16e4f'  -- ✅ 替換為實際的訂單 ID
ORDER BY created_at DESC;

-- 步驟 6：分析訂單創建和支付流程
SELECT 
    '步驟 6：分析訂單創建和支付流程' AS "診斷步驟";

-- 檢查訂單創建和支付的時間線
WITH booking_timeline AS (
    SELECT 
        b.id AS booking_id,
        b.booking_number,
        b.status AS current_status,
        b.created_at AS booking_created_at,
        b.updated_at AS booking_updated_at,
        p.id AS payment_id,
        p.type AS payment_type,
        p.status AS payment_status,
        p.confirmed_at AS payment_confirmed_at,
        EXTRACT(EPOCH FROM (b.updated_at - b.created_at)) AS seconds_between_create_and_update,
        EXTRACT(EPOCH FROM (p.confirmed_at - b.created_at)) AS seconds_between_create_and_payment
    FROM bookings b
    LEFT JOIN payments p ON b.id = p.booking_id
    WHERE b.id = 'aed42235-451d-4ece-ac4a-ce8267c16e4f'  -- ✅ 替換為實際的訂單 ID
)
SELECT 
    booking_id AS "訂單 ID",
    booking_number AS "訂單編號",
    current_status AS "當前狀態",
    booking_created_at AS "訂單創建時間",
    booking_updated_at AS "訂單更新時間",
    payment_confirmed_at AS "支付確認時間",
    seconds_between_create_and_update AS "創建到更新（秒）",
    seconds_between_create_and_payment AS "創建到支付（秒）",
    CASE 
        WHEN seconds_between_create_and_update < 1 THEN '⚠️ 更新太快（可能是同一個事務）'
        WHEN seconds_between_create_and_update < 5 THEN '✅ 正常（快速支付）'
        ELSE '✅ 正常'
    END AS "分析結果"
FROM booking_timeline;

-- 步驟 7：檢查是否有重複的 Trigger
SELECT 
    '步驟 7：檢查是否有重複的 Trigger' AS "診斷步驟";

SELECT 
    trigger_name AS "Trigger 名稱",
    COUNT(*) AS "數量"
FROM information_schema.triggers
WHERE event_object_table = 'bookings'
  AND event_object_schema = 'public'
GROUP BY trigger_name
HAVING COUNT(*) > 1;

-- 步驟 8：統計 outbox 記錄的分佈
SELECT 
    '步驟 8：統計 outbox 記錄的分佈' AS "診斷步驟";

SELECT 
    event_type AS "事件類型",
    COUNT(*) AS "記錄數量",
    COUNT(DISTINCT aggregate_id) AS "唯一訂單數",
    ROUND(COUNT(*)::NUMERIC / COUNT(DISTINCT aggregate_id), 2) AS "平均每訂單記錄數"
FROM outbox
WHERE aggregate_type = 'booking'
GROUP BY event_type
ORDER BY event_type;

-- ========================================
-- 結論和建議
-- ========================================

SELECT '========================================' AS "步驟";
SELECT '診斷結論' AS "步驟";
SELECT '========================================' AS "步驟";

SELECT 
    '根據診斷結果，請檢查以下項目：' AS "建議",
    '' AS "空行",
    '1. 步驟 1：確認 Trigger 是否在 INSERT 和 UPDATE 時都會觸發' AS "檢查項目 1",
    '2. 步驟 3：確認是否有多筆 outbox 記錄（這可能是正常的）' AS "檢查項目 2",
    '3. 步驟 6：確認訂單創建和支付的時間差' AS "檢查項目 3",
    '4. 步驟 7：確認是否有重複的 Trigger' AS "檢查項目 4",
    '' AS "空行2",
    '如果訂單創建後立即支付，產生兩筆 outbox 記錄是正常的：' AS "正常情況",
    '  - 第一筆：訂單創建（event_type: created, status: pending_payment）' AS "正常情況 1",
    '  - 第二筆：支付完成（event_type: updated, status: paid_deposit）' AS "正常情況 2",
    '' AS "空行3",
    '這是 Outbox Pattern 的預期行為，不需要修復。' AS "結論";

