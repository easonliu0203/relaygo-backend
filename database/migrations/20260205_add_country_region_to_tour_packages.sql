-- ============================================
-- 添加國家和地區欄位到 tour_packages 表
-- ============================================
-- 創建日期: 2026-02-05
-- 用途: 支援旅遊方案的多維度分類（國家 → 地區 → 方案）
-- ============================================

-- 1. 添加 country 欄位（國家代碼，ISO 3166-1 alpha-2）
ALTER TABLE tour_packages
ADD COLUMN IF NOT EXISTS country VARCHAR(2) DEFAULT 'TW';

-- 2. 添加 region 欄位（地區/城市代碼）
ALTER TABLE tour_packages
ADD COLUMN IF NOT EXISTS region VARCHAR(50) DEFAULT 'taipei';

-- 3. 添加 country_i18n 欄位（國家名稱多語言翻譯）
ALTER TABLE tour_packages
ADD COLUMN IF NOT EXISTS country_i18n JSONB DEFAULT '{}'::jsonb;

-- 4. 添加 region_i18n 欄位（地區名稱多語言翻譯）
ALTER TABLE tour_packages
ADD COLUMN IF NOT EXISTS region_i18n JSONB DEFAULT '{}'::jsonb;

-- 5. 添加註釋
COMMENT ON COLUMN tour_packages.country IS '國家代碼 (ISO 3166-1 alpha-2): TW, JP, KR, VN, TH, MY, ID';
COMMENT ON COLUMN tour_packages.region IS '地區/城市代碼: taipei, taichung, kaohsiung, jiufen, sunmoonlake, alishan, kenting, hualien';
COMMENT ON COLUMN tour_packages.country_i18n IS '國家名稱多語言翻譯 (JSONB): {"zh-TW": "台灣", "en": "Taiwan", "ja": "台湾"}';
COMMENT ON COLUMN tour_packages.region_i18n IS '地區名稱多語言翻譯 (JSONB): {"zh-TW": "台北", "en": "Taipei", "ja": "台北"}';

-- 6. 創建索引以優化查詢效能
CREATE INDEX IF NOT EXISTS idx_tour_packages_country ON tour_packages(country);
CREATE INDEX IF NOT EXISTS idx_tour_packages_region ON tour_packages(region);
CREATE INDEX IF NOT EXISTS idx_tour_packages_country_region ON tour_packages(country, region);

-- 7. 遷移現有資料：根據方案名稱設定對應的地區
-- 台灣的預設國家多語言翻譯
UPDATE tour_packages
SET
  country = 'TW',
  country_i18n = '{
    "zh-TW": "台灣",
    "en": "Taiwan",
    "ja": "台湾",
    "ko": "대만",
    "vi": "Đài Loan",
    "th": "ไต้หวัน",
    "ms": "Taiwan",
    "id": "Taiwan"
  }'::jsonb
WHERE country IS NULL OR country = 'TW';

-- 根據方案名稱設定地區（台北相關）
UPDATE tour_packages
SET
  region = 'taipei',
  region_i18n = '{
    "zh-TW": "台北",
    "en": "Taipei",
    "ja": "台北",
    "ko": "타이베이",
    "vi": "Đài Bắc",
    "th": "ไทเป",
    "ms": "Taipei",
    "id": "Taipei"
  }'::jsonb
WHERE name LIKE '%台北%' OR name LIKE '%Taipei%';

-- 根據方案名稱設定地區（台中相關）
UPDATE tour_packages
SET
  region = 'taichung',
  region_i18n = '{
    "zh-TW": "台中",
    "en": "Taichung",
    "ja": "台中",
    "ko": "타이중",
    "vi": "Đài Trung",
    "th": "ไถจง",
    "ms": "Taichung",
    "id": "Taichung"
  }'::jsonb
WHERE name LIKE '%台中%' OR name LIKE '%Taichung%';

-- 根據方案名稱設定地區（高雄相關）
UPDATE tour_packages
SET
  region = 'kaohsiung',
  region_i18n = '{
    "zh-TW": "高雄",
    "en": "Kaohsiung",
    "ja": "高雄",
    "ko": "가오슝",
    "vi": "Cao Hùng",
    "th": "เกาสง",
    "ms": "Kaohsiung",
    "id": "Kaohsiung"
  }'::jsonb
WHERE name LIKE '%高雄%' OR name LIKE '%Kaohsiung%';

-- 根據方案名稱設定地區（九份相關）
UPDATE tour_packages
SET
  region = 'jiufen',
  region_i18n = '{
    "zh-TW": "九份",
    "en": "Jiufen",
    "ja": "九份",
    "ko": "지우펀",
    "vi": "Cửu Phần",
    "th": "จิ่วเฟิ่น",
    "ms": "Jiufen",
    "id": "Jiufen"
  }'::jsonb
WHERE name LIKE '%九份%' OR name LIKE '%Jiufen%';

-- 根據方案名稱設定地區（日月潭相關）
UPDATE tour_packages
SET
  region = 'sunmoonlake',
  region_i18n = '{
    "zh-TW": "日月潭",
    "en": "Sun Moon Lake",
    "ja": "日月潭",
    "ko": "르웨탄",
    "vi": "Hồ Nhật Nguyệt",
    "th": "ทะเลสาบสุริยันจันทรา",
    "ms": "Tasik Sun Moon",
    "id": "Danau Sun Moon"
  }'::jsonb
WHERE name LIKE '%日月潭%' OR name LIKE '%Sun Moon%';

-- 根據方案名稱設定地區（阿里山相關）
UPDATE tour_packages
SET
  region = 'alishan',
  region_i18n = '{
    "zh-TW": "阿里山",
    "en": "Alishan",
    "ja": "阿里山",
    "ko": "아리산",
    "vi": "A Lý Sơn",
    "th": "อาลีซาน",
    "ms": "Alishan",
    "id": "Alishan"
  }'::jsonb
WHERE name LIKE '%阿里山%' OR name LIKE '%Alishan%';


-- 根據方案名稱設定地區（花蓮相關）
UPDATE tour_packages
SET
  region = 'hualien',
  region_i18n = '{
    "zh-TW": "花蓮",
    "en": "Hualien",
    "ja": "花蓮",
    "ko": "화롄",
    "vi": "Hoa Liên",
    "th": "ฮัวเหลียน",
    "ms": "Hualien",
    "id": "Hualien"
  }'::jsonb
WHERE name LIKE '%花蓮%' OR name LIKE '%Hualien%';

-- 根據方案名稱設定地區（墾丁相關）
UPDATE tour_packages
SET
  region = 'kenting',
  region_i18n = '{
    "zh-TW": "墾丁",
    "en": "Kenting",
    "ja": "墾丁",
    "ko": "컨딩",
    "vi": "Khẩn Đinh",
    "th": "เคินติง",
    "ms": "Kenting",
    "id": "Kenting"
  }'::jsonb
WHERE name LIKE '%墾丁%' OR name LIKE '%Kenting%';

-- 8. 確保所有未匹配的方案都有預設的台北地區設定
UPDATE tour_packages
SET
  region = 'taipei',
  region_i18n = '{
    "zh-TW": "台北",
    "en": "Taipei",
    "ja": "台北",
    "ko": "타이베이",
    "vi": "Đài Bắc",
    "th": "ไทเป",
    "ms": "Taipei",
    "id": "Taipei"
  }'::jsonb
WHERE region_i18n = '{}'::jsonb OR region_i18n IS NULL;
