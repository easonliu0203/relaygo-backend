-- ============================================
-- 添加多語言欄位到 tour_packages 表
-- ============================================
-- 創建日期: 2024-12-20
-- 用途: 支援旅遊方案的多語言名稱和描述
-- ============================================

-- 1. 添加 name_i18n 欄位（多語言方案名稱）
ALTER TABLE tour_packages 
ADD COLUMN IF NOT EXISTS name_i18n JSONB DEFAULT '{}'::jsonb;

-- 2. 添加 description_i18n 欄位（多語言方案描述）
ALTER TABLE tour_packages 
ADD COLUMN IF NOT EXISTS description_i18n JSONB DEFAULT '{}'::jsonb;

-- 3. 添加註釋
COMMENT ON COLUMN tour_packages.name_i18n IS '多語言方案名稱 (JSONB): {"zh-TW": "台北一日遊", "en": "Taipei Day Tour", "ja": "台北日帰りツアー"}';
COMMENT ON COLUMN tour_packages.description_i18n IS '多語言方案描述 (JSONB): {"zh-TW": "探索台北...", "en": "Explore Taipei...", "ja": "台北を探索..."}';

-- 4. 創建 GIN 索引以提高 JSONB 查詢效能
CREATE INDEX IF NOT EXISTS idx_tour_packages_name_i18n ON tour_packages USING GIN (name_i18n);
CREATE INDEX IF NOT EXISTS idx_tour_packages_description_i18n ON tour_packages USING GIN (description_i18n);

-- 5. 遷移現有資料：將現有的 name 和 description 複製到 name_i18n 和 description_i18n 的 zh-TW 欄位
UPDATE tour_packages
SET 
  name_i18n = jsonb_build_object('zh-TW', name),
  description_i18n = jsonb_build_object('zh-TW', COALESCE(description, ''))
WHERE name_i18n = '{}'::jsonb OR description_i18n = '{}'::jsonb;

-- 6. 驗證遷移結果
DO $$
DECLARE
  record_count INTEGER;
  i18n_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO record_count FROM tour_packages;
  SELECT COUNT(*) INTO i18n_count FROM tour_packages WHERE name_i18n != '{}'::jsonb;
  
  RAISE NOTICE '✅ tour_packages 表總記錄數: %', record_count;
  RAISE NOTICE '✅ 已遷移多語言資料的記錄數: %', i18n_count;
  
  IF record_count = i18n_count THEN
    RAISE NOTICE '✅ 所有記錄已成功遷移到多語言格式';
  ELSE
    RAISE WARNING '⚠️ 有 % 條記錄尚未遷移', (record_count - i18n_count);
  END IF;
END $$;

-- 7. 查看範例資料
SELECT 
  id,
  name,
  name_i18n,
  description_i18n
FROM tour_packages
LIMIT 3;

