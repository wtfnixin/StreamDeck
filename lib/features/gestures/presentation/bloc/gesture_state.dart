import 'package:equatable/equatable.dart';

abstract class GestureState extends Equatable {
  const GestureState();

  @override
  List<Object?> get props => [];
}

class GestureInitial extends GestureState {}

class GestureTriggering extends GestureState {}

class GestureTriggerSuccess extends GestureState {
  final String gestureType;
  const GestureTriggerSuccess(this.gestureType);

  @override
  List<Object?> get props => [gestureType];
}

class GestureTriggerFailure extends GestureState {
  final String message;
  const GestureTriggerFailure(this.message);

  @override
  List<Object?> get props => [message];
}
