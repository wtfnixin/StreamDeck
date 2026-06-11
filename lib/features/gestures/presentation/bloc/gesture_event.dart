import 'package:equatable/equatable.dart';

abstract class GestureEvent extends Equatable {
  const GestureEvent();

  @override
  List<Object?> get props => [];
}

class GestureTriggerEvent extends GestureEvent {
  final String gestureType;
  const GestureTriggerEvent(this.gestureType);

  @override
  List<Object?> get props => [gestureType];
}
