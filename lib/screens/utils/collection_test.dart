import 'package:cloud_firestore/cloud_firestore.dart';

/// Test utility to verify collection name logic
class CollectionTest {
  static void testCollectionNames() {
    print('=== COLLECTION NAME TEST ===');

    // Test Parent userType
    String userType1 = 'Parent';
    String collectionName1 = userType1 == 'Parent' ? 'Parents' : 'Children';
    print('UserType: $userType1 -> Collection: $collectionName1');

    // Test Children userType
    String userType2 = 'Children';
    String collectionName2 = userType2 == 'Parent' ? 'Parents' : 'Children';
    print('UserType: $userType2 -> Collection: $collectionName2');

    // Test case sensitivity
    String userType3 = 'parent';
    String collectionName3 = userType3 == 'Parent' ? 'Parents' : 'Children';
    print('UserType: $userType3 -> Collection: $collectionName3');

    // Test empty string
    String userType4 = '';
    String collectionName4 = userType4 == 'Parent' ? 'Parents' : 'Children';
    print('UserType: $userType4 -> Collection: $collectionName4');

    print('=== END TEST ===');
  }

  static Future<void> testFirestoreWrite() async {
    try {
      print('=== FIRESTORE WRITE TEST ===');

      // Test writing to Parents collection
      await FirebaseFirestore.instance
          .collection('Parents')
          .doc('test-parent')
          .set({'test': true, 'timestamp': FieldValue.serverTimestamp()});
      print('✅ Successfully wrote to Parents collection');

      // Test writing to Children collection
      await FirebaseFirestore.instance
          .collection('Children')
          .doc('test-child')
          .set({'test': true, 'timestamp': FieldValue.serverTimestamp()});
      print('✅ Successfully wrote to Children collection');

      // Clean up test documents
      await FirebaseFirestore.instance
          .collection('Parents')
          .doc('test-parent')
          .delete();
      await FirebaseFirestore.instance
          .collection('Children')
          .doc('test-child')
          .delete();
      print('✅ Cleaned up test documents');
    } catch (e) {
      print('❌ Firestore write test failed: $e');
    }
  }
}
