import { EventEmitter } from 'events';
import { notificationService } from '../notification/NotificationService';
import { chatService } from '../chat/ChatService';

// 事件類型定義
export interface BookingStatusChangedEvent {
  bookingId: string;
  oldStatus: string;
  newStatus: string;
  event: string;
  timestamp: Date;
}

// 預約事件總線
class BookingEventBus extends EventEmitter {
  constructor() {
    super();
    this.setupEventHandlers();
  }

  // 設定事件處理器
  private setupEventHandlers(): void {
    // 監聽預約狀態變更事件
    this.on('booking.status.changed', this.handleBookingStatusChanged.bind(this));
    
    // 監聽支付事件
    this.on('payment.completed', this.handlePaymentCompleted.bind(this));
    this.on('payment.failed', this.handlePaymentFailed.bind(this));
    
    // 監聽派單事件
    this.on('dispatch.completed', this.handleDispatchCompleted.bind(this));
    this.on('dispatch.failed', this.handleDispatchFailed.bind(this));
    
    // 監聽行程事件
    this.on('trip.started', this.handleTripStarted.bind(this));
    this.on('trip.ended', this.handleTripEnded.bind(this));
  }

  // 處理預約狀態變更
  private async handleBookingStatusChanged(eventData: BookingStatusChangedEvent): Promise<void> {
    try {
      console.log(`[EventBus] Booking status changed: ${eventData.bookingId} ${eventData.oldStatus} -> ${eventData.newStatus}`);
      
      // 發送通知
      await notificationService.handleBookingStatusChange(eventData);
      
      // 根據狀態執行特定邏輯
      switch (eventData.newStatus) {
        case 'paid_deposit':
          await this.handleDepositPaid(eventData);
          break;
          
        case 'assigned':
          await this.handleDriverAssigned(eventData);
          break;
          
        case 'driver_confirmed':
          await this.handleDriverConfirmed(eventData);
          break;
          
        case 'driver_departed':
          await this.handleDriverDeparted(eventData);
          break;
          
        case 'driver_arrived':
          await this.handleDriverArrived(eventData);
          break;
          
        case 'trip_started':
          await this.handleTripStarted(eventData);
          break;
          
        case 'trip_ended':
          await this.handleTripEnded(eventData);
          break;
          
        case 'completed':
          await this.handleBookingCompleted(eventData);
          break;
      }
      
    } catch (error) {
      console.error('[EventBus] Error handling booking status change:', error);
    }
  }

  // 處理訂金支付完成
  private async handleDepositPaid(eventData: BookingStatusChangedEvent): Promise<void> {
    console.log(`[EventBus] Deposit paid for booking ${eventData.bookingId}`);
    
    // 觸發自動派單檢查
    this.emit('auto.dispatch.check', {
      bookingId: eventData.bookingId,
      timestamp: new Date()
    });
  }

  // 處理司機派單
  private async handleDriverAssigned(eventData: BookingStatusChangedEvent): Promise<void> {
    console.log(`[EventBus] Driver assigned to booking ${eventData.bookingId}`);
    
    // 設定司機回應超時檢查
    setTimeout(() => {
      this.emit('driver.response.timeout.check', {
        bookingId: eventData.bookingId,
        assignedAt: eventData.timestamp
      });
    }, 10 * 60 * 1000); // 10分鐘後檢查
  }

  // 處理司機確認
  private async handleDriverConfirmed(eventData: BookingStatusChangedEvent): Promise<void> {
    console.log(`[EventBus] Driver confirmed booking ${eventData.bookingId}`);
    
    // 創建聊天室
    try {
      const booking = await this.getBookingById(eventData.bookingId);
      if (booking && booking.customerId && booking.driverId) {
        await chatService.createChatRoom(
          eventData.bookingId,
          booking.customerId,
          booking.driverId
        );
      }
    } catch (error) {
      console.error('[EventBus] Error creating chat room:', error);
    }
  }

  // 處理司機出發
  private async handleDriverDeparted(eventData: BookingStatusChangedEvent): Promise<void> {
    console.log(`[EventBus] Driver departed for booking ${eventData.bookingId}`);
    
    // 開始位置追蹤
    this.emit('location.tracking.start', {
      bookingId: eventData.bookingId,
      timestamp: eventData.timestamp
    });
  }

  // 處理司機到達
  private async handleDriverArrived(eventData: BookingStatusChangedEvent): Promise<void> {
    console.log(`[EventBus] Driver arrived for booking ${eventData.bookingId}`);
    
    // 設定客戶上車超時檢查
    setTimeout(() => {
      this.emit('customer.boarding.timeout.check', {
        bookingId: eventData.bookingId,
        arrivedAt: eventData.timestamp
      });
    }, 15 * 60 * 1000); // 15分鐘後檢查
  }

