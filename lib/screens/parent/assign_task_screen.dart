import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ use Auth UID
import '../../models/child.dart'; // (if used elsewhere)
import '../../models/task.dart';
import '../../models/child_options.dart';

class AssignTaskScreen extends StatefulWidget {
  const AssignTaskScreen({super.key});

  @override
  State<AssignTaskScreen> createState() => _AssignTaskScreenState();
}

class _AssignTaskScreenState extends State<AssignTaskScreen> {
  void _showError(String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFFF6A5D),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
  }

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

  // ✅ current parent UID
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

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
          .doc(_uid) // ✅ dynamic parent
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
      if (mounted) setState(() => _loadingChildren = false);
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
            Color(0xFFF0FDF4),
            Color(0xFFFEFCE8),
            Color(0xFFF0F9FF),
            Color(0xFFFDF2F8),
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
                          if (picked != null) setState(() => _toDate = picked);
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
                        prefix: const _RiyalSuffix(),
                        errorText: _allowanceError,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                          PositiveNumberFormatter(),
                        ],
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

  Future<void> _handleSubmit() async {
    // Reset validation errors
    setState(() {
      _formError = null;
      _nameError = null;
      _childError = null;
      _dateError = null;
      _priorityError = null;
      _allowanceError = null;
    });

    final trimmedName = _nameController.text.trim();
    if (trimmedName.isEmpty) _nameError = 'Please enter a task name';
    if (_selectedChildId == null) _childError = 'Please select a child';
    if (_toDate == null) _dateError = 'Please select an end date';
    if (_priority == null) _priorityError = 'Please choose a priority';

    final allowanceText = _allowanceController.text.trim();
    double? allowance;
    if (allowanceText.isEmpty) {
      _allowanceError = 'Please enter an allowance amount';
    } else {
      allowance = double.tryParse(allowanceText);
      if (allowance == null) {
        _allowanceError = 'Allowance must be a valid number';
      }
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

    try {
      final parentRef = FirebaseFirestore.instance
          .collection('Parents')
          .doc(_uid); // ✅

      // ✅ write directly under selected child
      final taskDoc = parentRef
          .collection('Children')
          .doc(_selectedChildId!)
          .collection('Tasks')
          .doc();

      final taskData = {
        'taskName': trimmedName,
        'allowance': allowance,
        'status': 'new', // matches your TaskStatus.newTask
        'priority': _priority.toString().split('.').last.toLowerCase(),
        'dueDate': _toDate != null ? Timestamp.fromDate(_toDate!) : null, // ✅
        'createdAt': FieldValue.serverTimestamp(),
        'assignedBy': parentRef, // DocumentReference
      };

      await taskDoc.set(taskData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task assigned successfully ✅')),
      );

      // Your TaskManagementScreen listens via StreamBuilder, so no need to return Task
      Navigator.pop(context);
    } catch (e) {
      _showError("Error assigning task: $e");
    }
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
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(0.9)),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
              child: Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFF7C3AED),
                    onPrimary: Colors.white,
                    onSurface: Color(0xFF111827),
                  ),
                  textButtonTheme: TextButtonThemeData(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF7C3AED),
                    ),
                  ),
                  dialogTheme: DialogThemeData(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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

class _RiyalSuffix extends StatelessWidget {
  const _RiyalSuffix();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 5.w),
      child: Image.asset(
        'assets/icons/riyal.png',
        width: 5.w,
        height: 5.w,
        fit: BoxFit.contain,
        color: const Color(0xFF6B7280),
      ),
    );
  }
}

class PositiveNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final value = double.tryParse(newValue.text);
    if (value == null || value < 0) {
      return oldValue;
    }
    return newValue;
  }
}
