import 'package:cloud_firestore/cloud_firestore.dart';

class WishlistItem {
  final String id;
  final String name;
  final double price;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isCompleted;

  WishlistItem({
    required this.id,
    required this.name,
    required this.price,
    this.description = '',
    required this.createdAt,
    required this.updatedAt,
    this.isCompleted = false,
  });

  factory WishlistItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Handle different field name variations
    String name = data['name'] ?? data['itemName'] ?? '';
    double price = (data['price'] ?? data['itemPrice'] ?? 0.0).toDouble();
    String description = data['description'] ?? '';
    bool isCompleted = data['isCompleted'] ?? (data['statuss'] == 'completed') ?? false;
    
    // Handle timestamp fields - use createdAt if available, otherwise use current time
    DateTime createdAt;
    DateTime updatedAt;
    
    if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    } else {
      createdAt = DateTime.now();
    }
    
    if (data['updatedAt'] != null && data['updatedAt'] is Timestamp) {
      updatedAt = (data['updatedAt'] as Timestamp).toDate();
    } else {
      updatedAt = DateTime.now();
    }
    
    return WishlistItem(
      id: doc.id,
      name: name,
      price: price,
      description: description,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isCompleted: isCompleted,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'price': price,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isCompleted': isCompleted,
    };
  }

  WishlistItem copyWith({
    String? id,
    String? name,
    double? price,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isCompleted,
  }) {
    return WishlistItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
