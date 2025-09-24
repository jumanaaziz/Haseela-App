import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'task_model.dart'; // <-- Task, TaskPriority, TaskStatus
import 'models/child_options.dart'; // <-- ChildOption model

class AssignTaskScreen extends StatefulWidget {
  const AssignTaskScreen({super.key});

  @override
  State<AssignTaskScreen> createState() => _AssignTaskScreenState();
}

class _AssignTaskScreenState extends State<AssignTaskScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _allowanceController = TextEditingController();

  DateTime? _toDate;
  String? _selectedChildId;
  TaskPriority? _priority;

  List<ChildOption> _children = [];
  bool _loadingChildren = false;

  // Validation state
  String? _formError;
  String? _nameError;
  String? _childError;
  String? _dateError;
  String? _priorityError;
  String? _allowanceError;

  @override
  void initState() {
    super.initState();
    _fetchChildren();
  }

  Future<void> _fetchChildren() async {
    setState(() => _loadingChildren = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection("Parents")
          .doc("parent001")
          .collection("Children")
          .get();

      setState(() {
        _children = snap.docs
            .map((doc) => ChildOption.fromFirestore(doc.id, doc.data()))
            .toList();
      });
    } catch (e) {
      _showError("Error loading children: $e");
    } finally {
      setState(() => _loadingChildren = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _allowanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF0FDF4), // Very pale mint green
            Color(0xFFFEFCE8), // Very pale yellow
            Color(0xFFF0F9FF), // Very pale blue
            Color(0xFFFDF2F8), // Very pale pink/peach
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close, color: Colors.black87, size: 22.sp),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          centerTitle: true,
          title: Text(
            'Assign Task',
            style: TextStyle(
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w700,
              fontSize: 16.sp,
            ),
          ),
        ),
        body: SafeArea(
          child: _loadingChildren
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_formError != null)
                        Container(
                          width: double.infinity,
                          margin: EdgeInsets.only(bottom: 16.h),
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFFF6A5D)),
                            borderRadius: BorderRadius.circular(8.r),
                            color: const Color(0xFFFFEBEA),
                          ),
                          child: Text(
                            _formError!,
                            style: TextStyle(
                              color: const Color(0xFFB91C1C),
                              fontWeight: FontWeight.w600,
                              fontSize: 13.sp,
                            ),
                          ),
                        ),

                      const _SectionLabel('Name'),
                      SizedBox(height: 8.h),
                      _buildTextField(
                        controller: _nameController,
                        hintText: 'Task name',
                        errorText: _nameError,
                        maxLength: 40,
                        inputFormatters: [LengthLimitingTextInputFormatter(40)],
                      ),
                      SizedBox(height: 20.h),

                      const _SectionLabel('Add Child'),
                      SizedBox(height: 12.h),
                      _ChildSelector(
                        children: _children,
                        selectedChildId: _selectedChildId,
                        onSelected: (id) =>
                            setState(() => _selectedChildId = id),
                      ),
                      if (_childError != null)
                        Padding(
                          padding: EdgeInsets.only(top: 8.h),
                          child: Text(
                            _childError!,
                            style: TextStyle(
                              color: const Color(0xFFB91C1C),
                              fontSize: 12.sp,
                            ),
                          ),
                        ),

                      SizedBox(height: 20.h),
                      const _SectionLabel('Due Date'),
                      SizedBox(height: 12.h),
                      _DateBox(
                        label: _toDate == null
                            ? 'End date'
                            : _formatDate(_toDate!),
                        iconColor: const Color(0xFF7C3AED),
                        onTap: () async {
                          final picked = await _pickDate(
                            context,
                            initial: _toDate,
                          );
                          if (picked != null) {
                            setState(() => _toDate = picked);
                          }
                        },
                      ),
                      if (_dateError != null)
                        Padding(
                          padding: EdgeInsets.only(top: 8.h),
                          child: Text(
                            _dateError!,
                            style: TextStyle(
                              color: const Color(0xFFB91C1C),
                              fontSize: 12.sp,
                            ),
                          ),
                        ),

                      SizedBox(height: 20.h),
                      const _SectionLabel('Priority'),
                      SizedBox(height: 12.h),
                      Wrap(
                        spacing: 12.w,
                        children: TaskPriority.values.map((p) {
                          final selected = _priority == p;
                          return ChoiceChip(
                            selected: selected,
                            onSelected: (_) => setState(() => _priority = p),
                            label: Text(
                              _priorityText(p),
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? const Color(0xFF7C3AED)
                                    : Colors.black87,
                              ),
                            ),
                            selectedColor: const Color(
                              0xFF7C3AED,
                            ).withOpacity(0.15),
                            backgroundColor: const Color(0xFFF3F4F6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              side: BorderSide(
                                color: selected
                                    ? const Color(0xFF7C3AED)
                                    : const Color(0xFFE5E7EB),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (_priorityError != null)
                        Padding(
                          padding: EdgeInsets.only(top: 8.h),
                          child: Text(
                            _priorityError!,
                            style: TextStyle(
                              color: const Color(0xFFB91C1C),
                              fontSize: 12.sp,
                            ),
                          ),
                        ),

                      SizedBox(height: 20.h),
                      const _SectionLabel('Allowance'),
                      SizedBox(height: 8.h),
                      _buildTextField(
                        controller: _allowanceController,
                        hintText: '0.00',
                        keyboardType: TextInputType.number,
                        prefix: const _RiyalPrefix(),
                        errorText: _allowanceError,
                      ),

                      SizedBox(height: 24.h),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                          ),
                          onPressed: _handleSubmit,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Create', style: TextStyle(fontSize: 14.sp)),
                              SizedBox(width: 8.w),
                              Icon(Icons.arrow_forward, size: 18.sp),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  void _handleSubmit() {
    // Reset errors
    setState(() {
      _formError = null;
      _nameError = null;
      _childError = null;
      _dateError = null;
      _priorityError = null;
      _allowanceError = null;
    });

    final trimmedName = _nameController.text.trim();
    if (trimmedName.isEmpty) {
      _nameError = 'Please enter a task name';
    } else if (trimmedName.length > 40) {
      _nameError = 'Task name must be at most 40 characters';
    }

    if (_selectedChildId == null) {
      _childError = 'Please select a child';
    }
    if (_toDate == null) {
      _dateError = 'Please select an end date';
    }
    if (_priority == null) {
      _priorityError = 'Please choose a priority';
    }

    final allowanceText = _allowanceController.text.trim();
    if (allowanceText.isEmpty) {
      _allowanceError = 'Please enter an allowance amount';
    } else if (double.tryParse(allowanceText) == null) {
      _allowanceError = 'Allowance must be a valid number';
    }

    final hasErrors = [
      _nameError,
      _childError,
      _dateError,
      _priorityError,
      _allowanceError,
    ].any((e) => e != null);

    if (hasErrors) {
      setState(() {
        _formError = 'Please fix the highlighted fields and try again.';
      });
      return;
    }

    // Create task
    final child = _children.firstWhere((c) => c.id == _selectedChildId!);
    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: trimmedName,
      deadline: _toDate!,
      priority: _priority!,
      status: TaskStatus.incomplete,
      assignedTo: child.firstName,
    );

    Navigator.pop(context, task);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF6A5D),
      ),
    );
  }

  Future<DateTime?> _pickDate(BuildContext context, {DateTime? initial}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            // Prevent oversized text scaling
            textScaler: const TextScaler.linear(0.9),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 400, // you can also use 400.w with screenutil
                maxHeight: 600, // or 600.h
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: const Color(0xFF7C3AED), // Header background
                    onPrimary: Colors.white, // Header text
                    onSurface: const Color(0xFF111827), // Body text
                  ),
                  textButtonTheme: TextButtonThemeData(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF7C3AED), // Buttons
                    ),
                  ),
                  dialogTheme: DialogThemeData(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16), // ✅ correct
                    ),
                  ),
                ),
                child: child!,
              ),
            ),
          ),
        );
      },
    );
    return picked;
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  String _priorityText(TaskPriority p) {
    switch (p) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.normal:
        return 'Normal';
      case TaskPriority.high:
        return 'High';
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    Widget? prefix,
    String? errorText,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      style: TextStyle(fontSize: 14.sp),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(fontSize: 13.sp),
        prefixIcon: prefix,
        filled: true,
        fillColor: Colors.white,
        errorText: errorText,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFF7C3AED)),
        ),
      ),
    );
  }
}

