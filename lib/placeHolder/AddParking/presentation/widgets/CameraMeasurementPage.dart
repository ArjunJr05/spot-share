import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

class ARRulerCameraPage extends StatefulWidget {
  final CameraDescription camera;
  final String side;
  
  const ARRulerCameraPage({
    super.key,
    required this.camera,
    required this.side,
  });

  @override
  State<ARRulerCameraPage> createState() => _ARRulerCameraPageState();
}

class _ARRulerCameraPageState extends State<ARRulerCameraPage> 
    with TickerProviderStateMixin {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late AnimationController _pulseController;
  late AnimationController _lineController;
  
  List<Offset> measurementPoints = [];
  double? measuredDistance;
  bool isCalibrated = false;
  double calibrationFactor = 1.0;
  
  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller.initialize();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _lineController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    _lineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                // Full Screen Camera Preview
                Positioned.fill(
                  child: CameraPreview(_controller),
                ),
                
                // AR Measurement Overlay
                Positioned.fill(
                  child: GestureDetector(
                    onTapUp: (details) => _addMeasurementPoint(details.localPosition),
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_pulseController, _lineController]),
                      builder: (context, child) {
                        return CustomPaint(
                          painter: ARRulerPainter(
                            points: measurementPoints,
                            distance: measuredDistance,
                            pulseAnimation: _pulseController.value,
                            lineAnimation: _lineController.value,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                // Top Header with Instructions
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Expanded(
                              child: Text(
                                'AR Ruler - ${widget.side}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 48), // Balance for close button
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getInstructionText(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (measuredDistance != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00BCD4), Color(0xFF3CC2A7)],
                              ),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF3CC2A7).withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.straighten, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  '${_formatDistance(measuredDistance!)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                // Bottom Control Panel
                Positioned(
                  bottom: 30,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        // Clear Button
                        Expanded(
                          child: _buildControlButton(
                            icon: Icons.refresh,
                            label: 'Reset',
                            onPressed: _clearMeasurement,
                            color: Colors.grey[600]!,
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Calibrate Button
                        Expanded(
                          child: _buildControlButton(
                            icon: Icons.tune,
                            label: 'Calibrate',
                            onPressed: _showCalibrationDialog,
                            color: Colors.orange[600]!,
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Confirm Button
                        Expanded(
                          flex: 2,
                          child: _buildControlButton(
                            icon: measuredDistance != null ? Icons.check_circle : Icons.radio_button_unchecked,
                            label: measuredDistance != null ? 'Done' : 'Measure',
                            onPressed: measuredDistance != null ? _confirmMeasurement : null,
                            color: measuredDistance != null 
                                ? const Color(0xFF3CC2A7) 
                                : Colors.grey[600]!,
                            isEnabled: measuredDistance != null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Crosshair in center
                if (measurementPoints.isEmpty || measurementPoints.length == 1)
                  Center(
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 30 + (_pulseController.value * 10),
                          height: 30 + (_pulseController.value * 10),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white.withOpacity(0.8 - _pulseController.value * 0.3),
                              width: 2,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add,
                            color: Colors.white.withOpacity(0.8),
                            size: 20,
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          } else {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF3CC2A7),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Initializing Camera...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
  
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
    bool isEnabled = true,
  }) {
    return ElevatedButton(
      onPressed: isEnabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: isEnabled ? color : Colors.grey[700],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: isEnabled ? 4 : 0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  
  String _getInstructionText() {
    if (measurementPoints.isEmpty) {
      return 'Tap to mark the START point\nAlign the crosshair with one end of the object';
    } else if (measurementPoints.length == 1) {
      return 'Move to the END point and tap\nAlign crosshair with the other end';
    } else {
      return 'Measurement completed!\nTap "Done" to save or "Reset" to try again';
    }
  }
  
  String _formatDistance(double meters) {
    if (meters >= 1.0) {
      return '${meters.toStringAsFixed(2)} m';
    } else {
      return '${(meters * 100).toStringAsFixed(0)} cm';
    }
  }
  
  void _addMeasurementPoint(Offset position) {
    setState(() {
      if (measurementPoints.length < 2) {
        measurementPoints.add(position);
        
        if (measurementPoints.length == 2) {
          _lineController.forward();
          _calculateImprovedDistance();
        }
      }
    });
  }
  
  void _calculateImprovedDistance() {
    if (measurementPoints.length == 2) {
      final point1 = measurementPoints[0];
      final point2 = measurementPoints[1];
      
      final pixelDistance = math.sqrt(
        math.pow(point2.dx - point1.dx, 2) + math.pow(point2.dy - point1.dy, 2),
      );
      
      // Improved distance calculation with calibration
      // Base estimation: assume phone held ~60cm from object
      // Screen diagonal in pixels vs real world calibration
      final screenSize = MediaQuery.of(context).size;
      final screenDiagonal = math.sqrt(
        math.pow(screenSize.width, 2) + math.pow(screenSize.height, 2),
      );
      
      // Estimate based on typical phone screen size (~6 inches = 0.15 meters)
      const estimatedScreenDiagonalMeters = 0.15;
      final pixelsPerMeter = screenDiagonal / estimatedScreenDiagonalMeters;
      
      // Apply distance estimation (objects appear smaller when farther)
      // Assume average viewing distance of 0.5-1 meter
      const averageViewingDistance = 0.7;
      double realWorldDistance = (pixelDistance / pixelsPerMeter) * averageViewingDistance;
      
      // Apply user calibration if available
      realWorldDistance *= calibrationFactor;
      
      setState(() {
        measuredDistance = realWorldDistance.clamp(0.01, 50.0);
      });
    }
  }
  
  void _clearMeasurement() {
    setState(() {
      measurementPoints.clear();
      measuredDistance = null;
      _lineController.reset();
    });
  }
  
  void _confirmMeasurement() {
    if (measuredDistance != null) {
      Navigator.pop(context, {
        'distance': measuredDistance!,
        'side': widget.side,
        'calibrationFactor': calibrationFactor,
      });
    }
  }
  
  void _showCalibrationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        double tempCalibration = calibrationFactor;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text(
                'Calibrate Measurements',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Place a known object (like a credit card: 8.5cm) in view and measure it. Then adjust the calibration.',
                    style: TextStyle(color: Colors.grey[300]),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Calibration Factor: ${tempCalibration.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Slider(
                    value: tempCalibration,
                    min: 0.1,
                    max: 5.0,
                    divisions: 49,
                    activeColor: const Color(0xFF3CC2A7),
                    onChanged: (value) {
                      setDialogState(() {
                        tempCalibration = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      calibrationFactor = tempCalibration;
                      isCalibrated = true;
                      if (measurementPoints.length == 2) {
                        _calculateImprovedDistance();
                      }
                    });
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3CC2A7),
                  ),
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// Enhanced AR Ruler Painter with animations and better visuals
class ARRulerPainter extends CustomPainter {
  final List<Offset> points;
  final double? distance;
  final double pulseAnimation;
  final double lineAnimation;
  
  ARRulerPainter({
    required this.points,
    this.distance,
    required this.pulseAnimation,
    required this.lineAnimation,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Enhanced point styling
    final pointPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.fill;
    
    final pointBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    
    final pointGlowPaint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    // Animated line paint
    final linePaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    
    final lineGlowPaint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.4)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;
    
    // Draw measurement line with animation
    if (points.length == 2) {
      final point1 = points[0];
      final point2 = points[1];
      
      // Animated line drawing
      final animatedPoint2 = Offset(
        point1.dx + (point2.dx - point1.dx) * lineAnimation,
        point1.dy + (point2.dy - point1.dy) * lineAnimation,
      );
      
      // Draw glow effect
      canvas.drawLine(point1, animatedPoint2, lineGlowPaint);
      // Draw main line
      canvas.drawLine(point1, animatedPoint2, linePaint);
      
      // Draw measurement ticks at endpoints
      if (lineAnimation >= 0.8) {
        _drawMeasurementTicks(canvas, point1, point2);
      }
      
      // Draw distance label
      if (distance != null && lineAnimation > 0.5) {
        _drawDistanceLabel(canvas, point1, point2, distance!);
      }
    }
    
    // Draw points with pulse animation
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final pulseSize = 8 + (pulseAnimation * 6);
      
      // Draw glow
      canvas.drawCircle(point, pulseSize + 8, pointGlowPaint);
      // Draw border
      canvas.drawCircle(point, 15, pointBorderPaint);
      // Draw main point
      canvas.drawCircle(point, 12, pointPaint);
      
      // Draw point number
      _drawPointLabel(canvas, point, i + 1);
    }
    
    // Draw grid overlay for better depth perception
    _drawGridOverlay(canvas, size);
  }
  
  void _drawMeasurementTicks(Canvas canvas, Offset point1, Offset point2) {
    final tickPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;
    
    // Calculate perpendicular direction for ticks
    final direction = point2 - point1;
    final length = direction.distance;
    final perpendicular = Offset(-direction.dy / length, direction.dx / length) * 15;
    
    // Draw ticks at start and end
    canvas.drawLine(
      point1 - perpendicular,
      point1 + perpendicular,
      tickPaint,
    );
    canvas.drawLine(
      point2 - perpendicular,
      point2 + perpendicular,
      tickPaint,
    );
  }
  
  void _drawDistanceLabel(Canvas canvas, Offset point1, Offset point2, double distance) {
    final midPoint = Offset(
      (point1.dx + point2.dx) / 2,
      (point1.dy + point2.dy) / 2,
    );
    
    String distanceText;
    if (distance >= 1.0) {
      distanceText = '${distance.toStringAsFixed(2)} m';
    } else {
      distanceText = '${(distance * 100).toStringAsFixed(0)} cm';
    }
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: distanceText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              offset: Offset(1, 1),
              blurRadius: 3,
              color: Colors.black,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    
    // Background for text
    final labelRect = Rect.fromCenter(
      center: midPoint,
      width: textPainter.width + 16,
      height: textPainter.height + 8,
    );
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect, const Radius.circular(8)),
      Paint()
        ..color = Colors.black.withOpacity(0.8)
        ..style = PaintingStyle.fill,
    );
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect, const Radius.circular(8)),
      Paint()
        ..color = const Color(0xFF00E5FF)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );
    
    textPainter.paint(
      canvas,
      Offset(
        midPoint.dx - textPainter.width / 2,
        midPoint.dy - textPainter.height / 2,
      ),
    );
  }
  
  void _drawPointLabel(Canvas canvas, Offset point, int number) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$number',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    
    textPainter.paint(
      canvas,
      Offset(
        point.dx - textPainter.width / 2,
        point.dy - textPainter.height / 2,
      ),
    );
  }
  
  void _drawGridOverlay(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 0.5;
    
    const gridSpacing = 50.0;
    
    // Vertical lines
    for (double x = 0; x <= size.width; x += gridSpacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }
    
    // Horizontal lines
    for (double y = 0; y <= size.height; y += gridSpacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}