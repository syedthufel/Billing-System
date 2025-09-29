import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/api_service.dart';
import '../repositories/user_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/invoice_repository.dart';
import '../repositories/stock_movement_repository.dart';
import '../repositories/tally_repository.dart';

part 'providers.g.dart';

@riverpod
ApiService apiService(ApiServiceRef ref) {
  return ApiService();
}

@riverpod
class AuthState extends _$AuthState {
  @override
  bool build() {
    return false; // Initial authentication state
  }

  void setAuthenticated(bool value) {
    state = value;
  }
}

// Repository providers
@riverpod
UserRepository userRepository(UserRepositoryRef ref) {
  final apiService = ref.watch(apiServiceProvider);
  return UserRepository(apiService);
}

@riverpod
ProductRepository productRepository(ProductRepositoryRef ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ProductRepository(apiService);
}

@riverpod
InvoiceRepository invoiceRepository(InvoiceRepositoryRef ref) {
  final apiService = ref.watch(apiServiceProvider);
  return InvoiceRepository(apiService);
}

@riverpod
StockMovementRepository stockMovementRepository(StockMovementRepositoryRef ref) {
  final apiService = ref.watch(apiServiceProvider);
  return StockMovementRepository(apiService);
}

@riverpod
TallyRepository tallyRepository(TallyRepositoryRef ref) {
  final apiService = ref.watch(apiServiceProvider);
  return TallyRepository(apiService);
}