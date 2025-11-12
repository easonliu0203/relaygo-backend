-- 系統設定初始資料

INSERT INTO system_settings (key, value, description) VALUES
-- 平台設定
('platform.commission_rate', '0.25', '平台抽成比例 (25%)'),
('platform.deposit_percentage', '0.25', '訂金比例 (25%)'),
('platform.foreign_language_surcharge', '2000', '外語司機加價 (NT$2000/日)'),

-- 取消政策 (小時)
('cancellation.full_refund_hours', '168', '全額退款時限 (7天前)'),
('cancellation.half_refund_hours', '24', '半額退款時限 (1天前)'),
('cancellation.reschedule_fee_rate', '0.10', '改期手續費比例 (10%)'),

-- 司機保證金設定
('driver.deposit_amount', '10000', '司機保證金金額'),
('driver.late_cancellation_penalty', '2000', '司機遲到取消罰款'),
('driver.no_show_penalty', '1000', '司機爽約罰款'),

-- 定位設定
('location.update_interval_seconds', '60', '定位更新頻率 (秒)'),
('location.tracking_start_hours', '1', '行程前開始追蹤時間 (小時)'),
('location.retention_days', '30', '定位資料保存天數'),

-- 聊天設定
('chat.open_hours_before', '24', '聊天室開啟時間 (行程前小時)'),
('chat.open_hours_after', '24', '聊天室關閉時間 (行程後小時)'),
('chat.history_retention_days', '60', '聊天記錄保存天數'),

-- 超時計費設定
('overtime.grace_period_minutes', '15', '超時寬限期 (分鐘)'),
('overtime.billing_unit_minutes', '60', '超時計費單位 (分鐘)'),

-- 推薦設定
('referral.commission_rate', '0.025', '推薦獎金比例 (2.5%)'),
('referral.driver_activity_threshold', '1', '司機推薦活躍門檻 (月完單數)'),
('referral.code_expiry_days', '365', '推薦碼有效期 (天)'),

-- 支付設定
('payment.max_tip_amount', '10000', '最大小費金額'),
('payment.settlement_delay_days', '1', '結算延遲天數 (T+N)'),

-- 檔案上傳設定
('upload.max_file_size_mb', '10', '最大檔案大小 (MB)'),
('upload.allowed_image_types', '["jpg", "jpeg", "png", "webp"]', '允許的圖片格式'),
('upload.allowed_document_types', '["pdf", "doc", "docx"]', '允許的文件格式'),

-- 通知設定
('notification.push_enabled', 'true', '推播通知開啟'),
('notification.email_enabled', 'true', '郵件通知開啟'),
('notification.sms_enabled', 'true', '簡訊通知開啟'),

-- API 限制
('api.rate_limit_per_minute', '100', 'API 每分鐘請求限制'),
('api.rate_limit_per_hour', '1000', 'API 每小時請求限制'),

-- 多語言設定
('i18n.default_language', '"zh-TW"', '預設語言'),
('i18n.supported_languages', '["zh-TW", "en", "ja", "ko", "vi", "th", "ms", "id"]', '支援語言列表'),

-- 地圖設定
('maps.default_zoom_level', '15', '預設地圖縮放等級'),
('maps.search_radius_km', '50', '搜尋半徑 (公里)'),

-- 業務規則
('business.min_booking_advance_hours', '2', '最小預約提前時間 (小時)'),
('business.max_booking_advance_days', '30', '最大預約提前天數'),
('business.driver_response_timeout_minutes', '15', '司機回應超時 (分鐘)'),

-- 安全設定
('security.session_timeout_hours', '24', 'Session 超時時間 (小時)'),
('security.max_login_attempts', '5', '最大登入嘗試次數'),
('security.lockout_duration_minutes', '30', '帳號鎖定時間 (分鐘)'),

-- 維護模式
('maintenance.enabled', 'false', '維護模式開啟'),
('maintenance.message', '"系統維護中，請稍後再試"', '維護模式訊息'),

-- 版本資訊
('app.version', '"1.0.0"', '應用程式版本'),
('app.min_supported_version', '"1.0.0"', '最小支援版本'),
('api.version', '"v1"', 'API 版本');

-- 插入車型價格資料
INSERT INTO vehicle_pricing (vehicle_type, duration_hours, base_price, overtime_rate) VALUES
('A', 6, 8000.00, 1000.00),
('A', 8, 10000.00, 1000.00),
('B', 6, 6000.00, 800.00),
('B', 8, 8000.00, 800.00),
('C', 6, 4500.00, 600.00),
('C', 8, 6000.00, 600.00),
('D', 6, 3375.00, 400.00),
('D', 8, 4500.00, 400.00);
