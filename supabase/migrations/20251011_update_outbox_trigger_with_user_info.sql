-- 更新 bookings_to_outbox trigger 函數以包含司機和客戶資訊
-- 修復日期：2025-10-11
-- 目的：在 outbox 事件中包含司機姓名、電話、車輛資訊和客戶姓名、電話

CREATE OR REPLACE FUNCTION bookings_to_outbox()
RETURNS TRIGGER AS $$
DECLARE
  customer_firebase_uid VARCHAR(128);
  customer_first_name VARCHAR(100);
  customer_last_name VARCHAR(100);
  customer_phone VARCHAR(20);
  driver_firebase_uid VARCHAR(128);
  driver_first_name VARCHAR(100);
  driver_last_name VARCHAR(100);
  driver_phone VARCHAR(20);
  driver_vehicle_plate VARCHAR(20);
  driver_vehicle_model VARCHAR(100);
  driver_rating DECIMAL(3,2);
BEGIN
  -- 獲取客戶資訊
  SELECT 
    u.firebase_uid,
    up.first_name,
    up.last_name,
    up.phone
  INTO 
    customer_firebase_uid,
    customer_first_name,
    customer_last_name,
    customer_phone
  FROM users u
  LEFT JOIN user_profiles up ON u.id = up.user_id
  WHERE u.id = NEW.customer_id;

  -- 獲取司機資訊（如果有分配司機）
  IF NEW.driver_id IS NOT NULL THEN
    SELECT 
      u.firebase_uid,
      up.first_name,
      up.last_name,
      up.phone,
      d.vehicle_plate,
      d.vehicle_model,
      d.rating
    INTO 
      driver_firebase_uid,
      driver_first_name,
      driver_last_name,
      driver_phone,
      driver_vehicle_plate,
      driver_vehicle_model,
      driver_rating
    FROM users u
    LEFT JOIN user_profiles up ON u.id = up.user_id
    LEFT JOIN drivers d ON u.id = d.user_id
    WHERE u.id = NEW.driver_id;
  END IF;

  -- 插入 outbox 事件
  INSERT INTO outbox (
    aggregate_type,
    aggregate_id,
    event_type,
    payload
  ) VALUES (
    'booking',
    NEW.id::TEXT,
    CASE
      WHEN TG_OP = 'INSERT' THEN 'created'
      WHEN TG_OP = 'UPDATE' THEN 'updated'
      WHEN TG_OP = 'DELETE' THEN 'deleted'
    END,
    jsonb_build_object(
      'id', NEW.id,
      'bookingNumber', NEW.booking_number,
      
      -- 客戶資訊
      'customerId', customer_firebase_uid,
      'customerName', CASE 
        WHEN customer_first_name IS NOT NULL OR customer_last_name IS NOT NULL 
        THEN TRIM(CONCAT(customer_first_name, ' ', customer_last_name))
        ELSE NULL
      END,
      'customerPhone', customer_phone,
      
      -- 司機資訊
      'driverId', driver_firebase_uid,
      'driverName', CASE 
        WHEN driver_first_name IS NOT NULL OR driver_last_name IS NOT NULL 
        THEN TRIM(CONCAT(driver_first_name, ' ', driver_last_name))
        ELSE NULL
      END,
      'driverPhone', driver_phone,
      'driverVehiclePlate', driver_vehicle_plate,
      'driverVehicleModel', driver_vehicle_model,
      'driverRating', driver_rating,
      
      -- 訂單基本資訊
      'status', NEW.status,
      'pickupAddress', NEW.pickup_location,
      'destination', NEW.destination,
      'startDate', NEW.start_date,
      'startTime', NEW.start_time,
      'durationHours', NEW.duration_hours,
      'vehicleType', NEW.vehicle_type,
      'specialRequirements', NEW.special_requirements,
      'passengerCount', NEW.passenger_count,
      'luggageCount', NEW.luggage_count,
      'totalAmount', NEW.total_amount,
      'depositAmount', NEW.deposit_amount,
      'createdAt', NEW.created_at,
      'actualStartTime', NEW.actual_start_time,
      'actualEndTime', NEW.actual_end_time,
      'pickupLocation', CASE 
        WHEN NEW.pickup_latitude IS NOT NULL AND NEW.pickup_longitude IS NOT NULL 
        THEN jsonb_build_object(
          'latitude', NEW.pickup_latitude,
          'longitude', NEW.pickup_longitude
        )
        ELSE NULL
      END
    )
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 重新創建 trigger（確保使用最新的函數）
DROP TRIGGER IF EXISTS bookings_outbox_trigger ON bookings;

CREATE TRIGGER bookings_outbox_trigger
AFTER INSERT OR UPDATE ON bookings
FOR EACH ROW
EXECUTE FUNCTION bookings_to_outbox();

-- 驗證 trigger 已更新
SELECT 
  'Trigger 已更新' as message,
  tgname as trigger_name,
  proname as function_name
FROM pg_trigger t
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE tgname = 'bookings_outbox_trigger';

