// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Expense _$ExpenseFromJson(Map<String, dynamic> json) => Expense(
  localId: json['localId'] as String? ?? '',
  clientOperationId: json['client_operation_id'] as String,
  userId: json['user_id'] as String,
  amount: (json['amount'] as num).toDouble(),
  description: json['description'] as String,
  date: DateTime.parse(json['date'] as String),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  syncStatus: json['syncStatus'] as String? ?? 'pending',
  serverId: (json['server_id'] as num?)?.toInt(),
  categoryId: json['category_id'] as String? ?? 'general',
  lastSyncedAt: json['last_synced_at'] == null
      ? null
      : DateTime.parse(json['last_synced_at'] as String),
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
);

Map<String, dynamic> _$ExpenseToJson(Expense instance) => <String, dynamic>{
  'localId': instance.localId,
  'server_id': instance.serverId,
  'client_operation_id': instance.clientOperationId,
  'user_id': instance.userId,
  'category_id': instance.categoryId,
  'amount': instance.amount,
  'description': instance.description,
  'date': instance.date.toIso8601String(),
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'syncStatus': instance.syncStatus,
  'last_synced_at': instance.lastSyncedAt?.toIso8601String(),
  'latitude': instance.latitude,
  'longitude': instance.longitude,
};