  // 處理行程開始
  private async handleTripStarted(eventData: BookingStatusChangedEvent): Promise<void> {
    console.log(`[EventBus] Trip started for booking ${eventData.bookingId}`);
    
    // 開始行程計時
    this.emit('trip.timer.start', {
      bookingId: eventData.bookingId,
      startTime: eventData.timestamp
    });
    
    // 啟用即時位置追蹤
    this.emit('realtime.tracking.enable', {
      bookingId: eventData.bookingId
    });
  }

  // 處理行程結束
  private async handleTripEnded(eventData: BookingStatusChangedEvent): Promise<void> {
    console.log(`[EventBus] Trip ended for booking ${eventData.bookingId}`);
    
    // 停止位置追蹤
    this.emit('location.tracking.stop', {
      bookingId: eventData.bookingId,
      endTime: eventData.timestamp
    });
    
    // 計算最終費用
    this.emit('final.amount.calculate', {
      bookingId: eventData.bookingId,
      endTime: eventData.timestamp
    });
  }

  // 處理預約完成
  private async handleBookingCompleted(eventData: BookingStatusChangedEvent): Promise<void> {
    console.log(`[EventBus] Booking completed: ${eventData.bookingId}`);
    
    // 關閉聊天室
    try {
      const chatRoomId = `chat_${eventData.bookingId}`;
      await chatService.closeChatRoom(chatRoomId);
    } catch (error) {
      console.error('[EventBus] Error closing chat room:', error);
    }
    
    // 觸發評價提醒
    setTimeout(() => {
      this.emit('rating.reminder', {
        bookingId: eventData.bookingId
      });
    }, 5 * 60 * 1000); // 5分鐘後提醒評價
    
    // 更新司機統計
    this.emit('driver.stats.update', {
      bookingId: eventData.bookingId,
      completedAt: eventData.timestamp
    });
  }

  // 處理支付完成
  private async handlePaymentCompleted(eventData: any): Promise<void> {
    console.log(`[EventBus] Payment completed: ${eventData.transactionId}`);
    
    // 觸發預約狀態更新
    this.emit('booking.status.changed', {
      bookingId: eventData.bookingId,
      oldStatus: 'pending_payment',
      newStatus: 'paid_deposit',
      event: 'payment_completed',
      timestamp: new Date()
    });
  }

  // 處理支付失敗
  private async handlePaymentFailed(eventData: any): Promise<void> {
    console.log(`[EventBus] Payment failed: ${eventData.transactionId}`);
    
    // 發送支付失敗通知
    await notificationService.sendToCustomer(eventData.customerId, {
      type: 'payment_failed',
      title: '支付失敗',
      message: '訂金支付失敗，請重新嘗試',
      data: {
        bookingId: eventData.bookingId,
        transactionId: eventData.transactionId
      }
    });
  }

  // 處理派單完成
  private async handleDispatchCompleted(eventData: any): Promise<void> {
    console.log(`[EventBus] Dispatch completed: ${eventData.bookingId} -> ${eventData.driverId}`);
    
    // 觸發預約狀態更新
    this.emit('booking.status.changed', {
      bookingId: eventData.bookingId,
      oldStatus: 'paid_deposit',
      newStatus: 'assigned',
      event: 'assign_driver',
      timestamp: new Date()
    });
  }

  // 處理派單失敗
  private async handleDispatchFailed(eventData: any): Promise<void> {
    console.log(`[EventBus] Dispatch failed: ${eventData.bookingId}`);
    
    // 發送派單失敗通知給管理員
    await notificationService.sendToAdmin('system', {
      type: 'dispatch_failed',
      title: '派單失敗',
      message: `訂單 ${eventData.bookingId} 派單失敗，需要手動處理`,
      data: {
        bookingId: eventData.bookingId,
        reason: eventData.reason
      }
    });
  }

  // 工具方法：獲取預約資訊
  private async getBookingById(bookingId: string): Promise<any> {
    // TODO: 實作資料庫查詢
    return null;
  }

  // 發送自定義事件
  public emitBookingEvent(eventName: string, eventData: any): void {
    this.emit(eventName, eventData);
  }

  // 監聽自定義事件
  public onBookingEvent(eventName: string, handler: (...args: any[]) => void): void {
    this.on(eventName, handler);
  }

  // 移除事件監聽器
  public removeBookingEventListener(eventName: string, handler: (...args: any[]) => void): void {
    this.removeListener(eventName, handler);
  }

  // 獲取事件統計
  public getEventStats(): any {
    return {
      listenerCount: this.eventNames().reduce((total, eventName) => {
        return total + this.listenerCount(eventName);
      }, 0),
      eventNames: this.eventNames(),
      maxListeners: this.getMaxListeners()
    };
  }
}

// 匯出單例
export const bookingEventBus = new BookingEventBus();

// 設定最大監聽器數量
bookingEventBus.setMaxListeners(50);

export default bookingEventBus;
