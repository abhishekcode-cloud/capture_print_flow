import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../model/logo_model.dart';
import '../controller/logo_controller.dart';
import 'image_preview_screen.dart'; // Make sure this import exists

class LogoUploadScreen extends StatefulWidget {
  const LogoUploadScreen({super.key});

  @override
  State<LogoUploadScreen> createState() => _LogoUploadScreenState();
}

class _LogoUploadScreenState extends State<LogoUploadScreen> {
  final LogoController _controller = LogoController();
  LogoModel? _logo;

  @override
  void initState() {
    super.initState();
    loadLogo();
  }

  void loadLogo() async {
    final logo = await _controller.getLogo();
    setState(() => _logo = logo);
  }

  void uploadLogo(ImageSource source) async {
    await _controller.uploadLogo(source);
    loadLogo();
  }

  void deleteLogo() async {
    if (_logo != null) {
      await _controller.deleteLogo(_logo!.id!);
      setState(() => _logo = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Logo Upload")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _logo == null
                ? const Text("No Logo Uploaded")
                : Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ImagePreviewScreen(imagePath: _logo!.path),
                            ),
                          );
                        },
                        child: SizedBox(
                          width: 350,
                          height: 350, // height = width makes it square only if width is fixed
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8), // optional
                            child: AspectRatio(
                              aspectRatio: 1, // Force square shape
                              child: Image.file(
                                File(_logo!.path),
                                fit: BoxFit.cover, // cover the square box
                              ),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: deleteLogo,
                      ),
                    ],
                  ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.photo),
              label: const Text("Upload from Gallery"),
              onPressed: () => uploadLogo(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }
}
