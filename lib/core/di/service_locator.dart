
import 'package:get_it/get_it.dart';
import 'package:spot_share2/features/users/bottom_nav/presentation/bloc/bottom_nav_bloc.dart';

final getIt = GetIt.instance;

void setUpServiceLocator() {
  // Bottom Bloc
  getIt.registerFactory<BottomNavBloc>(() => BottomNavBloc());
}
