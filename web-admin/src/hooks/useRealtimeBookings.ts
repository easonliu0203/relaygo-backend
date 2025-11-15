/**
 * Supabase Realtime Hook for Bookings
 *
 * 用於公司端後台即時監聽訂單變更
 * 解決 2-5 分鐘延遲問題
 */

import { useEffect, useState } from 'react';
import { supabase } from '@/lib/supabase';

export interface RealtimeBooking {
  id: string;
  booking_number: string;
  status: string;
  deposit_paid: boolean;
  customer_id: string;
  driver_id: string | null;
  created_at: string;
  updated_at: string;
  [key: string]: any;
}

/**
 * 將 Supabase 的 snake_case 數據轉換為前端的 camelCase 格式
 * 只轉換變更的字段，保留現有的關聯數據
 * ✅ 添加防禦性編程，避免 null/undefined 導致崩潰
 */
function convertBookingData(rawBooking: any, existingBooking?: any): any {
  try {
    return {
      id: rawBooking.id || existingBooking?.id,
      bookingNumber: rawBooking.booking_number || existingBooking?.bookingNumber,
      status: rawBooking.status || existingBooking?.status,
      depositPaid: rawBooking.deposit_paid ?? existingBooking?.depositPaid ?? false,

      // 保留現有的關聯數據（customer, driver）
      customer: existingBooking?.customer || null,
      driver: existingBooking?.driver || null,

      // 訂單詳情（使用 fallback 值）
      vehicleType: rawBooking.vehicle_type || existingBooking?.vehicleType || '',
      pickupLocation: rawBooking.pickup_location || existingBooking?.pickupLocation || '',
      dropoffLocation: rawBooking.destination || existingBooking?.dropoffLocation || '',
      scheduledDate: rawBooking.start_date || existingBooking?.scheduledDate || '',
      scheduledTime: rawBooking.start_time || existingBooking?.scheduledTime || '',
      durationHours: rawBooking.duration_hours ?? existingBooking?.durationHours ?? 0,

      // 價格資訊（使用 fallback 值）
      pricing: {
        basePrice: rawBooking.base_price ?? existingBooking?.pricing?.basePrice ?? 0,
        totalAmount: rawBooking.total_amount ?? existingBooking?.pricing?.totalAmount ?? 0,
        depositAmount: rawBooking.deposit_amount ?? existingBooking?.pricing?.depositAmount ?? 0,
      },

      // 時間戳
      createdAt: rawBooking.created_at || existingBooking?.createdAt || new Date().toISOString(),
      updatedAt: rawBooking.updated_at || existingBooking?.updatedAt || new Date().toISOString(),

      // 其他資訊
      specialRequirements: rawBooking.special_requirements || existingBooking?.specialRequirements || '',
      requiresForeignLanguage: rawBooking.requires_foreign_language ?? existingBooking?.requiresForeignLanguage ?? false,
    };
  } catch (error) {
    console.error('❌ convertBookingData 錯誤:', error, {
      rawBooking,
      existingBooking,
    });
    // 返回現有數據或空對象，避免崩潰
    return existingBooking || {};
  }
}

export function useRealtimeBookings(initialBookings: RealtimeBooking[] = []) {
  const [bookings, setBookings] = useState<RealtimeBooking[]>(initialBookings);
  const [isConnected, setIsConnected] = useState(false);

  useEffect(() => {
    console.log('🔄 開始監聽 Supabase Realtime 訂單變更...');

    // 創建 Realtime 頻道
    const channel = supabase
      .channel('bookings_changes')
      .on(
        'postgres_changes',
        {
          event: '*', // 監聽所有事件：INSERT, UPDATE, DELETE
          schema: 'public',
          table: 'bookings',
        },
        (payload: any) => {
          try {
            console.log('📡 Realtime 收到訂單變更:', payload);

            if (payload.eventType === 'INSERT') {
              // 新增訂單
              const rawBooking = payload.new as RealtimeBooking;
              const newBooking = convertBookingData(rawBooking);
              console.log('✅ 新增訂單:', newBooking.id);
              setBookings((prev) => [newBooking, ...prev]);
            } else if (payload.eventType === 'UPDATE') {
              // 更新訂單
              const rawBooking = payload.new as RealtimeBooking;
              console.log('✅ 更新訂單:', rawBooking.id, {
                status: rawBooking.status,
                deposit_paid: rawBooking.deposit_paid,
              });

              // ✅ 添加防禦性編程：合併更新時保留現有的關聯數據
              setBookings((prev) => {
                try {
                  return prev.map((booking) => {
                    if (booking.id === rawBooking.id) {
                      // 轉換數據格式並保留現有的關聯數據
                      const updatedBooking = convertBookingData(rawBooking, booking);
                      return updatedBooking;
                    }
                    return booking;
                  });
                } catch (error) {
                  console.error('❌ 更新訂單時發生錯誤:', error);
                  // 返回原始數據，避免崩潰
                  return prev;
                }
              });
            } else if (payload.eventType === 'DELETE') {
              // 刪除訂單
              const deletedBooking = payload.old as RealtimeBooking;
              console.log('✅ 刪除訂單:', deletedBooking.id);
              setBookings((prev) =>
                prev.filter((booking) => booking.id !== deletedBooking.id)
              );
            }
          } catch (error) {
            console.error('❌ Realtime 事件處理錯誤:', error, payload);
            // 不拋出錯誤，避免崩潰
          }
        }
      )
      .subscribe((status: any, err: any) => {
        console.log('📡 Realtime 連接狀態:', status);

        if (err) {
          console.error('❌ Realtime 連接錯誤:', err);
        }

        if (status === 'SUBSCRIBED') {
          console.log('✅ Realtime 連接成功');
          setIsConnected(true);
        } else if (status === 'CHANNEL_ERROR') {
          console.error('❌ Realtime 頻道錯誤 - 這可能是因為:');
          console.error('   1. Supabase Realtime 未啟用');
          console.error('   2. bookings 表的 Replication 未啟用');
          console.error('   3. RLS 策略阻止了訂閱');
          console.error('   請檢查 Supabase Dashboard → Database → Replication');
          setIsConnected(false);
        } else if (status === 'TIMED_OUT') {
          console.error('❌ Realtime 連接超時');
          setIsConnected(false);
        } else if (status === 'CLOSED') {
          console.log('🔌 Realtime 連接已關閉');
          setIsConnected(false);
        } else {
          setIsConnected(false);
        }
      });

    // 清理函數
    return () => {
      console.log('🔌 關閉 Supabase Realtime 連接');
      supabase.removeChannel(channel);
    };
  }, []);

  return {
    bookings,
    setBookings,
    isConnected,
  };
}

