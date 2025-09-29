import 'package:json_annotation/json_annotation.dart';

part 'product.g.dart';

@JsonSerializable()
class Product {
  final String id;
  final String name;
  final String? description;
  final String brand;
  final String category;
  final double price;
  final double gstRate;
  final int stock;
  final int minStockLevel;
  final String sku;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.brand,
    required this.category,
    required this.price,
    required this.gstRate,
    required this.stock,
    required this.minStockLevel,
    required this.sku,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
  Map<String, dynamic> toJson() => _$ProductToJson(this);

  Product copyWith({
    String? id,
    String? name,
    String? description,
    String? brand,
    String? category,
    double? price,
    double? gstRate,
    int? stock,
    int? minStockLevel,
    String? sku,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      price: price ?? this.price,
      gstRate: gstRate ?? this.gstRate,
      stock: stock ?? this.stock,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      sku: sku ?? this.sku,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Calculate GST amount for a given quantity
  double calculateGstAmount(int quantity) {
    return (price * quantity * gstRate) / 100;
  }

  // Calculate total amount including GST for a given quantity
  double calculateTotalAmount(int quantity) {
    final subtotal = price * quantity;
    final gstAmount = calculateGstAmount(quantity);
    return subtotal + gstAmount;
  }

  // Check if stock is low
  bool get isLowStock => stock <= minStockLevel;
}