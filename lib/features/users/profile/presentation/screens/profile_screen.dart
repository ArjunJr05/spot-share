import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spot_share2/core/constants/app_router_constants.dart';
import 'package:spot_share2/features/auth/services/driver_services.dart';
import 'package:spot_share2/features/auth/services/parking_services.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> with TickerProviderStateMixin {
  final DriverFirestoreService _driverService = DriverFirestoreService();
  final ParkingSessionService _parkingService = ParkingSessionService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Map<String, dynamic>? driverData;
  Map<String, dynamic>? driverStats;
  Map<String, dynamic>? parkingStats;
  List<DocumentSnapshot> recentSessions = [];
  DocumentSnapshot? activeParkingSession;
  bool isLoading = true;
  String? currentUserId;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _setupAnimations();
    _loadProfileData();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  void _initializeUser() {
    final user = _auth.currentUser;
    if (user != null) {
      currentUserId = user.uid;
    }
  }

  Future<void> _loadProfileData() async {
    if (currentUserId == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      // Get driver data
      final driverDoc = await _driverService.getDriverData(currentUserId!);
      if (driverDoc != null && driverDoc.exists) {
        driverData = driverDoc.data() as Map<String, dynamic>;
      }

      // Get driver statistics
      driverStats = await _driverService.getDriverStats(currentUserId!);

      // Get parking statistics
      parkingStats = await _parkingService.getParkingStatistics(currentUserId!);

      // Get recent parking sessions (limit to 3)
      final allSessions = await _parkingService.getParkingHistory(
        driverUid: currentUserId!,
        limit: 3,
      );
      recentSessions = allSessions;

      // Get active parking session
      activeParkingSession = await _parkingService.getActiveParkingSession(currentUserId!);

    } catch (e) {
      print('Error loading profile data: $e');
      // Set default values if error occurs
      driverData = {
        'name': 'Driver',
        'email': _auth.currentUser?.email ?? 'driver@parkspace.com',
        'phoneNumber': 'Not provided',
        'photoUrl': '',
        'emailVerified': _auth.currentUser?.emailVerified ?? false,
        'isGoogleSignIn': false,
        'createdAt': DateTime.now(),
        'vehicleInfo': {
          'vehicleType': 'Not specified',
          'vehicleNumber': '',
          'vehicleModel': '',
          'vehicleColor': '',
        },
      };
      
      driverStats = {
        'totalRides': 0,
        'totalSpent': 0.0,
        'rating': 0.0,
        'reviewCount': 0,
        'isDocumentsVerified': false,
        'preferredVehicleType': '',
        'paymentMethodsCount': 0,
      };
      
      parkingStats = {
        'totalSessions': 0,
        'totalSpent': 0.0,
        'totalTimeParked': 0,
        'averageSessionDuration': 0,
        'averageSessionCost': 0.0,
        'mostUsedLocation': 'N/A',
      };
      
      recentSessions = [];
      activeParkingSession = null;
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    } else {
      int hours = minutes ~/ 60;
      int remainingMinutes = minutes % 60;
      return remainingMinutes > 0 ? '${hours}h ${remainingMinutes}m' : '${hours}h';
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: isLoading 
            ? _buildLoadingState()
            : currentUserId == null 
                ? _buildNotSignedInState()
                : _buildProfileContent(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF3B46F1).withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: const CircularProgressIndicator(
              color: Color(0xFF3B46F1),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Loading your profile...',
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotSignedInState() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0F0F0F),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF3B46F1).withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B46F1).withValues(alpha: 0.1),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFF3B46F1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.directions_car,
                  color: Color(0xFF0F0F0F),
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'ParkSpace Driver',
                style: TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Sign in to access parking spaces and manage your rides',
                style: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _loadProfileData,
        color: const Color(0xFF3B46F1),
        backgroundColor: const Color(0xFF1A1A1A),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Header Section
              _buildHeader(),
              
              const SizedBox(height: 24),
              
              // Main Content
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Active Session (if any)
                    if (activeParkingSession != null) ...[
                      _buildActiveParkingSession(),
                      const SizedBox(height: 32),
                    ],
                    
                    // Dashboard Stats
                    _buildDashboardStats(),
                    
                    const SizedBox(height: 32),
                    
                    // Recent Parking Sessions
                    _buildRecentSessions(),
                    
                    const SizedBox(height: 32),
                    
                    // Vehicle Information
                    _buildVehicleInfo(),
                    
                    const SizedBox(height: 32),
                    
                    // Account Information
                    _buildAccountInfo(),
                    
                    const SizedBox(height: 32),
                    
                    // Quick Actions
                    _buildQuickActions(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final name = driverData?['name'] ?? 'Driver';
    final email = driverData?['email'] ?? 'driver@parkspace.com';
    final photoUrl = driverData?['photoUrl'];
    final rating = driverStats?['rating']?.toDouble() ?? 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Top Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Profile',
                style: TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF3B46F1).withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.settings,
                  color: Color(0xFF3B46F1),
                  size: 24,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          
          // Profile Info
          Column(
            children: [
              // Profile Picture with glow effect
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B46F1).withValues(alpha: 0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF3B46F1),
                      width: 3,
                    ),
                  ),
                  child: photoUrl != null && photoUrl.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            photoUrl,
                            width: 114,
                            height: 114,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultAvatar();
                            },
                          ),
                        )
                      : _buildDefaultAvatar(),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Name
              Text(
                name,
                style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Email
              Text(
                email,
                style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 16,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Rating and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Rating Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF3B46F1),
                          const Color(0xFF3B46F1).withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B46F1).withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          color: Color(0xFFFFFFFF),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          rating > 0 ? rating.toStringAsFixed(1) : 'New',
                          style: const TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Verification Status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: (driverStats?['isDocumentsVerified'] ?? false)
                          ? const Color(0xFF10B981).withValues(alpha: 0.2)
                          : const Color(0xFFFB923C).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: (driverStats?['isDocumentsVerified'] ?? false)
                            ? const Color(0xFF10B981)
                            : const Color(0xFFFB923C),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          (driverStats?['isDocumentsVerified'] ?? false)
                              ? Icons.verified
                              : Icons.pending,
                          color: (driverStats?['isDocumentsVerified'] ?? false)
                              ? const Color(0xFF10B981)
                              : const Color(0xFFFB923C),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          (driverStats?['isDocumentsVerified'] ?? false)
                              ? 'Verified'
                              : 'Pending',
                          style: TextStyle(
                            color: (driverStats?['isDocumentsVerified'] ?? false)
                                ? const Color(0xFF10B981)
                                : const Color(0xFFFB923C),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 114,
      height: 114,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.directions_car,
        color: Color(0xFF3B46F1),
        size: 50,
      ),
    );
  }

  Widget _buildActiveParkingSession() {
    if (activeParkingSession == null) return const SizedBox.shrink();
    
    final sessionData = activeParkingSession!.data() as Map<String, dynamic>;
    final startTime = (sessionData['startTime'] as Timestamp).toDate();
    final currentTime = DateTime.now();
    final duration = currentTime.difference(startTime);
    final location = sessionData['location'] ?? 'Unknown Location';
    final hourlyRate = sessionData['hourlyRate']?.toDouble() ?? 0.0;
    final currentCost = (duration.inMinutes / 60.0) * hourlyRate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Active Parking Session',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 20),
        
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF10B981).withValues(alpha: 0.1),
                const Color(0xFF10B981).withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_parking,
                      color: Color(0xFFFFFFFF),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location,
                          style: const TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Started ${_formatDuration(duration.inMinutes)} ago',
                          style: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Duration',
                            style: TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDuration(duration.inMinutes),
                            style: const TextStyle(
                              color: Color(0xFFFFFFFF),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Current Cost',
                            style: TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${currentCost.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Color(0xFFFFFFFF),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardStats() {
    if (driverStats == null || parkingStats == null) return const SizedBox.shrink();

    final totalRides = driverStats!['totalRides'] ?? 0;
    final totalSpent = parkingStats!['totalSpent']?.toDouble() ?? 0.0;
    final totalSessions = parkingStats!['totalSessions'] ?? 0;
    final averageSessionCost = parkingStats!['averageSessionCost']?.toDouble() ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dashboard Overview',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 20),
        
        // Primary Stats Row
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Sessions',
                totalSessions.toString(),
                Icons.local_parking_outlined,
                isLarge: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Total Spent',
                '₹${totalSpent.toStringAsFixed(0)}',
                Icons.account_balance_wallet_outlined,
                isLarge: true,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Secondary Stats Row
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Avg. Session Cost',
                '₹${averageSessionCost.toStringAsFixed(0)}',
                Icons.trending_up,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Rating',
                (driverStats!['rating']?.toDouble() ?? 0.0) > 0 
                    ? (driverStats!['rating']?.toDouble() ?? 0.0).toStringAsFixed(1)
                    : 'New',
                Icons.star_outline,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, {bool isLarge = false}) {
    return Container(
      padding: EdgeInsets.all(isLarge ? 24 : 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF3B46F1).withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B46F1).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: isLarge ? 56 : 48,
            height: isLarge ? 56 : 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF3B46F1),
                  const Color(0xFF3B46F1).withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B46F1).withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              icon, 
              color: const Color(0xFFFFFFFF), 
              size: isLarge ? 28 : 24,
            ),
          ),
          SizedBox(height: isLarge ? 20 : 16),
          Text(
            value,
            style: TextStyle(
              color: const Color(0xFFFFFFFF),
              fontSize: isLarge ? 28 : 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSessions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Parking Sessions',
              style: TextStyle(
                color: Color(0xFFFFFFFF),
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (recentSessions.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B46F1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF3B46F1).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: Color(0xFF3B46F1),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        
        if (recentSessions.isEmpty)
          _buildEmptySessionsState()
        else
          _buildSessionsList(),
      ],
    );
  }

  Widget _buildEmptySessionsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF3B46F1).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF3B46F1).withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF3B46F1).withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.history,
              color: Color(0xFF3B46F1),
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Parking Sessions Yet',
            style: TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start your first parking session to see your history here',
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF3B46F1),
                  const Color(0xFF3B46F1).withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B46F1).withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.search, color: Color(0xFFFFFFFF)),
              label: const Text(
                'Find Parking',
                style: TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsList() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF3B46F1).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          ...recentSessions.asMap().entries.map((entry) {
            final index = entry.key;
            final session = entry.value;
            final sessionData = session.data() as Map<String, dynamic>;
            final isLast = index == recentSessions.length - 1;
            
            final startTime = sessionData['startTime'] != null 
                ? (sessionData['startTime'] as Timestamp).toDate()
                : DateTime.now();
            final endTime = sessionData['endTime'] != null 
                ? (sessionData['endTime'] as Timestamp).toDate()
                : DateTime.now();
            final location = sessionData['location'] ?? 'Unknown Location';
            final totalCost = sessionData['totalCost']?.toDouble() ?? 0.0;
            final duration = sessionData['duration'] ?? 0;
            
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: !isLast ? Border(
                  bottom: BorderSide(
                    color: const Color(0xFF3B46F1).withValues(alpha: 0.1),
                    width: 1,
                  ),
                ) : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF3B46F1),
                          const Color(0xFF3B46F1).withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B46F1).withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_parking,
                      color: Color(0xFFFFFFFF),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location,
                          style: const TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(startTime),
                          style: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.5),
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                'COMPLETED',
                                style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _formatDuration(duration),
                              style: const TextStyle(
                                color: Color(0xFF3B46F1),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${totalCost.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Color(0xFFFFFFFF),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B46F1).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.chevron_right,
                          color: Color(0xFF3B46F1),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildVehicleInfo() {
    if (driverData == null) return const SizedBox.shrink();
    
    final vehicleInfo = driverData!['vehicleInfo'] as Map<String, dynamic>? ?? {};
    final vehicleType = vehicleInfo['vehicleType'] ?? 'Not specified';
    final vehicleNumber = vehicleInfo['vehicleNumber'] ?? '';
    final vehicleModel = vehicleInfo['vehicleModel'] ?? '';
    final vehicleColor = vehicleInfo['vehicleColor'] ?? '';
    final preferredVehicleType = driverStats?['preferredVehicleType'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vehicle Information',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 20),
        
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF3B46F1).withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              if (vehicleType != 'Not specified') ...[
                _buildInfoRow(
                  Icons.directions_car_outlined,
                  'Vehicle Type',
                  vehicleType,
                ),
                if (vehicleNumber.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildInfoRow(
                    Icons.confirmation_number_outlined,
                    'Vehicle Number',
                    vehicleNumber,
                  ),
                ],
                if (vehicleModel.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildInfoRow(
                    Icons.car_repair_outlined,
                    'Vehicle Model',
                    vehicleModel,
                  ),
                ],
                if (vehicleColor.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildInfoRow(
                    Icons.palette_outlined,
                    'Vehicle Color',
                    vehicleColor,
                  ),
                ],
                if (preferredVehicleType.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildInfoRow(
                    Icons.favorite_outline,
                    'Preferred Type',
                    preferredVehicleType,
                  ),
                ],
              ] else ...[
                Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B46F1).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF3B46F1).withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.directions_car_outlined,
                        color: Color(0xFF3B46F1),
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No Vehicle Information',
                      style: TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add your vehicle details for a better experience',
                      style: TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF3B46F1),
                            const Color(0xFF3B46F1).withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B46F1).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add, color: Color(0xFFFFFFFF), size: 18),
                        label: const Text(
                          'Add Vehicle',
                          style: TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountInfo() {
    if (driverData == null) return const SizedBox.shrink();
    
    final phoneNumber = driverData!['phoneNumber'] ?? 'Not provided';
    final createdAt = driverData!['createdAt'];
    final emailVerified = driverData!['emailVerified'] ?? false;
    final isGoogleSignIn = driverData!['isGoogleSignIn'] ?? false;
    final paymentMethodsCount = driverStats?['paymentMethodsCount'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Account Information',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 20),
        
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF3B46F1).withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              if (phoneNumber != 'Not provided') ...[
                _buildInfoRow(
                  Icons.phone_outlined,
                  'Phone Number',
                  phoneNumber,
                ),
                const SizedBox(height: 24),
              ],
              _buildInfoRow(
                isGoogleSignIn ? Icons.g_mobiledata : Icons.email_outlined,
                'Account Type',
                isGoogleSignIn ? 'Google Account' : 'Email Account',
              ),
              const SizedBox(height: 24),
              _buildInfoRow(
                emailVerified ? Icons.verified : Icons.warning_outlined,
                'Verification Status',
                emailVerified ? 'Verified' : 'Pending Verification',
              ),
              const SizedBox(height: 24),
              _buildInfoRow(
                Icons.credit_card_outlined,
                'Payment Methods',
                '$paymentMethodsCount method${paymentMethodsCount != 1 ? 's' : ''} added',
              ),
              const SizedBox(height: 24),
              _buildInfoRow(
                Icons.calendar_today_outlined,
                'Member Since',
                createdAt != null 
                    ? (createdAt is DateTime 
                        ? _formatDate(createdAt) 
                        : _formatDate(createdAt.toDate()))
                    : 'Unknown',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF3B46F1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF3B46F1).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(icon, color: const Color(0xFF3B46F1), size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 20),
        
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF3B46F1).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              _buildActionItem(
                Icons.search,
                'Find Parking',
                'Search for available parking spaces nearby',
                () {},
              ),
              _buildActionItem(
                Icons.directions_car_outlined,
                'Manage Vehicle',
                'Update your vehicle information',
                () {},
              ),
              _buildActionItem(
                Icons.credit_card_outlined,
                'Payment Methods',
                'Manage your payment options',
                () {},
              ),
              _buildActionItem(
                Icons.history,
                'Parking History',
                'View all your parking sessions',
                () {},
              ),
              _buildActionItem(
                Icons.notifications_outlined,
                'Notifications',
                'Manage notification preferences',
                () {},
              ),
              _buildActionItem(
                Icons.help_outline,
                'Help & Support',
                'Get help or contact our support team',
                () {},
              ),
              
              // Logout Button
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF3B46F1),
                      const Color(0xFF3B46F1).withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B46F1).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _showLogoutConfirmation,
                  icon: const Icon(Icons.logout, color: Color(0xFFFFFFFF), size: 20),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: const Color(0xFF3B46F1).withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF3B46F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF3B46F1).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: const Color(0xFF3B46F1), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF3B46F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.chevron_right,
                color: Color(0xFF3B46F1),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: const Color(0xFF3B46F1).withOpacity(0.2),
              width: 1,
            ),
          ),
          title: const Text(
            'Sign Out?',
            style: TextStyle(
              color: Color(0xFFFFFFFF),
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          content: const Text(
            'Are you sure you want to sign out of your account?',
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF3B46F1),
                    const Color(0xFF3B46F1).withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B46F1).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _performLogout();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text(
                  'Sign Out',
                  style: TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout() async {
    try {
      await _auth.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Successfully signed out',
              style: TextStyle(
                color: Color(0xFFFFFFFF),
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: const Color(0xFF3B46F1),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );

        // Navigate to authLogIn after sign out
        GoRouter.of(context).goNamed(AppRouterConstants.authLogIn);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error signing out: $e',
              style: const TextStyle(
                color: Color(0xFFFFFFFF),
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }
}