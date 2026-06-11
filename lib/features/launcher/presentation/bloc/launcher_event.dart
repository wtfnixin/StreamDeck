import 'package:equatable/equatable.dart';
import '../../data/models/launcher_models.dart';

abstract class LauncherEvent extends Equatable {
  const LauncherEvent();

  @override
  List<Object?> get props => [];
}

class LauncherLoadApps extends LauncherEvent {}

class LauncherLoadWebsites extends LauncherEvent {}

class LauncherLaunchApp extends LauncherEvent {
  final String id;
  const LauncherLaunchApp(this.id);

  @override
  List<Object?> get props => [id];
}

class LauncherLaunchWebsite extends LauncherEvent {
  final String id;
  const LauncherLaunchWebsite(this.id);

  @override
  List<Object?> get props => [id];
}

class LauncherAddApp extends LauncherEvent {
  final String name;
  final String executablePath;
  final String? icon;
  final String? category;

  const LauncherAddApp({
    required this.name,
    required this.executablePath,
    this.icon,
    this.category,
  });

  @override
  List<Object?> get props => [name, executablePath, icon, category];
}

class LauncherAddWebsite extends LauncherEvent {
  final String name;
  final String url;
  final String? icon;

  const LauncherAddWebsite({
    required this.name,
    required this.url,
    this.icon,
  });

  @override
  List<Object?> get props => [name, url, icon];
}

class LauncherDeleteApp extends LauncherEvent {
  final String id;
  const LauncherDeleteApp(this.id);

  @override
  List<Object?> get props => [id];
}

class LauncherDeleteWebsite extends LauncherEvent {
  final String id;
  const LauncherDeleteWebsite(this.id);

  @override
  List<Object?> get props => [id];
}

class LauncherAppsUpdated extends LauncherEvent {
  final List<AppModel> apps;
  const LauncherAppsUpdated(this.apps);

  @override
  List<Object?> get props => [apps];
}

class LauncherWebsitesUpdated extends LauncherEvent {
  final List<WebsiteModel> websites;
  const LauncherWebsitesUpdated(this.websites);

  @override
  List<Object?> get props => [websites];
}
