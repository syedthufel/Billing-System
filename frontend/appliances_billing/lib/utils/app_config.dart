class AppConfig {
  static const String apiBaseUrl = 'http://localhost:5000/api';
  static const String socketUrl = 'ws://localhost:5000';

  // API Endpoints
  static const String login = '/users/login';
  static const String register = '/users';
  static const String biometricLogin = '/users/login/biometric';
  static const String biometricRegister = '/users/biometric';
  
  static const String products = '/products';
  static const String productStock = '/products/{id}/stock';
  static const String productStockHistory = '/products/{id}/stock-history';
  
  static const String invoices = '/invoices';
  static const String invoicePayment = '/invoices/{id}/payment';
  
  static const String tallyDaily = '/tally/daily';
  static const String tallyExpense = '/tally/expense';
  static const String tallyClose = '/tally/close';
  static const String tallyReport = '/tally/report';
}