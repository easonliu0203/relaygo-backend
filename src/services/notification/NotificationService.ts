import { Server as SocketIOServer } from 'socket.io';
import admin from 'firebase-admin';
import { getFirebaseApp, getFirestore } from '../../config/firebase';

// 通知類型
export enum NotificationType {
  // 預約相關
  BOOKING_CREATED = 'booking_created',
  BOOKING_CONFIRMED = 'booking_confirmed',
  BOOKING_CANCELLED = 'booking_cancelled',
  
  // 派單相關
  DRIVER_ASSIGNED = 'driver_assigned',
  DRIVER_ACCEPTED = 'driver_accepted',
  DRIVER_REJECTED = 'driver_rejected',
  
  // 行程相關
  DRIVER_DEPARTED = 'driver_departed',
  DRIVER_ARRIVED = 'driver_arrived',
  TRIP_STARTED = 'trip_started',
  TRIP_ENDED = 'trip_ended',
  
  // 支付相關
  PAYMENT_REQUIRED = 'payment_required',
  PAYMENT_COMPLETED = 'payment_completed',
  PAYMENT_FAILED = 'payment_failed',
  
  // 聊天相關
  NEW_MESSAGE = 'new_message',
  CHAT_ROOM_OPENED = 'chat_room_opened',
  CHAT_ROOM_CLOSED = 'chat_room_closed',
  
  // 系統相關
  SYSTEM_MAINTENANCE = 'system_maintenance',
  SYSTEM_UPDATE = 'system_update'
}

// 通知接收者類型
export enum RecipientType {
  CUSTOMER = 'customer',
  DRIVER = 'driver',
  ADMIN = 'admin',
  ALL = 'all'
}

// 通知介面
export interface Notification {
  id: string;
  type: NotificationType;
  recipientType: RecipientType;
  recipientId: string;
  title: string;
  message: string;
  data?: Record<string, any>;
  isRead: boolean;
  createdAt: Date;
  expiresAt?: Date;
}

// 通知服務
export class NotificationService {
  private static instance: NotificationService;
  private io: SocketIOServer | null = null;
  private notifications: Map<string, Notification[]> = new Map();

  private constructor() {}

  public static getInstance(): NotificationService {
    if (!NotificationService.instance) {
      NotificationService.instance = new NotificationService();
    }
    return NotificationService.instance;
  }

  // 初始化 Socket.IO
  public initialize(io: SocketIOServer): void {
    this.io = io;
    this.setupSocketHandlers();
  }

  // 發送通知給客戶
  async sendToCustomer(customerId: string, notification: Partial<Notification>): Promise<void> {
    const fullNotification = this.createNotification({
      ...notification,
      recipientType: RecipientType.CUSTOMER,
      recipientId: customerId
    });

    await this.sendNotification(fullNotification);
  }

  // 發送通知給司機
  async sendToDriver(driverId: string, notification: Partial<Notification>): Promise<void> {
    const fullNotification = this.createNotification({
      ...notification,
      recipientType: RecipientType.DRIVER,
      recipientId: driverId
    });

    await this.sendNotification(fullNotification);
  }

  // 發送通知給管理員
  async sendToAdmin(adminId: string, notification: Partial<Notification>): Promise<void> {
    const fullNotification = this.createNotification({
      ...notification,
      recipientType: RecipientType.ADMIN,
      recipientId: adminId
    });

    await this.sendNotification(fullNotification);
  }

  // 廣播通知
  async broadcast(notification: Partial<Notification>): Promise<void> {
    const fullNotification = this.createNotification({
      ...notification,
      recipientType: RecipientType.ALL,
      recipientId: 'all'
    });

    await this.sendNotification(fullNotification);
  }

