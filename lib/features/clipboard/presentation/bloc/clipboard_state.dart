import 'package:equatable/equatable.dart';

abstract class ClipboardState extends Equatable {
  const ClipboardState();

  @override
  List<Object?> get props => [];
}

class ClipboardInitial extends ClipboardState {}

class ClipboardSyncing extends ClipboardState {
  final String? lastSyncedContent;
  final String? lastSyncSource; // 'local' or 'remote'

  const ClipboardSyncing({this.lastSyncedContent, this.lastSyncSource});

  @override
  List<Object?> get props => [lastSyncedContent, lastSyncSource];
}

class ClipboardSyncStopped extends ClipboardState {}
