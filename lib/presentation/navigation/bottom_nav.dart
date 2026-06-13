import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/floating_bottom_nav.dart';

class BottomNavBar extends StatefulWidget {
  final Widget child;
  final String location;

  const BottomNavBar({super.key, required this.child, required this.location});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = _getSelectedIndex(widget.location);
  }

  @override
  void didUpdateWidget(BottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) {
      setState(() {
        _selectedIndex = _getSelectedIndex(widget.location);
      });
    }
  }

  int _getSelectedIndex(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/courses')) return 1;
    if (location.startsWith('/live')) return 2;
    if (location.startsWith('/tests')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    final routes = ['/home', '/courses', '/live', '/tests', '/profile'];
    context.go(routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allows body to extend behind the floating nav bar
      body: widget.child,
      bottomNavigationBar: SafeArea(
        child: FloatingBottomNav(
          selectedIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