/* ---------- Child Selector ---------- */

class _ChildSelector extends StatelessWidget {
  final List<ChildOption> children;
  final String? selectedChildId;
  final ValueChanged<String> onSelected;

  const _ChildSelector({
    required this.children,
    required this.selectedChildId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: children.map((c) {
        final isSelected = c.id == selectedChildId;
        return ListTile(
          leading: CircleAvatar(
            radius: 20.r,
            backgroundImage: (c.avatar != null && c.avatar!.isNotEmpty)
                ? NetworkImage(c.avatar!)
                : null,
            child: (c.avatar == null || c.avatar!.isEmpty)
                ? Text(c.firstName[0], style: TextStyle(fontSize: 14.sp))
                : null,
          ),
          title: Text(c.firstName, style: TextStyle(fontSize: 14.sp)),
          trailing: isSelected
              ? Icon(Icons.check, color: const Color(0xFF7C3AED), size: 20.sp)
              : null,
          onTap: () => onSelected(c.id),
        );
      }).toList(),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF6B7280),
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  final String label;
  final Color iconColor;
  final VoidCallback onTap;

  const _DateBox({
    required this.label,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_clock, color: iconColor, size: 18.sp),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RiyalPrefix extends StatelessWidget {
  const _RiyalPrefix();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 12.w, right: 6.w),
      child: Text(
        '﷼',
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF6B7280),
        ),
      ),
    );
  }
}
