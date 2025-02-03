import 'package:flutter/material.dart';
import '../screens/dashboard_screen.dart';
import '../screens/reminders_screen.dart';
import '../screens/health_screen.dart';
import '../screens/connect_screen.dart';

class BottomNavBar extends StatefulWidget {
  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    DashboardScreen(),
    RemindersScreen(),
    HealthScreen(),
    ConnectScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Reminders"),
          BottomNavigationBarItem(icon: Icon(Icons.health_and_safety), label: "Health"),
          BottomNavigationBarItem(icon: Icon(Icons.connect_without_contact), label: "Connect"),
        ],
      ),
    );
  }
}
