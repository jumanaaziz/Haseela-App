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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'totalBalance': totalBalance,
      'spendingBalance': spendingBalance,
      'savingBalance': savingBalance,
      'savingGoal': savingGoal, // Updated to match your renamed database field
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Wallet.fromMap(Map<String, dynamic> map) {
    return Wallet(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      totalBalance: (map['totalBalance'] ?? 0.0).toDouble(),
      spendingBalance: (map['spendingBalance'] ?? 0.0).toDouble(),
      savingBalance: (map['savingBalance'] ?? 0.0).toDouble(),
      savingGoal: (map['savingGoal'] ?? 100.0)
          .toDouble(), // Updated to match your renamed database field
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        map['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
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

  // Helper method to check if saving goal is reached
  bool get isSavingGoalReached => savingBalance >= savingGoal;
}
