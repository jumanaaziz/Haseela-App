import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/parent_profile.dart';

class ParentDataService {
  static const String parentId = 'parent001';

  static Future<void> initializeParentData() async {
    try {
      // Check if parent already exists
      final doc = await FirebaseFirestore.instance
          .collection("Parents")
          .doc(parentId)
          .get();

      if (!doc.exists) {
        // Create sample parent data
        final parentProfile = ParentProfile(
          id: parentId,
          firstName: 'John',
          lastName: 'Smith',
          username: 'johnsmith',
          email: 'john.smith@example.com',
          password: 'Password123!',
          phoneNumber: '0123456789',
          avatar: null,
        );

        await FirebaseFirestore.instance
            .collection("Parents")
            .doc(parentId)
            .set(parentProfile.toFirestore());

        print('Parent data initialized successfully');
      }
    } catch (e) {
      print('Error initializing parent data: $e');
    }
  }
}
