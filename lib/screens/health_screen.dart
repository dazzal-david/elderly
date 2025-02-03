import 'package:flutter/material.dart';

class HealthScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Health")),
      body: Center(
        child: Text("This is the Health screen", style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
