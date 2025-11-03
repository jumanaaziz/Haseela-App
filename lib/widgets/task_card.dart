import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onDelete;
  final VoidCallback? onTapArrow;
  final VoidCallback? onEdit;

  const TaskCard({
    super.key,
    required this.task,
    this.onDelete,
    this.onTapArrow,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    // Gold styling for challenge tasks
    final isChallenge = task.isChallenge;
    final cardColor = isChallenge 
        ? const Color(0xFFFFD700).withOpacity(0.1) // Light gold background
        : Colors.white;
    final borderColor = isChallenge
        ? Colors.amber.shade600 // Gold border
        : Colors.transparent;
    final borderWidth = isChallenge ? 2.0 : 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: isChallenge
                ? Colors.amber.withOpacity(0.2) // Gold shadow
                : Colors.black.withOpacity(0.08),
            blurRadius: 20.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Challenge badge at top
            if (isChallenge)
              Container(
                margin: EdgeInsets.only(bottom: 12.h),
                padding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 6.h,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.shade600,
                      Colors.amber.shade800,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.workspace_premium,
                      color: Colors.white,
                      size: 16.sp,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'Challenge Task',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

            // Task title and optional icons
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.taskName,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: isChallenge 
                          ? Colors.amber.shade900 
                          : const Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                if (task.taskStatus == TaskStatus.pending && onTapArrow != null)
                  IconButton(
                    icon: Icon(
                      Icons.arrow_forward_ios,
                      color: const Color(0xFF6B7280),
                      size: 20.sp,
                    ),
                    onPressed: onTapArrow,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: 32.w,
                      minHeight: 32.h,
                    ),
                  ),
              ],
            ),

            SizedBox(height: 8.h),

            // Task description/subtitle
            Text(
              _getTaskSubtitle(),
              style: TextStyle(
                fontSize: 14.sp,
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),

            SizedBox(height: 16.h),

            // Task status and days remaining
            Row(
              children: [
                // Task status
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: _getStatusGradient(task.taskStatus),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    _getStatusText(task.taskStatus),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const Spacer(),

                // Days remaining
                Text(
                  _getDaysRemaining(),
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getTaskSubtitle() {
    if (task.dueDate != null) {
      return 'Due ${_formatDate(task.dueDate!)}';
    }
    return 'No due date';
  }

  String _getDaysRemaining() {
    if (task.dueDate != null) {
      final now = DateTime.now();
      final due = task.dueDate!;
      final difference = due.difference(now).inDays;

      if (difference < 0) {
        return 'Overdue';
      } else if (difference == 0) {
        return 'Due today';
      } else {
        return '$difference Days Left';
      }
    }
    return 'No deadline';
  }

  LinearGradient _getStatusGradient(TaskStatus status) {
    switch (status) {
      case TaskStatus.newTask:
        return const LinearGradient(
          colors: [
            Color(0xFF3B82F6),
            Color.fromARGB(255, 44, 116, 232),
          ], // Blue gradient
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        );
      case TaskStatus.pending:
        return const LinearGradient(
          colors: [
            Color(0xFFF59E0B),
            Color.fromARGB(255, 223, 144, 7),
          ], // Orange gradient
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        );
      case TaskStatus.done:
        return const LinearGradient(
          colors: [
            Color(0xFF10B981),
            Color.fromARGB(255, 8, 172, 118),
          ], // Green gradient
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        );
      case TaskStatus.rejected:
        return const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)], // Red gradient
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        );
    }
  }

  static String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

  static String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.newTask:
        return 'To-Do';
      case TaskStatus.pending:
        return 'Waiting Approval';
      case TaskStatus.done:
        return 'Completed';
      case TaskStatus.rejected:
        return 'Rejected';
    }
  }
}

