

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spot_share2/features/users/bottom_nav/presentation/bloc/bottom_nav_event.dart';
import 'package:spot_share2/features/users/bottom_nav/presentation/bloc/bottom_nav_state.dart';

// Bottom Nav Bloc Implementation
class BottomNavBloc extends Bloc<BottomNavEvent, BottomNavState> {
  BottomNavBloc() : super(const BottomNavState(currentIndex: 0)) {
    on<BottomNavIndexChanged>((event, emit) {
      emit(BottomNavState(currentIndex: event.newIndex));
    });
  }
}