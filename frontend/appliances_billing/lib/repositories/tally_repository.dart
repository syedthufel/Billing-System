import '../models/tally.dart';
import '../models/api_response.dart';
import '../services/api_service.dart';

class TallyRepository {
  final ApiService _apiService;

  TallyRepository(this._apiService);

  Future<ApiResponse<List<Tally>>> getAllTallies({
    Map<String, dynamic>? filters,
  }) async {
    final response = await _apiService.get<List<Tally>>(
      '/tallies',
      queryParameters: filters,
      fromJson: (json) => (json['data'] as List)
          .map((item) => Tally.fromJson(item))
          .toList(),
    );
    return response;
  }

  Future<ApiResponse<Tally>> getTallyById(String id) async {
    final response = await _apiService.get<Tally>(
      '/tallies/$id',
      fromJson: (json) => Tally.fromJson(json),
    );
    return response;
  }

  Future<ApiResponse<Tally>> createTally(Tally tally) async {
    final response = await _apiService.post<Tally>(
      '/tallies',
      data: tally.toJson(),
      fromJson: (json) => Tally.fromJson(json),
    );
    return response;
  }

  Future<ApiResponse<void>> updateTally(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final response = await _apiService.put<void>(
      '/tallies/$id',
      data: updates,
    );
    return response;
  }

  Future<ApiResponse<Map<String, num>>> getTallySummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final response = await _apiService.get<Map<String, num>>(
      '/tallies/summary',
      queryParameters: {
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      },
      fromJson: (json) => Map<String, num>.from(json['data']),
    );
    return response;
  }
}