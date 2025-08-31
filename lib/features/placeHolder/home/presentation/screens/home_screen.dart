import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spot_share2/commons/widgets/k_filled_icon_button.dart';
import 'package:spot_share2/commons/widgets/k_horizontal_spacer.dart';
import 'package:spot_share2/commons/widgets/k_text.dart';
import 'package:spot_share2/commons/widgets/k_vertical_spacer.dart';
import 'package:spot_share2/features/auth/services/land_owner_services.dart';
import 'package:spot_share2/features/placeHolder/AddParking/domain/location_model.dart';
import 'package:spot_share2/features/users/home/presentation/bloc/home_bloc.dart';
import 'package:spot_share2/features/users/home/presentation/bloc/home_event.dart';
import 'package:spot_share2/features/users/home/presentation/bloc/home_state.dart';

class ClientHomeScreen extends StatelessWidget {
  const ClientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc()..add(LoadInitialDataEvent()),
      child: const DynamicHomeView(),
    );
  }
}

class DynamicHomeView extends StatefulWidget {
  const DynamicHomeView({super.key});

  @override
  State<DynamicHomeView> createState() => _DynamicHomeViewState();
}

class _DynamicHomeViewState extends State<DynamicHomeView> {
  final LandownerFirestoreService _firestoreService = LandownerFirestoreService();
  String? selectedLocationId;
  LocationModel? selectedLocation;
  List<LocationModel> allLocations = [];
  Map<String, dynamic> overallStats = {};
  String? currentUserId;
  
  @override
  void initState() {
    super.initState();
    _initializeUser();
    _loadParkingData();
  }