  // 處理預約狀態變更通知
  async handleBookingStatusChange(eventData: any): Promise<void> {
    const { bookingId, oldStatus, newStatus, event } = eventData;
    
    // 獲取預約資訊
    const booking = await this.getBookingById(bookingId);
    if (!booking) return;

    switch (newStatus) {
      case 'assigned':
        await this.sendDriverAssignedNotifications(booking);
        break;
        
      case 'driver_confirmed':
        await this.sendDriverConfirmedNotifications(booking);
        break;
        
      case 'driver_departed':
        await this.sendDriverDepartedNotifications(booking);
        break;
        
      case 'driver_arrived':
        await this.sendDriverArrivedNotifications(booking);
        break;
        
      case 'trip_started':
        await this.sendTripStartedNotifications(booking);
        break;
        
      case 'trip_ended':
        await this.sendTripEndedNotifications(booking);
        break;
        
      case 'completed':
        await this.sendTripCompletedNotifications(booking);
        break;
    }
  }

  // 司機派單通知
  private async sendDriverAssignedNotifications(booking: any): Promise<void> {
    // 通知客戶
    await this.sendToCustomer(booking.customer_id, {
      type: NotificationType.DRIVER_ASSIGNED,
      title: '司機已安排',
      message: '已為您安排司機，請等待司機確認',
      data: { bookingId: booking.id }
    });

    // 通知司機
    if (booking.driver_id) {
      await this.sendToDriver(booking.driver_id, {
        type: NotificationType.DRIVER_ASSIGNED,
        title: '新訂單',
        message: '您有新的訂單，請確認接單',
        data: { bookingId: booking.id }
      });
    }
  }

  // 司機確認通知
  private async sendDriverConfirmedNotifications(booking: any): Promise<void> {
    await this.sendToCustomer(booking.customer_id, {
      type: NotificationType.DRIVER_ACCEPTED,
      title: '司機已確認',
      message: '司機已確認接單，請等待司機出發',
      data: { bookingId: booking.id, driverId: booking.driver_id }
    });
  }

  // 司機出發通知
  private async sendDriverDepartedNotifications(booking: any): Promise<void> {
    // 通知客戶
    await this.sendToCustomer(booking.customer_id, {
      type: NotificationType.DRIVER_DEPARTED,
      title: '司機已出發',
      message: '司機已出發前往接送地點，請準備上車',
      data: { bookingId: booking.id, driverId: booking.driver_id }
    });

    // 通知公司
    await this.sendToAdmin('system', {
      type: NotificationType.DRIVER_DEPARTED,
      title: '司機出發',
      message: `訂單 ${booking.booking_number} 的司機已出發`,
      data: { bookingId: booking.id, driverId: booking.driver_id }
    });
  }

  // 司機到達通知
  private async sendDriverArrivedNotifications(booking: any): Promise<void> {
    // 通知客戶
    await this.sendToCustomer(booking.customer_id, {
      type: NotificationType.DRIVER_ARRIVED,
      title: '司機已到達',
      message: '司機已到達接送地點，請準備上車',
      data: { bookingId: booking.id, driverId: booking.driver_id }
    });

    // 通知公司
    await this.sendToAdmin('system', {
      type: NotificationType.DRIVER_ARRIVED,
      title: '司機到達',
      message: `訂單 ${booking.booking_number} 的司機已到達`,
      data: { bookingId: booking.id, driverId: booking.driver_id }
    });
  }

  // 行程開始通知
  private async sendTripStartedNotifications(booking: any): Promise<void> {
    // 通知司機
    await this.sendToDriver(booking.driver_id, {
      type: NotificationType.TRIP_STARTED,
      title: '行程開始',
      message: '行程已開始，請安全駕駛',
      data: { bookingId: booking.id }
    });

    // 通知公司
    await this.sendToAdmin('system', {
      type: NotificationType.TRIP_STARTED,
      title: '行程開始',
      message: `訂單 ${booking.booking_number} 的行程已開始`,
      data: { bookingId: booking.id, driverId: booking.driver_id }
    });
  }

