import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedDummyDataForNouf() async {
  final parentId = 'ZsFEBFdCzigxQdrDkxjspIkuyW42';
  final parentRef = FirebaseFirestore.instance
      .collection('Parents')
      .doc(parentId);

  // Dummy child data
  final children = [
    {
      'firstName': 'Sara',
      'lastName': 'Ahmed',
      'email': 'sara@example.com',
      'phoneNumber': '966507115553',
      'avatar': '',
      'QR': '',
      'password': '',
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'firstName': 'Khalid',
      'lastName': 'Ahmed',
      'email': 'khalid@example.com',
      'phoneNumber': '966501234567',
      'avatar': '',
      'QR': '',
      'password': '',
      'createdAt': FieldValue.serverTimestamp(),
    },
  ];

  // Dummy task data for each child
  final tasks = [
    {
      'taskName': 'Do homework',
      'allowance': 20,
      'priority': 'High',
      'status': 'completed',
      'image': '',
      'completedImagePath':
          '/data/user/0/com.example.haseela_app/files/homework.jpg',
      'dueDate': DateTime.now().add(Duration(days: 2)),
      'completedDate': DateTime.now(),
      'createdAt': FieldValue.serverTimestamp(),
      'assignedBy': parentRef.path,
    },
    {
      'taskName': 'Clean your room',
      'allowance': 15,
      'priority': 'Normal',
      'status': 'new',
      'image': '',
      'dueDate': DateTime.now().add(Duration(days: 3)),
      'createdAt': FieldValue.serverTimestamp(),
      'assignedBy': parentRef.path,
    },
  ];

  for (final child in children) {
    // Add child to Firestore under Parents/{parentId}/Children
    final childDoc = await parentRef.collection('Children').add(child);

    // Add dummy tasks inside this child's Tasks subcollection
    for (final task in tasks) {
      await childDoc.collection('Tasks').add(task);
    }

    print('✅ Added child ${child['firstName']} with tasks.');
  }

  print('🎉 Dummy data seeded successfully for $parentId');
}
