// child_main_wrapper.dart
import 'package:flutter/material.dart';
import 'child/child_home_screen.dart';
import 'child/child_task_view_screen.dart';
import '../../widgets/custom_bottom_nav.dart';

class ChildMainWrapper extends StatefulWidget {
  final String parentId;
  final String childId;
  const ChildMainWrapper({
    Key? key,
    required this.parentId,
    required this.childId,
  }) : super(key: key);

  @override
  State<ChildMainWrapper> createState() => _ChildMainWrapperState();
}

class _ChildMainWrapperState extends State<ChildMainWrapper> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Build screens outside the list so they get correct props
    final home = HomeScreen(
      parentId: widget.parentId,
      childId: widget.childId,
      // no bottom nav here!
    );
    final tasks = ChildTaskViewScreen(
      parentId: widget.parentId,
      childId: widget.childId,
      // no bottom nav here!
    );

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: [home, tasks]),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex, // 0 = Home, 1 = Tasks
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}
