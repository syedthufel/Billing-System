import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/invoice.dart';
import '../providers/providers.dart';

class BillingController extends StateNotifier<AsyncValue<Invoice?>> {
  final Ref _ref;

  BillingController(this._ref) : super(const AsyncValue.data(null));

  Future<bool> createInvoice(Invoice invoice) async {
    state = const AsyncValue.loading();
    
    try {
      final invoiceRepo = _ref.read(invoiceRepositoryProvider);
      final response = await invoiceRepo.createInvoice(invoice);
      
      if (response.isSuccess && response.data != null) {
        state = AsyncValue.data(response.data);
        return true;
      } else {
        state = AsyncValue.error(
          response.error ?? 'Failed to create invoice',
          StackTrace.current,
        );
        return false;
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  Future<bool> updateInvoice(String id, Map<String, dynamic> updates) async {
    state = const AsyncValue.loading();
    
    try {
      final invoiceRepo = _ref.read(invoiceRepositoryProvider);
      final response = await invoiceRepo.updateInvoice(id, updates);
      
      if (response.isSuccess) {
        // Refresh the current invoice
        await getInvoiceById(id);
        return true;
      } else {
        state = AsyncValue.error(
          response.error ?? 'Failed to update invoice',
          StackTrace.current,
        );
        return false;
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  Future<void> getInvoiceById(String id) async {
    state = const AsyncValue.loading();
    
    try {
      final invoiceRepo = _ref.read(invoiceRepositoryProvider);
      final response = await invoiceRepo.getInvoiceById(id);
      
      if (response.isSuccess && response.data != null) {
        state = AsyncValue.data(response.data);
      } else {
        state = AsyncValue.error(
          response.error ?? 'Invoice not found',
          StackTrace.current,
        );
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<bool> generatePdf(String invoiceId) async {
    try {
      final invoiceRepo = _ref.read(invoiceRepositoryProvider);
      final response = await invoiceRepo.generatePdf(invoiceId);
      
      return response.isSuccess;
    } catch (error) {
      return false;
    }
  }

  void clearInvoice() {
    state = const AsyncValue.data(null);
  }
}

final billingControllerProvider = StateNotifierProvider<BillingController, AsyncValue<Invoice?>>((ref) {
  return BillingController(ref);
});