  // 行程結束通知
  private async sendTripEndedNotifications(booking: any): Promise<void> {
    // 通知客戶
    await this.sendToCustomer(booking.customer_id, {
      type: NotificationType.TRIP_ENDED,
      title: '行程結束',
      message: '行程已結束，請支付尾款並評價司機',
      data: { bookingId: booking.id, driverId: booking.driver_id }
    });

    // 通知司機
    await this.sendToDriver(booking.driver_id, {
      type: NotificationType.TRIP_ENDED,
      title: '行程結束',
      message: '行程已結束，等待客戶支付尾款',
      data: { bookingId: booking.id }
    });
  }

  // 行程完成通知
  private async sendTripCompletedNotifications(booking: any): Promise<void> {
    // 通知司機
    await this.sendToDriver(booking.driver_id, {
      type: NotificationType.PAYMENT_COMPLETED,
      title: '訂單完成',
      message: '客戶已完成支付，訂單結束',
      data: { bookingId: booking.id }
    });
  }

  // 創建通知
  private createNotification(data: Partial<Notification>): Notification {
    return {
      id: this.generateNotificationId(),
      type: data.type || NotificationType.SYSTEM_UPDATE,
      recipientType: data.recipientType || RecipientType.ALL,
      recipientId: data.recipientId || '',
      title: data.title || '',
      message: data.message || '',
      data: data.data,
      isRead: false,
      createdAt: new Date(),
      expiresAt: data.expiresAt
    };
  }

  // 發送通知
  private async sendNotification(notification: Notification): Promise<void> {
    // 1. 儲存通知
    await this.saveNotification(notification);

    // 2. 即時推送 (WebSocket)
    if (this.io) {
      this.sendRealtimeNotification(notification);
    }

    // 3. 推播通知 (FCM)
    await this.sendPushNotification(notification);

    // 4. 郵件通知 (可選)
    if (this.shouldSendEmail(notification)) {
      await this.sendEmailNotification(notification);
    }
  }

  // 即時推送
  private sendRealtimeNotification(notification: Notification): void {
    if (!this.io) return;

    const room = this.getSocketRoom(notification.recipientType, notification.recipientId);
    this.io.to(room).emit('notification', notification);
  }

  // 獲取 Socket 房間名稱
  private getSocketRoom(recipientType: RecipientType, recipientId: string): string {
    if (recipientType === RecipientType.ALL) {
      return 'all';
    }
    return `${recipientType}:${recipientId}`;
  }

  // 設定 Socket 處理器
  private setupSocketHandlers(): void {
    if (!this.io) return;

    this.io.on('connection', (socket) => {
      // 用戶加入房間
      socket.on('join', (data: { userType: string; userId: string }) => {
        const room = this.getSocketRoom(data.userType as RecipientType, data.userId);
        socket.join(room);
        console.log(`User ${data.userId} joined room ${room}`);
      });

      // 標記通知為已讀
      socket.on('mark_read', async (notificationId: string) => {
        await this.markAsRead(notificationId);
      });

      // 用戶離開
      socket.on('disconnect', () => {
        console.log('User disconnected');
      });
    });
  }

  // 儲存通知
  private async saveNotification(notification: Notification): Promise<void> {
    // 記憶體儲存 (實際應用中應該使用資料庫)
    const userNotifications = this.notifications.get(notification.recipientId) || [];
    userNotifications.push(notification);
    this.notifications.set(notification.recipientId, userNotifications);

    // TODO: 實作資料庫儲存
  }

  // 標記為已讀
  private async markAsRead(notificationId: string): Promise<void> {
    // TODO: 實作資料庫更新
    console.log(`Notification ${notificationId} marked as read`);
  }

