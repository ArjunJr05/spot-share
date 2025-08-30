class PolygonPoint {
  final double latitude;
  final double longitude;

  PolygonPoint({
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory PolygonPoint.fromJson(Map<String, dynamic> json) {
    return PolygonPoint(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
    );
  }
}

class LocationModel {
  final String id;
  final String name;
  final String area;
  final double latitude;
  final double longitude;
  final List<PolygonPoint> boundaries;
  final bool isActive;

  LocationModel({
    required this.id,
    required this.name,
    required this.area,
    required this.latitude,
    required this.longitude,
    required this.boundaries,
    this.isActive = true,
  });

  // Add the copyWith method
  LocationModel copyWith({
    String? id,
    String? name,
    String? area,
    double? latitude,
    double? longitude,
    List<PolygonPoint>? boundaries,
    bool? isActive,
  }) {
    return LocationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      area: area ?? this.area,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      boundaries: boundaries ?? this.boundaries,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'area': area,
      'latitude': latitude,
      'longitude': longitude,
      'boundaries': boundaries.map((point) => point.toJson()).toList(),
      'isActive': isActive,
    };
  }

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      area: json['area'] ?? '',
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      boundaries: (json['boundaries'] as List<dynamic>?)
          ?.map((point) => PolygonPoint.fromJson(point as Map<String, dynamic>))
          .toList() ?? [],
      isActive: json['isActive'] ?? true,
    );
  }
}