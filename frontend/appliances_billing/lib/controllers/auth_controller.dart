import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';
import '../providers/providers.dart';
import '../config/app_config.dart';

class AuthController extends StateNotifier<AsyncValue<User?>> {
  final Ref _ref;
  final _auth = LocalAuthentication();
  final _storage = const FlutterSecureStorage();

  AuthController(this._ref) : super(const AsyncValue.data(null)) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final token = await _storage.read(key: AppConfig.authTokenKey);
      if (token != null) {
        final repo = _ref.read(userRepositoryProvider);
        final response = await repo.getCurrentUser();
        
        if (response.isSuccess && response.data != null) {
          state = AsyncValue.data(response.data);
        } else {
          await _storage.delete(key: AppConfig.authTokenKey);
          state = const AsyncValue.data(null);
        }
      }
    } catch (e) {
      state = const AsyncValue.data(null);
    }
  }

  Future<bool> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(userRepositoryProvider);
      final response = await repo.login(email, password);
      
      if (response.isSuccess && response.data != null) {
        state = AsyncValue.data(response.data);
        
        // If biometrics is required, prompt for it
        if (AppConfig.requireBiometrics) {
          final canCheckBiometrics = await _auth.canCheckBiometrics;
          final isDeviceSupported = await _auth.isDeviceSupported();
          
          if (canCheckBiometrics && isDeviceSupported) {
            final didAuthenticate = await _auth.authenticate(
              localizedReason: AppConfig.biometricsReason,
              options: const AuthenticationOptions(
                stickyAuth: true,
                biometricOnly: true,
              ),
            );
            
            if (!didAuthenticate) {
              await logout();
              return false;
            }
          }
        }
        
        return true;
      } else {
        state = AsyncValue.error(
          response.error ?? 'Login failed',
          StackTrace.current,
        );
        return false;
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.data(null);
    await _storage.delete(key: AppConfig.authTokenKey);
  }

  Future<bool> checkBiometrics() async {
    try {
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      
      if (canCheckBiometrics && isDeviceSupported) {
        final didAuthenticate = await _auth.authenticate(
          localizedReason: AppConfig.biometricsReason,
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        );
        
        return didAuthenticate;
      }
      return true; // If biometrics not supported, allow access
    } catch (e) {
      debugPrint('Error checking biometrics: $e');
      return false;
    }
  }

  bool get isAuthenticated => state.value != null;
}

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<User?>>((ref) {
  return AuthController(ref);
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authControllerProvider);
  return authState.value != null;
});