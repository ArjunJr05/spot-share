import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:spot_share2/commons/widgets/k_filled_icon_button.dart';
import 'package:spot_share2/commons/widgets/k_horizontal_spacer.dart';
import 'package:spot_share2/commons/widgets/k_text.dart';
import 'package:spot_share2/commons/widgets/k_vertical_spacer.dart';
import 'package:spot_share2/features/users/home/presentation/bloc/home_bloc.dart';
import 'package:spot_share2/features/users/home/presentation/bloc/home_event.dart';
import 'package:spot_share2/features/users/home/presentation/bloc/home_state.dart';

class EnhancedHomePage extends StatelessWidget {
  const EnhancedHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc()..add(LoadInitialDataEvent()),
      child: const EnhancedHomeView(),
    );
  }
}

class EnhancedHomeView extends StatelessWidget {
  const EnhancedHomeView({super.key});

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
            final parkingData = state.parkingData;
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const KVerticalSpacer(height: 60),
                  
                  // Header with greeting and vehicle selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          KText(
                            text: 'Hello ${parkingData.driverName}',
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            textColor: Colors.grey[300],
                          ),
                          const KVerticalSpacer(height: 4),
                          KText(
                            text: parkingData.isCurrentlyParked 
                                ? 'Your vehicle is safely parked'
                                : 'Select your parking vehicle type',
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
                          color: parkingData.isCurrentlyParked 
                              ? const Color(0xFF3CC2A7) 
                              : const Color(0xFF3B46F1),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: (parkingData.isCurrentlyParked 
                                  ? const Color(0xFF3CC2A7) 
                                  : const Color(0xFF3B46F1)).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              parkingData.isCurrentlyParked 
                                  ? Icons.local_parking 
                                  : currentVehicle.icon,
                              color: Colors.white,
                              size: 18,
                            ),
                            const KHorizontalSpacer(width: 8),
                            KText(
                              text: parkingData.isCurrentlyParked 
                                  ? 'PARKED' 
                                  : currentVehicle.displayName,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              textColor: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const KVerticalSpacer(height: 40), // Reduced from default spacing
                  
                  // Vehicle Model Display Area (fixed height)
                  Container(
                    height: 300,
                    child: state.isPermissionGranted
                        ? Stack(
                            children: [
                              ModelViewer(
                                key: ValueKey(currentVehicle.displayName),
                                backgroundColor: Colors.transparent,
                                src: currentVehicle.modelPath,
                                alt: "${currentVehicle.displayName} 3D Model",
                                ar: true,
                                autoRotate: !parkingData.isCurrentlyParked,
                                rotationPerSecond: parkingData.isCurrentlyParked ? "0deg" : "-15deg",
                                cameraControls: true,
                                disableZoom: false,
                                loading: Loading.eager,
                                shadowIntensity: 1.0,
                                environmentImage: null,
                              ),
                              // Navigation arrows
                              if (!parkingData.isCurrentlyParked) ...[
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  bottom: 0,
                                  child: IconButton(
                                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                                    onPressed: () => context.read<HomeBloc>().add(CycleVehicleEvent(isNext: false)),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  bottom: 0,
                                  child: IconButton(
                                    icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                                    onPressed: () => context.read<HomeBloc>().add(CycleVehicleEvent(isNext: true)),
                                  ),
                                ),
                              ],
                            ],
                          )
                        : Center(
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
                  ),
                  
                  const KVerticalSpacer(height: 40),
                  
                  // Action Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: parkingData.isCurrentlyParked 
                            ? [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)]
                            : [const Color(0xFF3B46F1), const Color(0xFF3CC2A7)],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: (parkingData.isCurrentlyParked 
                              ? const Color(0xFFFF6B6B) 
                              : const Color(0xFF3B46F1)).withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(28),
                        onTap: () {
                          // Handle park/unpark action
                          context.read<HomeBloc>().add(UpdateParkingStatusEvent(
                            isParked: !parkingData.isCurrentlyParked,
                            location: !parkingData.isCurrentlyParked ? 'Demo Location A4' : null,
                            cost: !parkingData.isCurrentlyParked ? 0.0 : null,
                          ));
                        },
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                parkingData.isCurrentlyParked 
                                    ? Icons.exit_to_app 
                                    : Icons.local_parking,
                                color: Colors.white,
                                size: 24,
                              ),
                              const KHorizontalSpacer(width: 12),
                              KText(
                                text: parkingData.isCurrentlyParked 
                                    ? 'End Parking Session' 
                                    : 'Find Parking Spot',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                textColor: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const KVerticalSpacer(height: 40),
                  
                  // Dynamic stats based on parking status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: _buildDynamicStats(parkingData),
                  ),
                  
                  // Add bottom padding to account for bottom navigation bar
                  SizedBox(height: 20),
                ],
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  List<Widget> _buildDynamicStats(DriverParkingData parkingData) {
    if (parkingData.isCurrentlyParked) {
      // Show current parking session stats
      return [
        _buildStatCard(
          'Parked Time', 
          parkingData.displayTime, 
          Icons.access_time, 
          Colors.white,
          isHighlighted: true,
        ),
        _buildStatCard(
          'Current Cost', 
          parkingData.displayCost, 
          Icons.payments, 
          Colors.white,
          isHighlighted: true,
        ),
        _buildStatCard(
          'Location', 
          parkingData.displayLocation, 
          Icons.location_on, 
          Colors.white,
          isHighlighted: true,
        ),
      ];
    } else {
      // Show overall statistics when not parked
      return [
        _buildStatCard(
          'Total Rides', 
          '${parkingData.totalRides}', 
          Icons.directions_car, 
          Colors.white,
        ),
        _buildStatCard(
          'Total Spent', 
          '₹ ${parkingData.totalSpent.toStringAsFixed(0)}', 
          Icons.account_balance_wallet, 
          Colors.white,
        ),
        _buildStatCard(
          'Rating', 
          parkingData.rating > 0 ? '${parkingData.rating.toStringAsFixed(1)} ⭐' : 'No Rating', 
          Icons.star, 
          Colors.white,
        ),
      ];
    }
  }

  Widget _buildStatCard(
    String title, 
    String value, 
    IconData icon, 
    Color color, {
    bool isHighlighted = false,
  }) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isHighlighted ? const Color(0xFF3CC2A7) : const Color(0xFF3B46F1),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isHighlighted ? [
              BoxShadow(
                color: const Color(0xFF3CC2A7).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ] : null,
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