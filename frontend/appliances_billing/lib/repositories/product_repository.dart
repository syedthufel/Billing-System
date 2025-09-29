import '../models/product.dart';
import '../models/api_response.dart';
import '../services/api_service.dart';

class ProductRepository {
  final ApiService _apiService;

  ProductRepository(this._apiService);

  Future<ApiResponse<List<Product>>> getAllProducts({
    Map<String, dynamic>? filters,
  }) async {
    final response = await _apiService.get<List<Product>>(
      '/products',
      queryParameters: filters,
      fromJson: (json) => (json['data'] as List)
          .map((item) => Product.fromJson(item))
          .toList(),
    );
    return response;
  }

  Future<ApiResponse<Product>> getProductById(String id) async {
    final response = await _apiService.get<Product>(
      '/products/$id',
      fromJson: (json) => Product.fromJson(json),
    );
    return response;
  }

  Future<ApiResponse<Product>> createProduct(Product product) async {
    final response = await _apiService.post<Product>(
      '/products',
      data: product.toJson(),
      fromJson: (json) => Product.fromJson(json),
    );
    return response;
  }

  Future<ApiResponse<Product>> updateProduct(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final response = await _apiService.put<Product>(
      '/products/$id',
      data: updates,
      fromJson: (json) => Product.fromJson(json),
    );
    return response;
  }

  Future<ApiResponse<void>> deleteProduct(String id) async {
    final response = await _apiService.delete<void>(
      '/products/$id',
    );
    return response;
  }
}