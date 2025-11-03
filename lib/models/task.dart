import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// ✅ Status values for a task.
/// - `newTask`: When first assigned (child sees "new").
/// - `pending`: When child marks complete but waiting for parent approval.
/// - `done`: When parent approves / final state.
/// - `rejected`: When parent declines the task completion.
enum TaskStatus { newTask, pending, done, rejected }

/// ✅ Task Priority
enum TaskPriority { low, normal, high }

class Task {
  final String id;
  final String taskName;
  final double allowance;
  final String status; // kept as String in Firestore, normalized
  final String priority;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime? completedDate;
  final DocumentReference assignedBy;
  final IconData? categoryIcon;
  final Color? categoryColor;
  final String?
  completedImagePath; // URL of image uploaded by child when completing task
  final String? image; // 👈 add this
  final bool isChallenge; // Whether this task is a challenge task

  Task({
    required this.id,
    required this.taskName,
    required this.allowance,
    required this.status,
    required this.priority,
    this.dueDate,
    required this.createdAt,
    this.completedDate,
    required this.assignedBy,
    this.categoryIcon,
    this.categoryColor,
    this.completedImagePath,
    this.image,
    this.isChallenge = false,
  });

  /// 🔄 Convert Firestore document to Task object
  factory Task.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Handle assignedBy field - can be DocumentReference or String
    DocumentReference assignedByRef;
    if (data['assignedBy'] is DocumentReference) {
      assignedByRef = data['assignedBy'] as DocumentReference;
    } else if (data['assignedBy'] is String) {
      final assignedByPath = data['assignedBy'] as String;
      // Validate the path before creating DocumentReference
      if (assignedByPath.isNotEmpty && assignedByPath.contains('/')) {
        try {
          assignedByRef = FirebaseFirestore.instance.doc(assignedByPath);
        } catch (e) {
          print('Invalid assignedBy path: $assignedByPath, error: $e');
          assignedByRef = FirebaseFirestore.instance
              .collection('Parents')
              .doc('parent001');
        }
      } else {
        assignedByRef = FirebaseFirestore.instance
            .collection('Parents')
            .doc('parent001');
      }
    } else {
      assignedByRef = FirebaseFirestore.instance
          .collection('Parents')
          .doc('parent001');
    }

    return Task(
      id: doc.id,
      taskName: data['taskName'] ?? '',
      allowance: (data['allowance'] ?? 0).toDouble(),
      status: normalizeStatus(data['status']),
      priority: data['priority'] ?? 'medium',
      dueDate: data['dueDate'] != null
          ? (data['dueDate'] as Timestamp).toDate()
          : null,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      completedDate: data['completedDate'] != null
          ? (data['completedDate'] as Timestamp).toDate()
          : null,
      assignedBy: assignedByRef,
      completedImagePath: data['completedImagePath'],
      image: data['image'],
      isChallenge: data['isChallenge'] ?? false,
    );
  }

  /// 🔄 Normalize Firestore values into "new" / "pending" / "done" / "rejected"
  static String normalizeStatus(dynamic raw) {
    final value = (raw ?? '').toString().toLowerCase();
    switch (value) {
      case 'incomplete':
      case 'assigned':
      case 'new':
        return 'new';
      case 'pending':
      case 'complete': // legacy
      case 'completed': // legacy
        return 'pending';
      case 'done':
      case 'approved': // legacy
        return 'done';
      case 'rejected':
        return 'rejected';
      default:
        return 'new';
    }
  }

  /// 🖼 Add icon & color automatically depending on task name / priority
  Task withCategoryIcon() {
    IconData? icon;
    Color? color;

    String taskLower = taskName.toLowerCase();

    if (taskLower.contains('clean') ||
        taskLower.contains('room') ||
        taskLower.contains('house')) {
      icon = Icons.home;
      color = Colors.orange;
    } else if (taskLower.contains('homework') ||
        taskLower.contains('study') ||
        taskLower.contains('math')) {
      icon = Icons.calculate;
      color = Colors.blue;
    } else if (taskLower.contains('water') ||
        taskLower.contains('plant') ||
        taskLower.contains('garden')) {
      icon = Icons.local_florist;
      color = Colors.green;
    } else if (taskLower.contains('dish') ||
        taskLower.contains('kitchen') ||
        taskLower.contains('cook')) {
      icon = Icons.restaurant;
      color = Colors.purple;
    } else if (taskLower.contains('read') || taskLower.contains('book')) {
      icon = Icons.book;
      color = Colors.indigo;
    } else if (taskLower.contains('exercise') ||
        taskLower.contains('sport') ||
        taskLower.contains('run')) {
      icon = Icons.fitness_center;
      color = Colors.red;
    } else {
      // Default based on priority
      switch (priority.toLowerCase()) {
        case 'high':
          icon = Icons.priority_high;
          color = Colors.red;
          break;
        case 'medium':
          icon = Icons.task;
          color = Colors.orange;
          break;
        case 'low':
          icon = Icons.low_priority;
          color = Colors.green;
          break;
        default:
          icon = Icons.assignment;
          color = Colors.grey;
      }
    }

    return Task(
      id: id,
      taskName: taskName,
      allowance: allowance,
      status: status,
      priority: priority,
      dueDate: dueDate,
      createdAt: createdAt,
      completedDate: completedDate,
      assignedBy: assignedBy,
      categoryIcon: icon,
      categoryColor: color,
      completedImagePath: completedImagePath,
      image: image,
      isChallenge: isChallenge,
    );
  }

  /// 🔄 Convert status string → enum
  TaskStatus get taskStatus {
    switch (status.toLowerCase()) {
      case 'new':
        return TaskStatus.newTask;
      case 'pending':
        return TaskStatus.pending;
      case 'done':
        return TaskStatus.done;
      case 'rejected':
        return TaskStatus.rejected;
      default:
        return TaskStatus.newTask;
    }
  }
}

