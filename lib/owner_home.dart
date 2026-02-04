import 'package:flutter/material.dart';

class OwnerHome extends StatelessWidget {
  final String canteenName;

  const OwnerHome({super.key, required this.canteenName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("$canteenName Dashboard"),
      ),
      body: const Center(
        child: Text(
          "Manage Menu\nView Orders\nUpdate Status",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