  // 推播通知
  private async sendPushNotification(notification: Notification): Promise<void> {
    try {
      console.log('[FCM] 準備發送推播通知:', {
        recipientId: notification.recipientId,
        type: notification.type,
        title: notification.title
      });

      // 1. 從 Firestore 獲取用戶的 FCM Token
      const fcmToken = await this.getUserFcmToken(notification.recipientId);

      if (!fcmToken) {
        console.log('[FCM] 用戶沒有 FCM Token，跳過推播:', notification.recipientId);
        return;
      }

      console.log('[FCM] 找到 FCM Token:', fcmToken.substring(0, 20) + '...');

      // 2. 構建推播訊息
      const message: admin.messaging.Message = {
        token: fcmToken,
        notification: {
          title: notification.title,
          body: notification.message
        },
        data: {
          type: notification.type.toString(),
          notificationId: notification.id,
          ...(notification.data || {})
        },
        // Android 特定配置
        android: {
          priority: 'high',
          notification: {
            channelId: 'chat_messages',
            priority: 'high',
            sound: 'default',
            defaultSound: true,
            defaultVibrateTimings: true,
            defaultLightSettings: true
          }
        },
        // iOS 特定配置
        apns: {
          payload: {
            aps: {
              alert: {
                title: notification.title,
                body: notification.message
              },
              sound: 'default',
              badge: 1,
              contentAvailable: true
            }
          },
          headers: {
            'apns-priority': '10'
          }
        }
      };

      // 3. 發送推播
      const messaging = admin.messaging(getFirebaseApp());
      const response = await messaging.send(message);

      console.log('[FCM] ✅ 推播通知發送成功:', response);
    } catch (error: any) {
      console.error('[FCM] ❌ 推播通知發送失敗:', error);

      // 處理無效 Token 的情況
      if (error.code === 'messaging/invalid-registration-token' ||
          error.code === 'messaging/registration-token-not-registered') {
        console.log('[FCM] Token 無效，考慮清理:', notification.recipientId);
        // TODO: 可以在這裡清理無效的 Token
      }

      // 不拋出錯誤，避免影響主流程
    }
  }

  // 從 Firestore 獲取用戶的 FCM Token
  private async getUserFcmToken(userId: string): Promise<string | null> {
    try {
      const firestore = getFirestore();
      const userDoc = await firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        console.log('[FCM] 用戶文檔不存在:', userId);
        return null;
      }

      const userData = userDoc.data();
      const fcmToken = userData?.fcmToken;

      if (!fcmToken) {
        console.log('[FCM] 用戶沒有 FCM Token:', userId);
        return null;
      }

      return fcmToken;
    } catch (error) {
      console.error('[FCM] 獲取 FCM Token 失敗:', error);
      return null;
    }
  }

  // 郵件通知
  private async sendEmailNotification(notification: Notification): Promise<void> {
    // TODO: 實作郵件發送
    console.log('Email notification sent:', notification.title);
  }

  // 判斷是否需要發送郵件
  private shouldSendEmail(notification: Notification): boolean {
    const emailTypes = [
      NotificationType.BOOKING_CONFIRMED,
      NotificationType.BOOKING_CANCELLED,
      NotificationType.PAYMENT_COMPLETED
    ];
    return emailTypes.includes(notification.type);
  }

  // 生成通知 ID
  private generateNotificationId(): string {
    return `notif_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  // 獲取預約資訊 (需要實作)
  private async getBookingById(bookingId: string): Promise<any> {
    // TODO: 實作資料庫查詢
    return null;
  }

  // 獲取用戶通知
  async getUserNotifications(userId: string, limit: number = 20): Promise<Notification[]> {
    const userNotifications = this.notifications.get(userId) || [];
    return userNotifications
      .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime())
      .slice(0, limit);
  }

  // 清理過期通知
  async cleanupExpiredNotifications(): Promise<void> {
    const now = new Date();
    
    for (const [userId, notifications] of this.notifications.entries()) {
      const validNotifications = notifications.filter(
        notification => !notification.expiresAt || notification.expiresAt > now
      );
      this.notifications.set(userId, validNotifications);
    }
  }
}

// 匯出單例
export const notificationService = NotificationService.getInstance();
