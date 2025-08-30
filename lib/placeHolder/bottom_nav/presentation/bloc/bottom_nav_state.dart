import 'package:equatable/equatable.dart';

class ClientBottomNavState extends Equatable {
  final int currentIndex;

  const ClientBottomNavState({required this.currentIndex});

  @override
  List<Object> get props => [currentIndex];
}