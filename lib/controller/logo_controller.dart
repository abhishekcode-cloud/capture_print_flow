import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:img_scanner/model/db_helper.dart';
import 'package:img_scanner/model/logo_model.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class LogoController {
  final DBHelper _dbHelper = DBHelper();

  Future<LogoModel?> uploadLogo(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked != null) {
      final dir = await getApplicationDocumentsDirectory();
      final newPath = join(dir.path, picked.name);
      final newImage = await File(picked.path).copy(newPath);
      final logo = LogoModel(path: newImage.path);
      await _dbHelper.insertLogo(logo);
      return logo;
    }
    return null;
  }

  Future<LogoModel?> getLogo() => _dbHelper.getLogo();



  Future<void> deleteLogo(int id) => _dbHelper.deleteLogo(id);
}
