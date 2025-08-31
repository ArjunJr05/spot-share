import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:spot_share2/core/constants/app_router_constants.dart';
import 'package:spot_share2/features/auth/services/land_owner_services.dart';
import 'package:spot_share2/features/placeHolder/AddParking/domain/location_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  final LandownerFirestoreService _firestoreService = LandownerFirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Map<String, dynamic>? landownerData;
  Map<String, dynamic>? locationStats;
  List<LocationModel> recentLocations = [];
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
      // Get landowner data
      final landowners = await _firestoreService.getAllLandOwners();
      final currentLandownerDoc = landowners.docs.firstWhere(
        (doc) => doc.id == currentUserId,
        orElse: () => throw Exception('Landowner not found'),
      );
      
      landownerData = currentLandownerDoc.data() as Map<String, dynamic>;

      // Get location statistics
      locationStats = await _firestoreService.getLandownerLocationStats(currentUserId!);

      // Get recent locations (limit to 3)
      final allLocations = await _firestoreService.getLandownerLocations(currentUserId!);
      recentLocations = allLocations.take(3).toList();

    } catch (e) {
      print('Error loading profile data: $e');
      // Set default values if error occurs
      landownerData = {
        'name': 'Parking Owner',
        'email': _auth.currentUser?.email ?? 'owner@parkspace.com',
        'phoneNumber': 'Not provided',
        'photoUrl': '',
        'emailVerified': _auth.currentUser?.emailVerified ?? false,
        'isGoogleSignIn': false,
        'createdAt': DateTime.now(),
      };
      
      locationStats = {
        'totalLocations': 0,
        'activeLocations': 0,
        'totalSpots': 0,
        'totalEarnings': 0.0,
      };
      
      recentLocations = [];
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
                  Icons.local_parking,
                  color: Color(0xFF0F0F0F),
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'ParkSpace Owner',
                style: TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Sign in to manage your parking spaces and track your earnings',
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
                    // Dashboard Stats
                    _buildDashboardStats(),
                    
                    const SizedBox(height: 32),
                    
                    // Parking Locations
                    _buildParkingLocations(),
                    
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
    final name = landownerData?['name'] ?? 'Parking Owner';
    final email = landownerData?['email'] ?? 'owner@parkspace.com';
    final photoUrl = landownerData?['photoUrl'];

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
              
              // Status Badge with gradient
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF3B46F1),
                      const Color(0xFF3B46F1).withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B46F1).withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified,
                      color: Color(0xFFFFFFFF),
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Verified Owner',
                      style: TextStyle(
                        color: Color(0xFFFFFFFF),
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
        Icons.local_parking,
        color: Color(0xFF3B46F1),
        size: 50,
      ),
    );
  }

  Widget _buildDashboardStats() {
    if (locationStats == null) return const SizedBox.shrink();

    final totalLocations = locationStats!['totalLocations'] ?? 0;
    final activeLocations = locationStats!['activeLocations'] ?? 0;
    final totalSpots = locationStats!['totalSpots'] ?? 0;
    final totalEarnings = locationStats!['totalEarnings'] ?? 0.0;

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
                'Total Locations',
                totalLocations.toString(),
                Icons.location_on_outlined,
                isLarge: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Monthly Earnings',
                '₹${totalEarnings.toStringAsFixed(0)}',
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
                'Active Now',
                activeLocations.toString(),
                Icons.radio_button_checked,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Total Spots',
                totalSpots.toString(),
                Icons.local_parking_outlined,
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

  Widget _buildParkingLocations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Parking Locations',
              style: TextStyle(
                color: Color(0xFFFFFFFF),
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (recentLocations.isNotEmpty)
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
        
        if (recentLocations.isEmpty)
          _buildEmptyLocationsState()
        else
          _buildLocationsList(),
      ],
    );
  }

  Widget _buildEmptyLocationsState() {
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
              Icons.add_location_alt_outlined,
              color: Color(0xFF3B46F1),
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Parking Locations Yet',
            style: TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your first parking location to start earning',
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
              icon: const Icon(Icons.add, color: Color(0xFFFFFFFF)),
              label: const Text(
                'Add Location',
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

  Widget _buildLocationsList() {
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
          ...recentLocations.asMap().entries.map((entry) {
            final index = entry.key;
            final location = entry.value;
            final isLast = index == recentLocations.length - 1;
            
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
                      gradient: location.isActive 
                          ? LinearGradient(
                              colors: [
                                const Color(0xFF3B46F1),
                                const Color(0xFF3B46F1).withValues(alpha: 0.8),
                              ],
                            )
                          : null,
                      color: !location.isActive 
                          ? const Color(0xFF3B46F1).withValues(alpha: 0.1)
                          : null,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: location.isActive ? [
                        BoxShadow(
                          color: const Color(0xFF3B46F1).withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ] : null,
                    ),
                    child: Icon(
                      Icons.local_parking,
                      color: location.isActive 
                          ? const Color(0xFFFFFFFF)
                          : const Color(0xFF3B46F1),
                      size: 28,
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
                            color: Color(0xFFFFFFFF),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          location.area,
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
                                color: location.isActive 
                                    ? const Color(0xFF10B981).withValues(alpha: 0.2)
                                    : const Color(0xFF9CA3AF).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: location.isActive 
                                      ? const Color(0xFF10B981).withValues(alpha: 0.5)
                                      : const Color(0xFF9CA3AF).withValues(alpha: 0.5),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                location.isActive ? 'ACTIVE' : 'INACTIVE',
                                style: TextStyle(
                                  color: location.isActive 
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF9CA3AF),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${location.capacityFilled}/${location.totalSpots} spots',
                              style: const TextStyle(
                                color: Color(0xFF3B46F1),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${location.occupancyPercentage.toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: location.occupancyPercentage > 80 
                                    ? const Color(0xFFEF4444)
                                    : location.occupancyPercentage > 50 
                                        ? const Color(0xFFFB923C)
                                        : const Color(0xFF10B981),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildAccountInfo() {
    if (landownerData == null) return const SizedBox.shrink();
    
    final phoneNumber = landownerData!['phoneNumber'] ?? 'Not provided';
    final createdAt = landownerData!['createdAt'];
    final emailVerified = landownerData!['emailVerified'] ?? false;
    final isGoogleSignIn = landownerData!['isGoogleSignIn'] ?? false;

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
              // _buildInfoRow(
              //   Icons.phone_outlined,
              //   'Phone Number',
              //   phoneNumber,
              // ),
              // const SizedBox(height: 24),
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
                Icons.add_location_alt_outlined,
                'Add New Location',
                'Register a new parking space',
                () {},
              ),
              _buildActionItem(
                Icons.analytics_outlined,
                'View Analytics',
                'Check your earnings and usage stats',
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

      // 👇 Navigate to authLogIn after sign out
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