import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/services/database_service.dart';
import '../../../core/constants/app_constants.dart';
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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    
    if (uid == null) {
      return Scaffold(
        extendBody: true,
        body: widget.child,
        bottomNavigationBar: SafeArea(
          child: FloatingBottomNav(
            selectedIndex: _selectedIndex,
            onTap: _onItemTapped,
          ),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: DatabaseService().streamUser(uid),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null && data['isActive'] == false) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await FirebaseAuth.instance.signOut();
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove(StorageKeys.isLoggedIn);
              await prefs.remove(StorageKeys.userId);
              await prefs.remove(StorageKeys.profileComplete);
              if (context.mounted) {
                context.go('/blocked');
              }
            });
          }
        }

        return Scaffold(
          extendBody: true,
          body: widget.child,
          bottomNavigationBar: SafeArea(
            child: FloatingBottomNav(
              selectedIndex: _selectedIndex,
              onTap: _onItemTapped,
            ),
          ),
        );
      },
    );
  }
}
