import 'package:json_annotation/json_annotation.dart';
import 'invoice.dart';

part 'tally.g.dart';

@JsonSerializable()
class TallySales {
  final double total;
  final double cash;
  final double card;
  final double upi;
  final double other;

  TallySales({
    required this.total,
    required this.cash,
    required this.card,
    required this.upi,
    required this.other,
  });

  factory TallySales.fromJson(Map<String, dynamic> json) =>
      _$TallySalesFromJson(json);
  Map<String, dynamic> toJson() => _$TallySalesToJson(this);
}

@JsonSerializable()
class TallyExpense {
  final String description;
  final double amount;
  final String category;
  final String paymentMethod;

  TallyExpense({
    required this.description,
    required this.amount,
    required this.category,
    required this.paymentMethod,
  });

  factory TallyExpense.fromJson(Map<String, dynamic> json) =>
      _$TallyExpenseFromJson(json);
  Map<String, dynamic> toJson() => _$TallyExpenseToJson(this);
}

@JsonSerializable()
class Tally {
  final String id;
  final DateTime date;
  final TallySales sales;
  final List<TallyExpense> expenses;
  final double totalExpenses;
  final double netAmount;
  final List<Invoice> invoices;
  final String? remarks;
  final bool isClosed;
  final DateTime? closedAt;

  Tally({
    required this.id,
    required this.date,
    required this.sales,
    required this.expenses,
    required this.totalExpenses,
    required this.netAmount,
    required this.invoices,
    this.remarks,
    required this.isClosed,
    this.closedAt,
  });

  factory Tally.fromJson(Map<String, dynamic> json) => _$TallyFromJson(json);
  Map<String, dynamic> toJson() => _$TallyToJson(this);

  // Helper methods
  String get formattedDate {
    return '${date.day}/${date.month}/${date.year}';
  }

  Map<String, double> get expensesByCategory {
    final result = <String, double>{};
    for (final expense in expenses) {
      result[expense.category] =
          (result[expense.category] ?? 0) + expense.amount;
    }
    return result;
  }

  Map<String, double> get expensesByPaymentMethod {
    final result = <String, double>{};
    for (final expense in expenses) {
      result[expense.paymentMethod] =
          (result[expense.paymentMethod] ?? 0) + expense.amount;
    }
    return result;
  }
}