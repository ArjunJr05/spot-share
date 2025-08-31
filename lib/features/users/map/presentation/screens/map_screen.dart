import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spot_share2/features/auth/services/firestore_services.dart';
import 'package:spot_share2/features/placeHolder/AddParking/domain/location_model.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  bool _isLoading = true;
  String? _error;
  Set<Marker> _markers = {};
  List<LocationModel> _nearbyLocations = [];
  StreamSubscription<QuerySnapshot>? _locationsSubscription;
  BitmapDescriptor? _customMarkerIcon;
  final FirestoreService _firestoreService = FirestoreService();

  final String _darkMapStyle = '''[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#1a1a1a"}]
  },
  {
    "elementType": "labels.icon",
    "stylers": [{"visibility": "off"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#8a8a8a"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#1a1a1a"}]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [{"color": "#404040"}]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#6a6a6a"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#2a2a2a"}]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#5a5a5a"}]
  },
  {
    "featureType": "road.arterial",
    "elementType": "geometry",
    "stylers": [{"color": "#2a2a2a"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{"color": "#3c3c3c"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#7a7a7a"}]
  },
  {
    "featureType": "transit",
    "elementType": "geometry",
    "stylers": [{"color": "#2f2f2f"}]
  },
  {
    "featureType": "transit.station",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#6a6a6a"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#0f1419"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#4a5568"}]
  }
]''';

  @override
  void initState() {
    super.initState();
    _createCustomMarkerIcon();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _locationsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _createCustomMarkerIcon() async {
    try {
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      const double size = 120.0;

      // Create gradient background
      final Paint backgroundPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF3B46F1).withOpacity(0.9),
            const Color(0xFF2563EB).withOpacity(0.7),
          ],
        ).createShader(Rect.fromCircle(center: const Offset(size / 2, size / 2), radius: size / 2));

      // Draw background circle with shadow
      final Paint shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      
      canvas.drawCircle(Offset(size / 2 + 2, size / 2 + 2), size / 2 - 10, shadowPaint);
      canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 10, backgroundPaint);

      // Draw car icon
      final Paint carPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      // Simplified car shape
      const double carWidth = 40;
      const double carHeight = 24;
      const double centerX = size / 2;
      const double centerY = size / 2;

      // Car body
      final RRect carBody = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX, centerY),
          width: carWidth,
          height: carHeight,
        ),
        const Radius.circular(6),
      );
      canvas.drawRRect(carBody, carPaint);

      // Car windows
      final Paint windowPaint = Paint()
        ..color = const Color(0xFF3B46F1)
        ..style = PaintingStyle.fill;

      final RRect frontWindow = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX + 8, centerY),
          width: 16,
          height: 12,
        ),
        const Radius.circular(2),
      );
      canvas.drawRRect(frontWindow, windowPaint);

      final RRect rearWindow = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX - 8, centerY),
          width: 16,
          height: 12,
        ),
        const Radius.circular(2),
      );
      canvas.drawRRect(rearWindow, windowPaint);

      // Convert to image
      final ui.Picture picture = recorder.endRecording();
      final ui.Image image = await picture.toImage(size.toInt(), size.toInt());
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List uint8List = byteData!.buffer.asUint8List();

      _customMarkerIcon = BitmapDescriptor.fromBytes(uint8List);
    } catch (e) {
      print('Error creating custom marker: $e');
      _customMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _error = 'Location services are disabled';
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _error = 'Location permission denied';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Location permission permanently denied';
          _isLoading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      if (_mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentLocation!, 14),
        );
      }

      // Load nearby locations
      await _loadNearbyLocations();
    } catch (e) {
      setState(() {
        _error = 'Error getting location: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNearbyLocations() async {
    if (_currentLocation == null) return;

    try {
      // Use the optimized method to get nearby locations
      final nearbyLocations = await _firestoreService.getNearbyParkingLocations(
        centerLatitude: _currentLocation!.latitude,
        centerLongitude: _currentLocation!.longitude,
        radiusInKm: 5.0,
        activeOnly: true, // Only show active parking spots
        availableOnly: false, // Show all spots, not just available ones
      );

      setState(() {
        _nearbyLocations = nearbyLocations;
        _updateMarkers();
      });

    } catch (e) {
      print('Error loading nearby locations: $e');
    }
  }

  void _updateMarkers() {
    Set<Marker> markers = {};

    // Add current location marker
    if (_currentLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentLocation!,
          infoWindow: const InfoWindow(
            title: 'You are here',
            snippet: 'Your current location',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    // Add parking location markers
    for (var location in _nearbyLocations) {
      final distance = _currentLocation != null
          ? Geolocator.distanceBetween(
              _currentLocation!.latitude,
              _currentLocation!.longitude,
              location.latitude,
              location.longitude,
            ) / 1000 // Convert to km
          : 0.0;

      markers.add(
        Marker(
          markerId: MarkerId(location.id),
          position: LatLng(location.latitude, location.longitude),
          icon: _customMarkerIcon ?? BitmapDescriptor.defaultMarker,
          onTap: () => _showLocationDetails(location, distance),
          infoWindow: InfoWindow(
            title: location.name,
            snippet: '${location.capacityEmpty}/${location.totalSpots} spots available',
          ),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  void _showLocationDetails(LocationModel location, double distance) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location name and status
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                location.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (location.area.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  location.area,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: location.isActive ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            location.isActive ? 'OPEN' : 'CLOSED',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Distance and address
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.grey, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${distance.toStringAsFixed(1)} km away',
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      location.address,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Availability info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Available Spots',
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                              Text(
                                '${location.capacityEmpty}/${location.totalSpots}',
                                style: TextStyle(
                                  color: location.capacityEmpty > 0 ? Colors.green : Colors.red,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: location.occupancyPercentage / 100,
                            backgroundColor: Colors.grey[700],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              location.occupancyPercentage < 50
                                  ? Colors.green
                                  : location.occupancyPercentage < 80
                                      ? Colors.orange
                                      : Colors.red,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${location.occupancyPercentage.toStringAsFixed(0)}% occupied',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Vehicle types
                    const Text(
                      'Vehicle Types',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildVehicleTypeCard('Car', location.vehicleCount.car, Icons.directions_car),
                        _buildVehicleTypeCard('Bike', location.vehicleCount.bike, Icons.two_wheeler),
                        _buildVehicleTypeCard('Auto', location.vehicleCount.auto, Icons.airport_shuttle),
                        _buildVehicleTypeCard('Lorry', location.vehicleCount.lorry, Icons.local_shipping),
                      ],
                    ),
                    
                    const Spacer(),
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _show3DPreview(location);
                            },
                            icon: const Icon(Icons.view_in_ar, color: Colors.white),
                            label: const Text('Preview', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B46F1),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: location.capacityEmpty > 0 ? () {
                              // TODO: Book parking spot
                              Navigator.pop(context);
                              _showBookingDialog(location);
                            } : null,
                            icon: const Icon(Icons.local_parking),
                            label: const Text('Book Now'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: location.capacityEmpty > 0 ? const Color(0xFF3B46F1) : Colors.grey,
                              side: BorderSide(
                                color: location.capacityEmpty > 0 ? const Color(0xFF3B46F1) : Colors.grey,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add these methods after the existing ones

  void _show3DPreview(LocationModel location) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.view_in_ar, color: Color(0xFF3B46F1)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '3D Preview',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            location.name,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              
              // 3D View
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0F0F),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF3B46F1).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(location.latitude, location.longitude),
                        zoom: 18,
                        tilt: 60, // This creates the 3D effect
                        bearing: 45,
                      ),
                      mapType: MapType.hybrid, // Hybrid shows buildings in 3D
                      myLocationEnabled: false,
                      myLocationButtonEnabled: false,
                      compassEnabled: true,
                      zoomControlsEnabled: true,
                      mapToolbarEnabled: false,
                      rotateGesturesEnabled: true,
                      tiltGesturesEnabled: true,
                      onMapCreated: (GoogleMapController controller) async {
                        try {
                          // Apply a lighter style for 3D view
                          await controller.setMapStyle('[]'); // Reset to default style
                          
                          // Animate to the location with 3D effect
                          await controller.animateCamera(
                            CameraUpdate.newCameraPosition(
                              CameraPosition(
                                target: LatLng(location.latitude, location.longitude),
                                zoom: 18,
                                tilt: 60,
                                bearing: 45,
                              ),
                            ),
                          );
                        } catch (e) {
                          print("Error setting up 3D preview: $e");
                        }
                      },
                      markers: {
                        Marker(
                          markerId: MarkerId('preview_${location.id}'),
                          position: LatLng(location.latitude, location.longitude),
                          icon: _customMarkerIcon ?? BitmapDescriptor.defaultMarker,
                          infoWindow: InfoWindow(
                            title: location.name,
                            snippet: 'Parking Location',
                          ),
                        ),
                      },
                    ),
                  ),
                ),
              ),
              
              // Controls and Info
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _build3DControlButton(
                          'Rotate Left',
                          Icons.rotate_left,
                          () => _rotate3DView(-45),
                        ),
                        _build3DControlButton(
                          'Reset View',
                          Icons.center_focus_strong,
                          () => _reset3DView(location),
                        ),
                        _build3DControlButton(
                          'Rotate Right',
                          Icons.rotate_right,
                          () => _rotate3DView(45),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showBookingDialog(location);
                            },
                            icon: const Icon(Icons.local_parking, color: Colors.white),
                            label: const Text('Book This Spot', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B46F1),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _build3DControlButton(String label, IconData icon, VoidCallback onPressed) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: Colors.white),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  GoogleMapController? _previewMapController;

  void _rotate3DView(double bearing) {
    // This would require storing the preview map controller
    // For now, we'll show a simple instruction
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Drag to rotate the 3D view'),
        backgroundColor: const Color(0xFF3B46F1),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _reset3DView(LocationModel location) {
    // Reset to default 3D view
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Resetting to default view'),
        backgroundColor: const Color(0xFF3B46F1),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showBookingDialog(LocationModel location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Book Parking Spot',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location: ${location.name}',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Available: ${location.capacityEmpty} spots',
              style: TextStyle(
                color: location.capacityEmpty > 0 ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select vehicle type:',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _buildVehicleChip('Car', Icons.directions_car),
                _buildVehicleChip('Bike', Icons.two_wheeler),
                _buildVehicleChip('Auto', Icons.airport_shuttle),
                _buildVehicleChip('Lorry', Icons.local_shipping),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: location.capacityEmpty > 0 ? () {
              Navigator.pop(context);
              // TODO: Implement actual booking logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Booking feature coming soon!'),
                  backgroundColor: Color(0xFF3B46F1),
                ),
              );
            } : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B46F1),
            ),
            child: const Text('Book Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleChip(String type, IconData icon) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 4),
          Text(type, style: const TextStyle(color: Colors.white)),
        ],
      ),
      selected: false,
      onSelected: (selected) {
        // Handle vehicle type selection
      },
      backgroundColor: const Color(0xFF1A1A1A),
      selectedColor: const Color(0xFF3B46F1),
      checkmarkColor: Colors.white,
    );
  }

  void _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    
    try {
      await controller.setMapStyle(_darkMapStyle);
      print("Map style applied successfully");
    } catch (e) {
      print("Error setting map style: $e");
      // Continue without custom style if it fails
    }

    if (_currentLocation != null) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, 14),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Stack(
          children: [
            // Map
            _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Finding parking spots near you...',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _getCurrentLocation,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _currentLocation ?? const LatLng(13.0827, 80.2707),
                          zoom: 14,
                        ),
                        mapType: MapType.normal,
                        myLocationEnabled: false, // We'll show custom current location marker
                        myLocationButtonEnabled: false,
                        compassEnabled: true,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        buildingsEnabled: true, // Enable 3D buildings
                        trafficEnabled: false,
                        indoorViewEnabled: true,
                        onMapCreated: _onMapCreated,
                        markers: _markers,
                      ),
            
            // Header with search and filter
            if (!_isLoading && _error == null) ...[
              Positioned(
                top: 20,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_parking, color: Color(0xFF3B46F1)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Nearby Parking',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${_nearbyLocations.length} spots within 5km',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _loadNearbyLocations,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Current location button
              Positioned(
                bottom: 100,
                right: 20,
                child: FloatingActionButton(
                  onPressed: () async {
                    if (_currentLocation != null && _mapController != null) {
                      await _mapController!.animateCamera(
                        CameraUpdate.newLatLngZoom(_currentLocation!, 14),
                      );
                    }
                  },
                  backgroundColor: const Color(0xFF3B46F1),
                  child: const Icon(Icons.my_location, color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
 Widget _buildVehicleTypeCard(String type, int count, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            type,
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ],
      ),
    );
  }