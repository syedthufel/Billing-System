import '../models/user.dart';
import '../models/api_response.dart';
import '../services/api_service.dart';

class UserRepository {
  final ApiService _apiService;

  UserRepository(this._apiService);

  Future<ApiResponse<User>> login(String email, String password) async {
    final response = await _apiService.post<User>(
      '/users/login',
      data: {
        'email': email,
        'password': password,
      },
      fromJson: (json) => User.fromJson(json),
    );
    return response;
  }

  Future<ApiResponse<User>> register(User user) async {
    final response = await _apiService.post<User>(
      '/users',
      data: user.toJson(),
      fromJson: (json) => User.fromJson(json),
    );
    return response;
  }

  Future<ApiResponse<User>> getCurrentUser() async {
    final response = await _apiService.get<User>(
      '/users/me',
      fromJson: (json) => User.fromJson(json),
    );
    return response;
  }

  Future<ApiResponse<void>> updateUser(String id, Map<String, dynamic> updates) async {
    final response = await _apiService.put<void>(
      '/users/$id',
      data: updates,
    );
    return response;
  }
}