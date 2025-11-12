-- 測試 UUID 轉換為 TEXT 在 JSONB 中的使用
-- 此腳本用於驗證修復是否正確

-- ============================================
-- Test 1: 測試 UUID 直接插入 JSONB（應該失敗）
-- ============================================

DO $$
DECLARE
  test_uuid UUID := gen_random_uuid();
  test_jsonb JSONB;
BEGIN
  -- 嘗試直接使用 UUID（這會失敗）
  BEGIN
    test_jsonb := jsonb_build_object('id', test_uuid);
    RAISE NOTICE '❌ Test 1 Failed: UUID 應該無法直接插入 JSONB';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '✅ Test 1 Passed: UUID 無法直接插入 JSONB（預期行為）';
  END;
END $$;

-- ============================================
-- Test 2: 測試 UUID 轉換為 TEXT 後插入 JSONB（應該成功）
-- ============================================

DO $$
DECLARE
  test_uuid UUID := gen_random_uuid();
  test_jsonb JSONB;
BEGIN
  -- 使用 ::TEXT 轉換
  BEGIN
    test_jsonb := jsonb_build_object('id', test_uuid::TEXT);
    RAISE NOTICE '✅ Test 2 Passed: UUID::TEXT 可以插入 JSONB';
    RAISE NOTICE 'Result: %', test_jsonb;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Test 2 Failed: UUID::TEXT 應該可以插入 JSONB';
  END;
END $$;

-- ============================================
-- Test 3: 測試複雜的 JSONB 對象（模擬 trigger 函數）
-- ============================================

DO $$
DECLARE
  booking_id UUID := gen_random_uuid();
  message_id UUID := gen_random_uuid();
  sender_id UUID := gen_random_uuid();
  receiver_id UUID := gen_random_uuid();
  test_jsonb JSONB;
BEGIN
  -- 模擬 trigger 函數中的 JSONB 構建
  BEGIN
    test_jsonb := jsonb_build_object(
      'id', message_id::TEXT,
      'bookingId', booking_id::TEXT,
      'senderId', sender_id::TEXT,
      'receiverId', receiver_id::TEXT,
      'messageText', 'Test message',
      'translatedText', NULL,
      'createdAt', NOW(),
      'readAt', NULL,
      'bookingData', jsonb_build_object(
        'bookingId', booking_id::TEXT,
        'customerId', sender_id::TEXT,
        'driverId', receiver_id::TEXT,
        'customerName', 'Test Customer',
        'driverName', 'Test Driver',
        'pickupAddress', 'Test Address',
        'bookingTime', '2025-10-12T14:00:00'
      )
    );
    RAISE NOTICE '✅ Test 3 Passed: 複雜 JSONB 對象構建成功';
    RAISE NOTICE 'Result: %', test_jsonb;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Test 3 Failed: 複雜 JSONB 對象構建失敗';
    RAISE NOTICE 'Error: %', SQLERRM;
  END;
END $$;

-- ============================================
-- Test 4: 測試 TIMESTAMP 在 JSONB 中的使用
-- ============================================

DO $$
DECLARE
  test_timestamp TIMESTAMP WITH TIME ZONE := NOW();
  test_jsonb JSONB;
BEGIN
  -- TIMESTAMP 可以直接使用，PostgreSQL 會自動轉換
  BEGIN
    test_jsonb := jsonb_build_object(
      'createdAt', test_timestamp,
      'updatedAt', test_timestamp
    );
    RAISE NOTICE '✅ Test 4 Passed: TIMESTAMP 可以直接插入 JSONB';
    RAISE NOTICE 'Result: %', test_jsonb;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Test 4 Failed: TIMESTAMP 應該可以直接插入 JSONB';
  END;
END $$;

-- ============================================
-- 總結
-- ============================================

SELECT 
  '========================================' as separator,
  '測試總結' as title,
  '========================================' as separator2;

SELECT 
  '所有測試應該都通過（✅）' as expected_result,
  '如果有任何測試失敗（❌），請檢查 migration 文件' as action;

