import '../models/invoice.dart';
import '../models/api_response.dart';
import '../services/api_service.dart';

class InvoiceRepository {
  final ApiService _apiService;

  InvoiceRepository(this._apiService);

  Future<ApiResponse<List<Invoice>>> getAllInvoices({
    Map<String, dynamic>? filters,
  }) async {
    final response = await _apiService.get<List<Invoice>>(
      '/invoices',
      queryParameters: filters,
      fromJson: (json) => (json['data'] as List)
          .map((item) => Invoice.fromJson(item))
          .toList(),
    );
    return response;
  }

  Future<ApiResponse<Invoice>> getInvoiceById(String id) async {
    final response = await _apiService.get<Invoice>(
      '/invoices/$id',
      fromJson: (json) => Invoice.fromJson(json),
    );
    return response;
  }

  Future<ApiResponse<Invoice>> createInvoice(Invoice invoice) async {
    final response = await _apiService.post<Invoice>(
      '/invoices',
      data: invoice.toJson(),
      fromJson: (json) => Invoice.fromJson(json),
    );
    return response;
  }

  Future<ApiResponse<void>> updateInvoice(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final response = await _apiService.put<void>(
      '/invoices/$id',
      data: updates,
    );
    return response;
  }

  Future<ApiResponse<void>> deleteInvoice(String id) async {
    final response = await _apiService.delete<void>(
      '/invoices/$id',
    );
    return response;
  }

  Future<ApiResponse<void>> generatePdf(String id) async {
    final response = await _apiService.get<void>(
      '/invoices/$id/pdf',
    );
    return response;
  }
}