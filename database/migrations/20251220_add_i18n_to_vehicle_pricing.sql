-- 為 vehicle_pricing 表添加多語言支援
-- 日期: 2024-12-20
-- 目的: 支援車型描述、內容描述的多語言國際化

-- 1. 添加多語言 JSONB 欄位
ALTER TABLE vehicle_pricing 
ADD COLUMN IF NOT EXISTS vehicle_description_i18n JSONB DEFAULT '{}'::jsonb;

ALTER TABLE vehicle_pricing 
ADD COLUMN IF NOT EXISTS capacity_info_i18n JSONB DEFAULT '{}'::jsonb;

-- 2. 創建 GIN 索引以提高 JSONB 查詢效能
CREATE INDEX IF NOT EXISTS idx_vehicle_pricing_vehicle_description_i18n 
ON vehicle_pricing USING GIN (vehicle_description_i18n);

CREATE INDEX IF NOT EXISTS idx_vehicle_pricing_capacity_info_i18n 
ON vehicle_pricing USING GIN (capacity_info_i18n);

-- 3. 遷移現有資料到多語言格式（zh-TW）
-- 將現有的 vehicle_description 和 capacity_info 複製到 i18n 欄位的 zh-TW 鍵
UPDATE vehicle_pricing
SET 
  vehicle_description_i18n = jsonb_build_object('zh-TW', vehicle_description),
  capacity_info_i18n = jsonb_build_object('zh-TW', COALESCE(capacity_info, ''))
WHERE vehicle_description_i18n = '{}'::jsonb OR capacity_info_i18n = '{}'::jsonb;

-- 4. 添加註釋
COMMENT ON COLUMN vehicle_pricing.vehicle_description_i18n IS '車型描述的多語言翻譯 (JSONB格式)';
COMMENT ON COLUMN vehicle_pricing.capacity_info_i18n IS '內容描述的多語言翻譯 (JSONB格式)';

-- 5. 驗證 Migration
-- 檢查欄位是否成功添加
DO $$
DECLARE
  vehicle_description_i18n_exists BOOLEAN;
  capacity_info_i18n_exists BOOLEAN;
  total_records INTEGER;
  migrated_records INTEGER;
BEGIN
  -- 檢查欄位是否存在
  SELECT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'vehicle_pricing' 
      AND column_name = 'vehicle_description_i18n'
  ) INTO vehicle_description_i18n_exists;

  SELECT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'vehicle_pricing' 
      AND column_name = 'capacity_info_i18n'
  ) INTO capacity_info_i18n_exists;

  -- 檢查資料遷移狀態
  SELECT COUNT(*) INTO total_records FROM vehicle_pricing;
  SELECT COUNT(*) INTO migrated_records 
  FROM vehicle_pricing 
  WHERE vehicle_description_i18n != '{}'::jsonb 
    AND capacity_info_i18n != '{}'::jsonb;

  -- 輸出驗證結果
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Vehicle Pricing i18n Migration 驗證結果';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'vehicle_description_i18n 欄位存在: %', vehicle_description_i18n_exists;
  RAISE NOTICE 'capacity_info_i18n 欄位存在: %', capacity_info_i18n_exists;
  RAISE NOTICE 'vehicle_pricing 表總記錄數: %', total_records;
  RAISE NOTICE '已遷移多語言資料的記錄數: %', migrated_records;
  
  IF total_records = migrated_records THEN
    RAISE NOTICE '✅ 所有記錄已成功遷移到多語言格式';
  ELSE
    RAISE WARNING '⚠️ 部分記錄未遷移，請檢查資料';
  END IF;
  
  RAISE NOTICE '========================================';
END $$;

-- 6. 查詢範例資料（前 3 筆）
SELECT 
  id,
  vehicle_type,
  vehicle_description,
  vehicle_description_i18n,
  capacity_info,
  capacity_info_i18n
FROM vehicle_pricing
LIMIT 3;

