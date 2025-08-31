import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spot_share2/features/auth/services/driver_services.dart';
import 'package:spot_share2/features/auth/services/parking_services.dart';
import 'package:spot_share2/features/users/home/presentation/bloc/home_event.dart';
import 'package:spot_share2/features/users/home/presentation/bloc/home_state.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final DriverFirestoreService _driverService = DriverFirestoreService();
  final ParkingSessionService _parkingService = ParkingSessionService();
  StreamSubscription<DocumentSnapshot>? _driverDataSubscription;
  StreamSubscription<DocumentSnapshot?>? _parkingSessionSubscription;
  Timer? _parkingTimer;
  
  HomeBloc() : super(HomeInitial()) {
    on<LoadInitialDataEvent>(_onLoadInitialData);
    on<CycleVehicleEvent>(_onCycleVehicle);
    on<RequestPermissionEvent>(_onRequestPermission);
    on<LoadDriverDataEvent>(_onLoadDriverData);
    on<UpdateParkingStatusEvent>(_onUpdateParkingStatus);
  }

  @override
  Future<void> close() {
    _driverDataSubscription?.cancel();
    _parkingSessionSubscription?.cancel();
    _parkingTimer?.cancel();
    return super.close();
  }

  void _onLoadInitialData(
      LoadInitialDataEvent event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final availableVehicles = VehicleType.values;
      final status = await Permission.camera.status;
      
      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Load driver data and start listening for real-time updates
        add(LoadDriverDataEvent(driverUid: currentUser.uid));
        _startListeningToDriverData(currentUser.uid);
        _startListeningToParkingSession(currentUser.uid);
        _startParkingTimer(); // Start timer for real-time cost calculation
      }

      emit(HomeLoaded(
        currentVehicleIndex: 0,
        availableVehicles: availableVehicles,
        isPermissionGranted: status.isGranted,
        parkingData: DriverParkingData.empty(),
      ));
    } catch (e) {
      emit(HomeError('Failed to load initial data: ${e.toString()}'));
    }
  }

  void _onLoadDriverData(
      LoadDriverDataEvent event, Emitter<HomeState> emit) async {
    try {
      final driverDoc = await _driverService.getDriverData(event.driverUid);
      final driverStats = await _driverService.getDriverStats(event.driverUid);
      
      if (driverDoc != null && driverDoc.exists) {
        final driverData = driverDoc.data() as Map<String, dynamic>;
        
        // Check if currently parked using the parking session service
        final activeParkingSession = await _parkingService.getActiveParkingSession(event.driverUid);
        
        DriverParkingData parkingData;
        
        if (activeParkingSession != null && activeParkingSession.exists) {
          final sessionData = activeParkingSession.data() as Map<String, dynamic>;
          final startTime = (sessionData['startTime'] as Timestamp).toDate();
          final hourlyRate = (sessionData['hourlyRate'] as double? ?? 15.0);
          final duration = DateTime.now().difference(startTime);
          final hours = duration.inMinutes / 60.0;
          final currentCost = hours * hourlyRate;
          
          parkingData = DriverParkingData(
            isCurrentlyParked: true,
            currentLocation: sessionData['location'] ?? 'Unknown Location',
            parkedSince: startTime,
            currentCost: currentCost,
            totalRides: driverStats['totalRides'] ?? 0,
            totalSpent: (driverStats['totalSpent'] ?? 0.0).toDouble(),
            driverName: driverData['name'] ?? 'User',
            rating: (driverStats['rating'] ?? 0.0).toDouble(),
          );
        } else {
          parkingData = DriverParkingData(
            isCurrentlyParked: false,
            totalRides: driverStats['totalRides'] ?? 0,
            totalSpent: (driverStats['totalSpent'] ?? 0.0).toDouble(),
            driverName: driverData['name'] ?? 'User',
            rating: (driverStats['rating'] ?? 0.0).toDouble(),
            currentCost: 0.0,
          );
        }

        final currentState = state;
        if (currentState is HomeLoaded) {
          emit(currentState.copyWith(parkingData: parkingData));
        }
      }
    } catch (e) {
      print('Error loading driver data: $e');
    }
  }

  void _onCycleVehicle(
      CycleVehicleEvent event, Emitter<HomeState> emit) {
    final currentState = state;
    if (currentState is HomeLoaded) {
      int newIndex = currentState.currentVehicleIndex;
      if (event.isNext) {
        newIndex = (newIndex + 1) % currentState.availableVehicles.length;
      } else {
        newIndex = (newIndex - 1 + currentState.availableVehicles.length) %
            currentState.availableVehicles.length;
      }
      emit(currentState.copyWith(currentVehicleIndex: newIndex));
    }
  }

  void _onRequestPermission(
      RequestPermissionEvent event, Emitter<HomeState> emit) async {
    final currentState = state;
    if (currentState is HomeLoaded) {
      var status = await Permission.camera.request();
      emit(currentState.copyWith(isPermissionGranted: status.isGranted));
    }
  }

  void _onUpdateParkingStatus(
      UpdateParkingStatusEvent event, Emitter<HomeState> emit) async {
    final currentState = state;
    if (currentState is HomeLoaded) {
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) return;

        if (event.isParked) {
          // Start a new parking session
          await _parkingService.startParkingSession(
            driverUid: currentUser.uid,
            location: event.location ?? 'Demo Location A4',
            vehicleType: currentState.selectedVehicleType.displayName,
            hourlyRate: 15.0, // ₹15 per hour
          );
        } else {
          // End the current parking session
          final sessionResult = await _parkingService.endParkingSession(
            driverUid: currentUser.uid,
          );
          
          if (sessionResult != null) {
            // Show success message or handle session end
            print('Parking session ended. Total cost: ₹${sessionResult['totalCost']}');
          }
        }

        // Refresh driver data to get updated stats
        add(LoadDriverDataEvent(driverUid: currentUser.uid));
        
      } catch (e) {
        print('Error updating parking status: $e');
        // Handle error - maybe show a snackbar
      }
    }
  }

  void _startListeningToDriverData(String driverUid) {
    _driverDataSubscription?.cancel();
    _driverDataSubscription = _driverService.getDriverDataStream(driverUid).listen(
      (snapshot) {
        if (snapshot.exists) {
          add(LoadDriverDataEvent(driverUid: driverUid));
        }
      },
      onError: (error) {
        print('Error listening to driver data: $error');
      },
    );
  }

  void _startListeningToParkingSession(String driverUid) {
    _parkingSessionSubscription?.cancel();
    _parkingSessionSubscription = _parkingService.getActiveParkingSessionStream(driverUid).listen(
      (snapshot) {
        // Refresh data when parking session changes
        add(LoadDriverDataEvent(driverUid: driverUid));
      },
      onError: (error) {
        print('Error listening to parking session: $error');
      },
    );
  }

  void _startParkingTimer() {
    _parkingTimer?.cancel();
    _parkingTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final currentState = state;
      if (currentState is HomeLoaded && currentState.parkingData.isCurrentlyParked) {
        // Refresh parking data to get updated cost
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          add(LoadDriverDataEvent(driverUid: currentUser.uid));
        }
      }
    });
  }
}