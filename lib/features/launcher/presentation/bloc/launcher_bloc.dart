import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/socket_service.dart';
import '../../data/models/launcher_models.dart';
import 'launcher_event.dart';
import 'launcher_state.dart';

class LauncherBloc extends Bloc<LauncherEvent, LauncherState> {
  final SocketService _socketService;

  LauncherBloc(this._socketService) : super(LauncherInitial()) {
    on<LauncherLoadApps>(_onLoadApps);
    on<LauncherLoadWebsites>(_onLoadWebsites);
    on<LauncherLaunchApp>(_onLaunchApp);
    on<LauncherLaunchWebsite>(_onLaunchWebsite);
    on<LauncherAddApp>(_onAddApp);
    on<LauncherAddWebsite>(_onAddWebsite);
    on<LauncherDeleteApp>(_onDeleteApp);
    on<LauncherDeleteWebsite>(_onDeleteWebsite);
    on<LauncherAppsUpdated>(_onAppsUpdated);
    on<LauncherWebsitesUpdated>(_onWebsitesUpdated);

    // Listen to broadcast updates from server
    _socketService.on('launcher:apps:updated', (data) {
      if (data is Map && data['apps'] is List) {
        final appsList = (data['apps'] as List)
            .map((item) => AppModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
        add(LauncherAppsUpdated(appsList));
      }
    });

    _socketService.on('launcher:websites:updated', (data) {
      if (data is Map && data['websites'] is List) {
        final websList = (data['websites'] as List)
            .map((item) => WebsiteModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
        add(LauncherWebsitesUpdated(websList));
      }
    });
  }

  Future<void> _onLoadApps(LauncherLoadApps event, Emitter<LauncherState> emit) async {
    emit(LauncherLoading());
    final completer = Completer<LauncherState>();

    _socketService.emit('launcher:apps', null, ack: (response) {
      if (response is Map && response['success'] == true && response['apps'] is List) {
        final appsList = (response['apps'] as List)
            .map((item) => AppModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
        completer.complete(LauncherAppsLoaded(appsList));
      } else {
        completer.complete(const LauncherFailure('Failed to load apps from agent'));
      }
    });

    try {
      final state = await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => const LauncherFailure('Request timed out'),
      );
      emit(state);
    } catch (e) {
      emit(LauncherFailure(e.toString()));
    }
  }

  Future<void> _onLoadWebsites(LauncherLoadWebsites event, Emitter<LauncherState> emit) async {
    emit(LauncherLoading());
    final completer = Completer<LauncherState>();

    _socketService.emit('launcher:websites', null, ack: (response) {
      if (response is Map && response['success'] == true && response['websites'] is List) {
        final websList = (response['websites'] as List)
            .map((item) => WebsiteModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
        completer.complete(LauncherWebsitesLoaded(websList));
      } else {
        completer.complete(const LauncherFailure('Failed to load websites from agent'));
      }
    });

    try {
      final state = await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => const LauncherFailure('Request timed out'),
      );
      emit(state);
    } catch (e) {
      emit(LauncherFailure(e.toString()));
    }
  }

  void _onAppsUpdated(LauncherAppsUpdated event, Emitter<LauncherState> emit) {
    emit(LauncherAppsLoaded(event.apps));
  }

  void _onWebsitesUpdated(LauncherWebsitesUpdated event, Emitter<LauncherState> emit) {
    emit(LauncherWebsitesLoaded(event.websites));
  }

  Future<void> _onLaunchApp(LauncherLaunchApp event, Emitter<LauncherState> emit) async {
    _socketService.emit('launcher:launch-app', {'id': event.id});
  }

  Future<void> _onLaunchWebsite(LauncherLaunchWebsite event, Emitter<LauncherState> emit) async {
    _socketService.emit('launcher:launch-website', {'id': event.id});
  }

  Future<void> _onAddApp(LauncherAddApp event, Emitter<LauncherState> emit) async {
    emit(LauncherLoading());
    final completer = Completer<void>();
    _socketService.emit('launcher:register-app', {
      'name': event.name,
      'executablePath': event.executablePath,
      'icon': event.icon,
      'category': event.category,
    }, ack: (response) {
      completer.complete();
    });
    await completer.future;
    add(LauncherLoadApps());
  }

  Future<void> _onAddWebsite(LauncherAddWebsite event, Emitter<LauncherState> emit) async {
    emit(LauncherLoading());
    final completer = Completer<void>();
    _socketService.emit('launcher:register-website', {
      'name': event.name,
      'url': event.url,
      'icon': event.icon,
    }, ack: (response) {
      completer.complete();
    });
    await completer.future;
    add(LauncherLoadWebsites());
  }

  Future<void> _onDeleteApp(LauncherDeleteApp event, Emitter<LauncherState> emit) async {
    emit(LauncherLoading());
    final completer = Completer<void>();
    _socketService.emit('launcher:delete-app', {'id': event.id}, ack: (response) {
      completer.complete();
    });
    await completer.future;
    add(LauncherLoadApps());
  }

  Future<void> _onDeleteWebsite(LauncherDeleteWebsite event, Emitter<LauncherState> emit) async {
    emit(LauncherLoading());
    final completer = Completer<void>();
    _socketService.emit('launcher:delete-website', {'id': event.id}, ack: (response) {
      completer.complete();
    });
    await completer.future;
    add(LauncherLoadWebsites());
  }

  @override
  Future<void> close() {
    _socketService.off('launcher:apps:updated');
    _socketService.off('launcher:websites:updated');
    return super.close();
  }
}
