import 'package:equatable/equatable.dart';

abstract class ClipboardEvent extends Equatable {
  const ClipboardEvent();

  @override
  List<Object?> get props => [];
}

class ClipboardStartSync extends ClipboardEvent {}

class ClipboardStopSync extends ClipboardEvent {}

class ClipboardLocalChanged extends ClipboardEvent {
  final String content;
  const ClipboardLocalChanged(this.content);

  @override
  List<Object?> get props => [content];
}

class ClipboardRemoteReceived extends ClipboardEvent {
  final String content;
  const ClipboardRemoteReceived(this.content);

  @override
  List<Object?> get props => [content];
}

class ClipboardToggleSync extends ClipboardEvent {
  final bool enabled;
  const ClipboardToggleSync(this.enabled);

  @override
  List<Object?> get props => [enabled];
}
