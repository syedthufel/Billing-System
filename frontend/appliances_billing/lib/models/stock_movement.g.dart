// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_movement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StockMovement _$StockMovementFromJson(Map<String, dynamic> json) =>
    StockMovement(
      id: json['id'] as String,
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      type: json['type'] as String,
      quantity: (json['quantity'] as num).toInt(),
      previousStock: (json['previousStock'] as num).toInt(),
      newStock: (json['newStock'] as num).toInt(),
      reference: json['reference'] as String?,
      remarks: json['remarks'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$StockMovementToJson(StockMovement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'product': instance.product.toJson(),
      'type': instance.type,
      'quantity': instance.quantity,
      'previousStock': instance.previousStock,
      'newStock': instance.newStock,
      'reference': instance.reference,
      'remarks': instance.remarks,
      'createdAt': instance.createdAt.toIso8601String(),
    };
