-- 創建 tour_packages 表
-- 用於儲存旅遊方案配置，供客戶端選擇旅遊地點

-- 啟用 UUID 擴展（如果尚未啟用）
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 創建 tour_packages 表
CREATE TABLE IF NOT EXISTS tour_packages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(name)
);

-- 創建索引以提高查詢性能
CREATE INDEX IF NOT EXISTS idx_tour_packages_active 
    ON tour_packages(is_active, display_order) 
    WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_tour_packages_display_order 
    ON tour_packages(display_order);

-- 創建更新時間觸發器
CREATE OR REPLACE FUNCTION update_tour_packages_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_tour_packages_updated_at
    BEFORE UPDATE ON tour_packages
    FOR EACH ROW
    EXECUTE FUNCTION update_tour_packages_updated_at();

-- 添加註釋
COMMENT ON TABLE tour_packages IS '旅遊方案配置表，用於儲存不同旅遊地點的方案信息';
COMMENT ON COLUMN tour_packages.name IS '方案名稱（例如：台北一日遊、台中一日遊）';
COMMENT ON COLUMN tour_packages.description IS '方案描述';
COMMENT ON COLUMN tour_packages.is_active IS '是否為活躍方案';
COMMENT ON COLUMN tour_packages.display_order IS '顯示順序（數字越小越靠前）';

-- 插入初始旅遊方案數據
INSERT INTO tour_packages (name, description, is_active, display_order)
VALUES
    ('台北一日遊', '探索台北市區熱門景點，包含故宮博物院、101大樓、士林夜市等', true, 1),
    ('台中一日遊', '暢遊台中市區及周邊景點，包含逢甲夜市、高美濕地、彩虹眷村等', true, 2),
    ('高雄一日遊', '體驗高雄港都風情，包含駁二藝術特區、旗津海岸、愛河等', true, 3),
    ('九份一日遊', '漫步九份老街，欣賞山城美景，品嚐特色小吃', true, 4),
    ('日月潭一日遊', '遊覽日月潭風景區，搭乘遊艇、參觀文武廟、品嚐阿婆茶葉蛋', true, 5),
    ('阿里山一日遊', '登上阿里山，欣賞日出、雲海、森林鐵路等自然美景', true, 6),
    ('墾丁一日遊', '享受墾丁陽光沙灘，遊覽國家公園、鵝鑾鼻燈塔等景點', true, 7),
    ('花蓮一日遊', '探索花蓮太魯閣國家公園、七星潭、清水斷崖等自然奇景', true, 8)
ON CONFLICT (name) DO NOTHING;

-- 驗證插入結果
DO $$
DECLARE
    record_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO record_count FROM tour_packages WHERE is_active = true;
    RAISE NOTICE '✅ 成功插入 % 條活躍旅遊方案記錄', record_count;
END $$;