  void _initializeUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      currentUserId = user.uid;
    }
  }

  Future<void> _loadParkingData() async {
    if (currentUserId != null) {
      try {
        // Load all locations
        final locations = await _firestoreService.getLandownerLocations(currentUserId!);
        
        // Load overall statistics
        final stats = await _firestoreService.getLandownerLocationStats(currentUserId!);
        
        setState(() {
          allLocations = locations;
          overallStats = stats;
          
          // Set first active location as selected, or first location if none are active
          if (locations.isNotEmpty) {
            final activeLocations = locations.where((loc) => loc.isActive).toList();
            selectedLocation = activeLocations.isNotEmpty ? activeLocations.first : locations.first;
            selectedLocationId = selectedLocation?.id;
          }
        });
      } catch (e) {
        print('Error loading parking data: $e');
      }
    }
  }

  // Get vehicle count for selected vehicle type at selected location
  int _getVehicleCountForType(String vehicleType, LocationModel? location) {
    if (location == null) return 0;
    
    switch (vehicleType.toLowerCase()) {
      case 'car':
        return location.vehicleCount.car;
      case 'bike':
        return location.vehicleCount.bike;
      case 'truck':
      case 'lorry':
        return location.vehicleCount.lorry;
      case 'scooter':
      case 'auto':
        return location.vehicleCount.auto;
      default:
        return 0;
    }
  }

  // Calculate total earnings (mock calculation based on vehicle counts)
  double _calculateTotalEarnings() {
    if (allLocations.isEmpty) return 0.0;
    
    double totalEarnings = 0.0;
    for (var location in allLocations) {
      // Mock earnings calculation: car=50, bike=20, auto=30, lorry=100 per vehicle
      totalEarnings += location.vehicleCount.car * 50.0;
      totalEarnings += location.vehicleCount.bike * 20.0;
      totalEarnings += location.vehicleCount.auto * 30.0;
      totalEarnings += location.vehicleCount.lorry * 100.0;
    }
    return totalEarnings;
  }

  // Calculate overall occupancy percentage
  double _calculateOverallOccupancy() {
    if (overallStats.isEmpty) return 0.0;
    return (overallStats['overallOccupancyPercentage'] ?? 0.0).toDouble();
  }

  // Calculate total available spots
  int _calculateTotalAvailableSpots() {
    if (overallStats.isEmpty) return 0;
    return overallStats['totalCapacityEmpty'] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF3B46F1),
                strokeWidth: 3,
              ),
            );
          }

          if (state is HomeError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Icon(Icons.error, color: Colors.red, size: 40),
                  ),
                  const KVerticalSpacer(height: 20),
                  KText(
                    text: state.message,
                    textColor: Colors.white,
                    fontSize: 16,
                    textAlign: TextAlign.center,
                  ),
                  const KVerticalSpacer(height: 20),
                  ElevatedButton(
                    onPressed: () => context.read<HomeBloc>().add(LoadInitialDataEvent()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B46F1),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is HomeLoaded) {
            final currentVehicle = state.availableVehicles[state.currentVehicleIndex];
            final vehicleCount = _getVehicleCountForType(currentVehicle.displayName, selectedLocation);
            
            return RefreshIndicator(
              onRefresh: () async {
                await _loadParkingData();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const KVerticalSpacer(height: 60),
                    
                    // Header with vehicle badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const KText(
                                text: 'Parking Analytics',
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                textColor: Colors.white,
                              ),
                              const KVerticalSpacer(height: 4),
                              KText(
                                text: '${allLocations.length} locations available',
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                textColor: Colors.grey[400],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B46F1),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3B46F1).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                currentVehicle.icon,
                                color: Colors.white,
                                size: 18,
                              ),
                              const KHorizontalSpacer(width: 8),
                              KText(
                                text: currentVehicle.displayName,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                textColor: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const KVerticalSpacer(height: 20),
                    
                    // Dynamic Location Dropdown
                    if (allLocations.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF3B46F1).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedLocationId,
                            isExpanded: true,
                            dropdownColor: const Color(0xFF1A1A1A),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              color: Color(0xFF3B46F1),
                              size: 24,
                            ),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  selectedLocationId = newValue;
                                  selectedLocation = allLocations.firstWhere((loc) => loc.id == newValue);
                                });
                              }
                            },
                            items: allLocations.map<DropdownMenuItem<String>>((LocationModel location) {
                              return DropdownMenuItem<String>(
                                value: location.id,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: location.isActive ? const Color(0xFF3CC2A7) : Colors.grey,
                                      size: 20,
                                    ),
                                    const KHorizontalSpacer(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          KText(
                                            text: location.name,
                                            textColor: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          KText(
                                            text: '${location.area} • ${location.capacityEmpty} spots free',
                                            textColor: Colors.grey[400],
                                            fontSize: 12,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: location.isActive ? Colors.green : Colors.grey,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: KText(
                                        text: location.isActive ? 'Active' : 'Inactive',
                                        textColor: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                   if (allLocations.isEmpty)
  Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16), // Reduced padding
    decoration: BoxDecoration(
      color: const Color(0xFF1A1A1A),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Colors.orange.withOpacity(0.3),
        width: 1,
      ),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.info_outline,
          color: Colors.orange,
          size: 20,
        ),
        const KHorizontalSpacer(width: 12),
        Expanded(
          child: KText(
            text: 'No Parking Locations Available',
            textColor: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  ),
                    
                    const KVerticalSpacer(height: 10),
                    
                    // 3D Model Viewer
                    SizedBox(
                      height: 400,
                      child: Stack(
                        children: [
                          if (state.isPermissionGranted)
                            ModelViewer(
                              key: ValueKey(currentVehicle.displayName),
                              backgroundColor: Colors.transparent,
                              src: currentVehicle.modelPath,
                              alt: "${currentVehicle.displayName} 3D Model",
                              ar: true,
                              autoRotate: true,
                              rotationPerSecond: "-15deg",
                              cameraControls: true,
                              disableZoom: false,
                              loading: Loading.eager,
                              shadowIntensity: 1.0,
                              environmentImage: null,
                            ),
                          if (!state.isPermissionGranted)
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF3B46F1), Color(0xFF3CC2A7)],
                                      ),
                                      borderRadius: BorderRadius.circular(40),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ),
                                  const KVerticalSpacer(height: 20),
                                  const KText(
                                    text: "Camera Permission Required",
                                    textColor: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  const KVerticalSpacer(height: 8),
                                  KText(
                                    text: "Enable camera access for AR experience",
                                    textColor: Colors.grey[400],
                                    fontSize: 14,
                                    textAlign: TextAlign.center,
                                  ),
                                  const KVerticalSpacer(height: 24),
                                  KFilledIconBtn(
                                    text: 'Grant Permission',
                                    onPressed: () => context
                                        .read<HomeBloc>()
                                        .add(RequestPermissionEvent()),
                                    backgroundColor: const Color(0xFF3B46F1),
                                    textColor: Colors.white,
                                    height: 48,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    borderRadius: BorderRadius.circular(24),
                                    svgIconPath: null,
                                  ),
                                ],
                              ),
                            ),
                          // Left navigation arrow
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                              onPressed: () => context.read<HomeBloc>().add(CycleVehicleEvent(isNext: false)),
                            ),
                          ),
                          // Right navigation arrow
                          Positioned(
                            right: 0,
                            top: 0,
                            bottom: 0,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                              onPressed: () => context.read<HomeBloc>().add(CycleVehicleEvent(isNext: true)),
                            ),
                          ),
                          // Dynamic vehicle count for selected location
                          Positioned(
                            bottom: 20,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFF3B46F1).withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.local_parking,
                                      color: Color(0xFF3CC2A7),
                                      size: 16,
                                    ),
                                    const KHorizontalSpacer(width: 6),
                                    KText(
                                      text: selectedLocation != null 
                                          ? "Currently Parked: $vehicleCount at ${selectedLocation!.name}"
                                          : "No location selected",
                                      textColor: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const KVerticalSpacer(height: 5),
                    
                    // Dynamic Statistics Cards
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard(
                          'Total Earned', 
                          '₹ ${_calculateTotalEarnings().toStringAsFixed(0)}', 
                          Icons.account_balance_wallet, 
                          Colors.white
                        ),
                        _buildStatCard(
                          'Occupancy', 
                          '${_calculateOverallOccupancy().toStringAsFixed(1)}%', 
                          Icons.analytics, 
                          Colors.white
                        ),
                        _buildStatCard(
                          'Available Spots', 
                          '${_calculateTotalAvailableSpots()}', 
                          Icons.local_parking, 
                          Colors.white
                        ),
                      ],
                    ),
                    const KVerticalSpacer(height: 20),
                  ],
                ),
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFF3B46F1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const KVerticalSpacer(height: 8),
        KText(
          text: title,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          textColor: Colors.grey[400],
        ),
        KText(
          text: value,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          textColor: Colors.white,
        ),
      ],
    );
  }
}