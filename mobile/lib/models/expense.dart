import 'package:json_annotation/json_annotation.dart';

part 'expense.g.dart';

@JsonSerializable()
class Expense {
  const Expense({
    required this.localId,
    required this.clientOperationId,
    required this.userId,
    required this.amount,
    required this.description,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.serverId,
    this.categoryId = 'general',
    this.lastSyncedAt,
    this.receiptPhotoPath,
    this.latitude,
    this.longitude,
  });

  @JsonKey(defaultValue: '')
  final String localId;
  @JsonKey(name: 'server_id')
  final int? serverId;
  @JsonKey(name: 'client_operation_id')
  final String clientOperationId;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'category_id')
  final String categoryId;
  final double amount;
  final String description;
  @JsonKey(name: 'date')
  final DateTime date;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @JsonKey(defaultValue: 'pending')
  final String syncStatus;
  @JsonKey(name: 'last_synced_at')
  final DateTime? lastSyncedAt;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? receiptPhotoPath;
  final double? latitude;
  final double? longitude;

  bool get isPending => syncStatus == 'pending' || syncStatus == 'failed';
  bool get hasReceiptPhoto => receiptPhotoPath != null;
  bool get hasLocation => latitude != null && longitude != null;

  factory Expense.fromJson(Map<String, dynamic> json) => _$ExpenseFromJson(json);
  Map<String, dynamic> toJson() => _$ExpenseToJson(this);

  Map<String, Object?> toMap() => {
        'local_id': localId,
        'server_id': serverId,
        'client_operation_id': clientOperationId,
        'user_id': userId,
        'category_id': categoryId,
        'amount': amount,
        'description': description,
        'expense_date': date.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'sync_status': syncStatus,
        'last_synced_at': lastSyncedAt?.toIso8601String(),
        'receipt_photo_path': receiptPhotoPath,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory Expense.fromMap(Map<String, Object?> map) => Expense(
        localId: map['local_id']! as String,
        serverId: map['server_id'] as int?,
        clientOperationId: map['client_operation_id']! as String,
        userId: map['user_id']! as String,
        categoryId: (map['category_id'] as String?) ?? 'general',
        amount: (map['amount'] as num).toDouble(),
        description: (map['description'] as String?) ?? '',
        date: DateTime.parse(map['expense_date']! as String),
        createdAt: DateTime.parse(map['created_at']! as String),
        updatedAt: DateTime.parse(map['updated_at']! as String),
        syncStatus: map['sync_status']! as String,
        lastSyncedAt: map['last_synced_at'] == null
            ? null
            : DateTime.parse(map['last_synced_at']! as String),
        receiptPhotoPath: map['receipt_photo_path'] as String?,
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
      );

  Map<String, Object?> toApiPayload() => {
        'client_operation_id': clientOperationId,
        'user_id': userId,
        'category_id': categoryId,
        'amount': amount,
        'description': description,
        'date': date.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };
}