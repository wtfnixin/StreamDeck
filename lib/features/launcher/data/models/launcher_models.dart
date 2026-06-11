import 'package:equatable/equatable.dart';

class AppModel extends Equatable {
  final String id;
  final String name;
  final String? icon;
  final String executablePath;
  final String? category;

  const AppModel({
    required this.id,
    required this.name,
    this.icon,
    required this.executablePath,
    this.category,
  });

  factory AppModel.fromJson(Map<String, dynamic> json) {
    return AppModel(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String?,
      executablePath: json['executablePath'] as String? ?? json['executable_path'] as String? ?? '',
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'executablePath': executablePath,
      'category': category,
    };
  }

  @override
  List<Object?> get props => [id, name, icon, executablePath, category];
}

class WebsiteModel extends Equatable {
  final String id;
  final String name;
  final String url;
  final String? icon;

  const WebsiteModel({
    required this.id,
    required this.name,
    required this.url,
    this.icon,
  });

  factory WebsiteModel.fromJson(Map<String, dynamic> json) {
    return WebsiteModel(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String? ?? json['url_path'] as String? ?? '',
      icon: json['icon'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'icon': icon,
    };
  }

  @override
  List<Object?> get props => [id, name, url, icon];
}
