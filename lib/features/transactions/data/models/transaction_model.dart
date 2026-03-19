class TransactionModel {
  final int? id;
  final String? mongoId;
  final String accountId;
  final String? toAccountId; // Thêm biến này
  final String category;
  final String type;
  final double amount;
  final String note;
  final String date;
  final int isSynced;
  final String offlineId;

  TransactionModel({
    this.id, this.mongoId, required this.accountId, this.toAccountId, required this.category,
    required this.type, required this.amount, required this.note,
    required this.date, this.isSynced = 0, required this.offlineId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id, 'mongoId': mongoId, 'accountId': accountId, 'toAccountId': toAccountId,
      'category': category, 'type': type, 'amount': amount, 'note': note, 
      'date': date, 'isSynced': isSynced, 'offlineId': offlineId,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'], mongoId: map['mongoId'], accountId: map['accountId'],
      toAccountId: map['toAccountId'], category: map['category'], 
      type: map['type'], amount: (map['amount'] as num).toDouble(),
      note: map['note'], date: map['date'], 
      isSynced: map['isSynced'] ?? 0, offlineId: map['offlineId'],
    );
  }
}