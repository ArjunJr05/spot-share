import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:spot_share2/features/placeHolder/AddParking/domain/location_model.dart';
import 'package:spot_share2/features/placeHolder/AddParking/presentation/bloc/location_bloc.dart';
import 'package:spot_share2/features/placeHolder/AddParking/presentation/bloc/location_event.dart';
import 'package:spot_share2/features/placeHolder/AddParking/presentation/bloc/location_state.dart';

class AddLocationPage extends StatefulWidget {
  const AddLocationPage({super.key});

  @override
  State<AddLocationPage> createState() => _AddLocationPageState();
}

class _AddLocationPageState extends State<AddLocationPage> {
  final _nameController = TextEditingController();
  final _areaController = TextEditingController();
  final _addressController = TextEditingController();
  
  double? generatedLat;
  double? generatedLng;
  bool isLoadingLocation = false;
  
  // AR Ruler points
  List<Point> landPoints = [];
  double calculatedArea = 0.0;
  bool isRecording = false;
  int currentPointIndex = 0;
  
  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add New Location',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: BlocListener<LocationBloc, LocationState>(
        listener: (context, state) {
          if (state is LocationLoaded) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location added successfully!'),
                backgroundColor: Color(0xFF3B46F1),
                duration: Duration(seconds: 2),
              ),
            );
          }
          
          if (state is LocationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Location Information',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              
              // Parking Name Field
              _buildInputField(
                controller: _nameController,
                label: 'Parking Name',
                hint: 'e.g., Raj Parking',
                icon: Icons.business,
              ),
              
              const SizedBox(height: 16),
              
              // Area Field
              _buildInputField(
                controller: _areaController,
                label: 'Area',
                hint: 'e.g., T Nagar, Anna Nagar',
                icon: Icons.location_city,
              ),
              
              const SizedBox(height: 16),
              
              // Address Field
              _buildInputField(
                controller: _addressController,
                label: 'Full Address',
                hint: 'Enter complete address',
                icon: Icons.home,
                maxLines: 2,
              ),
              
              const SizedBox(height: 24),
              
              // Get Current Location Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoadingLocation ? null : _getCurrentLocation,
                  icon: isLoadingLocation
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.my_location, color: Colors.white),
                  label: Text(
                    isLoadingLocation ? 'Getting Location...' : 'Get Current Location',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLoadingLocation
                        ? Colors.grey[600]
                        : const Color(0xFF3B46F1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              
              if (generatedLat != null && generatedLng != null) ...[
                const SizedBox(height: 20),
                
                // Location Coordinates Display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B46F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF3B46F1).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Color(0xFF3B46F1), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Location Coordinates',
                            style: TextStyle(
                              color: Color(0xFF3B46F1),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Lat: ${generatedLat!.toStringAsFixed(6)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Lng: ${generatedLng!.toStringAsFixed(6)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // AR Ruler Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F0F0F),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF3B46F1).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.straighten, color: Color(0xFF3B46F1), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'AR Land Measurement',
                          style: TextStyle(
                            color: Color(0xFF3B46F1),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    Text(
                      'Mark the corners of your land area (A → B → C → D → A)',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 14,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Current Point Indicator
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B46F1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: const Color(0xFF3B46F1),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isRecording 
                                ? 'Point ${String.fromCharCode(65 + currentPointIndex)} - Tap to mark'
                                : landPoints.isEmpty 
                                    ? 'Ready to start measurement'
                                    : 'Measurement completed',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Points Display
                    if (landPoints.isNotEmpty) ...[
                      const Text(
                        'Marked Points:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      ...landPoints.asMap().entries.map((entry) {
                        int index = entry.key;
                        Point point = entry.value;
                        String pointName = String.fromCharCode(65 + index);
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B46F1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF3B46F1),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    pointName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'X: ${point.x.toStringAsFixed(2)}, Y: ${point.y.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      
                      const SizedBox(height: 16),
                    ],
                    
                    // AR Ruler Controls
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: landPoints.length == 4 ? null : _startARMeasurement,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isRecording
                                  ? Colors.red
                                  : const Color(0xFF3B46F1),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              landPoints.length == 4 
                                  ? 'Measurement Complete'
                                  : isRecording 
                                      ? 'Stop Recording'
                                      : 'Start AR Ruler',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: landPoints.isEmpty ? null : _clearPoints,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[600],
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Icon(
                            Icons.clear,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    
                    // Mock AR Camera View (Placeholder)
                    if (isRecording) ...[
                      const SizedBox(height: 16),
                      
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF3B46F1),
                            width: 2,
                          ),
                        ),
                        child: Stack(
                          children: [
                            const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 48,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'AR Camera View',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Point your camera at the ground',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Crosshair
                            Center(
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFF3B46F1),
                                    width: 2,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.add,
                                    color: Color(0xFF3B46F1),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            
                            // Tap to mark button
                            Positioned(
                              bottom: 16,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: ElevatedButton(
                                  onPressed: _markPoint,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3B46F1),
                                    shape: const CircleBorder(),
                                    padding: const EdgeInsets.all(16),
                                  ),
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    // Area Display
                    if (calculatedArea > 0) ...[
                      const SizedBox(height: 16),
                      
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B46F1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF3B46F1).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.calculate, color: Color(0xFF3B46F1), size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Calculated Area',
                                  style: TextStyle(
                                    color: Color(0xFF3B46F1),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            Text(
                              '${calculatedArea.toStringAsFixed(2)} sq meters',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            Text(
                              '≈ ${(calculatedArea / 10.764).toStringAsFixed(2)} sq feet',
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Add Location Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: BlocBuilder<LocationBloc, LocationState>(
                  builder: (context, state) {
                    final isProcessing = state is LocationLoading;
                    
                    return ElevatedButton(
                      onPressed: isProcessing || !_canAddLocation() ? null : _addLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _canAddLocation() && !isProcessing
                            ? const Color(0xFF3B46F1)
                            : Colors.grey[600],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: _canAddLocation() ? 8 : 0,
                        shadowColor: const Color(0xFF3B46F1).withOpacity(0.3),
                      ),
                      child: isProcessing
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Adding Location...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_location_alt, color: Colors.white, size: 24),
                                const SizedBox(width: 12),
                                Text(
                                  _canAddLocation() ? 'Add Parking Location' : 'Complete Required Fields',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F0F),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF3B46F1).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            onChanged: (value) => setState(() {}),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              prefixIcon: Icon(
                icon,
                color: const Color(0xFF3B46F1),
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Future<void> _getCurrentLocation() async {
    setState(() {
      isLoadingLocation = true;
    });
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable them.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        generatedLat = position.latitude;
        generatedLng = position.longitude;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Current location obtained successfully!'),
            backgroundColor: Color(0xFF3B46F1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        isLoadingLocation = false;
      });
    }
  }
  
  void _startARMeasurement() {
    setState(() {
      if (isRecording) {
        isRecording = false;
        currentPointIndex = 0;
      } else {
        isRecording = true;
        currentPointIndex = 0;
        landPoints.clear();
        calculatedArea = 0.0;
      }
    });
  }
  
  void _markPoint() {
    if (currentPointIndex >= 4) return;
    
    // Simulate AR point marking with random coordinates for demo
    final random = math.Random();
    final point = Point(
      x: random.nextDouble() * 20, // 0-20 meters range
      y: random.nextDouble() * 20, // 0-20 meters range
    );
    
    setState(() {
      landPoints.add(point);
      currentPointIndex++;
      
      if (currentPointIndex >= 4) {
        isRecording = false;
        currentPointIndex = 0;
        _calculateArea();
      }
    });
    
    // Haptic feedback
    HapticFeedback.lightImpact();
  }
  
  void _clearPoints() {
    setState(() {
      landPoints.clear();
      calculatedArea = 0.0;
      isRecording = false;
      currentPointIndex = 0;
    });
  }
  
  void _calculateArea() {
    if (landPoints.length != 4) return;
    
    // Use shoelace formula to calculate area of polygon
    double area = 0.0;
    int n = landPoints.length;
    
    for (int i = 0; i < n; i++) {
      int j = (i + 1) % n;
      area += landPoints[i].x * landPoints[j].y;
      area -= landPoints[j].x * landPoints[i].y;
    }
    
    setState(() {
      calculatedArea = (area.abs() / 2.0);
    });
  }
  
  bool _canAddLocation() {
    return _nameController.text.isNotEmpty &&
           _areaController.text.isNotEmpty &&
           _addressController.text.isNotEmpty &&
           generatedLat != null &&
           generatedLng != null &&
           calculatedArea > 0 &&
           landPoints.length == 4;
  }
  
  void _addLocation() {
    if (!_canAddLocation()) return;
    
    // Convert points to a simple format for storage
    final pointsData = landPoints.map((point) => {
      'x': point.x,
      'y': point.y,
    }).toList();
    
    final newLocation = LocationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      area: _areaController.text.trim(),
      address: _addressController.text.trim(),
      latitude: generatedLat!,
      longitude: generatedLng!,
      capacity: calculatedArea, // Area in square meters
      totalSpots: (calculatedArea / 12.5).round(), // Assume 12.5 sq meters per parking spot
      vehicleCount: VehicleCount(), // Initialize with zero counts
      isActive: true,
      // You can add landPoints data to LocationModel if needed
    );
    
    context.read<LocationBloc>().add(AddLocationEvent(newLocation));
  }
}

// Point class for AR measurements
class Point {
  final double x;
  final double y;
  
  Point({required this.x, required this.y});
}