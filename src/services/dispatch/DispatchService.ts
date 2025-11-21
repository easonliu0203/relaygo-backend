import { BookingStateMachine, BookingEvent } from '../booking/BookingStateMachine';

// 派單模式
export enum DispatchMode {
  MANUAL = 'manual',     // 手動派單
  AUTO = 'auto'          // 自動派單
}

// 派單結果
export interface DispatchResult {
  success: boolean;
  bookingId: string;
  driverId?: string;
  message: string;
  dispatchMode: DispatchMode;
  dispatchedAt: Date;
  metadata?: Record<string, any>;
}

// 司機可用性檢查結果
export interface DriverAvailability {
  driverId: string;
  isAvailable: boolean;
  conflictingBookings?: string[];
  distance?: number;
  rating?: number;
  totalTrips?: number;
}

// 自動派單配置
export interface AutoDispatchConfig {
  enabled: boolean;
  maxRadius: number;        // 最大派單半徑 (公里)
  maxRetryAttempts: number; // 最大重試次數
  retryDelayMs: number;     // 重試延遲 (毫秒)
  priorityFactors: {
    distance: number;       // 距離權重
    rating: number;         // 評分權重
    experience: number;     // 經驗權重
  };
}

// 派單服務
export class DispatchService {
  private static instance: DispatchService;
  private autoDispatchConfig: AutoDispatchConfig;

  private constructor() {
    this.autoDispatchConfig = {
      enabled: process.env.AUTO_DISPATCH_ENABLED === 'true',
      maxRadius: parseInt(process.env.AUTO_DISPATCH_MAX_RADIUS || '20'),
      maxRetryAttempts: parseInt(process.env.AUTO_DISPATCH_MAX_RETRY || '3'),
      retryDelayMs: parseInt(process.env.AUTO_DISPATCH_RETRY_DELAY || '30000'),
      priorityFactors: {
        distance: 0.4,
        rating: 0.3,
        experience: 0.3
      }
    };
  }

  public static getInstance(): DispatchService {
    if (!DispatchService.instance) {
      DispatchService.instance = new DispatchService();
    }
    return DispatchService.instance;
  }

  // 手動派單
  async manualDispatch(bookingId: string, driverId: string, adminId: string): Promise<DispatchResult> {
    try {
      // 1. 檢查訂單狀態
      const booking = await this.getBookingById(bookingId);
      if (!booking) {
        return {
          success: false,
          bookingId,
          message: '訂單不存在',
          dispatchMode: DispatchMode.MANUAL,
          dispatchedAt: new Date()
        };
      }

      // 2. 檢查司機可用性
      const availability = await this.checkDriverAvailability(driverId, booking);
      if (!availability.isAvailable) {
        return {
          success: false,
          bookingId,
          driverId,
          message: `司機不可用: ${availability.conflictingBookings?.join(', ')}`,
          dispatchMode: DispatchMode.MANUAL,
          dispatchedAt: new Date()
        };
      }

      // 3. 執行派單
      const result = await this.assignDriverToBooking(bookingId, driverId, adminId);
      
      return {
        success: true,
        bookingId,
        driverId,
        message: '手動派單成功',
        dispatchMode: DispatchMode.MANUAL,
        dispatchedAt: new Date(),
        metadata: {
          adminId,
          driverInfo: availability
        }
      };

    } catch (error) {
      console.error('Manual dispatch failed:', error);
      return {
        success: false,
        bookingId,
        driverId,
        message: `派單失敗: ${error.message}`,
        dispatchMode: DispatchMode.MANUAL,
        dispatchedAt: new Date()
      };
    }
  }

  // 自動派單
  async autoDispatch(bookingId: string): Promise<DispatchResult> {
    if (!this.autoDispatchConfig.enabled) {
      return {
        success: false,
        bookingId,
        message: '自動派單功能未啟用',
        dispatchMode: DispatchMode.AUTO,
        dispatchedAt: new Date()
      };
    }

    try {
      // 1. 獲取訂單資訊
      const booking = await this.getBookingById(bookingId);
      if (!booking) {
        return {
          success: false,
          bookingId,
          message: '訂單不存在',
          dispatchMode: DispatchMode.AUTO,
          dispatchedAt: new Date()
        };
      }

      // 2. 尋找可用司機
      const availableDrivers = await this.findAvailableDrivers(booking);
      if (availableDrivers.length === 0) {
        return {
          success: false,
          bookingId,
          message: '沒有可用的司機',
          dispatchMode: DispatchMode.AUTO,
          dispatchedAt: new Date()
        };
      }

      // 3. 選擇最佳司機
      const bestDriver = this.selectBestDriver(availableDrivers, booking);

      // 4. 執行派單
      await this.assignDriverToBooking(bookingId, bestDriver.driverId);

      return {
        success: true,
        bookingId,
        driverId: bestDriver.driverId,
        message: '自動派單成功',
        dispatchMode: DispatchMode.AUTO,
        dispatchedAt: new Date(),
        metadata: {
          candidateCount: availableDrivers.length,
          selectedDriver: bestDriver
        }
      };

    } catch (error) {
      console.error('Auto dispatch failed:', error);
      return {
        success: false,
        bookingId,
        message: `自動派單失敗: ${error.message}`,
        dispatchMode: DispatchMode.AUTO,
        dispatchedAt: new Date()
      };
    }
  }

