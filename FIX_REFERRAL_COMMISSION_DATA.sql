-- ============================================
-- 修復推薦關係和佣金記錄資料
-- ============================================
-- 
-- 問題描述：
-- 1. bookings.ts 中使用 firebase_uid 而不是 users.id 來查詢和插入 referrals 記錄
-- 2. 導致推薦關係沒有建立
-- 3. 導致 promo_code_usage 記錄缺少佣金相關欄位
--
-- 修復內容：
-- 1. 為缺少推薦關係的訂單補充 referrals 記錄
-- 2. 更新 promo_code_usage 記錄，填寫佣金相關欄位
--
-- ⚠️ 重要：此腳本只修復歷史資料，不影響未來的訂單
-- ============================================

BEGIN;

-- 步驟 1：查找所有使用客戶推廣人優惠碼但沒有推薦關係的訂單
DO $$
DECLARE
  v_record RECORD;
  v_influencer RECORD;
  v_customer RECORD;
  v_commission_type TEXT;
  v_commission_rate FLOAT;
  v_commission_amount DECIMAL(10,2);
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE '開始修復推薦關係和佣金記錄';
  RAISE NOTICE '========================================';
  
  -- 遍歷所有需要修復的 promo_code_usage 記錄
  FOR v_record IN 
    SELECT 
      pcu.id as usage_id,
      pcu.booking_id,
      pcu.influencer_id,
      pcu.promo_code,
      pcu.final_price,
      b.customer_id
    FROM promo_code_usage pcu
    JOIN bookings b ON b.id = pcu.booking_id
    LEFT JOIN referrals r ON r.referee_id = b.customer_id
    WHERE r.id IS NULL  -- 沒有推薦關係
      AND pcu.commission_type IS NULL  -- 佣金資訊不完整
  LOOP
    RAISE NOTICE '處理訂單: %', v_record.booking_id;
    
    -- 獲取推廣人資訊
    SELECT * INTO v_influencer
    FROM influencers
    WHERE id = v_record.influencer_id;
    
    IF v_influencer IS NULL THEN
      RAISE NOTICE '  ⚠️ 推廣人不存在，跳過';
      CONTINUE;
    END IF;
    
    -- 只處理客戶推廣人
    IF v_influencer.affiliate_type != 'customer_affiliate' THEN
      RAISE NOTICE '  ⚠️ 非客戶推廣人，跳過';
      CONTINUE;
    END IF;
    
    IF v_influencer.user_id IS NULL THEN
      RAISE NOTICE '  ⚠️ 推廣人沒有 user_id，跳過';
      CONTINUE;
    END IF;
    
    -- 獲取客戶資訊
    SELECT * INTO v_customer
    FROM users
    WHERE id = v_record.customer_id;
    
    IF v_customer IS NULL THEN
      RAISE NOTICE '  ⚠️ 客戶不存在，跳過';
      CONTINUE;
    END IF;
    
    -- 檢查是否已有推薦關係（防止重複）
    IF EXISTS (SELECT 1 FROM referrals WHERE referee_id = v_record.customer_id) THEN
      RAISE NOTICE '  ⚠️ 客戶已有推薦關係，跳過';
      CONTINUE;
    END IF;
    
    -- 創建推薦關係
    INSERT INTO referrals (
      referrer_id,
      referee_id,
      influencer_id,
      promo_code,
      first_booking_id
    ) VALUES (
      v_influencer.user_id,
      v_record.customer_id,
      v_record.influencer_id,
      v_record.promo_code,
      v_record.booking_id
    );
    
    RAISE NOTICE '  ✅ 推薦關係已創建';
    
    -- 計算佣金
    IF v_influencer.is_commission_fixed_active THEN
      v_commission_type := 'fixed';
      v_commission_rate := v_influencer.commission_fixed;
      v_commission_amount := v_influencer.commission_fixed;
    ELSIF v_influencer.is_commission_percent_active THEN
      v_commission_type := 'percent';
      v_commission_rate := v_influencer.commission_percent;
      v_commission_amount := ROUND(v_record.final_price * v_influencer.commission_percent / 100, 2);
    ELSE
      v_commission_type := NULL;
      v_commission_rate := 0;
      v_commission_amount := 0;
    END IF;
    
    -- 更新 promo_code_usage 記錄
    UPDATE promo_code_usage
    SET 
      referee_id = v_record.customer_id,
      commission_type = v_commission_type,
      commission_rate = v_commission_rate,
      commission_amount = v_commission_amount,
      order_amount = v_record.final_price
    WHERE id = v_record.usage_id;
    
    RAISE NOTICE '  ✅ 佣金資訊已更新: type=%, rate=%, amount=%', 
      v_commission_type, v_commission_rate, v_commission_amount;
    
  END LOOP;
  
  RAISE NOTICE '========================================';
  RAISE NOTICE '✅ 修復完成！';
  RAISE NOTICE '========================================';
END $$;

COMMIT;

-- 驗證修復結果
SELECT 
  '修復後的 promo_code_usage 記錄' as description,
  COUNT(*) as total_count,
  COUNT(CASE WHEN commission_type IS NOT NULL THEN 1 END) as with_commission_type,
  COUNT(CASE WHEN referee_id IS NOT NULL THEN 1 END) as with_referee_id
FROM promo_code_usage;

SELECT 
  '推薦關係記錄' as description,
  COUNT(*) as total_count
FROM referrals;

