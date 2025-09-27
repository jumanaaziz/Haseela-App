import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toastification/toastification.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'models/task.dart';
import 'assign_task_screen.dart';
import 'models/child_options.dart';
import 'task_card.dart';
import 'widgets/custom_bottom_nav.dart';

class TaskManagementScreen extends StatefulWidget {
  const TaskManagementScreen({super.key});

  @override
  State<TaskManagementScreen> createState() => _TaskManagementScreenState();
}

class _TaskManagementScreenState extends State<TaskManagementScreen> {
  String selectedUserId = '';
  List<ChildOption> _children = [];
  int _currentIndex = 1;
  String selectedStatusFilter = 'All'; // Default to show all tasks

  // Available status filter options
  final List<String> _statusFilterOptions = [
    'All',
    'New',
    'Pending',
    'Approved',
  ];

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  /// ✅ Load children for parent
  Future<void> _loadChildren() async {
    final snap = await FirebaseFirestore.instance
        .collection("Parents")
        .doc("parent001")
        .collection("Children")
        .get();

    setState(() {
      _children = snap.docs
          .map((doc) => ChildOption.fromFirestore(doc.id, doc.data()))
          .where((c) => c.firstName.trim().isNotEmpty)
          .toList();

      if (_children.isNotEmpty) {
        selectedUserId = _children.first.id;
      }
    });
  }

  /// ✅ Delete task
  Future<void> _deleteTask(String taskId) async {
    await FirebaseFirestore.instance
        .collection("Parents")
        .doc("parent001")
        .collection("Children")
        .doc(selectedUserId)
        .collection("Tasks")
        .doc(taskId)
        .delete();
  }

