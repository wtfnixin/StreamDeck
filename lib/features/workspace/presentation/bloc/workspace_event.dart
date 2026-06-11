import 'package:equatable/equatable.dart';
import '../../data/models/workspace_models.dart';

abstract class WorkspaceEvent extends Equatable {
  const WorkspaceEvent();

  @override
  List<Object?> get props => [];
}

class WorkspaceLoadList extends WorkspaceEvent {}

class WorkspaceExecute extends WorkspaceEvent {
  final String id;
  const WorkspaceExecute(this.id);

  @override
  List<Object?> get props => [id];
}

class WorkspaceRegister extends WorkspaceEvent {
  final WorkspaceModel workspace;
  const WorkspaceRegister(this.workspace);

  @override
  List<Object?> get props => [workspace];
}

class WorkspaceDelete extends WorkspaceEvent {
  final String id;
  const WorkspaceDelete(this.id);

  @override
  List<Object?> get props => [id];
}

class WorkspaceListUpdated extends WorkspaceEvent {
  final List<WorkspaceModel> workspaces;
  const WorkspaceListUpdated(this.workspaces);

  @override
  List<Object?> get props => [workspaces];
}
