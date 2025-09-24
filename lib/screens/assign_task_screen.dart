import 'package:flutter/material.dart';

class AssignTaskScreen extends StatefulWidget {
  const AssignTaskScreen({super.key});

  @override
  State<AssignTaskScreen> createState() => _AssignTaskScreenState();
}

class _AssignTaskScreenState extends State<AssignTaskScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _allowanceController = TextEditingController();

  DateTime? _fromDate;
  DateTime? _toDate;
  String? _selectedChildId; // selected child from dropdown
  TaskPriority? _priority;

  final List<_Child> _children = const [
    _Child(id: '1', name: 'Nouf', avatarUrl: null, color: Color(0xFF0EA5E9)),
    _Child(id: '2', name: 'Hanin', avatarUrl: null, color: Color(0xFFF59E0B)),
    _Child(
      id: '3',
      name: 'Abdulrahman',
      avatarUrl: null,
      color: Color(0xFF10B981),
    ),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _allowanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
        title: const Text(
          'Assign Task',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel('Name'),
              const SizedBox(height: 8),
              _buildTextField(controller: _nameController, hintText: 'Text'),
              const SizedBox(height: 20),

              const _SectionLabel('Add Child'),
              const SizedBox(height: 12),
              _ChildSelector(
                children: _children,
                selectedChildId: _selectedChildId,
                onSelected: (id) => setState(() => _selectedChildId = id),
              ),

              const SizedBox(height: 20),
              const _SectionLabel('Due Date'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DateBox(
                      label: _fromDate == null
                          ? 'Select date'
                          : _formatDate(_fromDate!),
                      iconColor: const Color(0xFF7C3AED),
                      onTap: () async {
                        final picked = await _pickDate(
                          context,
                          initial: _fromDate,
                        );
                        if (picked != null) setState(() => _fromDate = picked);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _DateBox(
                      label: _toDate == null
                          ? 'Select date'
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
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const _SectionLabel('Priority'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: TaskPriority.values.map((p) {
                  final selected = _priority == p;
                  return ChoiceChip(
                    selected: selected,
                    onSelected: (_) => setState(() => _priority = p),
                    label: Text(_priorityText(p)),
                    selectedColor: const Color(0xFF7C3AED).withOpacity(0.15),
                    labelStyle: TextStyle(
                      color: selected
                          ? const Color(0xFF7C3AED)
                          : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: const Color(0xFFF3F4F6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: selected
                            ? const Color(0xFF7C3AED)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),
              const _SectionLabel('Allowance'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _allowanceController,
                hintText: '0.00',
                keyboardType: TextInputType.number,
                prefix: const _RiyalPrefix(),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    // Collect values, integrate later
                    Navigator.maybePop(context);
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Create'),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<DateTime?> _pickDate(BuildContext context, {DateTime? initial}) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
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
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: prefix,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF7C3AED)),
        ),
      ),
    );
  }
}

enum TaskPriority { low, normal, high }

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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock_clock, color: iconColor, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
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
      padding: const EdgeInsets.only(left: 12, right: 6),
      child: Text(
        '﷼',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }
}

class _Child {
  final String id;
  final String name;
  final String? avatarUrl;
  final Color color;

  const _Child({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.color,
  });
}

class _ChildSelector extends StatefulWidget {
  final List<_Child> children;
  final String? selectedChildId;
  final ValueChanged<String> onSelected;

  const _ChildSelector({
    required this.children,
    required this.selectedChildId,
    required this.onSelected,
  });

  @override
  State<_ChildSelector> createState() => _ChildSelectorState();
}

class _ChildSelectorState extends State<_ChildSelector> {
  bool _menuOpen = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Only a + button initially. On tap shows dropdown menu with avatars + names.
        _DashedCircleButton(
          onTap: () => setState(() => _menuOpen = !_menuOpen),
        ),
        const SizedBox(width: 8),
        if (_menuOpen)
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.children.map((c) {
                  return InkWell(
                    onTap: () {
                      widget.onSelected(c.id);
                      setState(() => _menuOpen = false);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: c.color.withOpacity(0.2),
                            child: Text(
                              c.name.substring(0, 1),
                              style: TextStyle(
                                color: c.color,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              c.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }
}

class _DashedCircleButton extends StatelessWidget {
  final VoidCallback onTap;
  const _DashedCircleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF7C3AED),
            width: 1.5,
            style: BorderStyle.solid, // Flutter has no dashed border built-in
          ),
        ),
        child: const Icon(Icons.add, color: Color(0xFF7C3AED)),
      ),
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
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF6B7280),
      ),
    );
  }
}
