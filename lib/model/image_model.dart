class ImageModel {
  final int? id;
  final String path;
  final String status; // New field

  ImageModel({this.id, required this.path, required this.status});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'path': path,
      'status': status,
    };
  }

  factory ImageModel.fromMap(Map<String, dynamic> map) {
    return ImageModel(
      id: map['id'],
      path: map['path'],
      status: map['status'],
    );
  }
}
