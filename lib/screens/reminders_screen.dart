import 'package:flutter/material.dart';

class RemindersScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Reminders")),
      body: Center(
        child: Text("This is the Reminders screen", style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
