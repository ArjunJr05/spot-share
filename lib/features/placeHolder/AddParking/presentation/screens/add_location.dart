import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spot_share2/features/auth/services/land_owner_services.dart';
import 'package:spot_share2/features/placeHolder/AddParking/domain/location_model.dart';
import 'package:spot_share2/features/placeHolder/AddParking/presentation/bloc/location_bloc.dart';
import 'package:spot_share2/features/placeHolder/AddParking/presentation/bloc/location_event.dart';
import 'package:spot_share2/features/placeHolder/AddParking/presentation/bloc/location_state.dart';
import 'package:spot_share2/features/placeHolder/AddParking/presentation/widgets/AddLocationPage.dart';

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
  final LandownerFirestoreService _firestoreService = LandownerFirestoreService();
  String? currentUserId;
  
  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      currentUserId = user.uid;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              
              // Header
              const Text(
                'Parking Analytics',
                style: TextStyle(
                  fontSize: 24,
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
              const SizedBox(height: 20),
              
              // Content Area
              Expanded(
                child: currentUserId != null 
                    ? StreamBuilder<List<LocationModel>>(
                        stream: _firestoreService.getLandownerLocationsStream(currentUserId!),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return _buildLoadingState();
                          }
                          
                          if (snapshot.hasError) {
                            return _buildErrorState(snapshot.error.toString());
                          }
                          
                          final locations = snapshot.data ?? [];
                          
                          if (locations.isEmpty) {
                            return _buildEmptyState(context);
                          }
                          
                          return _buildLocationsContent(context, locations);
                        },
                      )
                    : _buildAuthErrorState(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: currentUserId != null ? Padding(
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
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ) : null,
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF3B46F1),
        strokeWidth: 3,
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF3B46F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(Icons.error_outline, color: Color(0xFF3B46F1), size: 40),
          ),
          const SizedBox(height: 20),
          const Text(
            'Something went wrong',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              if (mounted) {
                setState(() {});
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B46F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF3B46F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(Icons.account_circle_outlined, color: Color(0xFF3B46F1), size: 40),
          ),
          const SizedBox(height: 20),
          const Text(
            'Authentication Required',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Please sign in to manage your parking locations.',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF3B46F1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.local_parking,
              color: Colors.white,
              size: 60,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Welcome to Parking Management!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Start by adding your first parking location to begin monitoring and managing your parking spaces effectively.',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Check if widget is still mounted before navigating
                if (mounted && context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BlocProvider.value(
                        value: context.read<LocationBloc>(),
                        child: const AddLocationPage(),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B46F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Create Your First Parking Space',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationsContent(BuildContext context, List<LocationModel> locations) {
    return Column(
      children: [
        // Statistics Card
        _buildStatsCard(context, locations),
        const SizedBox(height: 20),
        
        // Locations List
        Expanded(
          child: ListView.builder(
            itemCount: locations.length,
            itemBuilder: (context, index) {
              final location = locations[index];
              return _buildLocationCard(context, location);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard(BuildContext context, List<LocationModel> locations) {
    final activeCount = locations.where((loc) => loc.isActive).length;
    final totalCapacity = locations.fold<int>(0, (sum, loc) => sum + loc.totalSpots);
    final totalOccupied = locations.fold<int>(0, (sum, loc) => sum + loc.capacityFilled);
    final occupancyRate = totalCapacity > 0 ? (totalOccupied / totalCapacity * 100) : 0.0;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatCard('Active Locations', activeCount.toString(), Icons.check_circle),
        _buildStatCard('Occupancy', '${occupancyRate.toStringAsFixed(1)}%', Icons.analytics),
        _buildStatCard('Total Spots', totalCapacity.toString(), Icons.local_parking),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
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
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[400],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard(BuildContext context, LocationModel location) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF3B46F1).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          trailing: const SizedBox.shrink(),
          title: Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B46F1),
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
                      Text(
                        location.area,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: location.isActive 
                        ? Colors.green
                        : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    location.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: location.isActive ? Colors.white : Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildLocationStatCard(
                        'Capacity',
                        '${location.totalSpots}',
                        Icons.local_parking,
                      ),
                      _buildLocationStatCard(
                        'Occupied',
                        '${location.capacityFilled}',
                        Icons.directions_car,
                      ),
                      _buildLocationStatCard(
                        'Available',
                        '${location.capacityEmpty}',
                        Icons.event_available,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildVehicleCountGrid(location),
                  
                  const SizedBox(height: 20),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _toggleLocationStatus(context, location),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: location.isActive 
                                ? Colors.grey[600] 
                                : const Color(0xFF3B46F1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(location.isActive ? 'Deactivate' : 'Activate'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showDeleteConfirmation(context, location),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Delete'),
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

  Widget _buildLocationStatCard(String title, String value, IconData icon) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF3B46F1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[400],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleCountGrid(LocationModel location) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vehicle Count',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildVehicleCountCard(
              'Bikes',
              location.vehicleCount.bike.toString(),
              Icons.two_wheeler,
            ),
            _buildVehicleCountCard(
              'Cars',
              location.vehicleCount.car.toString(),
              Icons.directions_car,
            ),
            _buildVehicleCountCard(
              'Autos',
              location.vehicleCount.auto.toString(),
              Icons.local_taxi,
            ),
            _buildVehicleCountCard(
              'Lorries',
              location.vehicleCount.lorry.toString(),
              Icons.local_shipping,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVehicleCountCard(String label, String count, IconData icon) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF3B46F1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          count,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _toggleLocationStatus(BuildContext context, LocationModel location) async {
    // Check if widget is still mounted before proceeding
    if (!mounted || currentUserId == null) return;
    
    try {
      await _firestoreService.updateLandownerLocation(
        landOwnerUid: currentUserId!,
        location: location.copyWith(isActive: !location.isActive),
      );
      
      // Check if widget is still mounted before showing snackbar
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              location.isActive 
                  ? '${location.name} deactivated' 
                  : '${location.name} activated',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF3B46F1),
          ),
        );
      }
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating location: $e'),
            backgroundColor: Colors.grey[600],
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(BuildContext context, LocationModel location) {
    // Check if widget is still mounted before showing dialog
    if (!mounted || !context.mounted) return;
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F0F0F),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Delete Location',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Are you sure you want to delete "${location.name}"? This action cannot be undone.',
            style: TextStyle(color: Colors.grey[400]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                
                // Check if widget is still mounted and user ID is available
                if (!mounted || currentUserId == null) return;
                
                try {
                  await _firestoreService.deleteLandownerLocation(
                    landOwnerUid: currentUserId!,
                    locationId: location.id,
                  );
                  
                  // Check if widget is still mounted before showing snackbar
                  if (mounted && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${location.name} deleted successfully'),
                        backgroundColor: const Color(0xFF3B46F1),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error deleting location: $e'),
                        backgroundColor: Colors.grey[600],
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}