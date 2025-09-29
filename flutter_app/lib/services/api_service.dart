import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';
  static String? _token;

  // Initialize token from storage
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  // Save token to storage
  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    _token = token;
  }

  // Clear token from storage
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _token = null;
  }

  // Get headers with authorization
  static Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // Generic API request method
  static Future<Map<String, dynamic>> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    try {
      String url = '$baseUrl$endpoint';
      if (queryParams != null) {
        url += '?' + queryParams.entries
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&');
      }

      late http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(Uri.parse(url), headers: _headers);
          break;
        case 'POST':
          response = await http.post(
            Uri.parse(url),
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            Uri.parse(url),
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(Uri.parse(url), headers: _headers);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseBody;
      } else {
        throw ApiException(
          responseBody['error'] ?? 'Unknown error occurred',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e', 0);
    }
  }

  // Authentication methods
  static Future<AuthResult> login(String username, String password) async {
    final response = await _request('POST', '/auth/login', body: {
      'username': username,
      'password': password,
    });

    final token = response['token'] as String;
    await _saveToken(token);

    return AuthResult(
      success: true,
      user: response['user'],
      token: token,
      message: response['message'],
    );
  }

  static Future<AuthResult> biometricLogin(String userId, Map<String, dynamic> biometricData) async {
    final response = await _request('POST', '/auth/biometric-login', body: {
      'userId': userId,
      'biometricData': biometricData,
    });

    final token = response['token'] as String;
    await _saveToken(token);

    return AuthResult(
      success: true,
      user: response['user'],
      token: token,
      message: response['message'],
    );
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    final response = await _request('POST', '/auth/register', body: userData);
    
    if (response.containsKey('token')) {
      await _saveToken(response['token']);
    }
    
    return response;
  }

  static Future<Map<String, dynamic>> getProfile() async {
    return await _request('GET', '/auth/profile');
  }

  static Future<void> logout() async {
    await clearToken();
  }

  // Product methods
  static Future<Map<String, dynamic>> getProducts({
    int page = 1,
    int limit = 10,
    String? category,
    String? brand,
    String? search,
    double? minPrice,
    double? maxPrice,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (category != null) queryParams['category'] = category;
    if (brand != null) queryParams['brand'] = brand;
    if (search != null) queryParams['search'] = search;
    if (minPrice != null) queryParams['minPrice'] = minPrice.toString();
    if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();

    return await _request('GET', '/products', queryParams: queryParams);
  }

  static Future<Map<String, dynamic>> getProduct(String id) async {
    return await _request('GET', '/products/$id');
  }

  static Future<Map<String, dynamic>> createProduct(Map<String, dynamic> productData) async {
    return await _request('POST', '/products', body: productData);
  }

  static Future<Map<String, dynamic>> updateProduct(String id, Map<String, dynamic> productData) async {
    return await _request('PUT', '/products/$id', body: productData);
  }

  static Future<Map<String, dynamic>> deleteProduct(String id) async {
    return await _request('DELETE', '/products/$id');
  }

  // Invoice methods
  static Future<Map<String, dynamic>> getInvoices({
    int page = 1,
    int limit = 10,
    String? status,
    String? paymentStatus,
    String? startDate,
    String? endDate,
    String? customer,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (status != null) queryParams['status'] = status;
    if (paymentStatus != null) queryParams['paymentStatus'] = paymentStatus;
    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;
    if (customer != null) queryParams['customer'] = customer;

    return await _request('GET', '/invoices', queryParams: queryParams);
  }

  static Future<Map<String, dynamic>> getInvoice(String id) async {
    return await _request('GET', '/invoices/$id');
  }

  static Future<Map<String, dynamic>> createInvoice(Map<String, dynamic> invoiceData) async {
    return await _request('POST', '/invoices', body: invoiceData);
  }

  static Future<Map<String, dynamic>> updateInvoice(String id, Map<String, dynamic> invoiceData) async {
    return await _request('PUT', '/invoices/$id', body: invoiceData);
  }

  static Future<Map<String, dynamic>> cancelInvoice(String id) async {
    return await _request('DELETE', '/invoices/$id');
  }

  static Future<Map<String, dynamic>> getInvoiceStats({String? startDate, String? endDate}) async {
    final queryParams = <String, String>{};
    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;
    
    return await _request('GET', '/invoices/stats/summary', queryParams: queryParams);
  }

  // Stock methods
  static Future<Map<String, dynamic>> getStock({
    int page = 1,
    int limit = 10,
    String? status,
    String? category,
    String? search,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (status != null) queryParams['status'] = status;
    if (category != null) queryParams['category'] = category;
    if (search != null) queryParams['search'] = search;

    return await _request('GET', '/stock', queryParams: queryParams);
  }

  static Future<Map<String, dynamic>> getProductStock(String productId) async {
    return await _request('GET', '/stock/product/$productId');
  }

  static Future<Map<String, dynamic>> createStock(Map<String, dynamic> stockData) async {
    return await _request('POST', '/stock', body: stockData);
  }

  static Future<Map<String, dynamic>> updateStock(String id, Map<String, dynamic> stockData) async {
    return await _request('PUT', '/stock/$id', body: stockData);
  }

  static Future<Map<String, dynamic>> addStockMovement(String id, Map<String, dynamic> movementData) async {
    return await _request('POST', '/stock/$id/movement', body: movementData);
  }

  static Future<Map<String, dynamic>> getLowStockAlerts() async {
    return await _request('GET', '/stock/alerts/low-stock');
  }

  static Future<Map<String, dynamic>> getStockSummary() async {
    return await _request('GET', '/stock/summary/dashboard');
  }

  // Tally methods
  static Future<Map<String, dynamic>> getDailySales(String date) async {
    return await _request('GET', '/tally/daily/$date');
  }

  static Future<Map<String, dynamic>> getMonthlySales(int year, int month) async {
    return await _request('GET', '/tally/monthly/$year/$month');
  }

  static Future<Map<String, dynamic>> getGSTReport(String startDate, String endDate) async {
    return await _request('GET', '/tally/gst/$startDate/$endDate');
  }

  static Future<Map<String, dynamic>> getProductSalesReport(String startDate, String endDate) async {
    return await _request('GET', '/tally/products/$startDate/$endDate');
  }

  static Future<Map<String, dynamic>> getPaymentAnalysis(String startDate, String endDate) async {
    return await _request('GET', '/tally/payments/$startDate/$endDate');
  }

  static Future<Map<String, dynamic>> getTopCustomers([int limit = 10]) async {
    return await _request('GET', '/tally/customers/top/$limit');
  }

  static Future<Map<String, dynamic>> getDashboardData() async {
    return await _request('GET', '/tally/dashboard');
  }
}

class AuthResult {
  final bool success;
  final Map<String, dynamic>? user;
  final String? token;
  final String? message;
  final String? error;

  AuthResult({
    required this.success,
    this.user,
    this.token,
    this.message,
    this.error,
  });
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}