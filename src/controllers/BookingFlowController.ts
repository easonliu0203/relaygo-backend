import { Request, Response } from 'express';
import { BookingStateMachine, BookingEvent, BookingStatus } from '../services/booking/BookingStateMachine';
import { dispatchService } from '../services/dispatch/DispatchService';
import { notificationService } from '../services/notification/NotificationService';
import { chatService } from '../services/chat/ChatService';
import { getPaymentService } from '../services/payment';

// 完整業務流程控制器
export class BookingFlowController {
  
  // 1. 客戶預約 (創建訂單)
  async createBooking(req: Request, res: Response): Promise<void> {
    try {
      const {
        customerId,
        vehicleType,
        startDate,
        startTime,
        duration,
        pickupLocation,
        pickupLatitude,
        pickupLongitude,
        specialRequirements
      } = req.body;

      // 1. 創建預約記錄
      const bookingData = {
        customerId,
        vehicleType,
        startDate,
        startTime,
        duration,
        pickupLocation,
        pickupLatitude,
        pickupLongitude,
        specialRequirements,
        status: BookingStatus.PENDING_PAYMENT,
        createdAt: new Date()
      };

      // 2. 計算價格
      const pricing = await this.calculatePricing(bookingData);
      bookingData.totalAmount = pricing.totalAmount;
      bookingData.depositAmount = pricing.depositAmount;

      // 3. 儲存到資料庫
      const booking = await this.saveBooking(bookingData);

      // 4. 發送確認通知
      await notificationService.sendToCustomer(customerId, {
        type: 'booking_created',
        title: '預約已建立',
        message: '請完成訂金支付以確認預約',
        data: { bookingId: booking.id }
      });

      res.status(201).json({
        success: true,
        data: {
          booking,
          pricing,
          nextStep: 'payment_required'
        }
      });

    } catch (error) {
      console.error('Create booking error:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

  // 2. 支付訂金
  async payDeposit(req: Request, res: Response): Promise<void> {
    try {
      const { bookingId } = req.params;
      const { paymentMethod } = req.body;

      // 1. 獲取預約資訊
      const booking = await this.getBookingById(bookingId);
      if (!booking) {
        return res.status(404).json({
          success: false,
          error: '預約不存在'
        });
      }

      // 2. 檢查狀態
      if (booking.status !== BookingStatus.PENDING_PAYMENT) {
        return res.status(400).json({
          success: false,
          error: '預約狀態不正確'
        });
      }

      // 3. 發起支付
      const paymentService = getPaymentService();
      const paymentResult = await paymentService.initiatePayment({
        orderId: booking.bookingNumber,
        amount: booking.depositAmount,
        currency: 'TWD',
        description: `包車服務訂金 - ${booking.bookingNumber}`,
        customerInfo: {
          customerId: booking.customerId,
          email: booking.customerEmail,
          phone: booking.customerPhone
        },
        metadata: {
          bookingId: booking.id,
          paymentType: 'deposit'
        }
      });

      if (paymentResult.success) {
        // 4. 更新預約狀態 (如果是自動完成的模擬支付)
        if (paymentResult.metadata?.autoCompleted) {
          await this.handlePaymentSuccess(bookingId, paymentResult.transactionId);
        }

        res.json({
          success: true,
          data: {
            transactionId: paymentResult.transactionId,
            paymentUrl: paymentResult.paymentUrl,
            instructions: paymentResult.instructions,
            expiresAt: paymentResult.expiresAt,
            autoCompleted: paymentResult.metadata?.autoCompleted
          }
        });
      } else {
        res.status(400).json({
          success: false,
          error: '支付發起失敗'
        });
      }

    } catch (error) {
      console.error('Pay deposit error:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

  // 3. 處理支付成功回調
  async handlePaymentSuccess(bookingId: string, transactionId: string): Promise<void> {
    try {
      // 1. 更新預約狀態
      const stateMachine = new BookingStateMachine(bookingId);
      await this.loadBookingStatus(stateMachine, bookingId);
      stateMachine.transition(BookingEvent.PAYMENT_COMPLETED);

      // 2. 更新資料庫
      await this.updateBookingStatus(bookingId, BookingStatus.PAID_DEPOSIT);

      // 3. 自動派單 (如果啟用)
      const autoDispatchEnabled = process.env.AUTO_DISPATCH_ENABLED === 'true';
      if (autoDispatchEnabled) {
        setTimeout(async () => {
          await dispatchService.autoDispatch(bookingId);
        }, 5000); // 5秒後自動派單
      }

      // 4. 發送通知
      const booking = await this.getBookingById(bookingId);
      await notificationService.sendToCustomer(booking.customerId, {
        type: 'payment_completed',
        title: '支付成功',
        message: '訂金支付成功，正在為您安排司機',
        data: { bookingId, transactionId }
      });

    } catch (error) {
      console.error('Handle payment success error:', error);
    }
  }

  // 4. 手動派單 (公司端)
  async manualDispatch(req: Request, res: Response): Promise<void> {
    try {
      const { bookingId } = req.params;
      const { driverId } = req.body;
      const adminId = req.user?.id; // 從認證中間件獲取

      const result = await dispatchService.manualDispatch(bookingId, driverId, adminId);

      res.json({
        success: result.success,
        data: result,
        message: result.message
      });

    } catch (error) {
      console.error('Manual dispatch error:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

  // 5. 司機確認接單
  async driverAcceptBooking(req: Request, res: Response): Promise<void> {
    try {
      const { bookingId } = req.params;
      const driverId = req.user?.id; // 從認證中間件獲取

      // 1. 檢查預約狀態
      const booking = await this.getBookingById(bookingId);
      if (!booking || booking.driverId !== driverId) {
        return res.status(403).json({
          success: false,
          error: '無權限操作此預約'
        });
      }

      // 2. 更新狀態
      const stateMachine = new BookingStateMachine(bookingId);
      await this.loadBookingStatus(stateMachine, bookingId);
      stateMachine.transition(BookingEvent.DRIVER_ACCEPT);

      // 3. 更新資料庫
      await this.updateBookingStatus(bookingId, BookingStatus.DRIVER_CONFIRMED);

      // 4. 創建聊天室
      const chatRoom = await chatService.createChatRoom(
        bookingId,
        booking.customerId,
        driverId
      );

      res.json({
        success: true,
        data: {
          bookingId,
          status: BookingStatus.DRIVER_CONFIRMED,
          chatRoomId: chatRoom.id,
          nextStep: 'driver_depart'
        }
      });

    } catch (error) {
      console.error('Driver accept booking error:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

  // 6. 司機出發
  async driverDepart(req: Request, res: Response): Promise<void> {
    try {
      const { bookingId } = req.params;
      const driverId = req.user?.id;

      // 1. 更新狀態
      const stateMachine = new BookingStateMachine(bookingId);
      await this.loadBookingStatus(stateMachine, bookingId);
      stateMachine.transition(BookingEvent.DRIVER_DEPART);

      // 2. 更新資料庫
      await this.updateBookingStatus(bookingId, BookingStatus.DRIVER_DEPARTED);
      await this.updateBookingTimestamp(bookingId, 'departedAt', new Date());

      res.json({
        success: true,
        data: {
          bookingId,
          status: BookingStatus.DRIVER_DEPARTED,
          departedAt: new Date(),
          nextStep: 'driver_arrive'
        }
      });

    } catch (error) {
      console.error('Driver depart error:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

  // 7. 司機到達
  async driverArrive(req: Request, res: Response): Promise<void> {
    try {
      const { bookingId } = req.params;
      const driverId = req.user?.id;

      // 1. 更新狀態
      const stateMachine = new BookingStateMachine(bookingId);
      await this.loadBookingStatus(stateMachine, bookingId);
      stateMachine.transition(BookingEvent.DRIVER_ARRIVE);

      // 2. 更新資料庫
      await this.updateBookingStatus(bookingId, BookingStatus.DRIVER_ARRIVED);
      await this.updateBookingTimestamp(bookingId, 'arrivedAt', new Date());

      res.json({
        success: true,
        data: {
          bookingId,
          status: BookingStatus.DRIVER_ARRIVED,
          arrivedAt: new Date(),
          nextStep: 'customer_start_trip'
        }
      });

    } catch (error) {
      console.error('Driver arrive error:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

  // 8. 客戶開始行程
  async startTrip(req: Request, res: Response): Promise<void> {
    try {
      const { bookingId } = req.params;
      const customerId = req.user?.id;

      // 1. 驗證權限
      const booking = await this.getBookingById(bookingId);
      if (!booking || booking.customerId !== customerId) {
        return res.status(403).json({
          success: false,
          error: '無權限操作此預約'
        });
      }

      // 2. 更新狀態
      const stateMachine = new BookingStateMachine(bookingId);
      await this.loadBookingStatus(stateMachine, bookingId);
      stateMachine.transition(BookingEvent.START_TRIP);

      // 3. 更新資料庫
      await this.updateBookingStatus(bookingId, BookingStatus.TRIP_STARTED);
      await this.updateBookingTimestamp(bookingId, 'tripStartedAt', new Date());

      res.json({
        success: true,
        data: {
          bookingId,
          status: BookingStatus.TRIP_STARTED,
          tripStartedAt: new Date(),
          nextStep: 'customer_end_trip'
        }
      });

    } catch (error) {
      console.error('Start trip error:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

  // 9. 客戶結束行程
  async endTrip(req: Request, res: Response): Promise<void> {
    try {
      const { bookingId } = req.params;
      const customerId = req.user?.id;

      // 1. 更新狀態
      const stateMachine = new BookingStateMachine(bookingId);
      await this.loadBookingStatus(stateMachine, bookingId);
      stateMachine.transition(BookingEvent.END_TRIP);

      // 2. 計算最終費用
      const booking = await this.getBookingById(bookingId);
      const finalAmount = await this.calculateFinalAmount(booking);

      // 3. 更新資料庫
      await this.updateBookingStatus(bookingId, BookingStatus.TRIP_ENDED);
      await this.updateBookingTimestamp(bookingId, 'tripEndedAt', new Date());
      await this.updateBookingAmount(bookingId, finalAmount);

      res.json({
        success: true,
        data: {
          bookingId,
          status: BookingStatus.TRIP_ENDED,
          tripEndedAt: new Date(),
          finalAmount,
          balanceAmount: finalAmount.balanceAmount,
          nextStep: 'payment_balance'
        }
      });

    } catch (error) {
      console.error('End trip error:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

  // 私有方法 - 需要實作
  private async calculatePricing(bookingData: any): Promise<any> {
    // TODO: 實作價格計算邏輯
    const basePrice = 2000; // 基礎價格
    const hourlyRate = 500; // 每小時費率
    const totalAmount = basePrice + (bookingData.duration * hourlyRate);
    const depositAmount = Math.round(totalAmount * 0.25); // 25% 訂金

    return {
      basePrice,
      hourlyRate,
      totalAmount,
      depositAmount,
      balanceAmount: totalAmount - depositAmount
    };
  }

  private async saveBooking(bookingData: any): Promise<any> {
    // TODO: 實作資料庫儲存
    return {
      id: `booking_${Date.now()}`,
      bookingNumber: `BK${Date.now()}`,
      ...bookingData
    };
  }

  private async getBookingById(bookingId: string): Promise<any> {
    // TODO: 實作資料庫查詢
    return null;
  }

  private async loadBookingStatus(stateMachine: BookingStateMachine, bookingId: string): Promise<void> {
    // TODO: 從資料庫載入當前狀態
  }

  private async updateBookingStatus(bookingId: string, status: BookingStatus): Promise<void> {
    // TODO: 實作資料庫更新
  }

  private async updateBookingTimestamp(bookingId: string, field: string, timestamp: Date): Promise<void> {
    // TODO: 實作時間戳更新
  }

  private async updateBookingAmount(bookingId: string, amounts: any): Promise<void> {
    // TODO: 實作金額更新
  }

  private async calculateFinalAmount(booking: any): Promise<any> {
    // TODO: 實作最終金額計算 (包含超時費用等)
    return {
      totalAmount: booking.totalAmount,
      depositAmount: booking.depositAmount,
      balanceAmount: booking.totalAmount - booking.depositAmount,
      overtimeFee: 0,
      tip: 0
    };
  }
}
