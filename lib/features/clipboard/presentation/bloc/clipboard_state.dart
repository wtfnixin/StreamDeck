import 'package:equatable/equatable.dart';

abstract class ClipboardState extends Equatable {
  const ClipboardState();

  @override
  List<Object?> get props => [];
}

class ClipboardInitial extends ClipboardState {}

class ClipboardSyncing extends ClipboardState {
  final String? lastPcContent;
  final String? lastPhoneContent;

  const ClipboardSyncing({this.lastPcContent, this.lastPhoneContent});

  @override
  List<Object?> get props => [lastPcContent, lastPhoneContent];
}

class ClipboardSyncStopped extends ClipboardState {}
