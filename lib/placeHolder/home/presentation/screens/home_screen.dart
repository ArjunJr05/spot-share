import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:spot_share2/commons/widgets/k_filled_icon_button.dart';
import 'package:spot_share2/commons/widgets/k_horizontal_spacer.dart';
import 'package:spot_share2/commons/widgets/k_text.dart';
import 'package:spot_share2/commons/widgets/k_vertical_spacer.dart';
import 'package:spot_share2/features/home/presentation/bloc/home_bloc.dart';
import 'package:spot_share2/features/home/presentation/bloc/home_event.dart';
import 'package:spot_share2/features/home/presentation/bloc/home_state.dart';

class ClientHomeScreen extends StatelessWidget {
  const ClientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc()..add(LoadInitialDataEvent()),
      child: const EnhancedHomeView(),
    );
  }
}

class EnhancedHomeView extends StatefulWidget {
  const EnhancedHomeView({super.key});

  @override
  State<EnhancedHomeView> createState() => _EnhancedHomeViewState();
}

class _EnhancedHomeViewState extends State<EnhancedHomeView> {
  String selectedLocation = "Vijay Parking - T Nagar";

  // List of parking locations
  final List<String> parkingLocations = [
    "Vijay Parking - T Nagar",
    "Raja Parking - Anna Nagar",
    "Siva Parking - Adyar",
    "Kumar Parking - Velachery",
    "Lakshmi Parking - Tambaram",
    "Devi Parking - Chrompet",
  ];

  // Method to get parked count for each vehicle type based on location and vehicle type
  int _getParkedCountForVehicle(String vehicleType, String location) {
    // Base counts for different vehicle types
    Map<String, int> baseCounts = {
      'car': 10,
      'sedan': 10,
      'hatchback': 10,
      'bike': 20,
      'motorcycle': 20,
      'scooter': 20,
      'truck': 3,
      'lorry': 3,
      'bus': 2,
      'bicycle': 15,
      'cycle': 15,
      'suv': 7,
      'van': 5,
    };

    // Location multipliers to vary counts across locations
    Map<String, double> locationMultipliers = {
      "Vijay Parking - T Nagar": 1.2,
      "Raja Parking - Anna Nagar": 0.8,
      "Siva Parking - Adyar": 1.5,
      "Kumar Parking - Velachery": 0.9,
      "Lakshmi Parking - Tambaram": 1.1,
      "Devi Parking - Chrompet": 0.7,
    };

    String vehicleKey = vehicleType.toLowerCase();
    int baseCount = baseCounts[vehicleKey] ?? 8;
    double multiplier = locationMultipliers[location] ?? 1.0;
    
    return (baseCount * multiplier).round();
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
                ],
              ),
            );
          }

          if (state is HomeLoaded) {
            final currentVehicle = state.availableVehicles[state.currentVehicleIndex];
            final parkedCount = _getParkedCountForVehicle(currentVehicle.displayName, selectedLocation);
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const KVerticalSpacer(height: 60),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
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
                            text: 'Monitor your parking space usage',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            textColor: Colors.grey[400],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFF3B46F1),
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
                  // Location Dropdown
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
                        value: selectedLocation,
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
                          setState(() {
                            selectedLocation = newValue!;
                          });
                        },
                        items: parkingLocations.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Color(0xFF3CC2A7),
                                  size: 20,
                                ),
                                const KHorizontalSpacer(width: 12),
                                Expanded(
                                  child: KText(
                                    text: value,
                                    textColor: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const KVerticalSpacer(height: 10),
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
                        // Parked count positioned at the bottom center of the model viewer
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
                                  Icon(
                                    Icons.local_parking,
                                    color: const Color(0xFF3CC2A7),
                                    size: 16,
                                  ),
                                  const KHorizontalSpacer(width: 6),
                                  KText(
                                    text: "Currently Parked: $parkedCount",
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard('Total Earned', '₹ 3,250', Icons.account_balance_wallet, Colors.white),
                      _buildStatCard('Occupancy', '75%', Icons.analytics, Colors.white),
                      _buildStatCard('Available Spots', '12', Icons.local_parking, Colors.white),
                    ],
                  ),
                  const KVerticalSpacer(height: 20),
                ],
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
            color: Color(0xFF3B46F1),
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

class SyncedCurvedProgressPainter extends CustomPainter {
  final double progress;
  SyncedCurvedProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint basePaint = Paint()
      ..color = const Color.fromARGB(255, 22, 94, 218).withOpacity(0.3)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final Paint progressPaint = Paint()
      ..color = const Color(0xFF3CC2A7)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    Rect rect = Rect.fromLTWH(0, -size.height, size.width, size.height * 2);
    double sweepAngle = math.pi * 0.50;
    double startAngle = (math.pi - sweepAngle) / 2;

    canvas.drawArc(rect, startAngle, sweepAngle, false, basePaint);
    canvas.drawArc(rect, startAngle, sweepAngle * progress, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}