// 預約訂單狀態機
export enum BookingStatus {
  // 初始狀態
  DRAFT = 'draft',                    // 草稿
  PENDING_PAYMENT = 'pending_payment', // 待付訂金

  // 支付完成後
  PAID_DEPOSIT = 'paid_deposit',      // 已付訂金
  MATCHED = 'matched',                // 已配對（公司端配對司機）
  ASSIGNED = 'assigned',              // 已派單（保留向後兼容）
  DRIVER_CONFIRMED = 'driver_confirmed', // 司機確認

  // 行程進行中
  DRIVER_DEPARTED = 'driver_departed', // 司機出發
  DRIVER_ARRIVED = 'driver_arrived',   // 司機到達
  TRIP_STARTED = 'trip_started',       // 行程開始
  TRIP_ENDED = 'trip_ended',           // 行程結束

  // 結算階段
  PENDING_BALANCE = 'pending_balance', // 待付尾款
  COMPLETED = 'completed',             // 已完成

  // 異常狀態
  CANCELLED = 'cancelled',             // 已取消
  REFUNDED = 'refunded'               // 已退款
}

// 狀態轉換事件
export enum BookingEvent {
  // 支付相關
  PAYMENT_COMPLETED = 'payment_completed',
  PAYMENT_FAILED = 'payment_failed',
  
  // 派單相關
  ASSIGN_DRIVER = 'assign_driver',
  DRIVER_ACCEPT = 'driver_accept',
  DRIVER_REJECT = 'driver_reject',
  
  // 行程相關
  DRIVER_DEPART = 'driver_depart',
  DRIVER_ARRIVE = 'driver_arrive',
  START_TRIP = 'start_trip',
  END_TRIP = 'end_trip',
  
  // 結算相關
  BALANCE_PAID = 'balance_paid',
  COMPLETE_ORDER = 'complete_order',
  
  // 異常處理
  CANCEL_ORDER = 'cancel_order',
  REFUND_ORDER = 'refund_order'
}

// 狀態轉換規則
export const STATE_TRANSITIONS: Record<BookingStatus, BookingEvent[]> = {
  [BookingStatus.DRAFT]: [
    BookingEvent.PAYMENT_COMPLETED,
    BookingEvent.CANCEL_ORDER
  ],
  
  [BookingStatus.PENDING_PAYMENT]: [
    BookingEvent.PAYMENT_COMPLETED,
    BookingEvent.PAYMENT_FAILED,
    BookingEvent.CANCEL_ORDER
  ],
  
  [BookingStatus.PAID_DEPOSIT]: [
    BookingEvent.ASSIGN_DRIVER,
    BookingEvent.CANCEL_ORDER,
    BookingEvent.REFUND_ORDER
  ],

  [BookingStatus.MATCHED]: [
    BookingEvent.DRIVER_ACCEPT,
    BookingEvent.DRIVER_REJECT,
    BookingEvent.CANCEL_ORDER
  ],

  [BookingStatus.ASSIGNED]: [
    BookingEvent.DRIVER_ACCEPT,
    BookingEvent.DRIVER_REJECT,
    BookingEvent.CANCEL_ORDER
  ],
  
  [BookingStatus.DRIVER_CONFIRMED]: [
    BookingEvent.DRIVER_DEPART,
    BookingEvent.CANCEL_ORDER
  ],
  
  [BookingStatus.DRIVER_DEPARTED]: [
    BookingEvent.DRIVER_ARRIVE,
    BookingEvent.CANCEL_ORDER
  ],
  
  [BookingStatus.DRIVER_ARRIVED]: [
    BookingEvent.START_TRIP,
    BookingEvent.CANCEL_ORDER
  ],
  
  [BookingStatus.TRIP_STARTED]: [
    BookingEvent.END_TRIP
  ],
  
  [BookingStatus.TRIP_ENDED]: [
    BookingEvent.BALANCE_PAID,
    BookingEvent.COMPLETE_ORDER
  ],
  
  [BookingStatus.PENDING_BALANCE]: [
    BookingEvent.BALANCE_PAID,
    BookingEvent.COMPLETE_ORDER
  ],
  
  [BookingStatus.COMPLETED]: [],
  [BookingStatus.CANCELLED]: [BookingEvent.REFUND_ORDER],
  [BookingStatus.REFUNDED]: []
};

