import 'package:cloud_firestore/cloud_firestore.dart';

class Wallet {
  final String id;
  final String userId;
  final double totalBalance;
  final double spendingBalance;
  final double savingBalance;
  final double savingGoal;
  final DateTime createdAt;
  final DateTime updatedAt;

  Wallet({
    required this.id,
    required this.userId,
    required this.totalBalance,
    required this.spendingBalance,
    required this.savingBalance,
    required this.savingGoal,
    required this.createdAt,
    required this.updatedAt,
  });

  // ✅ Convert Firestore document → Wallet object
  factory Wallet.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return Wallet(
      id: snapshot.id,
      userId: data['userId'] ?? '',
      totalBalance: (data['totalBalance'] ?? 0.0).toDouble(),
      spendingBalance: (data['spendingBalance'] ?? 0.0).toDouble(),
      savingBalance: (data['savingBalance'] ?? 0.0).toDouble(),
      savingGoal: (data['savingGoal'] ?? 100.0).toDouble(),
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: (data['updatedAt'] is Timestamp)
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  // ✅ Convert Wallet object → Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'totalBalance': totalBalance,
      'spendingBalance': spendingBalance,
      'savingBalance': savingBalance,
      'savingGoal': savingGoal,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'totalBalance': totalBalance,
      'spendingBalance': spendingBalance,
      'savingBalance': savingBalance,
      'savingGoal': savingGoal,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Wallet.fromMap(Map<String, dynamic> map) {
    DateTime _parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return Wallet(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      totalBalance: (map['totalBalance'] ?? 0.0).toDouble(),
      spendingBalance: (map['spendingBalance'] ?? 0.0).toDouble(),
      savingBalance: (map['savingBalance'] ?? 0.0).toDouble(),
      savingGoal: (map['savingGoal'] ?? 100.0).toDouble(),
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  Wallet copyWith({
    String? id,
    String? userId,
    double? totalBalance,
    double? spendingBalance,
    double? savingBalance,
    double? savingGoal,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Wallet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      totalBalance: totalBalance ?? this.totalBalance,
      spendingBalance: spendingBalance ?? this.spendingBalance,
      savingBalance: savingBalance ?? this.savingBalance,
      savingGoal: savingGoal ?? this.savingGoal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isSavingGoalReached => savingBalance >= savingGoal;
}
