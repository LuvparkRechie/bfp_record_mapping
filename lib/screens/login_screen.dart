import 'package:bfp_record_mapping/screens/app_theme.dart';
import 'package:bfp_record_mapping/screens/web_screen/web_landing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;
  bool _passwordVisible = false;

  Future<void> _handleLogin() async {
    // if (_formKey.currentState?.saveAndValidate() ?? false) {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 2));

    final formData = _formKey.currentState!.value;
    final email = formData['email'];
    final password = formData['password'];

    // Simulate successful login
    setState(() {
      _isLoading = false;
    });
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => WebLandingPage()),
    );
    // }
  }

  void _handleForgotPassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reset Password',
          style: TextStyle(color: AppColors.darkRed),
        ),
        content: const Text(
          'A password reset link will be sent to your email address.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Password reset email sent!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
            ),
            child: const Text('Send Email'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, AppColors.offWhite, Color(0xFFFFF5F5)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1200),
              padding: const EdgeInsets.all(24),
              child: isDesktop
                  ? Row(
                      children: [
                        // Left side - Brand/Info
                        Expanded(child: _buildLeftSide()),
                        const SizedBox(width: 60),
                        // Right side - Login Form
                        Expanded(child: _buildLoginForm()),
                      ],
                    )
                  : Column(
                      children: [
                        // Logo and title for mobile
                        _buildMobileHeader(),
                        const SizedBox(height: 40),
                        // Login Form
                        _buildLoginForm(),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeftSide() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo with red gradient
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: AppColors.redGradient,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryRed.withOpacity(0.3),
                blurRadius: 25,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.local_fire_department,
            size: 50,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 30),

        // App Title with red accent
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'BFP ',
                style: GoogleFonts.poppins(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkRed,
                  letterSpacing: 1.5,
                ),
              ),
              TextSpan(
                text: 'Record\n',
                style: GoogleFonts.poppins(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryRed,
                  letterSpacing: 1.5,
                ),
              ),
              TextSpan(
                text: 'Mapping',
                style: GoogleFonts.poppins(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  color: AppColors.black,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 15),

        // Tagline
        Text(
          'Fire Safety & Records Management System',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppColors.darkGrey,
            letterSpacing: 0.5,
          ),
        ),

        const SizedBox(height: 40),

        // Features list with red accents
        _buildFeatureItem(Icons.map_outlined, 'Fire Risk Mapping'),
        _buildFeatureItem(Icons.description_outlined, 'Digital Records'),
        _buildFeatureItem(Icons.security_outlined, 'Secure Access'),
        _buildFeatureItem(Icons.analytics_outlined, 'Fire Data Analytics'),
        _buildFeatureItem(Icons.report_outlined, 'Incident Reports'),
        _buildFeatureItem(
          Icons.assignment_turned_in_outlined,
          'Compliance Tracking',
        ),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryRed, size: 20),
          ),
          const SizedBox(width: 16),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.darkGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: AppColors.redGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryRed.withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 3,
              ),
            ],
          ),
          child: const Icon(
            Icons.local_fire_department,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'BFP ',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkRed,
                ),
              ),
              TextSpan(
                text: 'Record Mapping',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to continue',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AppColors.lightGrey.withOpacity(0.15),
            blurRadius: 40,
            spreadRadius: 5,
          ),
        ],
        border: Border.all(
          color: AppColors.lightGrey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Welcome back with red accent
          Text(
            'Welcome Back',
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.darkRed,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            'Enter your credentials to access the system',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.grey,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 40),

          FormBuilder(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Email Field
                FormBuilderTextField(
                  name: 'email',
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    labelStyle: TextStyle(color: AppColors.darkGrey),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: AppColors.primaryRed,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: AppColors.lightGrey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(
                        color: AppColors.primaryRed,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.offWhite,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                  ),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(
                      errorText: 'Email is required',
                    ),
                    FormBuilderValidators.email(
                      errorText: 'Enter a valid email',
                    ),
                  ]),
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 24),

                // Password Field
                FormBuilderTextField(
                  name: 'password',
                  obscureText: !_passwordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: AppColors.darkGrey),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: AppColors.primaryRed,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: AppColors.primaryRed,
                      ),
                      onPressed: () {
                        setState(() {
                          _passwordVisible = !_passwordVisible;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: AppColors.lightGrey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(
                        color: AppColors.primaryRed,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.offWhite,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                  ),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(
                      errorText: 'Password is required',
                    ),
                    FormBuilderValidators.minLength(
                      6,
                      errorText: 'Password must be at least 6 characters',
                    ),
                  ]),
                ),

                const SizedBox(height: 16),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _handleForgotPassword,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryRed,
                    ),
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: AppColors.primaryRed,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Login Button with red gradient
                SizedBox(
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: Colors.white,
                      elevation: 5,
                      shadowColor: AppColors.primaryRed.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.login, size: 22),
                              const SizedBox(width: 12),
                              Text(
                                'Sign In',
                                style: GoogleFonts.poppins(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 25),

                // Divider
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: AppColors.lightGrey, thickness: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: AppColors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: AppColors.lightGrey, thickness: 1),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // Demo Login Button
                SizedBox(
                  height: 60,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () {
                            _formKey.currentState?.patchValue({
                              'email': 'officer@bfp.gov.ph',
                              'password': 'bfp12345',
                            });
                          },
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('Use Demo Credentials'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primaryRed),
                      foregroundColor: AppColors.primaryRed,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Footer Text
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.grey,
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(text: 'By signing in, you agree to our '),
                      TextSpan(
                        text: 'Terms of Service',
                        style: TextStyle(
                          color: AppColors.primaryRed,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(
                          color: AppColors.primaryRed,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                // Official BFP Notice
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryRed.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.security,
                        color: AppColors.primaryRed,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Official BFP personnel only. Unauthorized access is prohibited.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.darkRed,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
