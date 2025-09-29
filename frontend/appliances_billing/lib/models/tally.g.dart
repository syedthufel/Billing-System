// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tally.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TallySales _$TallySalesFromJson(Map<String, dynamic> json) => TallySales(
      total: (json['total'] as num).toDouble(),
      cash: (json['cash'] as num).toDouble(),
      card: (json['card'] as num).toDouble(),
      upi: (json['upi'] as num).toDouble(),
      other: (json['other'] as num).toDouble(),
    );

Map<String, dynamic> _$TallySalesToJson(TallySales instance) =>
    <String, dynamic>{
      'total': instance.total,
      'cash': instance.cash,
      'card': instance.card,
      'upi': instance.upi,
      'other': instance.other,
    };

TallyExpense _$TallyExpenseFromJson(Map<String, dynamic> json) => TallyExpense(
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      paymentMethod: json['paymentMethod'] as String,
    );

Map<String, dynamic> _$TallyExpenseToJson(TallyExpense instance) =>
    <String, dynamic>{
      'description': instance.description,
      'amount': instance.amount,
      'category': instance.category,
      'paymentMethod': instance.paymentMethod,
    };

Tally _$TallyFromJson(Map<String, dynamic> json) => Tally(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      sales: TallySales.fromJson(json['sales'] as Map<String, dynamic>),
      expenses: (json['expenses'] as List<dynamic>)
          .map((e) => TallyExpense.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalExpenses: (json['totalExpenses'] as num).toDouble(),
      netAmount: (json['netAmount'] as num).toDouble(),
      invoices: (json['invoices'] as List<dynamic>)
          .map((e) => Invoice.fromJson(e as Map<String, dynamic>))
          .toList(),
      remarks: json['remarks'] as String?,
      isClosed: json['isClosed'] as bool,
      closedAt: json['closedAt'] == null
          ? null
          : DateTime.parse(json['closedAt'] as String),
    );

Map<String, dynamic> _$TallyToJson(Tally instance) => <String, dynamic>{
      'id': instance.id,
      'date': instance.date.toIso8601String(),
      'sales': instance.sales.toJson(),
      'expenses': instance.expenses.map((e) => e.toJson()).toList(),
      'totalExpenses': instance.totalExpenses,
      'netAmount': instance.netAmount,
      'invoices': instance.invoices.map((e) => e.toJson()).toList(),
      'remarks': instance.remarks,
      'isClosed': instance.isClosed,
      'closedAt': instance.closedAt?.toIso8601String(),
    };