  // 檢查司機可用性
  async checkDriverAvailability(driverId: string, booking: any): Promise<DriverAvailability> {
    try {
      // 1. 檢查司機基本狀態
      const driver = await this.getDriverById(driverId);
      if (!driver || !driver.is_available) {
        return {
          driverId,
          isAvailable: false
        };
      }

      // 2. 檢查車型匹配
      if (driver.vehicle_type !== booking.vehicle_type) {
        return {
          driverId,
          isAvailable: false
        };
      }

      // 3. 檢查時間衝突
      const conflictingBookings = await this.checkTimeConflicts(driverId, booking);
      if (conflictingBookings.length > 0) {
        return {
          driverId,
          isAvailable: false,
          conflictingBookings: conflictingBookings.map(b => b.booking_number)
        };
      }

      // 4. 計算距離 (如果有位置資訊)
      let distance;
      if (booking.pickup_latitude && booking.pickup_longitude) {
        distance = await this.calculateDistance(driverId, booking);
      }

      return {
        driverId,
        isAvailable: true,
        distance,
        rating: driver.rating,
        totalTrips: driver.total_trips
      };

    } catch (error) {
      console.error('Error checking driver availability:', error);
      return {
        driverId,
        isAvailable: false
      };
    }
  }

  // 尋找可用司機
  private async findAvailableDrivers(booking: any): Promise<DriverAvailability[]> {
    // 1. 獲取符合車型的司機
    const drivers = await this.getDriversByVehicleType(booking.vehicle_type);
    
    // 2. 並行檢查可用性
    const availabilityChecks = drivers.map(driver => 
      this.checkDriverAvailability(driver.user_id, booking)
    );
    
    const availabilities = await Promise.all(availabilityChecks);
    
    // 3. 過濾可用司機
    return availabilities.filter(availability => availability.isAvailable);
  }

  // 選擇最佳司機 (平均分配原則)
  private selectBestDriver(availableDrivers: DriverAvailability[], booking: any): DriverAvailability {
    // 封測階段使用簡單的平均分配原則
    // 選擇完成訂單數最少的司機
    return availableDrivers.reduce((best, current) => {
      if (!best || (current.totalTrips || 0) < (best.totalTrips || 0)) {
        return current;
      }
      return best;
    });
  }

  // 執行派單
  private async assignDriverToBooking(bookingId: string, driverId: string, adminId?: string): Promise<void> {
    // 1. 更新訂單狀態
    await this.updateBookingDriver(bookingId, driverId);
    
    // 2. 更新狀態機
    const stateMachine = new BookingStateMachine(bookingId);
    // 這裡需要從資料庫載入當前狀態
    stateMachine.transition(BookingEvent.ASSIGN_DRIVER);
    
    // 3. 發送通知
    await this.sendDispatchNotifications(bookingId, driverId, adminId);
    
    // 4. 記錄派單日誌
    await this.logDispatchAction(bookingId, driverId, adminId);
  }

  // 檢查時間衝突
  private async checkTimeConflicts(driverId: string, booking: any): Promise<any[]> {
    // 實作時間衝突檢查邏輯
    // 檢查司機在同一日期是否有其他訂單
    
    // TODO: 實作資料庫查詢
    return [];
  }

  // 計算距離
  private async calculateDistance(driverId: string, booking: any): Promise<number> {
    // 實作距離計算邏輯
    // 可以使用 Google Maps API 或其他地圖服務
    
    // TODO: 實作距離計算
    return 0;
  }

  // 發送派單通知
  private async sendDispatchNotifications(bookingId: string, driverId: string, adminId?: string): Promise<void> {
    const notificationService = require('../notification/NotificationService').getInstance();
    
    // 通知司機
    await notificationService.sendToDriver(driverId, {
      type: 'new_booking_assigned',
      bookingId,
      message: '您有新的訂單，請確認接單'
    });
    
    // 通知客戶
    const booking = await this.getBookingById(bookingId);
    if (booking) {
      await notificationService.sendToCustomer(booking.customer_id, {
        type: 'driver_assigned',
        bookingId,
        driverId,
        message: '已為您安排司機，請等待司機確認'
      });
    }
  }

  // 記錄派單日誌
  private async logDispatchAction(bookingId: string, driverId: string, adminId?: string): Promise<void> {
    // TODO: 實作派單日誌記錄
    console.log('Dispatch action logged:', {
      bookingId,
      driverId,
      adminId,
      timestamp: new Date()
    });
  }

  // 資料庫操作方法 (需要實作)
  private async getBookingById(bookingId: string): Promise<any> {
    // TODO: 實作資料庫查詢
    return null;
  }

  private async getDriverById(driverId: string): Promise<any> {
    // TODO: 實作資料庫查詢
    return null;
  }

  private async getDriversByVehicleType(vehicleType: string): Promise<any[]> {
    // TODO: 實作資料庫查詢
    return [];
  }

  private async updateBookingDriver(bookingId: string, driverId: string): Promise<void> {
    // TODO: 實作資料庫更新
  }

  // 配置管理
  updateAutoDispatchConfig(config: Partial<AutoDispatchConfig>): void {
    this.autoDispatchConfig = {
      ...this.autoDispatchConfig,
      ...config
    };
  }

  getAutoDispatchConfig(): AutoDispatchConfig {
    return { ...this.autoDispatchConfig };
  }
}

// 匯出單例
export const dispatchService = DispatchService.getInstance();