// 狀態轉換結果
export const EVENT_TRANSITIONS: Record<BookingEvent, BookingStatus> = {
  [BookingEvent.PAYMENT_COMPLETED]: BookingStatus.PAID_DEPOSIT,
  [BookingEvent.PAYMENT_FAILED]: BookingStatus.PENDING_PAYMENT,
  [BookingEvent.ASSIGN_DRIVER]: BookingStatus.MATCHED,  // 公司端配對後狀態為 matched
  [BookingEvent.DRIVER_ACCEPT]: BookingStatus.DRIVER_CONFIRMED,
  [BookingEvent.DRIVER_REJECT]: BookingStatus.PAID_DEPOSIT,
  [BookingEvent.DRIVER_DEPART]: BookingStatus.DRIVER_DEPARTED,
  [BookingEvent.DRIVER_ARRIVE]: BookingStatus.DRIVER_ARRIVED,
  [BookingEvent.START_TRIP]: BookingStatus.TRIP_STARTED,
  [BookingEvent.END_TRIP]: BookingStatus.TRIP_ENDED,
  [BookingEvent.BALANCE_PAID]: BookingStatus.PENDING_BALANCE,
  [BookingEvent.COMPLETE_ORDER]: BookingStatus.COMPLETED,
  [BookingEvent.CANCEL_ORDER]: BookingStatus.CANCELLED,
  [BookingEvent.REFUND_ORDER]: BookingStatus.REFUNDED
};

// 狀態機類
export class BookingStateMachine {
  private currentStatus: BookingStatus;
  private bookingId: string;

  constructor(bookingId: string, initialStatus: BookingStatus = BookingStatus.DRAFT) {
    this.bookingId = bookingId;
    this.currentStatus = initialStatus;
  }

  // 檢查是否可以執行事件
  canTransition(event: BookingEvent): boolean {
    const allowedEvents = STATE_TRANSITIONS[this.currentStatus];
    return allowedEvents.includes(event);
  }

  // 執行狀態轉換
  transition(event: BookingEvent): BookingStatus {
    if (!this.canTransition(event)) {
      throw new Error(
        `Invalid transition: Cannot execute ${event} from ${this.currentStatus}`
      );
    }

    const newStatus = EVENT_TRANSITIONS[event];
    const oldStatus = this.currentStatus;
    this.currentStatus = newStatus;

    // 觸發狀態轉換事件
    this.emitTransitionEvent(oldStatus, newStatus, event);

    return newStatus;
  }

  // 獲取當前狀態
  getCurrentStatus(): BookingStatus {
    return this.currentStatus;
  }

  // 獲取可執行的事件列表
  getAvailableEvents(): BookingEvent[] {
    return STATE_TRANSITIONS[this.currentStatus] || [];
  }

  // 檢查是否為終止狀態
  isTerminalState(): boolean {
    return [
      BookingStatus.COMPLETED,
      BookingStatus.CANCELLED,
      BookingStatus.REFUNDED
    ].includes(this.currentStatus);
  }

  // 獲取狀態顯示名稱
  getStatusDisplayName(status?: BookingStatus): string {
    const targetStatus = status || this.currentStatus;
    
    const displayNames: Record<BookingStatus, string> = {
      [BookingStatus.DRAFT]: '草稿',
      [BookingStatus.PENDING_PAYMENT]: '待付訂金',
      [BookingStatus.PAID_DEPOSIT]: '已付訂金',
      [BookingStatus.MATCHED]: '已配對',
      [BookingStatus.ASSIGNED]: '已派單',
      [BookingStatus.DRIVER_CONFIRMED]: '司機確認',
      [BookingStatus.DRIVER_DEPARTED]: '司機出發',
      [BookingStatus.DRIVER_ARRIVED]: '司機到達',
      [BookingStatus.TRIP_STARTED]: '行程進行中',
      [BookingStatus.TRIP_ENDED]: '行程結束',
      [BookingStatus.PENDING_BALANCE]: '待付尾款',
      [BookingStatus.COMPLETED]: '已完成',
      [BookingStatus.CANCELLED]: '已取消',
      [BookingStatus.REFUNDED]: '已退款'
    };

    return displayNames[targetStatus] || '未知狀態';
  }

  // 觸發狀態轉換事件
  private emitTransitionEvent(
    oldStatus: BookingStatus,
    newStatus: BookingStatus,
    event: BookingEvent
  ): void {
    // 這裡會觸發事件，通知其他系統組件
    const eventData = {
      bookingId: this.bookingId,
      oldStatus,
      newStatus,
      event,
      timestamp: new Date()
    };

    // 發送到事件總線
    process.nextTick(() => {
      require('../events/BookingEventBus').emit('booking.status.changed', eventData);
    });
  }

  // 驗證狀態轉換路徑
  static validateTransitionPath(
    fromStatus: BookingStatus,
    toStatus: BookingStatus
  ): { isValid: boolean; path?: BookingEvent[] } {
    // 簡單的路徑驗證實作
    // 實際應用中可能需要更複雜的路徑搜尋算法
    
    if (fromStatus === toStatus) {
      return { isValid: true, path: [] };
    }

    // 檢查直接轉換
    const allowedEvents = STATE_TRANSITIONS[fromStatus];
    for (const event of allowedEvents) {
      if (EVENT_TRANSITIONS[event] === toStatus) {
        return { isValid: true, path: [event] };
      }
    }

    return { isValid: false };
  }

  // 重設狀態機
  reset(newStatus: BookingStatus = BookingStatus.DRAFT): void {
    this.currentStatus = newStatus;
  }
}
