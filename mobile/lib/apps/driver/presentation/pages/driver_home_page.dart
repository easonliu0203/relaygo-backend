import 'package:flutter/material.dart';

class DriverHomePage extends StatelessWidget {
  const DriverHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('司機端'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_taxi, size: 64, color: Color(0xFF4CAF50)),
            SizedBox(height: 16),
            Text('司機端首頁開發中...', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
