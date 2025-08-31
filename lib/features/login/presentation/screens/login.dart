import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:spot_share2/core/constants/app_router_constants.dart';
import 'package:spot_share2/features/auth/services/auth_services.dart';
import 'package:spot_share2/features/auth/services/base_services.dart';
import 'package:spot_share2/features/auth/services/firestore_services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    // Add listeners to update button state
    _emailController.addListener(_updateButtonState);
    _passwordController.addListener(_updateButtonState);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _updateButtonState() {
    setState(() {
      // This will trigger a rebuild to update button state
    });
  }

  bool get _isFormValid {
    return _emailController.text.trim().isNotEmpty &&
           _passwordController.text.trim().isNotEmpty &&
           _isValidEmail(_emailController.text.trim()) &&
           _passwordController.text.length >= 6;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(email);
  }

  Future<void> _signInWithEmailAndPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final userCredential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential != null && userCredential.user != null) {
        // Get user data from Firestore to determine user type
        final userData = await _firestoreService.getUserData(userCredential.user!.uid);
        
        if (userData != null && userData.exists) {
          final userDataMap = userData.data() as Map<String, dynamic>;
          
          // Determine user type based on which collection the user was found in
          UserType userType;
          if (userData.reference.parent.id == 'land_owners') {
            userType = UserType.landOwner;
          } else {
            userType = UserType.driver;
          }
          
          // Update last login
          await _firestoreService.updateLastLogin(userCredential.user!.uid, userType);
          
          // Save login analytics
          await _firestoreService.saveLoginAnalytics(
            uid: userCredential.user!.uid,
            email: email,
            userType: userType,
            isGoogleSignIn: false,
          );
          
          if (mounted) {
            _showSuccessSnackBar('Welcome back, ${userDataMap['name']}!');
            
            // Navigate based on user type
            if (userType == UserType.landOwner) {
              // Navigate to client main page for land owners
              GoRouter.of(context).goNamed(AppRouterConstants.clientMainPage);
            } else {
              // Navigate to bottom navigation for drivers
              GoRouter.of(context).goNamed(AppRouterConstants.bottomNav);
            }
          }
        } else {
          if (mounted) {
            _showErrorSnackBar('Account data not found. Please contact support or sign up again.');
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _showAuthErrorSnackBar(e);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('An unexpected error occurred. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white),),
        backgroundColor: Color(0xFF3B46F1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAuthErrorSnackBar(FirebaseAuthException e) {
    String errorMessage;
    switch (e.code) {
      case 'user-not-found':
        errorMessage = 'No account found with this email. Please sign up first.';
        break;
      case 'wrong-password':
      case 'invalid-credential':
        errorMessage = 'Incorrect password. Please try again.';
        break;
      case 'invalid-email':
        errorMessage = 'The email address is not valid.';
        break;
      case 'user-disabled':
        errorMessage = 'This account has been disabled. Please contact support.';
        break;
      case 'too-many-requests':
        errorMessage = 'Too many failed attempts. Please try again later.';
        break;
      default:
        errorMessage = 'Login failed: ${e.message}';
    }
    _showErrorSnackBar(errorMessage);
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showErrorSnackBar('Please enter your email first to reset password.');
      return;
    }
    try {
      await _authService.resetPassword(email);
      if (mounted) {
        _showSuccessSnackBar('Password reset email sent! Check your inbox.');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage;
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'No account found with this email.';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email address.';
            break;
          default:
            errorMessage = 'Error sending reset email: ${e.message}';
        }
        _showErrorSnackBar(errorMessage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = size.width * 0.08;
    final logoSize = size.width * 0.20;
    final fontScale = size.width < 400 ? 0.85 : 1.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: size.height * 0.06),
                Image.asset(
                  'assets/images/png/spotshare2.png',
                  width: logoSize * 2,
                  height: logoSize,
                  fit: BoxFit.cover,
                ),
                SizedBox(height: size.height * 0.05),
                Text(
                  'Welcome back',
                  style: TextStyle(
                    fontSize: 32 * fontScale,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: size.height * 0.015),
                Text(
                  'Sign in to access your Spot Share account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16 * fontScale,
                    color: Colors.white60,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: size.height * 0.04),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(value.trim())) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.white70, fontSize: 14 * fontScale),
                    hintText: 'Enter your email',
                    hintStyle: TextStyle(color: Colors.white38, fontSize: 14 * fontScale),
                    prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF3B46F1)),
                    filled: true,
                    fillColor: Color(0xFF1A1A1A),
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFF333333)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFF333333)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFF3B46F1), width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red.shade400),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red.shade400, width: 2),
                    ),
                  ),
                ),
                SizedBox(height: size.height * 0.025),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Password is required';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: Colors.white70, fontSize: 14 * fontScale),
                    hintText: 'Enter your password',
                    hintStyle: TextStyle(color: Colors.white38, fontSize: 14 * fontScale),
                    prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF3B46F1)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white60,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: Color(0xFF1A1A1A),
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFF333333)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFF333333)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFF3B46F1), width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red.shade400),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red.shade400, width: 2),
                    ),
                  ),
                ),
                SizedBox(height: size.height * 0.015),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: _forgotPassword,
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Color(0xFF3B46F1),
                        fontSize: 14 * fontScale,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: size.height * 0.035),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFormValid && !_isLoading
                          ? const Color(0xFF3B46F1)
                          : const Color(0xFF3B46F1).withOpacity(0.5),
                      foregroundColor: Colors.white,
                      minimumSize: Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      disabledBackgroundColor: const Color(0xFF3B46F1).withOpacity(0.5),
                      disabledForegroundColor: Colors.white.withOpacity(0.7),
                    ),
                    onPressed: (_isFormValid && !_isLoading) ? _signInWithEmailAndPassword : null,
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 18 * fontScale,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: size.height * 0.03),
                Row(
                  children: [
                    Expanded(child: Divider(color: Color(0xFF333333), thickness: 1)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 14 * fontScale,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Color(0xFF333333), thickness: 1)),
                  ],
                ),
                SizedBox(height: size.height * 0.03),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Google Sign-In Button with local SVG
                    GestureDetector(
                      onTap: () {
                        // Action to perform on tap, if any (e.g., show a toast)
                        _showErrorSnackBar('Google Sign-In is currently disabled.');
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Color(0xFF333333)),
                        ),
                        child: SvgPicture.asset(
                          'assets/images/svg/google.svg',
                          width: 20,
                          height: 20,
                        ),
                      ),
                    ),
                    SizedBox(width: 20),
                    // Apple Sign-In Button with local SVG
                    GestureDetector(
                      onTap: () {
                        // Action to perform on tap, if any (e.g., show a toast)
                        _showErrorSnackBar('Apple Sign-In is currently disabled.');
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Color(0xFF333333)),
                        ),
                        child: SvgPicture.asset(
                          'assets/images/svg/apple.svg',
                          width: 20,
                          height: 20,
                          colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: size.height * 0.04),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'New to Spot Share? ',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 14 * fontScale,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        GoRouter.of(context).goNamed(AppRouterConstants.authSignIn);
                      },
                      child: Text(
                        'Sign up',
                        style: TextStyle(
                          color: Color(0xFF3B46F1),
                          fontWeight: FontWeight.w600,
                          fontSize: 14 * fontScale,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: size.height * 0.04),
              ],
            ),
          ),
        ),
      ),
    );
  }
}