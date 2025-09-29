class AppConfig {
  // Environment-specific API URLs
  static const String _localApiUrl = 'http://localhost:5000/api';
  static const String _codespaceApiUrl = 'https://stunning-cod-974455r54gp4cxjp4-5000.app.github.dev/api';
  
  // Use codespace URL for device deployment
  static const String apiBaseUrl = _codespaceApiUrl;
  
  // Authentication
  static const Duration tokenExpiration = Duration(hours: 24);
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  
  // Local Auth
  static const bool requireBiometrics = true;
  static const String biometricsReason = 'Please authenticate to access the app';
  
  // App Settings
  static const String appName = 'Appliances Billing';
  static const String currencySymbol = '₹';
  static const int defaultGstRate = 18;
  
  // Caching
  static const Duration cacheDuration = Duration(hours: 1);
  
  // Pagination
  static const int defaultPageSize = 20;
  
  // PDF Settings
  static const String companyName = 'RIFA APPLIANCES';
  static const String companyAddress = '93, TAJ COMPLEX, CHERRY ROAD,\nKUMARSAMY PATTY, SALEM - 636007';
  static const String companyPhone = '98427 84919, 91503 28675';
  static const String companyEmail = 'rifa.appliances@gmail.com';
  static const String companyGstin = '33CCYPS5494Q1Z5';
  
  // Error Messages
  static const String networkError = 'Please check your internet connection';
  static const String serverError = 'Something went wrong. Please try again later';
  static const String authError = 'Invalid credentials';
  static const String sessionExpired = 'Session expired. Please login again';
  
  // Success Messages
  static const String loginSuccess = 'Login successful';
  static const String logoutSuccess = 'Logout successful';
  static const String saveSuccess = 'Changes saved successfully';
  static const String deleteSuccess = 'Deleted successfully';
  
  // Validation Rules
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 32;
  static const int otpLength = 6;
  
  // Date Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
}