import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spot_share2/placeHolder/AddParking/domain/location_model.dart';
import 'package:spot_share2/placeHolder/AddParking/presentation/bloc/location_bloc.dart';
import 'package:spot_share2/placeHolder/AddParking/presentation/bloc/location_event.dart';
import 'package:spot_share2/placeHolder/AddParking/presentation/bloc/location_state.dart';
import 'package:spot_share2/placeHolder/AddParking/presentation/widgets/AddLocationPage.dart';

class LocationsListPage extends StatelessWidget {
  const LocationsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LocationBloc()..add(LoadLocationsEvent()),
      child: const LocationsListView(),
    );
  }
}

class LocationsListView extends StatefulWidget {
  const LocationsListView({super.key});

  @override
  State<LocationsListView> createState() => _LocationsListViewState();
}

class _LocationsListViewState extends State<LocationsListView> {
  // Controllers for text input
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  
  // Variables for location data
  double? generatedLat;
  double? generatedLng;
  List<PolygonPoint> boundaries = [];

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: 
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Parking Analytics',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Monitor your parking space usage',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Content
            Expanded(
              child: BlocBuilder<LocationBloc, LocationState>(
                builder: (context, state) {
                  if (state is LocationLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF3B46F1),
                        strokeWidth: 3,
                      ),
                    );
                  }
                  
                  if (state is LocationError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            state.message,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  
                  if (state is LocationLoaded) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ListView.builder(
                        itemCount: state.locations.length,
                        itemBuilder: (context, index) {
                          final location = state.locations[index];
                          return _buildLocationCard(context, location);
                        },
                      ),
                    );
                  }
                  
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BlocProvider.value(
                  value: context.read<LocationBloc>(),
                  child: const AddLocationPage(),
                ),
              ),
            );
          },
          backgroundColor: const Color(0xFF3B46F1),
          child: const Icon(Icons.add, color: Colors.white, size: 28,),
        ),
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context, LocationModel location) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: const Color(0xFF3B46F1).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: ExpansionTile(
          backgroundColor: const Color(0xFF1A1A1A),
          collapsedBackgroundColor: const Color(0xFF1A1A1A),
          iconColor: const Color(0xFF3B46F1),
          collapsedIconColor: const Color(0xFF3B46F1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B46F1), Color(0xFF3CC2A7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          color: location.isActive ? const Color(0xFF3CC2A7) : Colors.grey,
                          size: 8,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          location.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: location.isActive ? const Color(0xFF3CC2A7) : Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Color(0xFF3B46F1), thickness: 1),
                  const SizedBox(height: 16),
                  
                  // Area Information
                  Row(
                    children: [
                      const Icon(Icons.place, color: Color(0xFF3B46F1), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Area: ${location.area}',
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Coordinates
                  Row(
                    children: [
                      const Icon(Icons.gps_fixed, color: Color(0xFF3B46F1), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Coordinates: ${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Boundaries Section
                  if (location.boundaries.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.crop_free, color: Color(0xFF3B46F1), size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Boundaries',
                          style: TextStyle(
                            color: Color(0xFF3B46F1),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F0F0F),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF3B46F1).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: location.boundaries.asMap().entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3B46F1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${entry.key + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '${entry.value.latitude.toStringAsFixed(6)}, ${entry.value.longitude.toStringAsFixed(6)}',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Edit location functionality
                            context.read<LocationBloc>().add(SelectLocationEvent(location));
                          },
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Edit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B46F1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Toggle active status
                            context.read<LocationBloc>().add(
                              UpdateLocationEvent(location.copyWith(isActive: !location.isActive))
                            );
                          },
                          icon: Icon(
                            location.isActive ? Icons.pause : Icons.play_arrow,
                            size: 16,
                          ),
                          label: Text(location.isActive ? 'Deactivate' : 'Activate'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: location.isActive ? Colors.orange : const Color(0xFF3CC2A7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
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
  
  bool _canAddLocation() {
    return _nameController.text.isNotEmpty &&
           _areaController.text.isNotEmpty &&
           generatedLat != null &&
           generatedLng != null &&
           boundaries.isNotEmpty;
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
    final offset = 0.001; // Approximately 100 meters
    
    return [
      PolygonPoint(latitude: centerLat + offset, longitude: centerLng - offset), // Top-left
      PolygonPoint(latitude: centerLat + offset, longitude: centerLng + offset), // Top-right  
      PolygonPoint(latitude: centerLat - offset, longitude: centerLng + offset), // Bottom-right
      PolygonPoint(latitude: centerLat - offset, longitude: centerLng - offset), // Bottom-left
    ];
  }
}