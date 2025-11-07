import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChildNotificationsScreen extends StatelessWidget {
  final String parentId;
  final String childId;
  const ChildNotificationsScreen({super.key, required this.parentId, required this.childId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('Parents')
            .doc(parentId)
            .collection('Children')
            .doc(childId)
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No notifications yet'));
          }
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final n = docs[i].data();
              final title = (n['title'] ?? 'Notification').toString();
              final body = (n['body'] ?? '').toString();
              final read = (n['read'] ?? false) == true;
              return ListTile(
                leading: Icon(
                  read ? Icons.notifications : Icons.notifications_active,
                  color: read ? Colors.grey : Colors.blue,
                ),
                title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(body, maxLines: 2, overflow: TextOverflow.ellipsis),
                onTap: () async {
                  await docs[i].reference.update({'read': true});
                },
              );
            },
          );
        },
      ),
    );
  }
}


