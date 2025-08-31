class LocationModel {
  final String id;
  final String name;
  final String area;
  final String address;
  final double latitude;
  final double longitude;
  final double capacity; // Total area in sq meters
  final int totalSpots; // Total parking spots available
  final VehicleCount vehicleCount;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  LocationModel({
    required this.id,
    required this.name,
    required this.area,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.capacity,
    required this.totalSpots,
    required this.vehicleCount,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      area: map['area'] ?? '',
      address: map['address'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      capacity: (map['capacity'] ?? 0.0).toDouble(),
      totalSpots: map['totalSpots'] ?? 0,
      vehicleCount: VehicleCount.fromMap(map['vehicleCount'] ?? {}),
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt']?.toDate(),
      updatedAt: map['updatedAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'area': area,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'capacity': capacity,
      'totalSpots': totalSpots,
      'vehicleCount': vehicleCount.toMap(),
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  LocationModel copyWith({
    String? id,
    String? name,
    String? area,
    String? address,
    double? latitude,
    double? longitude,
    double? capacity,
    int? totalSpots,
    VehicleCount? vehicleCount,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LocationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      area: area ?? this.area,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      capacity: capacity ?? this.capacity,
      totalSpots: totalSpots ?? this.totalSpots,
      vehicleCount: vehicleCount ?? this.vehicleCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  int get capacityFilled => vehicleCount.total;
  int get capacityEmpty => totalSpots - capacityFilled;
  double get occupancyPercentage => totalSpots > 0 ? (capacityFilled / totalSpots) * 100 : 0;
  bool get isFull => capacityFilled >= totalSpots;
}

class VehicleCount {
  final int bike;
  final int car;
  final int auto;
  final int lorry;

  VehicleCount({
    this.bike = 0,
    this.car = 0,
    this.auto = 0,
    this.lorry = 0,
  });

  factory VehicleCount.fromMap(Map<String, dynamic> map) {
    return VehicleCount(
      bike: map['bike'] ?? 0,
      car: map['car'] ?? 0,
      auto: map['auto'] ?? 0,
      lorry: map['lorry'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bike': bike,
      'car': car,
      'auto': auto,
      'lorry': lorry,
    };
  }

  int get total => bike + car + auto + lorry;

  VehicleCount copyWith({
    int? bike,
    int? car,
    int? auto,
    int? lorry,
  }) {
    return VehicleCount(
      bike: bike ?? this.bike,
      car: car ?? this.car,
      auto: auto ?? this.auto,
      lorry: lorry ?? this.lorry,
    );
  }

  VehicleCount operator +(VehicleCount other) {
    return VehicleCount(
      bike: bike + other.bike,
      car: car + other.car,
      auto: auto + other.auto,
      lorry: lorry + other.lorry,
    );
  }

  VehicleCount operator -(VehicleCount other) {
    return VehicleCount(
      bike: (bike - other.bike).clamp(0, double.infinity).toInt(),
      car: (car - other.car).clamp(0, double.infinity).toInt(),
      auto: (auto - other.auto).clamp(0, double.infinity).toInt(),
      lorry: (lorry - other.lorry).clamp(0, double.infinity).toInt(),
    );
  }
}