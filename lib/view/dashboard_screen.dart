import 'package:flutter/material.dart';
import 'package:img_scanner/view/generate_screen.dart';
import 'package:img_scanner/view/home_screen.dart';
import 'package:img_scanner/view/logo_upload_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> menuItems = [
      {'icon': Icons.image, 'label': 'Logo Upload'},
      {'icon': Icons.camera, 'label': 'Capture Img'},
      {'icon': Icons.download, 'label': 'Generate'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: menuItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          ),
          itemBuilder: (context, index) {
            final item = menuItems[index];
            return GestureDetector(
              onTap: () {
                if (item['label'] == 'Capture Img') {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HomeScreen()));
                } else if (item['label'] == 'Logo Upload') {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LogoUploadScreen()));
                } else if (item['label'] == 'Generate') {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const GenerateScreen()));
                }
                // Add more conditions here
              },
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item['icon'], size: 40, color: Colors.blue),
                    const SizedBox(height: 8),
                    Text(
                      item['label'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
