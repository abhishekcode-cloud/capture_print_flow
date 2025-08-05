class LogoModel {
  final int? id;
  final String path;

  LogoModel({this.id, required this.path});

  Map<String, dynamic> toMap() {
    return {'id': id, 'path': path};
  }

  factory LogoModel.fromMap(Map<String, dynamic> map) {
    return LogoModel(id: map['id'], path: map['path']);
  }
}
