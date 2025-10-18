class Transaction {
  final String id;
  final String userId;
  final String walletId;
  final String type; // 'transfer', 'spending', 'saving'
  final String category; // 'food', 'gaming', 'movies', etc.
  final double amount;
  final String description;
  final DateTime date;
  final String fromWallet; // 'total', 'spending', 'saving'
  final String toWallet; // 'total', 'spending', 'saving' (for transfers)

  Transaction({
    required this.id,
    required this.userId,
    required this.walletId,
    required this.type,
    required this.category,
    required this.amount,
    required this.description,
    required this.date,
    required this.fromWallet,
    required this.toWallet,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'walletId': walletId,
      'type': type,
      'category': category,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
      'fromWallet': fromWallet,
      'toWallet': toWallet,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      walletId: map['walletId'] ?? '',
      type: map['type'] ?? '',
      category: map['category'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      description: map['description'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      fromWallet: map['fromWallet'] ?? '',
      toWallet: map['toWallet'] ?? '',
    );
  }

  Transaction copyWith({
    String? id,
    String? userId,
    String? walletId,
    String? type,
    String? category,
    double? amount,
    String? description,
    DateTime? date,
    String? fromWallet,
    String? toWallet,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      walletId: walletId ?? this.walletId,
      type: type ?? this.type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
      fromWallet: fromWallet ?? this.fromWallet,
      toWallet: toWallet ?? this.toWallet,
    );
  }
}

