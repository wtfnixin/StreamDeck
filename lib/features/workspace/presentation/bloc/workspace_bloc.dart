import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/socket_service.dart';
import '../../data/models/workspace_models.dart';
import 'workspace_event.dart';
import 'workspace_state.dart';

class WorkspaceBloc extends Bloc<WorkspaceEvent, WorkspaceState> {
  final SocketService _socketService;

  WorkspaceBloc(this._socketService) : super(WorkspaceInitial()) {
    on<WorkspaceLoadList>(_onLoadList);
    on<WorkspaceExecute>(_onExecute);
    on<WorkspaceRegister>(_onRegister);
    on<WorkspaceDelete>(_onDelete);
    on<WorkspaceListUpdated>(_onListUpdated);

    // Listen to broadcast updates from server
    _socketService.on('workspace:list:updated', (data) {
      if (data is Map && data['workspaces'] is List) {
        final list = (data['workspaces'] as List)
            .map((item) => WorkspaceModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
        add(WorkspaceListUpdated(list));
      }
    });
  }

  Future<void> _onLoadList(WorkspaceLoadList event, Emitter<WorkspaceState> emit) async {
    emit(WorkspaceLoading());
    final completer = Completer<WorkspaceState>();

    _socketService.emit('workspace:list', null, ack: (response) {
      if (response is Map && response['success'] == true && response['workspaces'] is List) {
        final list = (response['workspaces'] as List)
            .map((item) => WorkspaceModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
        completer.complete(WorkspaceListLoaded(list));
      } else {
        completer.complete(const WorkspaceFailure('Failed to load workspace list'));
      }
    });

    try {
      final state = await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => const WorkspaceFailure('Request timed out'),
      );
      emit(state);
    } catch (e) {
      emit(WorkspaceFailure(e.toString()));
    }
  }

  Future<void> _onExecute(WorkspaceExecute event, Emitter<WorkspaceState> emit) async {
    emit(WorkspaceExecutionInProgress());
    final completer = Completer<WorkspaceState>();

    _socketService.emit('workspace:execute', {'id': event.id}, ack: (response) {
      if (response is Map && response['success'] == true) {
        completer.complete(WorkspaceExecutionSuccess());
      } else {
        final error = response is Map ? response['error'] as String? : null;
        completer.complete(WorkspaceFailure(error ?? 'Failed to execute workspace profile'));
      }
    });

    try {
      final state = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => const WorkspaceFailure('Execution timed out'),
      );
      emit(state);
      
      // Reload list to ensure state stability after flow execution
      add(WorkspaceLoadList());
    } catch (e) {
      emit(WorkspaceFailure(e.toString()));
    }
  }

  Future<void> _onRegister(WorkspaceRegister event, Emitter<WorkspaceState> emit) async {
    emit(WorkspaceLoading());
    final completer = Completer<void>();

    _socketService.emit('workspace:register', event.workspace.toJson(), ack: (response) {
      completer.complete();
    });

    await completer.future;
    add(WorkspaceLoadList());
  }

  Future<void> _onDelete(WorkspaceDelete event, Emitter<WorkspaceState> emit) async {
    emit(WorkspaceLoading());
    final completer = Completer<void>();

    _socketService.emit('workspace:delete', {'id': event.id}, ack: (response) {
      completer.complete();
    });

    await completer.future;
    add(WorkspaceLoadList());
  }

  void _onListUpdated(WorkspaceListUpdated event, Emitter<WorkspaceState> emit) {
    emit(WorkspaceListLoaded(event.workspaces));
  }

  @override
  Future<void> close() {
    _socketService.off('workspace:list:updated');
    return super.close();
  }
}
