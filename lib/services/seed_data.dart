import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreSeeder {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> seedDummyData() async {
    const parentId = "parent001";

    // 1. Create Parent
    final parentRef = _db.collection("Parents").doc(parentId);
    await parentRef.set({
      "firstName": "Ahmed",
      "lastName": "Alotaibi",
      "email": "ahmed.parent@example.com",
      "createdAt": FieldValue.serverTimestamp(),
    });

    // 2. Children data
    final children = [
      {
        "id": "child001",
        "firstName": "Sara",
        "lastName": "Ahmed",
        "email": "sara@example.com",
      },
      {
        "id": "child002",
        "firstName": "Omar",
        "lastName": "Ahmed",
        "email": "omar@example.com",
      },
      {
        "id": "child003",
        "firstName": "Mona",
        "lastName": "Saleh",
        "email": "mona@example.com",
      },
    ];

    // 3. Loop children
    for (var child in children) {
      final childRef = parentRef.collection("Children").doc(child["id"]);

      await childRef.set({
        "firstName": child["firstName"],
        "lastName": child["lastName"],
        "email": child["email"],
        "QR": "",
        "avatar": "",
        "parent": parentRef.path,
        "password": "",
        "createdAt": FieldValue.serverTimestamp(),
      });

      // 4. Add two dummy tasks for each child
      await childRef.collection("Tasks").doc("task1").set({
        "taskName": "Do homework",
        "allowance": 20,
        "status": "pending",
        "priority": "High",
        "assignedBy": parentRef.path,
        "createdAt": FieldValue.serverTimestamp(),
        "dueDate": DateTime.now().add(const Duration(days: 2)),
      });

      await childRef.collection("Tasks").doc("task2").set({
        "taskName": "Clean room",
        "allowance": 10,
        "status": "completed",
        "priority": "Low",
        "assignedBy": parentRef.path,
        "createdAt": FieldValue.serverTimestamp(),
        "dueDate": DateTime.now().add(const Duration(days: 1)),
      });

      // 5. Add an extra task only for Omar
      if (child["id"] == "child002") {
        await childRef.collection("Tasks").doc("task3").set({
          "taskName": "Wash the dishes",
          "allowance": 15,
          "status": "pending",
          "priority": "Normal",
          "assignedBy": parentRef.path,
          "createdAt": FieldValue.serverTimestamp(),
          "dueDate": DateTime.now().add(const Duration(days: 3)),
        });
      }
    }

    print("✅ Dummy data seeded successfully!");
  }
}
