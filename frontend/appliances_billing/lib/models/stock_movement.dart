import 'package:json_annotation/json_annotation.dart';
import 'product.dart';

part 'stock_movement.g.dart';

@JsonSerializable()
class StockMovement {
  final String id;
  final Product product;
  final String type;
  final int quantity;
  final int previousStock;
  final int newStock;
  final String? reference;
  final String? remarks;
  final DateTime createdAt;

  StockMovement({
    required this.id,
    required this.product,
    required this.type,
    required this.quantity,
    required this.previousStock,
    required this.newStock,
    this.reference,
    this.remarks,
    required this.createdAt,
  });

  factory StockMovement.fromJson(Map<String, dynamic> json) =>
      _$StockMovementFromJson(json);
  Map<String, dynamic> toJson() => _$StockMovementToJson(this);

  // Helper methods
  bool get isStockIn => type == 'in';
  bool get isStockOut => type == 'out';

  String get formattedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  String get formattedTime {
    return '${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
  }
}