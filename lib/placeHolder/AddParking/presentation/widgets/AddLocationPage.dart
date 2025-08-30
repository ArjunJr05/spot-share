import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:spot_share2/placeHolder/AddParking/domain/location_model.dart';
import 'package:spot_share2/placeHolder/AddParking/presentation/bloc/location_bloc.dart';
import 'package:spot_share2/placeHolder/AddParking/presentation/bloc/location_event.dart';
import 'package:spot_share2/placeHolder/AddParking/presentation/bloc/location_state.dart';
import 'package:spot_share2/placeHolder/AddParking/presentation/widgets/CameraMeasurementPage.dart';


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
  List<PolygonPoint> boundaries = [];
  
  // Measurement data
  Map<String, double?> measurements = {
    'A-B': null,
    'B-C': null,
    'C-D': null,
    'D-A': null,
  };
  
  double? calculatedArea;
  bool isLoadingLocation = false;
  
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
                backgroundColor: Color(0xFF3CC2A7),
              ),
            );
          }
          
          if (state is LocationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
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
                hint: 'Enter complete address for coordinate generation',
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
                    isLoadingLocation ? 'Getting Location...' : 'Use Current Location',
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
                
                // Generated Coordinates Display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3CC2A7).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF3CC2A7).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Color(0xFF3CC2A7), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Current Location',
                            style: TextStyle(
                              color: Color(0xFF3CC2A7),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.my_location, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Center Point',
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
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
                
                const SizedBox(height: 24),
                
                // Area Measurement Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF3B46F1).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.straighten, color: Color(0xFF3B46F1), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Area Measurement',
                                style: TextStyle(
                                  color: Color(0xFF3B46F1),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton(
                            onPressed: _calculateAreaFromMeasurements,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3CC2A7),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Calculate Area',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Measurement Grid (2x2)
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        childAspectRatio: 2.2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        children: measurements.keys.map((side) {
                          return _buildMeasurementBlock(side);
                        }).toList(),
                      ),
                      
                      if (calculatedArea != null) ...[
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3CC2A7).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF3CC2A7).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.square_foot, color: Color(0xFF3CC2A7), size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Quadrilateral Area',
                                    style: TextStyle(
                                      color: Color(0xFF3CC2A7),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${calculatedArea!.toStringAsFixed(2)} sq meters',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Estimated Capacity: ${_estimateCapacityFromArea()} vehicles',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              
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
                            ? const Color(0xFF3CC2A7) 
                            : Colors.grey[600],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: _canAddLocation() ? 8 : 0,
                        shadowColor: const Color(0xFF3CC2A7).withOpacity(0.3),
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
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF3B46F1).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
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
  
  Widget _buildMeasurementBlock(String side) {
    final measurement = measurements[side];
    final hasValue = measurement != null;
    
    return GestureDetector(
      onTap: () => _openCameraMeasurement(side),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasValue ? const Color(0xFF3CC2A7).withOpacity(0.5) : Colors.grey[600]!,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasValue ? Icons.check_circle : Icons.camera_alt,
              color: hasValue ? const Color(0xFF3CC2A7) : Colors.grey[400],
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              '$side Point',
              style: TextStyle(
                color: hasValue ? Colors.white : Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              hasValue ? '${measurement.toStringAsFixed(1)}m' : 'Tap to measure',
              style: TextStyle(
                color: hasValue ? const Color(0xFF3CC2A7) : Colors.grey[500],
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
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
        boundaries = _generateBoundaries(position.latitude, position.longitude);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Current location obtained successfully!'),
            backgroundColor: Color(0xFF3CC2A7),
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
  
  Future<void> _openCameraMeasurement(String side) async {
    final cameraStatus = await Permission.camera.status;
    if (cameraStatus.isDenied) {
      final result = await Permission.camera.request();
      if (result.isDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera permission is required for measurement'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }
    
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No camera available'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      if (mounted) {
        final result = await Navigator.push<double>(
          context,
          MaterialPageRoute(
            builder: (context) => ARRulerCameraPage(
              camera: cameras.first,
              side: side,
            ),
          ),
        );
        
        if (result != null) {
          setState(() {
            measurements[side] = result;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening camera: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _calculateAreaFromMeasurements() {
    final allMeasured = measurements.values.every((value) => value != null);
    
    if (!allMeasured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please measure all four sides first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final ab = measurements['A-B']!;
    final bc = measurements['B-C']!;
    final cd = measurements['C-D']!;
    final da = measurements['D-A']!;
    
    // Simple rectangular approximation
    final length1 = (ab + cd) / 2;
    final width1 = (bc + da) / 2;
    final area = length1 * width1;
    
    setState(() {
      calculatedArea = area;
      boundaries = _generateBoundariesFromMeasurements();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Area calculated successfully!'),
        backgroundColor: Color(0xFF3CC2A7),
      ),
    );
  }
  
  bool _canAddLocation() {
    return _nameController.text.isNotEmpty &&
           _areaController.text.isNotEmpty &&
           _addressController.text.isNotEmpty &&
           generatedLat != null &&
           generatedLng != null &&
           calculatedArea != null &&
           measurements.values.every((value) => value != null);
  }
  
  void _addLocation() {
    if (_canAddLocation()) {
      final newLocation = LocationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        area: _areaController.text.trim(),
        latitude: generatedLat!,
        longitude: generatedLng!,
        boundaries: boundaries,
        isActive: true,
      );
      
      context.read<LocationBloc>().add(AddLocationEvent(newLocation));
    }
  }
  
  List<PolygonPoint> _generateBoundaries(double centerLat, double centerLng) {
    final offset = 0.0008;
    final random = math.Random();
    
    return [
      PolygonPoint(
        latitude: centerLat + offset + (random.nextDouble() - 0.5) * 0.0002,
        longitude: centerLng - offset + (random.nextDouble() - 0.5) * 0.0002,
      ),
      PolygonPoint(
        latitude: centerLat + offset + (random.nextDouble() - 0.5) * 0.0002,
        longitude: centerLng + offset + (random.nextDouble() - 0.5) * 0.0002,
      ),
      PolygonPoint(
        latitude: centerLat - offset + (random.nextDouble() - 0.5) * 0.0002,
        longitude: centerLng + offset + (random.nextDouble() - 0.5) * 0.0002,
      ),
      PolygonPoint(
        latitude: centerLat - offset + (random.nextDouble() - 0.5) * 0.0002,
        longitude: centerLng - offset + (random.nextDouble() - 0.5) * 0.0002,
      ),
    ];
  }
  
  List<PolygonPoint> _generateBoundariesFromMeasurements() {
    if (generatedLat == null || generatedLng == null) return [];
    
    final meterToDegree = 0.000009;
    
    final ab = measurements['A-B']! * meterToDegree;
    final bc = measurements['B-C']! * meterToDegree;
    
    return [
      PolygonPoint(
        latitude: generatedLat! + bc/2,
        longitude: generatedLng! - ab/2,
      ),
      PolygonPoint(
        latitude: generatedLat! + bc/2,
        longitude: generatedLng! + ab/2,
      ),
      PolygonPoint(
        latitude: generatedLat! - bc/2,
        longitude: generatedLng! + ab/2,
      ),
      PolygonPoint(
        latitude: generatedLat! - bc/2,
        longitude: generatedLng! - ab/2,
      ),
    ];
  }
  
  int _estimateCapacityFromArea() {
    if (calculatedArea == null) return 0;
    return (calculatedArea! / 13).round().clamp(5, 200);
  }
}