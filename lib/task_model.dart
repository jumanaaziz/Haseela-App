// lib/task_model.dart
enum TaskPriority { low, normal, high }

enum TaskStatus { completed, incomplete }

class Task {
  final String id;
  final String title;
  final DateTime deadline;
  final TaskPriority priority;
  final TaskStatus status;
  final String assignedTo;

  Task({
    required this.id,
    required this.title,
    required this.deadline,
    required this.priority,
    required this.status,
    required this.assignedTo,
  });
}
