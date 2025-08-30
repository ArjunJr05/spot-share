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
                            text: 'Choose Vehicle',
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            textColor: Colors.white,
                          ),
                          const KVerticalSpacer(height: 4),
                          KText(
                            text: 'Select your parking vehicle type',
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
                  const KVerticalSpacer(height: 30),
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
                    ),
                  ),
                  const KVerticalSpacer(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard('Parked Time', '02h 30m', Icons.timer, Colors.white),
                      _buildStatCard('Cost', '₹ 250', Icons.payments, Colors.white),
                      _buildStatCard('Location', 'Spot A4', Icons.location_on, Colors.white),
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

// =========================================================================
// home_state.dart
// =========================================================================



// =========================================================================
// home_event.dart
// =========================================================================


// =========================================================================
// home_bloc.dart
// =========================================================================

