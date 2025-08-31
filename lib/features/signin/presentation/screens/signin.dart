import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:spot_share2/core/constants/app_router_constants.dart';
import 'package:spot_share2/features/auth/services/auth_services.dart';
import 'package:spot_share2/features/auth/services/base_services.dart';
import 'package:spot_share2/features/auth/services/firestore_services.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  UserType? _selectedUserType;

  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    // Add listeners to all controllers to update button state
    _nameController.addListener(_updateButtonState);
    _emailController.addListener(_updateButtonState);
    _passwordController.addListener(_updateButtonState);
    _confirmPasswordController.addListener(_updateButtonState);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _updateButtonState() {
    setState(() {
      // This will trigger a rebuild to update button state
    });
  }

  bool get _isFormValid {
    return _nameController.text.trim().isNotEmpty &&
           _emailController.text.trim().isNotEmpty &&
           _passwordController.text.trim().isNotEmpty &&
           _confirmPasswordController.text.trim().isNotEmpty &&
           _passwordController.text == _confirmPasswordController.text &&
           _selectedUserType != null &&
           _acceptTerms &&
           _isValidEmail(_emailController.text.trim()) &&
           _isValidPassword(_passwordController.text.trim()) &&
           _isValidName(_nameController.text.trim());
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidPassword(String password) {
    return password.length >= 8 && 
           RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(password);
  }

  bool _isValidName(String name) {
    return name.length >= 2;
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

  void _showSuccessSnackBar(String message, {Duration duration = const Duration(seconds: 2)}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Color(0xFF3B46F1),
        behavior: SnackBarBehavior.floating,
        duration: duration,
      ),
    );
  }

  Future<void> _signUpWithEmailAndPassword() async {
    if (!_validateFormAndUserType()) return;
    setState(() { _isLoading = true; });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();

      // Check if user already exists in either collection
      final existingUser = await _firestoreService.getUserByEmail(email);
      if (existingUser != null) {
        if (mounted) {
          _showErrorSnackBar('An account with this email already exists. Please sign in instead.');
        }
        return;
      }

      final userCredential = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
        userType: _selectedUserType!,
        phoneNumber: phone.isNotEmpty ? phone : null,
      );

      if (userCredential != null && userCredential.user != null) {
        // Save user data to appropriate collection based on user type
        await _firestoreService.saveUserData(
          uid: userCredential.user!.uid,
          email: email,
          name: name,
          userType: _selectedUserType!,
          phoneNumber: phone.isNotEmpty ? phone : null,
          isGoogleSignIn: false,
          emailVerified: userCredential.user!.emailVerified,
        );

        // Save registration analytics
        await _firestoreService.saveRegistrationAnalytics(
          uid: userCredential.user!.uid,
          email: email,
          userType: _selectedUserType!,
          isGoogleSignIn: false,
        );
        
        if (mounted) {
          _showSuccessSnackBar(
            'Account created successfully! Please verify your email to continue.',
            duration: Duration(seconds: 4)
          );
          GoRouter.of(context).goNamed(AppRouterConstants.authLogIn);
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage;
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = 'An account already exists with this email.';
            break;
          case 'invalid-email':
            errorMessage = 'The email address is not valid.';
            break;
          case 'weak-password':
            errorMessage = 'The password provided is too weak.';
            break;
          default:
            errorMessage = 'Signup failed: ${e.message}';
        }
        _showErrorSnackBar(errorMessage);
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

  bool _validateFormAndUserType() {
    if (_selectedUserType == null) {
      _showErrorSnackBar('Please select your account type');
      return false;
    }
    if (!_acceptTerms) {
      _showErrorSnackBar('Please accept the terms and conditions');
      return false;
    }
    if (!_formKey.currentState!.validate()) {
      return false;
    }
    return true;
  }

  Widget _buildCompactUserTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Type',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedUserType = UserType.landOwner;
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _selectedUserType == UserType.landOwner
                        ? Color(0xFF3B46F1).withOpacity(0.2)
                        : Color(0xFF1A1A1A),
                    border: Border.all(
                      color: _selectedUserType == UserType.landOwner
                          ? Color(0xFF3B46F1)
                          : Color(0xFF333333),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.business,
                        color: _selectedUserType == UserType.landOwner
                            ? Color(0xFF3B46F1)
                            : Colors.white60,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Land Owner',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedUserType = UserType.driver;
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _selectedUserType == UserType.driver
                        ? Color(0xFF3B46F1).withOpacity(0.2)
                        : Color(0xFF1A1A1A),
                    border: Border.all(
                      color: _selectedUserType == UserType.driver
                          ? Color(0xFF3B46F1)
                          : Color(0xFF333333),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.directions_car,
                        color: _selectedUserType == UserType.driver
                            ? Color(0xFF3B46F1)
                            : Colors.white60,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Driver',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = size.width * 0.08;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 10),
                // Compact Logo
                Image.asset(
                  'assets/images/png/spotshare2.png',
                  width: 120,
                  height: 120,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF3B46F1), Color(0xFF5C6BF7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'SS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                // Title
                Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Join Spot Share and start sharing parking spaces',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white60,
                  ),
                ),
                SizedBox(height: 20),
                
                // Compact User Type Selector
                _buildCompactUserTypeSelector(),
                SizedBox(height: 16),
                
                // Name field
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    labelStyle: TextStyle(color: Colors.white70, fontSize: 12),
                    hintText: 'Enter your full name',
                    hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
                    prefixIcon: Icon(Icons.person_outline, color: Color(0xFF3B46F1), size: 18),
                    filled: true,
                    fillColor: Color(0xFF1A1A1A),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Color(0xFF333333)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Color(0xFF333333)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Color(0xFF3B46F1), width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.red.shade400),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                
                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.white70, fontSize: 12),
                    hintText: 'Enter your email',
                    hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
                    prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF3B46F1), size: 18),
                    filled: true,
                    fillColor: Color(0xFF1A1A1A),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Color(0xFF333333)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Color(0xFF333333)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Color(0xFF3B46F1), width: 1.5),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                
                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Password is required';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
                      return 'Password must contain uppercase, lowercase, and number';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: Colors.white70, fontSize: 12),
                    hintText: 'Create a strong password',
                    hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
                    prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF3B46F1), size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white60,
                        size: 18,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: Color(0xFF1A1A1A),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Color(0xFF333333)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Color(0xFF333333)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Color(0xFF3B46F1), width: 1.5),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                
                // Confirm Password field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    labelStyle: TextStyle(color: Colors.white70, fontSize: 12),
                    hintText: 'Re-enter your password',
                    hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
                    prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF3B46F1), size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white60,
                        size: 18,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: Color(0xFF1A1A1A),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Color(0xFF333333)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Color(0xFF333333)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Color(0xFF3B46F1), width: 1.5),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                
                // Compact Terms checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Transform.scale(
                      scale: 0.8,
                      child: Checkbox(
                        value: _acceptTerms,
                        onChanged: (value) {
                          setState(() {
                            _acceptTerms = value ?? false;
                          });
                        },
                        activeColor: Color(0xFF3B46F1),
                        checkColor: Colors.white,
                        side: BorderSide(color: Color(0xFF333333)),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white60,
                            ),
                            children: [
                              TextSpan(text: 'I agree to the '),
                              TextSpan(
                                text: 'Terms of Service',
                                style: TextStyle(
                                  color: Color(0xFF3B46F1),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                  color: Color(0xFF3B46F1),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5),
                
                // Create Account button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFormValid && !_isLoading
                          ? const Color(0xFF3B46F1)
                          : const Color(0xFF3B46F1).withOpacity(0.5),
                      foregroundColor: Colors.white,
                      minimumSize: Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                      disabledBackgroundColor: const Color(0xFF3B46F1).withOpacity(0.5),
                      disabledForegroundColor: Colors.white.withOpacity(0.7),
                    ),
                    onPressed: (_isFormValid && !_isLoading) ? _signUpWithEmailAndPassword : null,
                    child: _isLoading
                        ? SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 10),
                
                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Color(0xFF333333), thickness: 1)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Color(0xFF333333), thickness: 1)),
                  ],
                ),
                SizedBox(height: 10),
                
                // Compact Social login buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        _showErrorSnackBar('Google Sign-Up is currently disabled.');
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Color(0xFF333333)),
                        ),
                        child: SvgPicture.asset(
                          'assets/images/svg/google.svg',
                          width: 20,
                          height: 20,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        _showErrorSnackBar('Apple Sign-Up is currently disabled.');
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(10),
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
                SizedBox(height: 20),
                
                // Sign in link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        GoRouter.of(context).goNamed(AppRouterConstants.authLogIn);
                      },
                      child: Text(
                        'Sign in',
                        style: TextStyle(
                          color: Color(0xFF3B46F1),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}