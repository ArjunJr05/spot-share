import 'package:equatable/equatable.dart';

sealed class BottomNavEvent extends Equatable {
  const BottomNavEvent();
}

class BottomNavIndexChanged extends BottomNavEvent {
  final int newIndex;

  const BottomNavIndexChanged(this.newIndex);

  @override
  List<Object> get props => [newIndex];
}