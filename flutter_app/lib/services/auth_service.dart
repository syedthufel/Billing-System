import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;
  final LocalAuthentication _localAuth = LocalAuthentication();

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  AuthService() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    _setLoading(true);
    try {
      await ApiService.init();
      final userProfile = await ApiService.getProfile();
      _currentUser = User.fromJson(userProfile['user']);
      _isAuthenticated = true;
    } catch (e) {
      // User is not authenticated or token is invalid
      _isAuthenticated = false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await ApiService.login(username, password);
      if (result.success) {
        _currentUser = User.fromJson(result.user!);
        _isAuthenticated = true;
        notifyListeners();
        return true;
      } else {
        _setError(result.error ?? 'Login failed');
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> biometricLogin() async {
    _setLoading(true);
    _setError(null);

    try {
      // Check if biometric authentication is available
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      if (!isAvailable) {
        _setError('Biometric authentication is not available');
        return false;
      }

      // Check what biometric types are enrolled
      final List<BiometricType> availableBiometrics = 
          await _localAuth.getAvailableBiometrics();
      
      if (availableBiometrics.isEmpty) {
        _setError('No biometric authentication methods enrolled');
        return false;
      }

      // Authenticate using biometrics
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access the billing system',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (!didAuthenticate) {
        _setError('Biometric authentication failed');
        return false;
      }

      // Get stored user ID for biometric login
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('biometric_user_id');
      
      if (userId == null) {
        _setError('No user registered for biometric login');
        return false;
      }

      // Perform biometric login via API
      final result = await ApiService.biometricLogin(userId, {
        'verified': true,
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (result.success) {
        _currentUser = User.fromJson(result.user!);
        _isAuthenticated = true;
        notifyListeners();
        return true;
      } else {
        _setError(result.error ?? 'Biometric login failed');
        return false;
      }
    } catch (e) {
      _setError('Biometric authentication error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(String username, String email, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await ApiService.register({
        'username': username,
        'email': email,
        'password': password,
      });

      if (response.containsKey('user')) {
        _currentUser = User.fromJson(response['user']);
        _isAuthenticated = true;
        notifyListeners();
        return true;
      } else {
        _setError('Registration failed');
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> enableBiometric() async {
    if (_currentUser == null) return false;

    _setLoading(true);
    _setError(null);

    try {
      // Check if biometric authentication is available
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      if (!isAvailable) {
        _setError('Biometric authentication is not available');
        return false;
      }

      // Authenticate using biometrics to confirm
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to enable biometric login',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (!didAuthenticate) {
        _setError('Biometric authentication failed');
        return false;
      }

      // Enable biometric in backend
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/auth/biometric'),
        headers: ApiService._headers,
        body: jsonEncode({'enabled': true}),
      );

      final responseBody = jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(responseBody['error'] ?? 'Unknown error', response.statusCode);
      }

      // Store user ID for future biometric logins
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('biometric_user_id', _currentUser!.id);

      // Update current user
      _currentUser = User.fromJson(response['user']);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to enable biometric: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> disableBiometric() async {
    if (_currentUser == null) return false;

    _setLoading(true);
    _setError(null);

    try {
      // Disable biometric in backend
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/auth/biometric'),
        headers: ApiService._headers,
        body: jsonEncode({'enabled': false}),
      );

      final responseBody = jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(responseBody['error'] ?? 'Unknown error', response.statusCode);
      }

      // Remove stored user ID
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('biometric_user_id');

      // Update current user
      _currentUser = User.fromJson(response['user']);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to disable biometric: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await ApiService.logout();
      _currentUser = null;
      _isAuthenticated = false;
      _error = null;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> isBiometricAvailable() async {
    try {
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      final List<BiometricType> availableBiometrics = 
          await _localAuth.getAvailableBiometrics();
      return isAvailable && availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('biometric_user_id') && 
           (_currentUser?.biometricEnabled ?? false);
  }
}