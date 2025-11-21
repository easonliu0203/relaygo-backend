import { Server as SocketIOServer } from 'socket.io';

// 訊息類型
export enum MessageType {
  TEXT = 'text',
  IMAGE = 'image',
  LOCATION = 'location',
  SYSTEM = 'system'
}

// 訊息狀態
export enum MessageStatus {
  SENT = 'sent',
  DELIVERED = 'delivered',
  READ = 'read'
}

// 聊天室狀態
export enum ChatRoomStatus {
  ACTIVE = 'active',
  INACTIVE = 'inactive',
  CLOSED = 'closed'
}

// 訊息介面
export interface ChatMessage {
  id: string;
  chatRoomId: string;
  senderId: string;
  senderType: 'customer' | 'driver' | 'system';
  type: MessageType;
  content: string;
  metadata?: Record<string, any>;
  status: MessageStatus;
  createdAt: Date;
  updatedAt: Date;
}

// 聊天室介面
export interface ChatRoom {
  id: string;
  bookingId: string;
  customerId: string;
  driverId: string;
  status: ChatRoomStatus;
  createdAt: Date;
  closedAt?: Date;
  lastMessageAt?: Date;
  unreadCount: {
    customer: number;
    driver: number;
  };
}

// 聊天服務
export class ChatService {
  private static instance: ChatService;
  private io: SocketIOServer | null = null;
  private chatRooms: Map<string, ChatRoom> = new Map();
  private messages: Map<string, ChatMessage[]> = new Map();

  private constructor() {}

  public static getInstance(): ChatService {
    if (!ChatService.instance) {
      ChatService.instance = new ChatService();
    }
    return ChatService.instance;
  }

  // 初始化 Socket.IO
  public initialize(io: SocketIOServer): void {
    this.io = io;
    this.setupSocketHandlers();
  }

  // 創建聊天室
  async createChatRoom(bookingId: string, customerId: string, driverId: string): Promise<ChatRoom> {
    const chatRoom: ChatRoom = {
      id: this.generateChatRoomId(bookingId),
      bookingId,
      customerId,
      driverId,
      status: ChatRoomStatus.ACTIVE,
      createdAt: new Date(),
      unreadCount: {
        customer: 0,
        driver: 0
      }
    };

    // 儲存聊天室
    this.chatRooms.set(chatRoom.id, chatRoom);
    this.messages.set(chatRoom.id, []);

    // 發送系統訊息
    await this.sendSystemMessage(chatRoom.id, '聊天室已開啟，您可以與司機/客戶進行溝通');

    // 通知相關用戶
    await this.notifyChatRoomCreated(chatRoom);

    return chatRoom;
  }

  // 發送訊息
  async sendMessage(
    chatRoomId: string,
    senderId: string,
    senderType: 'customer' | 'driver',
    type: MessageType,
    content: string,
    metadata?: Record<string, any>
  ): Promise<ChatMessage> {
    const chatRoom = this.chatRooms.get(chatRoomId);
    if (!chatRoom || chatRoom.status !== ChatRoomStatus.ACTIVE) {
      throw new Error('聊天室不存在或已關閉');
    }

    // 驗證發送者權限
    if (
      (senderType === 'customer' && senderId !== chatRoom.customerId) ||
      (senderType === 'driver' && senderId !== chatRoom.driverId)
    ) {
      throw new Error('無權限發送訊息');
    }

    const message: ChatMessage = {
      id: this.generateMessageId(),
      chatRoomId,
      senderId,
      senderType,
      type,
      content,
      metadata,
      status: MessageStatus.SENT,
      createdAt: new Date(),
      updatedAt: new Date()
    };

    // 儲存訊息
    const roomMessages = this.messages.get(chatRoomId) || [];
    roomMessages.push(message);
    this.messages.set(chatRoomId, roomMessages);

    // 更新聊天室資訊
    chatRoom.lastMessageAt = new Date();
    
    // 更新未讀計數
    if (senderType === 'customer') {
      chatRoom.unreadCount.driver++;
    } else {
      chatRoom.unreadCount.customer++;
    }

    // 即時推送訊息
    if (this.io) {
      this.io.to(`chat:${chatRoomId}`).emit('new_message', message);
    }

    // 發送推播通知
    await this.sendMessageNotification(message, chatRoom);

    return message;
  }

