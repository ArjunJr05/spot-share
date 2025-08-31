import 'package:flutter/material.dart';

abstract class HomeEvent {}

class LoadInitialDataEvent extends HomeEvent {}

class CycleVehicleEvent extends HomeEvent {
  final bool isNext;
  CycleVehicleEvent({required this.isNext});
}

class RequestPermissionEvent extends HomeEvent {}

class LoadDriverDataEvent extends HomeEvent {
  final String driverUid;
  LoadDriverDataEvent({required this.driverUid});
}

class UpdateParkingStatusEvent extends HomeEvent {
  final bool isParked;
  final String? location;
  final double? cost;
  
  UpdateParkingStatusEvent({
    required this.isParked,
    this.location,
    this.cost,
  });
}

enum VehicleType {
  car,
  bike,
  truck,
  scooter,
}

extension VehicleTypeExtension on VehicleType {
  String get displayName {
    switch (this) {
      case VehicleType.car:
        return 'Car';
      case VehicleType.bike:
        return 'Bike';
      case VehicleType.truck:
        return 'Truck';
      case VehicleType.scooter:
        return 'Scooter';
    }
  }

  String get modelPath {
    switch (this) {
      case VehicleType.car:
        return 'assets/model/car.glb';
      case VehicleType.bike:
        return 'assets/model/bike.glb';
      case VehicleType.truck:
        return 'assets/model/truck2.0.glb';
      case VehicleType.scooter:
        return 'assets/model/auto.glb';
    }
  }

  IconData get icon {
    switch (this) {
      case VehicleType.car:
        return Icons.directions_car;
      case VehicleType.bike:
        return Icons.two_wheeler;
      case VehicleType.truck:
        return Icons.local_shipping;
      case VehicleType.scooter:
        return Icons.electric_scooter;
    }
  }

  String get description {
    switch (this) {
      case VehicleType.car:
        return 'Personal vehicle';
      case VehicleType.bike:
        return 'Two-wheeler';
      case VehicleType.truck:
        return 'Heavy vehicle';
      case VehicleType.scooter:
        return 'Electric scooter';
    }
  }

  Color get accentColor {
    switch (this) {
      case VehicleType.car:
        return const Color(0xFF3B46F1);
      case VehicleType.bike:
        return const Color(0xFF3CC2A7);
      case VehicleType.truck:
        return const Color(0xFFFF6B6B);
      case VehicleType.scooter:
        return const Color(0xFFFFD93D);
    }
  }
}