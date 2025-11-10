import 'package:flutter/material.dart';
import 'login_page.dart';

void main() {
  runApp(const WarehouseManagementApp());
}

class WarehouseManagementApp extends StatelessWidget {
  const WarehouseManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'System Zarządzania Magazynem',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Magazynowy'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warehouse, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'Witaj w systemie zarządzania magazynem!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Przejdź do logowania'),
            ),
          ],
        ),
      ),
    );
  }
}