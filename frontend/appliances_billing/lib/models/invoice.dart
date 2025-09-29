import 'package:json_annotation/json_annotation.dart';

part 'invoice.g.dart';

@JsonSerializable()
class InvoiceItem {
  final String product;
  final String productId;
  final String description;
  final String hsnCode;
  final int quantity;
  final double price;
  final double gstRate;
  final double gstAmount;
  final double total;

  InvoiceItem({
    required this.product,
    required this.productId,
    required this.description,
    required this.hsnCode,
    required this.quantity,
    required this.price,
    required this.gstRate,
    required this.gstAmount,
    required this.total,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) =>
      _$InvoiceItemFromJson(json);
  Map<String, dynamic> toJson() => _$InvoiceItemToJson(this);

  InvoiceItem copyWith({
    String? product,
    String? productId,
    String? description,
    String? hsnCode,
    int? quantity,
    double? price,
    double? gstRate,
    double? gstAmount,
    double? total,
  }) {
    return InvoiceItem(
      product: product ?? this.product,
      productId: productId ?? this.productId,
      description: description ?? this.description,
      hsnCode: hsnCode ?? this.hsnCode,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      gstRate: gstRate ?? this.gstRate,
      gstAmount: gstAmount ?? this.gstAmount,
      total: total ?? this.total,
    );
  }
}

@JsonSerializable()
class Customer {
  final String name;
  final String phone;
  final String email;
  final String address;
  final String gstin;

  Customer({
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.gstin,
  });

  factory Customer.fromJson(Map<String, dynamic> json) =>
      _$CustomerFromJson(json);
  Map<String, dynamic> toJson() => _$CustomerToJson(this);
}

@JsonSerializable()
class Invoice {
  final String id;
  final String invoiceNumber;
  final Customer customer;
  final List<InvoiceItem> items;
  final double subtotal;
  final double totalGST;
  final double total;
  final String paymentMethod;
  final String paymentStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.customer,
    required this.items,
    required this.subtotal,
    required this.totalGST,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) => _$InvoiceFromJson(json);
  Map<String, dynamic> toJson() => _$InvoiceToJson(this);

  // Helper methods
  bool get isPaid => paymentStatus == 'paid';
  bool get isPending => paymentStatus == 'pending';
  bool get isPartiallyPaid => paymentStatus == 'partial';

  String get formattedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  String get formattedTime {
    return '${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
  }
}