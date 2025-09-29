class Product {
  final String id;
  final String name;
  final String brand;
  final String model;
  final String category;
  final String description;
  final double basePrice;
  final double gstRate;
  final double sellingPrice;
  final double costPrice;
  final String sku;
  final String? barcode;
  final int warranty;
  final Map<String, String>? specifications;
  final bool isActive;
  final List<String>? images;
  final List<String>? tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.model,
    required this.category,
    required this.description,
    required this.basePrice,
    required this.gstRate,
    required this.sellingPrice,
    required this.costPrice,
    required this.sku,
    this.barcode,
    required this.warranty,
    this.specifications,
    required this.isActive,
    this.images,
    this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      category: json['category'] ?? 'other',
      description: json['description'] ?? '',
      basePrice: (json['basePrice'] ?? 0).toDouble(),
      gstRate: (json['gstRate'] ?? 18).toDouble(),
      sellingPrice: (json['sellingPrice'] ?? 0).toDouble(),
      costPrice: (json['costPrice'] ?? 0).toDouble(),
      sku: json['sku'] ?? '',
      barcode: json['barcode'],
      warranty: json['warranty'] ?? 12,
      specifications: json['specifications'] != null 
          ? Map<String, String>.from(json['specifications'])
          : null,
      isActive: json['isActive'] ?? true,
      images: json['images'] != null 
          ? List<String>.from(json['images'])
          : null,
      tags: json['tags'] != null 
          ? List<String>.from(json['tags'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'brand': brand,
      'model': model,
      'category': category,
      'description': description,
      'basePrice': basePrice,
      'gstRate': gstRate,
      'sellingPrice': sellingPrice,
      'costPrice': costPrice,
      'sku': sku,
      'barcode': barcode,
      'warranty': warranty,
      'specifications': specifications,
      'isActive': isActive,
      'images': images,
      'tags': tags,
    };
  }

  double get priceWithGST => basePrice + (basePrice * gstRate / 100);
  double get gstAmount => basePrice * gstRate / 100;

  Product copyWith({
    String? name,
    String? brand,
    String? model,
    String? category,
    String? description,
    double? basePrice,
    double? gstRate,
    double? sellingPrice,
    double? costPrice,
    String? sku,
    String? barcode,
    int? warranty,
    Map<String, String>? specifications,
    bool? isActive,
    List<String>? images,
    List<String>? tags,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      category: category ?? this.category,
      description: description ?? this.description,
      basePrice: basePrice ?? this.basePrice,
      gstRate: gstRate ?? this.gstRate,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      costPrice: costPrice ?? this.costPrice,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      warranty: warranty ?? this.warranty,
      specifications: specifications ?? this.specifications,
      isActive: isActive ?? this.isActive,
      images: images ?? this.images,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}