  /// ✅ Confirm delete dialog
  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete task?', style: TextStyle(fontSize: 16.sp)),
          content: Text(
            'Are you sure you want to delete this task?',
            style: TextStyle(fontSize: 14.sp),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: TextStyle(fontSize: 14.sp)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text('Delete', style: TextStyle(fontSize: 14.sp)),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  /// ✅ Filter tasks based on selected status
  List<Task> _filterTasksByStatus(List<Task> tasks) {
    if (selectedStatusFilter == 'All') {
      return tasks;
    }

    return tasks.where((task) {
      switch (selectedStatusFilter) {
        case 'New':
          return task.taskStatus == TaskStatus.newTask;
        case 'Pending':
          return task.taskStatus == TaskStatus.pending;
        case 'Approved':
          return task.taskStatus == TaskStatus.done;
        default:
          return true;
      }
    }).toList();
  }

  /// ✅ Get color for status indicator in dropdown
  Color _getStatusColor(String status) {
    switch (status) {
      case 'All':
        return Colors.grey[400]!;
      case 'New':
        return Colors.blue;
      case 'Pending':
        return Colors.orange;
      case 'Approved':
        return Colors.green;
      default:
        return Colors.grey[400]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: SafeArea(
          bottom: false,
          child: Row(
            children: [
              Padding(padding: EdgeInsets.only(left: 16.w)),
              const Spacer(),
              Text(
                'Tasks',
                style: TextStyle(
                  color: const Color(0xFF1A1A1A),
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                margin: EdgeInsets.only(right: 16.w),
                decoration: const BoxDecoration(
                  color: Color(0xFF7C3AED),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AssignTaskScreen(),
                      ),
                    );
                    // Task is already saved in AssignTaskScreen, StreamBuilder will auto-update
                  },
                  icon: Icon(Icons.add, color: Colors.white, size: 22.sp),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 👶 Child filter row
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _children.map((child) {
                    final isSelected = child.id == selectedUserId;
                    return Container(
                      margin: EdgeInsets.only(right: 8.w),
                      child: ElevatedButton(
                        onPressed: () {
                          print(
                            'Selected child: ${child.firstName} with ID: ${child.id}',
                          );
                          setState(() {
                            selectedUserId = child.id;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected
                              ? const Color(0xFF7C3AED)
                              : Colors.white,
                          foregroundColor: isSelected
                              ? Colors.white
                              : Colors.grey[600],
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFF7C3AED)
                                : Colors.grey[300]!,
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 8.h,
                          ),
                        ),
                        child: Text(
                          child.firstName,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // 🔍 Status Filter Button
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6), // Light purple background
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedStatusFilter,
                    isExpanded: true,
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: const Color(0xFF7C3AED),
                      size: 20.sp,
                    ),
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: const Color(0xFF7C3AED),
                      fontWeight: FontWeight.w600,
                    ),
                    selectedItemBuilder: (BuildContext context) {
                      return _statusFilterOptions.map((String status) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.filter_list,
                                color: const Color(0xFF7C3AED),
                                size: 16.sp,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'Filter',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF7C3AED),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList();
                    },
                    items: _statusFilterOptions.map((String status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.filter_list,
                                color: _getStatusColor(status),
                                size: 16.sp,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                status,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF374151),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedStatusFilter = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
            ),

            // 📋 Task List
            Expanded(
              child: selectedUserId.isEmpty
                  ? Center(
                      child: Text(
                        "No child selected",
                        style: TextStyle(fontSize: 14.sp),
                      ),
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection("Parents")
                          .doc("parent001")
                          .collection("Children")
                          .doc(selectedUserId)
                          .collection("Tasks")
                          .snapshots(),
                      builder: (context, snapshot) {
                        print(
                          'StreamBuilder - selectedUserId: $selectedUserId',
                        );
                        print(
                          'StreamBuilder - snapshot.hasError: ${snapshot.hasError}',
                        );
                        if (snapshot.hasError) {
                          print('StreamBuilder - Error: ${snapshot.error}');
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 48.sp,
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  'Error loading tasks: ${snapshot.error}',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.red,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return Center(
                            child: Text(
                              "No tasks yet.",
                              style: TextStyle(fontSize: 14.sp),
                            ),
                          );
                        }

                        final allTasks = docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;

                          // Debug: Print the actual data to see what's causing the issue
                          print('Task data for ${doc.id}: $data');

                          // Handle assignedBy field - can be DocumentReference or String
                          DocumentReference assignedByRef;
                          if (data['assignedBy'] is DocumentReference) {
                            assignedByRef =
                                data['assignedBy'] as DocumentReference;
                          } else if (data['assignedBy'] is String) {
                            final assignedByPath = data['assignedBy'] as String;
                            // Validate the path before creating DocumentReference
                            if (assignedByPath.isNotEmpty &&
                                assignedByPath.contains('/')) {
                              try {
                                assignedByRef = FirebaseFirestore.instance.doc(
                                  assignedByPath,
                                );
                              } catch (e) {
                                print(
                                  'Invalid assignedBy path: $assignedByPath, error: $e',
                                );
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
                            status: Task.normalizeStatus(data['status']),
                            priority: data['priority'] ?? 'normal',
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
                          );
                        }).toList();

                        // Apply status filter
                        final tasks = _filterTasksByStatus(allTasks);

                        // Show message if no tasks match the filter
                        if (tasks.isEmpty && allTasks.isNotEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.filter_list,
                                  color: Colors.grey[400],
                                  size: 48.sp,
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  'No tasks with "$selectedStatusFilter" status',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  'Try selecting a different filter',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                itemCount: tasks.length,
                                itemBuilder: (context, index) {
                                  final task = tasks[index];
                                  return Dismissible(
                                    key: Key(task.id),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      color: Colors.red,
                                      alignment: Alignment.centerRight,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 20.w,
                                      ),
                                      child: Icon(
                                        Icons.delete,
                                        color: Colors.white,
                                        size: 20.sp,
                                      ),
                                    ),
                                    confirmDismiss: (_) async {
                                      return await _confirmDelete(context);
                                    },
                                    onDismissed: (_) async {
                                      await _deleteTask(task.id);
                                      if (context.mounted) {
                                        toastification.show(
                                          context: context,
                                          type: ToastificationType.success,
                                          style:
                                              ToastificationStyle.flatColored,
                                          title: Text(
                                            'Task deleted',
                                            style: TextStyle(fontSize: 14.sp),
                                          ),
                                          autoCloseDuration: const Duration(
                                            seconds: 2,
                                          ),
                                        );
                                      }
                                    },
                                    child: TaskCard(task: task),
                                  );
                                },
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(16.w),
                              margin: EdgeInsets.symmetric(horizontal: 16.w),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF1F3),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                '💡 Swipe right on any task to delete it',
                                style: TextStyle(
                                  color: const Color(0xFF6B7280),
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}
