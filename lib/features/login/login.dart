import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';
import 'package:spot_share2/core/constants/app_router_constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Future<void> _signInWithGoogle() async {
    setState(() { _isLoading = true; });
    try {
      // Use the new API for google_sign_in ^7.1.1
      if (GoogleSignIn.instance.supportsAuthenticate()) {
        final user = await GoogleSignIn.instance.authenticate();
        final serverAuth = await user.authorizationClient.authorizeServer([]);
        final idToken = serverAuth?.serverAuthCode;
        if (idToken == null) {
          throw Exception('Unable to retrieve Google server auth code.');
        }
        final credential = GoogleAuthProvider.credential(
          idToken: idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
        if (mounted) {
          GoRouter.of(context).goNamed(AppRouterConstants.bottomNav);
        }
      } else {
        throw Exception('Google Sign In not supported on this platform.');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign In failed: ${e.message}'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmailAndPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (mounted) {
        GoRouter.of(context).goNamed(AppRouterConstants.bottomNav);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage;
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'No user found with this email.';
            break;
          case 'wrong-password':
            errorMessage = 'Wrong password provided.';
            break;
          case 'invalid-email':
            errorMessage = 'The email address is not valid.';
            break;
          case 'user-disabled':
            errorMessage = 'This user account has been disabled.';
            break;
          default:
            errorMessage = 'Login failed: ${e.message}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
                
                // Logo with improved design
                Hero(
                  tag: 'app_logo',
                  child: Container(
                    width: logoSize,
                    height: logoSize,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF3B46F1), Color(0xFF5C6BF7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(logoSize * 0.3),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF3B46F1).withOpacity(0.3),
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'SS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: logoSize * 0.35,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: size.height * 0.05),
                
                // Welcome text with animation
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
                  'Sign in to see what\'s happening near you',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16 * fontScale,
                    color: Colors.white60,
                    height: 1.4,
                  ),
                ),
                
                SizedBox(height: size.height * 0.04),
                
                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
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
                
                // Password field
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
                
                SizedBox(height: size.height * 0.035),
                
                // Login button with loading state
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B46F1),
                      foregroundColor: Colors.white,
                      minimumSize: Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    onPressed: _isLoading ? null : _signInWithEmailAndPassword,
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
                            'Login',
                            style: TextStyle(
                              fontSize: 18 * fontScale,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                
                SizedBox(height: size.height * 0.03),
                
                // Divider
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
                
                // Google sign in button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      minimumSize: Size.fromHeight(56),
                      side: BorderSide(color: Color(0xFF333333)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Container(
                      padding: EdgeInsets.all(2),
                      child: Image.network(
                        'https://developers.google.com/identity/images/g-logo.png',
                        width: 20,
                        height: 20,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.g_mobiledata,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    label: Text(
                      'Continue with Google',
                      style: TextStyle(fontSize: 16 * fontScale),
                    ),
                    onPressed: _isLoading ? null : _signInWithGoogle,
                  ),
                ),
                
                SizedBox(height: size.height * 0.04),
                
                // Sign up link
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
                        GoRouter.of(context).goNamed(AppRouterConstants.authLogIn);
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