  // 發送系統訊息
  async sendSystemMessage(chatRoomId: string, content: string): Promise<ChatMessage> {
    const message: ChatMessage = {
      id: this.generateMessageId(),
      chatRoomId,
      senderId: 'system',
      senderType: 'system',
      type: MessageType.SYSTEM,
      content,
      status: MessageStatus.DELIVERED,
      createdAt: new Date(),
      updatedAt: new Date()
    };

    // 儲存訊息
    const roomMessages = this.messages.get(chatRoomId) || [];
    roomMessages.push(message);
    this.messages.set(chatRoomId, roomMessages);

    // 即時推送
    if (this.io) {
      this.io.to(`chat:${chatRoomId}`).emit('new_message', message);
    }

    return message;
  }

  // 獲取聊天記錄
  async getChatHistory(
    chatRoomId: string,
    userId: string,
    limit: number = 50,
    offset: number = 0
  ): Promise<ChatMessage[]> {
    const chatRoom = this.chatRooms.get(chatRoomId);
    if (!chatRoom) {
      throw new Error('聊天室不存在');
    }

    // 驗證用戶權限
    if (userId !== chatRoom.customerId && userId !== chatRoom.driverId) {
      throw new Error('無權限查看聊天記錄');
    }

    const roomMessages = this.messages.get(chatRoomId) || [];
    return roomMessages
      .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime())
      .slice(offset, offset + limit)
      .reverse();
  }

  // 標記訊息為已讀
  async markMessagesAsRead(chatRoomId: string, userId: string): Promise<void> {
    const chatRoom = this.chatRooms.get(chatRoomId);
    if (!chatRoom) {
      throw new Error('聊天室不存在');
    }

    // 重設未讀計數
    if (userId === chatRoom.customerId) {
      chatRoom.unreadCount.customer = 0;
    } else if (userId === chatRoom.driverId) {
      chatRoom.unreadCount.driver = 0;
    }

    // 更新訊息狀態
    const roomMessages = this.messages.get(chatRoomId) || [];
    roomMessages.forEach(message => {
      if (message.senderId !== userId && message.status !== MessageStatus.READ) {
        message.status = MessageStatus.READ;
        message.updatedAt = new Date();
      }
    });

    // 通知發送者訊息已讀
    if (this.io) {
      this.io.to(`chat:${chatRoomId}`).emit('messages_read', {
        chatRoomId,
        readBy: userId,
        timestamp: new Date()
      });
    }
  }

  // 關閉聊天室
  async closeChatRoom(chatRoomId: string): Promise<void> {
    const chatRoom = this.chatRooms.get(chatRoomId);
    if (!chatRoom) {
      throw new Error('聊天室不存在');
    }

    chatRoom.status = ChatRoomStatus.CLOSED;
    chatRoom.closedAt = new Date();

    // 發送系統訊息
    await this.sendSystemMessage(chatRoomId, '聊天室已關閉');

    // 通知用戶
    if (this.io) {
      this.io.to(`chat:${chatRoomId}`).emit('chat_room_closed', {
        chatRoomId,
        closedAt: chatRoom.closedAt
      });
    }
  }

  // 獲取用戶的聊天室列表
  async getUserChatRooms(userId: string, userType: 'customer' | 'driver'): Promise<ChatRoom[]> {
    const userChatRooms: ChatRoom[] = [];

    for (const chatRoom of this.chatRooms.values()) {
      if (
        (userType === 'customer' && chatRoom.customerId === userId) ||
        (userType === 'driver' && chatRoom.driverId === userId)
      ) {
        userChatRooms.push(chatRoom);
      }
    }

    return userChatRooms.sort((a, b) => {
      const aTime = a.lastMessageAt || a.createdAt;
      const bTime = b.lastMessageAt || b.createdAt;
      return bTime.getTime() - aTime.getTime();
    });
  }

  // 設定 Socket 處理器
  private setupSocketHandlers(): void {
    if (!this.io) return;

    this.io.on('connection', (socket) => {
      // 加入聊天室
      socket.on('join_chat', (data: { chatRoomId: string; userId: string }) => {
        socket.join(`chat:${data.chatRoomId}`);
        console.log(`User ${data.userId} joined chat room ${data.chatRoomId}`);
      });

      // 離開聊天室
      socket.on('leave_chat', (data: { chatRoomId: string; userId: string }) => {
        socket.leave(`chat:${data.chatRoomId}`);
        console.log(`User ${data.userId} left chat room ${data.chatRoomId}`);
      });

      // 發送訊息
      socket.on('send_message', async (data: {
        chatRoomId: string;
        senderId: string;
        senderType: 'customer' | 'driver';
        type: MessageType;
        content: string;
        metadata?: Record<string, any>;
      }) => {
        try {
          const message = await this.sendMessage(
            data.chatRoomId,
            data.senderId,
            data.senderType,
            data.type,
            data.content,
            data.metadata
          );
          
          socket.emit('message_sent', { success: true, message });
        } catch (error) {
          socket.emit('message_sent', { success: false, error: error.message });
        }
      });

      // 標記已讀
      socket.on('mark_read', async (data: { chatRoomId: string; userId: string }) => {
        try {
          await this.markMessagesAsRead(data.chatRoomId, data.userId);
        } catch (error) {
          console.error('Error marking messages as read:', error);
        }
      });

      // 正在輸入
      socket.on('typing', (data: { chatRoomId: string; userId: string; isTyping: boolean }) => {
        socket.to(`chat:${data.chatRoomId}`).emit('user_typing', {
          userId: data.userId,
          isTyping: data.isTyping
        });
      });
    });
  }

  // 發送訊息通知
  private async sendMessageNotification(message: ChatMessage, chatRoom: ChatRoom): Promise<void> {
    const notificationService = require('../notification/NotificationService').getInstance();
    
    // 確定接收者
    const recipientId = message.senderType === 'customer' ? chatRoom.driverId : chatRoom.customerId;
    const recipientType = message.senderType === 'customer' ? 'driver' : 'customer';

    await notificationService.sendNotification({
      type: 'new_message',
      recipientType,
      recipientId,
      title: '新訊息',
      message: message.content.length > 50 ? 
        message.content.substring(0, 50) + '...' : 
        message.content,
      data: {
        chatRoomId: chatRoom.id,
        bookingId: chatRoom.bookingId,
        messageId: message.id
      }
    });
  }

  // 通知聊天室創建
  private async notifyChatRoomCreated(chatRoom: ChatRoom): Promise<void> {
    const notificationService = require('../notification/NotificationService').getInstance();

    // 通知客戶
    await notificationService.sendToCustomer(chatRoom.customerId, {
      type: 'chat_room_opened',
      title: '聊天室已開啟',
      message: '您可以與司機進行溝通',
      data: { chatRoomId: chatRoom.id, bookingId: chatRoom.bookingId }
    });

    // 通知司機
    await notificationService.sendToDriver(chatRoom.driverId, {
      type: 'chat_room_opened',
      title: '聊天室已開啟',
      message: '您可以與客戶進行溝通',
      data: { chatRoomId: chatRoom.id, bookingId: chatRoom.bookingId }
    });
  }

  // 生成聊天室 ID
  private generateChatRoomId(bookingId: string): string {
    return `chat_${bookingId}`;
  }

  // 生成訊息 ID
  private generateMessageId(): string {
    return `msg_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  // 清理過期聊天室
  async cleanupInactiveChatRooms(): Promise<void> {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    for (const [chatRoomId, chatRoom] of this.chatRooms.entries()) {
      if (
        chatRoom.status === ChatRoomStatus.CLOSED &&
        chatRoom.closedAt &&
        chatRoom.closedAt < thirtyDaysAgo
      ) {
        this.chatRooms.delete(chatRoomId);
        this.messages.delete(chatRoomId);
      }
    }
  }
}

// 匯出單例
export const chatService = ChatService.getInstance();
