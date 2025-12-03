-- Migration: 移除 vehicle_pricing 表的 UNIQUE 約束
-- Date: 2025-12-03
-- Author: System
-- Reason: 允許公司端修改車型等級 (vehicle_type)

-- 問題描述:
-- 原有的 UNIQUE 約束 (vehicle_type, duration_hours, effective_from) 
-- 導致無法修改 vehicle_type 欄位，因為會與現有記錄產生衝突
-- 
-- 錯誤訊息:
-- - 公司端: 409 Conflict
-- - Supabase: duplicate key value violates unique constraint

-- 解決方案:
-- 移除 UNIQUE 約束，改用 PRIMARY KEY (id) 作為唯一識別
-- 
-- 影響:
-- - 失去價格歷史版本管理功能（但目前系統並未使用）
-- - 允許自由修改車型等級、時長等欄位
-- - 如需價格歷史，可另建 vehicle_pricing_history 表

-- 執行 Migration
ALTER TABLE vehicle_pricing 
DROP CONSTRAINT IF EXISTS vehicle_pricing_vehicle_type_duration_hours_effective_from_key;

-- 驗證約束已移除
-- 預期結果: 不應包含 vehicle_pricing_vehicle_type_duration_hours_effective_from_key
SELECT 
  conname AS constraint_name, 
  contype AS constraint_type,
  pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint 
WHERE conrelid = 'vehicle_pricing'::regclass 
ORDER BY conname;

-- 測試修改車型等級
-- 以下 SQL 應該可以成功執行（之前會失敗）
-- UPDATE vehicle_pricing 
-- SET vehicle_type = 'S' 
-- WHERE vehicle_type = 'M' AND duration_hours = 6;

-- Rollback (如需恢復約束)
-- 注意: 恢復約束前需確保沒有重複的 (vehicle_type, duration_hours, effective_from) 組合
-- ALTER TABLE vehicle_pricing 
-- ADD CONSTRAINT vehicle_pricing_vehicle_type_duration_hours_effective_from_key 
-- UNIQUE (vehicle_type, duration_hours, effective_from);

