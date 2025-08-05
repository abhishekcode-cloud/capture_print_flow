import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:img_scanner/controller/logo_controller.dart';
import 'package:img_scanner/model/logo_model.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../controller/image_controller.dart';
import '../model/image_model.dart';
import 'image_preview_screen.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:math';

class GenerateScreen extends StatefulWidget {
  const GenerateScreen({super.key});

  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen> {
  final ImageController _controller = ImageController();
  final LogoController _ctrlLogo = LogoController();
  List<ImageModel> _images = [];
  LogoModel? _logo;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadImages();
    loadLogo();
  }

  void loadLogo() async {
    final logo = await _ctrlLogo.getLogo();
    setState(() => _logo = logo);
  }

  Future<void> _loadImages() async {
    final data = await _controller.getAllImages();
    setState(() => _images = data);
  }

  Future<String> saveImage(Uint8List imageBytes, String originalPath) async {
    final directory = await getApplicationDocumentsDirectory();

    // Optional: create a new filename based on original
    final filename = '${path.basenameWithoutExtension(originalPath)}_logo.png';

    final filePath = path.join(directory.path, filename);

    final file = File(filePath);
    await file.writeAsBytes(imageBytes);

    return filePath; // ✅ Return the saved file path
  }

  Future<void> _generateImage(int id, String imagePath) async {
    setState(() {
      _isLoading = true;
    });
    try {
      if (_logo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please upload a logo first")),
        );
        return;
      }

      // Load original image
      final originalImageData = await File(imagePath).readAsBytes();
      final originalCodec = await ui.instantiateImageCodec(originalImageData);
      final originalFrame = await originalCodec.getNextFrame();
      final ui.Image originalImage = originalFrame.image;

      // Load logo
      final logoFile = File(_logo!.path);
      final logoData = await logoFile.readAsBytes();
      final logoCodec = await ui.instantiateImageCodec(logoData);
      final logoFrame = await logoCodec.getNextFrame();
      final ui.Image logoImage = logoFrame.image;
      // Setup canvas
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint();
      // Define a padding value for the entire composition.
      const double padding = 25.0;

      final double canvasWidth = originalImage.width.toDouble();
      final double canvasHeight = originalImage.height.toDouble();
      // --- ENHANCED: Draw the logo as the background and the main image in a circle ---
      // Create a destination Rect for the logo that respects the padding.
      final Rect logoDstRect = Rect.fromLTWH(
        padding,
        padding,
        canvasWidth - (2 * padding),
        canvasHeight - (2 * padding),
      );
      // Draw the logo image to fill the entire canvas. This is the new background.
      // Draw the logo image to fill the padded area on the canvas.
      canvas.drawImageRect(
        logoImage,
        Rect.fromLTWH(
            0, 0, logoImage.width.toDouble(), logoImage.height.toDouble()),
        logoDstRect,
        paint,
      );
      // Define the size and position for the circular main image.
      // The circle size is calculated to fit within the padded area.
      final double circleDiameter =
          logoDstRect.width * 0.7; // Example: 60% of the padded area width
      final double centerX = logoDstRect.left + logoDstRect.width / 2;
      final double centerY = logoDstRect.top + logoDstRect.height / 2;

      // Define the destination rectangle for the main image circle.
      final Rect circularRect = Rect.fromCircle(
        center: Offset(centerX, centerY),
        radius: circleDiameter / 2,
      );
      // Create a circular path for clipping.
      final Path circularPath = Path()..addOval(circularRect);

      // Save the canvas state before clipping. This allows us to restore it later.
      canvas.save();

      // Clip the canvas to the circular path. All subsequent drawing will be
      // confined to this circular area.
      canvas.clipPath(circularPath);

      // Draw the main image, which will now be clipped to a circle.
      canvas.drawImageRect(
        originalImage,
        Rect.fromLTWH(0, 0, originalImage.width.toDouble(),
            originalImage.height.toDouble()),
        circularRect,
        paint,
      );

      // Restore the canvas to its original state, removing the clip.
      canvas.restore();
      // --- END OF ENHANCED SECTION ---
      // Final image from canvas
      final resultImage = await recorder
          .endRecording()
          .toImage(originalImage.width, originalImage.height);
      final byteData =
          await resultImage.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List finalImageBytes = byteData!.buffer.asUint8List();
      final savedPath = await saveImage(finalImageBytes, imagePath);
      await _controller.updateImage(
        ImageModel(id: id, path: savedPath, status: 'generated'),
      );
      await _loadImages();
      _isLoading = false;
      // Show preview or snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image generated successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error generating image: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  // Future<void> _generateImage(int id, String imagePath) async {
  //   setState(() {
  //     _isLoading = true;
  //   });
  //   try {
  //     if (_logo == null) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text("Please upload a logo first")),
  //       );
  //       return;
  //     }

  //     // Load original image
  //     final originalImageData = await File(imagePath).readAsBytes();
  //     final originalCodec = await ui.instantiateImageCodec(originalImageData);
  //     final originalFrame = await originalCodec.getNextFrame();
  //     final ui.Image originalImage = originalFrame.image;

  //     // Load logo
  //     final logoFile = File(_logo!.path);
  //     final logoData = await logoFile.readAsBytes();
  //     final logoCodec = await ui.instantiateImageCodec(logoData);
  //     final logoFrame = await logoCodec.getNextFrame();
  //     final ui.Image logoImage = logoFrame.image;
  //     // Setup canvas
  //     final recorder = ui.PictureRecorder();
  //     final canvas = Canvas(recorder);
  //     final paint = Paint();

  //     // Draw main image on the canvas
  //     canvas.drawImage(originalImage, Offset.zero, paint);

  //     // --- ENHANCED: Draw circular logo on the canvas ---
  //     const double logoSize = 80;
  //     const double padding = 10;

  //     // The user's image is assumed to be 400x400. We can calculate the position dynamically.
  //     final double dstX = originalImage.width - logoSize - padding;
  //     final double dstY = originalImage.height - logoSize - padding;

  //     // Define the destination rectangle for the logo.
  //     final Rect logoRect = Rect.fromLTWH(dstX, dstY, logoSize, logoSize);

  //     // Create a circular path for clipping.
  //     final Path circularPath = Path()..addOval(logoRect);

  //     // Save the canvas state before clipping. This allows us to restore it later.
  //     canvas.save();

  //     // Clip the canvas to the circular path. All subsequent drawing will be
  //     // confined to this circular area.
  //     canvas.clipPath(circularPath);

  //     // Draw the logo image, which will now be clipped to a circle.
  //     canvas.drawImageRect(
  //       logoImage,
  //       Rect.fromLTWH(
  //           0, 0, logoImage.width.toDouble(), logoImage.height.toDouble()),
  //       logoRect,
  //       paint,
  //     );
  //     // Restore the canvas to its original state, removing the clip.
  //     canvas.restore();
  //     // --- END OF ENHANCED SECTION ---
  //     // Final image from canvas
  //     final resultImage = await recorder
  //         .endRecording()
  //         .toImage(originalImage.width, originalImage.height);
  //     final byteData =
  //         await resultImage.toByteData(format: ui.ImageByteFormat.png);
  //     final Uint8List finalImageBytes = byteData!.buffer.asUint8List();
  //     final savedPath = await saveImage(finalImageBytes, imagePath);
  //     await _controller.updateImage(
  //       ImageModel(id: id, path: savedPath, status: 'generated'),
  //     );
  //     await _loadImages();
  //     _isLoading = false;
  //     // Show preview or snackbar
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("Image generated successfully")),
  //     );
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("Error generating image: $e")),
  //     );
  //   } finally {
  //     setState(() {
  //       _isLoading = false;
  //     });
  //   }
  // }

 Future<void> _printImage( String imagePath) async {
  try {
    // 1. Load the image
    Uint8List imageBytes;
    if (imagePath.startsWith('data:')) {
      final String base64String = imagePath.split(',').last;
      imageBytes = base64Decode(base64String);
    } else {
      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('File not found at path: $imagePath');
      }
      imageBytes = await file.readAsBytes();
    }

    // 2. Basic validation
    if (imageBytes.isEmpty) {
      throw Exception('Image bytes are empty');
    }

    // 3. Create PDF (simpler approach without image processing)
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Image(
              pw.MemoryImage(imageBytes),
              fit: pw.BoxFit.contain,
            ),
          );
        },
      ),
    );

    // 4. Print with error handling
    final result = await Printing.layoutPdf(
      onLayout: (_) => pdf.save(),
      name: 'Image_Print_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );

    if (!result) {
      throw Exception('Printing failed or was canceled');
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Printing error: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
    debugPrint('Printing error: $e');
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Generate List")),
      body: _images.isEmpty
          ? const Center(child: Text("No Images Found"))
          : ListView.builder(
              itemCount: _images.length,
              itemBuilder: (context, index) {
                final image = _images[index];
                final file = File(image.path);

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: 3,
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    leading: file.existsSync()
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              file,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(Icons.broken_image, size: 60),
                    title: Text(
                      image.path.split('/').last,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    trailing: image.status == 'generated'
                        ? IconButton(
                            icon: const Icon(Icons.print, color: Colors.black),
                            onPressed: () => _printImage(image.path),
                          )
                        : (_isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : IconButton(
                                icon: const Icon(Icons.rotate_right_sharp,
                                    color: Colors.blue),
                                onPressed: () =>
                                    _generateImage(image.id!, image.path),
                              )),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ImagePreviewScreen(imagePath: image.path),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
