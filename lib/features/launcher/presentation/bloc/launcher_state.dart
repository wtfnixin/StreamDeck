import 'package:equatable/equatable.dart';
import '../../data/models/launcher_models.dart';

abstract class LauncherState extends Equatable {
  const LauncherState();
  
  @override
  List<Object?> get props => [];
}

class LauncherInitial extends LauncherState {}

class LauncherLoading extends LauncherState {}

class LauncherAppsLoaded extends LauncherState {
  final List<AppModel> apps;
  const LauncherAppsLoaded(this.apps);

  @override
  List<Object?> get props => [apps];
}

class LauncherWebsitesLoaded extends LauncherState {
  final List<WebsiteModel> websites;
  const LauncherWebsitesLoaded(this.websites);

  @override
  List<Object?> get props => [websites];
}

class LauncherFailure extends LauncherState {
  final String message;
  const LauncherFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class LauncherLaunchSuccess extends LauncherState {}
