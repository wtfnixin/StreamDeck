import 'package:equatable/equatable.dart';
import '../../data/models/workspace_models.dart';

abstract class WorkspaceState extends Equatable {
  const WorkspaceState();

  @override
  List<Object?> get props => [];
}

class WorkspaceInitial extends WorkspaceState {}

class WorkspaceLoading extends WorkspaceState {}

class WorkspaceListLoaded extends WorkspaceState {
  final List<WorkspaceModel> workspaces;
  const WorkspaceListLoaded(this.workspaces);

  @override
  List<Object?> get props => [workspaces];
}

class WorkspaceFailure extends WorkspaceState {
  final String message;
  const WorkspaceFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class WorkspaceExecutionInProgress extends WorkspaceState {}

class WorkspaceExecutionSuccess extends WorkspaceState {}
