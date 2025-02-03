import 'package:flutter/material.dart';

class ConnectScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Connect")),
      body: Center(
        child: Text("This is the Connect screen", style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
