-- ========================================
-- 修復 payments 資料表和創建 system_settings 資料表
-- ========================================

-- 1. 刪除舊的 payments 資料表（如果存在）
DROP TABLE IF EXISTS payments CASCADE;

-- 2. 創建新的 payments 資料表（使用正確的欄位名稱）
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL REFERENCES bookings(id),
    customer_id UUID NOT NULL REFERENCES users(id),
    transaction_id VARCHAR(100) UNIQUE NOT NULL,
    
    -- ✅ 使用 'type' 而不是 'payment_type'
    type VARCHAR(20) NOT NULL CHECK (type IN ('deposit', 'balance', 'refund')),
    
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'TWD',
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN (
        'pending', 'processing', 'completed', 'failed', 'cancelled', 'expired', 'refunded'
    )),
    
    -- 支付提供者資訊
    payment_provider VARCHAR(50) NOT NULL,
    payment_method VARCHAR(50),
    is_test_mode BOOLEAN DEFAULT false,
    
    -- 交易資訊
    external_transaction_id VARCHAR(255),
    payment_url TEXT,
    instructions TEXT,
    
    -- 時間資訊
    expires_at TIMESTAMP WITH TIME ZONE,
    processed_at TIMESTAMP WITH TIME ZONE,
    confirmed_at TIMESTAMP WITH TIME ZONE, -- ✅ 支付確認時間
    
    -- 管理資訊
    confirmed_by UUID REFERENCES users(id),
    admin_notes TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. 創建索引
CREATE INDEX idx_payments_booking_id ON payments(booking_id);
CREATE INDEX idx_payments_customer_id ON payments(customer_id);
CREATE INDEX idx_payments_transaction_id ON payments(transaction_id);
CREATE INDEX idx_payments_type ON payments(type);
CREATE INDEX idx_payments_status ON payments(status);

-- 4. 啟用 RLS
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- 5. 創建 RLS 策略
-- 允許 service_role 完全訪問
CREATE POLICY "Service role can do anything with payments"
ON payments
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- 允許用戶查看自己的支付記錄
CREATE POLICY "Users can view their own payments"
ON payments
FOR SELECT
TO authenticated
USING (customer_id = auth.uid());

-- 6. 創建 system_settings 資料表
CREATE TABLE IF NOT EXISTS system_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key VARCHAR(100) UNIQUE NOT NULL,
    value JSONB NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. 創建索引
CREATE INDEX idx_system_settings_key ON system_settings(key);

-- 8. 啟用 RLS
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;

-- 9. 創建 RLS 策略
-- 允許 service_role 完全訪問
CREATE POLICY "Service role can do anything with system_settings"
ON system_settings
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- 允許所有人讀取系統設定
CREATE POLICY "Anyone can read system_settings"
ON system_settings
FOR SELECT
TO authenticated
USING (true);

-- 10. 插入價格配置資料
INSERT INTO system_settings (key, value, description)
VALUES (
    'pricing_config',
    '{
        "vehicleTypes": {
            "large": {
                "name": "大型車（8-9人座）",
                "packages": {
                    "6_hours": {
                        "duration": 6,
                        "original_price": 90,
                        "discount_price": 75,
                        "overtime_rate": 15
                    },
                    "8_hours": {
                        "duration": 8,
                        "original_price": 120,
                        "discount_price": 100,
                        "overtime_rate": 15
                    }
                }
            },
            "small": {
                "name": "小型車（3-4人座）",
                "packages": {
                    "6_hours": {
                        "duration": 6,
                        "original_price": 60,
                        "discount_price": 50,
                        "overtime_rate": 10
                    },
                    "8_hours": {
                        "duration": 8,
                        "original_price": 80,
                        "discount_price": 65,
                        "overtime_rate": 10
                    }
                }
            }
        },
        "depositRate": 0.3
    }'::jsonb,
    '價格配置（包含車型、套餐、訂金比例）'
)
ON CONFLICT (key) DO UPDATE
SET value = EXCLUDED.value,
    updated_at = NOW();

-- 11. 插入封測配置資料
INSERT INTO system_settings (key, value, description)
VALUES (
    'beta_config',
    '{
        "auto_payment_enabled": true,
        "payment_delay_seconds": 5,
        "auto_assign_driver": false
    }'::jsonb,
    '封測階段配置（自動支付、自動派單等）'
)
ON CONFLICT (key) DO UPDATE
SET value = EXCLUDED.value,
    updated_at = NOW();

-- ========================================
-- 驗證
-- ========================================

-- 檢查 payments 資料表的欄位
SELECT 
    '✅ payments 資料表的欄位:' AS "說明";

SELECT 
    column_name AS "欄位名稱",
    data_type AS "資料類型",
    is_nullable AS "允許 NULL"
FROM information_schema.columns
WHERE table_name = 'payments'
ORDER BY ordinal_position;

-- 檢查 system_settings 資料表的欄位
SELECT 
    '✅ system_settings 資料表的欄位:' AS "說明";

SELECT 
    column_name AS "欄位名稱",
    data_type AS "資料類型",
    is_nullable AS "允許 NULL"
FROM information_schema.columns
WHERE table_name = 'system_settings'
ORDER BY ordinal_position;

-- 檢查價格配置
SELECT 
    '✅ 價格配置:' AS "說明";

SELECT 
    key AS "設定鍵",
    value AS "設定值",
    description AS "說明"
FROM system_settings
WHERE key = 'pricing_config';

-- 檢查封測配置
SELECT 
    '✅ 封測配置:' AS "說明";

SELECT 
    key AS "設定鍵",
    value AS "設定值",
    description AS "說明"
FROM system_settings
WHERE key = 'beta_config';

-- ========================================
-- 完成
-- ========================================

SELECT 
    '🎉 修復完成！' AS "狀態",
    '請重新啟動 Backend API 並測試支付訂金功能。' AS "下一步";

