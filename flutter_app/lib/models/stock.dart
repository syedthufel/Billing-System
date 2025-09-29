class StockMovement {
  final String type; // 'in', 'out', 'adjustment'
  final int quantity;
  final String reason;
  final String? reference;
  final String performedBy;
  final DateTime timestamp;

  StockMovement({
    required this.type,
    required this.quantity,
    required this.reason,
    this.reference,
    required this.performedBy,
    required this.timestamp,
  });

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    return StockMovement(
      type: json['type'] ?? 'in',
      quantity: json['quantity'] ?? 0,
      reason: json['reason'] ?? '',
      reference: json['reference'],
      performedBy: json['performedBy'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class StockLocation {
  final String warehouse;
  final String section;
  final String shelf;

  StockLocation({
    required this.warehouse,
    required this.section,
    required this.shelf,
  });

  factory StockLocation.fromJson(Map<String, dynamic> json) {
    return StockLocation(
      warehouse: json['warehouse'] ?? 'Main',
      section: json['section'] ?? 'A',
      shelf: json['shelf'] ?? '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'warehouse': warehouse,
      'section': section,
      'shelf': shelf,
    };
  }

  @override
  String toString() => '$warehouse-$section-$shelf';
}

class Stock {
  final String id;
  final String productId;
  final int currentStock;
  final int minimumStock;
  final int maximumStock;
  final int reorderLevel;
  final StockLocation location;
  final List<StockMovement> movements;
  final DateTime lastUpdated;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Stock({
    required this.id,
    required this.productId,
    required this.currentStock,
    required this.minimumStock,
    required this.maximumStock,
    required this.reorderLevel,
    required this.location,
    required this.movements,
    required this.lastUpdated,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      id: json['_id'] ?? '',
      productId: json['product'] ?? '',
      currentStock: json['currentStock'] ?? 0,
      minimumStock: json['minimumStock'] ?? 10,
      maximumStock: json['maximumStock'] ?? 1000,
      reorderLevel: json['reorderLevel'] ?? 20,
      location: StockLocation.fromJson(json['location']),
      movements: (json['movements'] as List? ?? [])
          .map((movement) => StockMovement.fromJson(movement))
          .toList(),
      lastUpdated: DateTime.parse(json['lastUpdated']),
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'currentStock': currentStock,
      'minimumStock': minimumStock,
      'maximumStock': maximumStock,
      'reorderLevel': reorderLevel,
      'location': location.toJson(),
    };
  }

  String get stockStatus {
    if (currentStock <= 0) return 'out-of-stock';
    if (currentStock <= reorderLevel) return 'low-stock';
    if (currentStock <= minimumStock) return 'minimum-reached';
    if (currentStock >= maximumStock) return 'overstock';
    return 'in-stock';
  }

  bool get isLowStock => currentStock <= reorderLevel;
  bool get isOutOfStock => currentStock <= 0;
  bool get needsReorder => currentStock <= minimumStock;
}