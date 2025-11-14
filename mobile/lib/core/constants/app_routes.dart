/// 應用程式路由常數
class AppRoutes {
  // 基礎路由
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String roleSelection = '/role-selection';
  
  // 認證路由
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // 客戶端認證路由
  static const String customerLogin = '/customer/login';
  static const String customerRegister = '/customer/register';

  // 司機端認證路由
  static const String driverLogin = '/driver/login';
  static const String driverRegister = '/driver/register';
  
  // 乘客端路由
  static const String customerHome = '/customer';
  static const String booking = '/customer/booking';
  static const String tripDetail = '/customer/trip';
  static const String tripHistory = '/customer/history';
  static const String customerProfile = '/customer/profile';
  static const String customerSettings = '/customer/settings';
  static const String paymentMethods = '/customer/payment-methods';
  static const String referralCode = '/customer/referral';
  static const String customerSupport = '/customer/support';
  
  // 司機端路由
  static const String driverHome = '/driver';
  static const String tripManagement = '/driver/trips';
  static const String driverEarnings = '/driver/earnings';
  static const String driverProfile = '/driver/profile';
  static const String driverSettings = '/driver/settings';
  static const String driverDocuments = '/driver/documents';
  static const String driverSupport = '/driver/support';
  
  // 共用路由
  static const String chat = '/chat';
  static const String map = '/map';
  static const String notifications = '/notifications';
  static const String help = '/help';
  static const String about = '/about';
  static const String privacyPolicy = '/privacy-policy';
  static const String termsOfService = '/terms-of-service';
}
