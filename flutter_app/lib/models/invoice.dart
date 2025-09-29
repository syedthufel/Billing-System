class InvoiceItem {
  final String productId;
  final String productName;
  final String sku;
  final int quantity;
  final double unitPrice;
  final double gstRate;
  final double gstAmount;
  final double totalAmount;
  final double discount;

  InvoiceItem({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.unitPrice,
    required this.gstRate,
    required this.gstAmount,
    required this.totalAmount,
    this.discount = 0.0,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      productId: json['product'] ?? '',
      productName: json['productName'] ?? '',
      sku: json['sku'] ?? '',
      quantity: json['quantity'] ?? 1,
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      gstRate: (json['gstRate'] ?? 0).toDouble(),
      gstAmount: (json['gstAmount'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
      'discount': discount,
    };
  }
}

class CustomerInfo {
  final String name;
  final String? email;
  final String phone;
  final Address? address;
  final String? gstin;

  CustomerInfo({
    required this.name,
    this.email,
    required this.phone,
    this.address,
    this.gstin,
  });

  factory CustomerInfo.fromJson(Map<String, dynamic> json) {
    return CustomerInfo(
      name: json['name'] ?? '',
      email: json['email'],
      phone: json['phone'] ?? '',
      address: json['address'] != null 
          ? Address.fromJson(json['address'])
          : null,
      gstin: json['gstin'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'address': address?.toJson(),
      'gstin': gstin,
    };
  }
}

class Address {
  final String? street;
  final String? city;
  final String? state;
  final String? pincode;
  final String country;

  Address({
    this.street,
    this.city,
    this.state,
    this.pincode,
    this.country = 'India',
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street'],
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'],
      country: json['country'] ?? 'India',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'pincode': pincode,
      'country': country,
    };
  }
}

class Invoice {
  final String id;
  final String invoiceNumber;
  final CustomerInfo customerInfo;
  final List<InvoiceItem> items;
  final double subtotal;
  final double totalGST;
  final double totalDiscount;
  final double grandTotal;
  final String paymentMethod;
  final String paymentStatus;
  final String status;
  final DateTime? dueDate;
  final String? notes;
  final String createdBy;
  final List<String>? tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.customerInfo,
    required this.items,
    required this.subtotal,
    required this.totalGST,
    required this.totalDiscount,
    required this.grandTotal,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    this.dueDate,
    this.notes,
    required this.createdBy,
    this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['_id'] ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      customerInfo: CustomerInfo.fromJson(json['customerInfo']),
      items: (json['items'] as List)
          .map((item) => InvoiceItem.fromJson(item))
          .toList(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      totalGST: (json['totalGST'] ?? 0).toDouble(),
      totalDiscount: (json['totalDiscount'] ?? 0).toDouble(),
      grandTotal: (json['grandTotal'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'] ?? 'cash',
      paymentStatus: json['paymentStatus'] ?? 'pending',
      status: json['status'] ?? 'draft',
      dueDate: json['dueDate'] != null 
          ? DateTime.parse(json['dueDate'])
          : null,
      notes: json['notes'],
      createdBy: json['createdBy'] ?? '',
      tags: json['tags'] != null 
          ? List<String>.from(json['tags'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerInfo': customerInfo.toJson(),
      'items': items.map((item) => item.toJson()).toList(),
      'paymentMethod': paymentMethod,
      'notes': notes,
      'tags': tags,
    };
  }
}