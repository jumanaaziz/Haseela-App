import 'package:cloud_firestore/cloud_firestore.dart';

class Child {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String avatar;
  final String qr;
  final DocumentReference parent;

  Child({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.avatar,
    required this.qr,
    required this.parent,
  });

  factory Child.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Handle parent field - can be DocumentReference or String
    DocumentReference parentRef;
    if (data['parent'] is DocumentReference) {
      parentRef = data['parent'] as DocumentReference;
    } else if (data['parent'] is String) {
      final parentPath = data['parent'] as String;
      if (parentPath.isNotEmpty && parentPath.contains('/')) {
        try {
          parentRef = FirebaseFirestore.instance.doc(parentPath);
        } catch (e) {
          print('Invalid parent path: $parentPath, error: $e');
          parentRef = FirebaseFirestore.instance
              .collection('Parents')
              .doc('parent001');
        }
      } else {
        parentRef = FirebaseFirestore.instance
            .collection('Parents')
            .doc('parent001');
      }
    } else {
      parentRef = FirebaseFirestore.instance
          .collection('Parents')
          .doc('parent001');
    }

    return Child(
      id: doc.id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      avatar: data['avatar'] ?? '',
      qr: data['QR'] ?? '',
      parent: parentRef,
    );
  }

  String get fullName => '$firstName $lastName'.trim();
}
