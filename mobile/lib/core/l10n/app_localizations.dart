import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('zh', 'TW'), // 繁體中文
    Locale('zh', 'CN'), // 簡體中文
    Locale('en', 'US'), // 英文
  ];

  // 通用
  String get appName => _localizedValues[locale.languageCode]!['app_name']!;
  String get ok => _localizedValues[locale.languageCode]!['ok']!;
  String get cancel => _localizedValues[locale.languageCode]!['cancel']!;
  String get confirm => _localizedValues[locale.languageCode]!['confirm']!;
  String get save => _localizedValues[locale.languageCode]!['save']!;
  String get delete => _localizedValues[locale.languageCode]!['delete']!;
  String get edit => _localizedValues[locale.languageCode]!['edit']!;
  String get loading => _localizedValues[locale.languageCode]!['loading']!;
  String get error => _localizedValues[locale.languageCode]!['error']!;
  String get success => _localizedValues[locale.languageCode]!['success']!;
  String get retry => _localizedValues[locale.languageCode]!['retry']!;

  // 認證相關
  String get login => _localizedValues[locale.languageCode]!['login']!;
  String get logout => _localizedValues[locale.languageCode]!['logout']!;
  String get register => _localizedValues[locale.languageCode]!['register']!;
  String get email => _localizedValues[locale.languageCode]!['email']!;
  String get password => _localizedValues[locale.languageCode]!['password']!;
  String get phone => _localizedValues[locale.languageCode]!['phone']!;
  String get name => _localizedValues[locale.languageCode]!['name']!;

  // 導航
  String get home => _localizedValues[locale.languageCode]!['home']!;
  String get bookings => _localizedValues[locale.languageCode]!['bookings']!;
  String get profile => _localizedValues[locale.languageCode]!['profile']!;
  String get settings => _localizedValues[locale.languageCode]!['settings']!;

  // 訂車相關
  String get bookRide => _localizedValues[locale.languageCode]!['book_ride']!;
  String get pickupLocation => _localizedValues[locale.languageCode]!['pickup_location']!;
  String get destination => _localizedValues[locale.languageCode]!['destination']!;
  String get selectDate => _localizedValues[locale.languageCode]!['select_date']!;
  String get selectTime => _localizedValues[locale.languageCode]!['select_time']!;

  static const Map<String, Map<String, String>> _localizedValues = {
    'zh': {
      'app_name': '包車服務',
      'ok': '確定',
      'cancel': '取消',
      'confirm': '確認',
      'save': '儲存',
      'delete': '刪除',
      'edit': '編輯',
      'loading': '載入中...',
      'error': '錯誤',
      'success': '成功',
      'retry': '重試',
      'login': '登入',
      'logout': '登出',
      'register': '註冊',
      'email': '電子郵件',
      'password': '密碼',
      'phone': '電話號碼',
      'name': '姓名',
      'home': '首頁',
      'bookings': '訂單',
      'profile': '個人資料',
      'settings': '設定',
      'book_ride': '預約用車',
      'pickup_location': '上車地點',
      'destination': '目的地',
      'select_date': '選擇日期',
      'select_time': '選擇時間',
    },
    'en': {
      'app_name': 'Ride Booking',
      'ok': 'OK',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'retry': 'Retry',
      'login': 'Login',
      'logout': 'Logout',
      'register': 'Register',
      'email': 'Email',
      'password': 'Password',
      'phone': 'Phone',
      'name': 'Name',
      'home': 'Home',
      'bookings': 'Bookings',
      'profile': 'Profile',
      'settings': 'Settings',
      'book_ride': 'Book Ride',
      'pickup_location': 'Pickup Location',
      'destination': 'Destination',
      'select_date': 'Select Date',
      'select_time': 'Select Time',
    },
  };
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .any((supportedLocale) => supportedLocale.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
