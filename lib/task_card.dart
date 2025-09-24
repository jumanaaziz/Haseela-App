import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../task_model.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onDelete;

  const TaskCard({super.key, required this.task, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 16.w,
                    runSpacing: 8.h,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16.sp,
                            color: const Color(0xFF7C3AED),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Deadline ${_formatDate(task.deadline)}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: const Color(0xFF7C3AED),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.flag,
                            size: 16.sp,
                            color: _getPriorityColor(task.priority),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Priority ${_getPriorityText(task.priority)}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: _getPriorityColor(task.priority),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Status + optional delete button
            Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: task.status == TaskStatus.completed
                        ? Colors.green
                        : Colors.red,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Text(
                    task.status == TaskStatus.completed
                        ? 'Completed'
                        : 'Incomplete',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (onDelete != null) ...[
                  SizedBox(height: 8.h),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red, size: 20.sp),
                    onPressed: onDelete,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

  static Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.orange[300]!;
      case TaskPriority.normal:
        return Colors.orange[500]!;
      case TaskPriority.high:
        return Colors.orange[700]!;
    }
  }

  static String _getPriorityText(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.normal:
        return 'Normal';
      case TaskPriority.high:
        return 'High';
    }
  }
}
