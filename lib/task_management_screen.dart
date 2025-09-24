import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toastification/toastification.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'task_model.dart';
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

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

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

  Future<void> _addTask(Task task) async {
    if (selectedUserId.isEmpty) return;

    final taskRef = FirebaseFirestore.instance
        .collection("Parents")
        .doc("parent001")
        .collection("Children")
        .doc(selectedUserId)
        .collection("Tasks")
        .doc(task.id);

    await taskRef.set({
      "taskName": task.title,
      "dueDate": task.deadline,
      "priority": task.priority.name,
      "status": task.status.name,
      "assignedBy": "parent001",
    });
  }

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
                    final task = await Navigator.push<Task>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AssignTaskScreen(),
                      ),
                    );
                    if (task != null) {
                      await _addTask(task);
                    }
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
            // Child filter row
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

            // Task List
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
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              "Error: ${snapshot.error}",
                              style: TextStyle(fontSize: 14.sp),
                            ),
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

                        final tasks = docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return Task(
                            id: doc.id,
                            title: data['taskName'] ?? '',
                            deadline: (data['dueDate'] != null)
                                ? (data['dueDate'] as Timestamp).toDate()
                                : DateTime.now(),
                            priority: TaskPriority.values.firstWhere(
                              (e) =>
                                  e.name.toLowerCase() ==
                                  (data['priority'] ?? 'normal').toLowerCase(),
                              orElse: () => TaskPriority.normal,
                            ),
                            status: TaskStatus.values.firstWhere(
                              (e) =>
                                  e.name.toLowerCase() ==
                                  (data['status'] ?? 'incomplete')
                                      .toLowerCase(),
                              orElse: () => TaskStatus.incomplete,
                            ),
                            assignedTo: data['assignedBy'] ?? '',
                          );
                        }).toList();

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
