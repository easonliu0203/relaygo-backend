-- Manual Setup Script for Supabase Database
-- Execute this in Supabase Dashboard SQL Editor
-- URL: https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc/sql

-- Step 1: Create base tables
CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    firebase_uid VARCHAR(128) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    role VARCHAR(20) NOT NULL CHECK (role IN ('customer', 'driver', 'admin')),
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    preferred_language VARCHAR(10) DEFAULT 'zh-TW',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES users(id),
    driver_id UUID REFERENCES users(id),
    booking_number VARCHAR(20) UNIQUE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    start_date DATE NOT NULL,
    start_time TIME NOT NULL,
    duration_hours INTEGER NOT NULL,
    vehicle_type VARCHAR(10) NOT NULL,
    pickup_location TEXT NOT NULL,
    pickup_latitude DECIMAL(10, 8),
    pickup_longitude DECIMAL(11, 8),
    destination TEXT,
    special_requirements TEXT,
    requires_foreign_language BOOLEAN DEFAULT false,
    base_price DECIMAL(10,2) NOT NULL,
    foreign_language_surcharge DECIMAL(10,2) DEFAULT 0.00,
    overtime_fee DECIMAL(10,2) DEFAULT 0.00,
    tip_amount DECIMAL(10,2) DEFAULT 0.00,
    total_amount DECIMAL(10,2) NOT NULL,
    deposit_amount DECIMAL(10,2) NOT NULL,
    actual_start_time TIMESTAMP WITH TIME ZONE,
    actual_end_time TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_firebase_uid ON users(firebase_uid);
CREATE INDEX IF NOT EXISTS idx_bookings_customer_id ON bookings(customer_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON bookings(status);

-- Step 2: Create outbox table
CREATE TABLE IF NOT EXISTS outbox (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  aggregate_type VARCHAR(50) NOT NULL,
  aggregate_id VARCHAR(255) NOT NULL,
  event_type VARCHAR(50) NOT NULL,
  payload JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  processed_at TIMESTAMP WITH TIME ZONE,
  retry_count INTEGER DEFAULT 0,
  error_message TEXT
);

CREATE INDEX idx_outbox_processed ON outbox(processed_at) WHERE processed_at IS NULL;
CREATE INDEX idx_outbox_created_at ON outbox(created_at);
CREATE INDEX idx_outbox_aggregate ON outbox(aggregate_type, aggregate_id);

-- Step 3: Create trigger function
CREATE OR REPLACE FUNCTION bookings_to_outbox()
RETURNS TRIGGER AS $$
BEGIN
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
      'customerId', (SELECT firebase_uid FROM users WHERE id = NEW.customer_id),
      'status', NEW.status,
      'pickupAddress', NEW.pickup_location,
      'destination', NEW.destination,
      'startDate', NEW.start_date,
      'startTime', NEW.start_time,
      'durationHours', NEW.duration_hours,
      'vehicleType', NEW.vehicle_type,
      'specialRequirements', NEW.special_requirements,
      'requiresForeignLanguage', NEW.requires_foreign_language,
      'basePrice', NEW.base_price,
      'foreignLanguageSurcharge', NEW.foreign_language_surcharge,
      'overtimeFee', NEW.overtime_fee,
      'tipAmount', NEW.tip_amount,
      'totalAmount', NEW.total_amount,
      'depositAmount', NEW.deposit_amount,
      'createdAt', NEW.created_at,
      'updatedAt', NEW.updated_at,
      'pickupLocation', jsonb_build_object(
        'latitude', NEW.pickup_latitude,
        'longitude', NEW.pickup_longitude
      ),
      'driverId', CASE 
        WHEN NEW.driver_id IS NOT NULL 
        THEN (SELECT firebase_uid FROM users WHERE id = NEW.driver_id)
        ELSE NULL
      END,
      'actualStartTime', NEW.actual_start_time,
      'actualEndTime', NEW.actual_end_time
    )
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 4: Create trigger
CREATE TRIGGER bookings_outbox_trigger
AFTER INSERT OR UPDATE ON bookings
FOR EACH ROW
EXECUTE FUNCTION bookings_to_outbox();

-- Step 5: Create cleanup function
CREATE OR REPLACE FUNCTION cleanup_old_outbox_events()
RETURNS void AS $$
BEGIN
  DELETE FROM outbox
  WHERE processed_at IS NOT NULL
    AND processed_at < NOW() - INTERVAL '7 days';
END;
$$ LANGUAGE plpgsql;

-- Verification queries
SELECT 'Setup completed successfully!' as message;
SELECT 'Tables created:' as info, COUNT(*) as count FROM information_schema.tables WHERE table_schema = 'public' AND table_name IN ('users', 'bookings', 'outbox');
SELECT 'Trigger created:' as info, COUNT(*) as count FROM information_schema.triggers WHERE trigger_name = 'bookings_outbox_trigger';

