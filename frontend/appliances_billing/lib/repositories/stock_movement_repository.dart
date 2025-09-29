import '../models/stock_movement.dart';
import '../models/api_response.dart';
import '../services/api_service.dart';

class StockMovementRepository {
  final ApiService _apiService;

  StockMovementRepository(this._apiService);

  Future<ApiResponse<List<StockMovement>>> getAllStockMovements({
    Map<String, dynamic>? filters,
  }) async {
    final response = await _apiService.get<List<StockMovement>>(
      '/stock-movements',
      queryParameters: filters,
      fromJson: (json) => (json['data'] as List)
          .map((item) => StockMovement.fromJson(item))
          .toList(),
    );
    return response;
  }

  Future<ApiResponse<StockMovement>> getStockMovementById(String id) async {
    final response = await _apiService.get<StockMovement>(
      '/stock-movements/$id',
      fromJson: (json) => StockMovement.fromJson(json),
    );
    return response;
  }

  Future<ApiResponse<StockMovement>> createStockMovement(
    StockMovement stockMovement,
  ) async {
    final response = await _apiService.post<StockMovement>(
      '/stock-movements',
      data: stockMovement.toJson(),
      fromJson: (json) => StockMovement.fromJson(json),
    );
    return response;
  }

  Future<ApiResponse<void>> updateStockMovement(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final response = await _apiService.put<void>(
      '/stock-movements/$id',
      data: updates,
    );
    return response;
  }

  Future<ApiResponse<Map<String, int>>> getStockSummary() async {
    final response = await _apiService.get<Map<String, int>>(
      '/stock-movements/summary',
      fromJson: (json) => Map<String, int>.from(json['data']),
    );
    return response;
  }
}