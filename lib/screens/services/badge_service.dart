import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/badge.dart';
import '../../models/wallet.dart';
import 'firebase_service.dart';

// test
class BadgeService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _badgeCollection(
    String parentId,
    String childId,
  ) {
    return _db
        .collection('Parents')
        .doc(parentId)
        .collection('Children')
        .doc(childId)
        .collection('Badges');
  }

  static Map<BadgeType, Badge> get _defaultBadges {
    final defaults = Badge.getDefaultBadges();
    return {for (final badge in defaults) badge.type: badge};
  }

  static String _badgeDocId(BadgeType type) {
    return _defaultBadges[type]?.id ?? type.toString().split('.').last;
  }

  static Future<void> _ensureBadgeDocuments(
    String parentId,
    String childId,
  ) async {
    final collection = _badgeCollection(parentId, childId);
    final snapshot = await collection.get();

    final existingIds = snapshot.docs.map((doc) => doc.id).toSet();

    for (final badge in _defaultBadges.values) {
      if (!existingIds.contains(badge.id)) {
        await collection.doc(badge.id).set(badge.toFirestore());
      } else {
        // Ensure existing badges have correct imageAsset path
        final existingDoc = snapshot.docs.firstWhere(
          (doc) => doc.id == badge.id,
        );
        final data = existingDoc.data();
        final currentImageAsset = data['imageAsset'] as String? ?? '';
        // Update if missing, empty, or has wrong path (badge vs badges)
        if (currentImageAsset.isEmpty ||
            currentImageAsset.contains('/badge/') ||
            currentImageAsset != badge.imageAsset) {
          await collection.doc(badge.id).update({
            'imageAsset': badge.imageAsset,
          });
        }
      }
    }
  }

  static Future<void> _unlockBadge(
    String parentId,
    String childId,
    BadgeType type,
  ) async {
    await _ensureBadgeDocuments(parentId, childId);

    final collection = _badgeCollection(parentId, childId);
    final docRef = collection.doc(_badgeDocId(type));
    final snapshot = await docRef.get();

    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      if (data['isUnlocked'] == true) {
        return;
      }
    }

    final defaultBadge = _defaultBadges[type];

    await docRef.set({
      'type': defaultBadge?.type.toString().split('.').last,
      'name': defaultBadge?.name,
      'description': defaultBadge?.description,
      'imageAsset': defaultBadge?.imageAsset,
      'isUnlocked': true,
      'unlockedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  static Future<void> checkAllBadges(String parentId, String childId) async {
    await Future.wait([
      _checkTenaciousTaskmaster(parentId, childId),
      _checkFinancialFreedomFlyer(parentId, childId),
    ]);
  }

  static Future<void> _checkTenaciousTaskmaster(
    String parentId,
    String childId,
  ) async {
    try {
      final tasksSnapshot = await _db
          .collection('Parents')
          .doc(parentId)
          .collection('Children')
          .doc(childId)
          .collection('Tasks')
          .get();

      final completedCount = tasksSnapshot.docs.where((doc) {
        final data = doc.data();
        final status = (data['status'] ?? '').toString().toLowerCase();
        return status == 'done';
      }).length;

      if (completedCount >= 10) {
        await _unlockBadge(parentId, childId, BadgeType.tenaciousTaskmaster);
      }
    } catch (e) {
      print('Error checking Tenacious Taskmaster badge: $e');
    }
  }

  static Future<void> _checkFinancialFreedomFlyer(
    String parentId,
    String childId,
  ) async {
    try {
      final Wallet? wallet = await FirebaseService.getChildWallet(
        parentId,
        childId,
      );

      final savingBalance = wallet?.savingBalance ?? 0;

      if (savingBalance >= 100) {
        await _unlockBadge(parentId, childId, BadgeType.financialFreedomFlyer);
      }
    } catch (e) {
      print('Error checking Financial Freedom Flyer badge: $e');
    }
  }

  static Future<void> checkConquerorsCrown(
    String parentId,
    String childId,
  ) async {
    try {
      await _unlockBadge(parentId, childId, BadgeType.conquerorsCrown);
    } catch (e) {
      print('Error unlocking Conqueror\'s Crown badge: $e');
    }
  }

  static Future<List<Badge>> getChildBadges(
    String parentId,
    String childId,
  ) async {
    await _ensureBadgeDocuments(parentId, childId);

    final collection = _badgeCollection(parentId, childId);
    final snapshot = await collection.get();

    return snapshot.docs.map((doc) => Badge.fromFirestore(doc)).toList()
      ..sort((a, b) => a.type.index.compareTo(b.type.index));
  }
}
