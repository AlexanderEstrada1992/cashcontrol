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
  });

  final String localId;
  final int? serverId;
  final String clientOperationId;
  final String userId;
  final String categoryId;
  final double amount;
  final String description;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String syncStatus;
  final DateTime? lastSyncedAt;

  bool get isPending => syncStatus == 'pending' || syncStatus == 'failed';

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
      );

  Map<String, Object?> toApiPayload() => {
        'client_operation_id': clientOperationId,
        'user_id': userId,
        'category_id': categoryId,
        'amount': amount,
        'description': description,
        'date': date.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}