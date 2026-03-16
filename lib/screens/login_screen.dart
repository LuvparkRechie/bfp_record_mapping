import 'dart:convert';
import 'dart:math';

import 'package:bfp_record_mapping/api/api_key.dart';
import 'package:bfp_record_mapping/api/path_variables.dart';
import 'package:bfp_record_mapping/screens/app_theme.dart';
import 'package:bfp_record_mapping/screens/inspector_screen/assigned_task.dart';
import 'package:bfp_record_mapping/screens/otp_scren.dart';
import 'package:bfp_record_mapping/screens/terms_conditions.dart';
import 'package:bfp_record_mapping/screens/web_screen/web_landing.dart';
import 'package:bfp_record_mapping/shared_pref.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _isAgree = false;
  Future<String> _generateOTP(userData) async {
    Random random = Random();
    int otp = 100000 + random.nextInt(900000);

    final result = await ApiPhp(tableName: "").insert(
      subUrl: "${ApiKeys.pathVariable}${ApiKeys.otpHandler}",
      jsonParam: json.encode({
        "data": {
          "user_id": userData["id"],
          "otp": otp,
          "phone": userData["mobile_no"].toString(),
          "message":
              "Your OTP code for device registration is $otp. Do not share this code with anyone.",
          "device_key": await getUniqueDeviceId(),
        },
      }),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result["message"].toString()),
        backgroundColor: result["data"].isEmpty ? Colors.red : Colors.green,
      ),
    );

    return result["data"].isEmpty ? "" : otp.toString();
  }

  Future<String> getUniqueDeviceId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedDeviceId = prefs.getString('device_id');

    if (storedDeviceId == null) {
      var uuid = Uuid();
      storedDeviceId = uuid.v4();
      await prefs.setString('device_id', storedDeviceId);
    }

    return storedDeviceId;
  }

  void routeProcess(userData) {
    setState(() {
      _isLoading = false;
    });

    if (!kIsWeb && userData["role"] != "Inspector") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: Not supported for this account'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (kIsWeb && userData["role"] == "Inspector") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: Not supported for this account'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!kIsWeb && userData["role"] == "Inspector") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => InspAssignedTask()),
      );
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => WebLandingPage()),
    );
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() {
        _isLoading = true;
      });
      String deviceKey = await getUniqueDeviceId();
      final userData = await StoreCredentials().getUserData();
      final formData = _formKey.currentState!.value;
      final email = formData['email'];
      final password = formData['password'];

      final result = await ApiPhp(tableName: "users").insert(
        jsonParam: json.encode({
          'data': {'email': email, 'password': password},
        }),
        subUrl: "${ApiKeys.pathVariable}${ApiKeys.login}",
      );

      if (result["success"]) {
        if ((userData == null || userData["device_key"].toString().isEmpty) ||
            (result["data"]["user"]["device_key"].toString().isEmpty ||
                result["data"]["user"]["device_key"].toString() !=
                    userData["device_key"].toString())) {
          final otpCode = await _generateOTP(result["data"]["user"]);
          setState(() {
            _isLoading = false;
          });
          if (otpCode.isEmpty) {
            return;
          }
          final Map<String, dynamic> verParam = {
            "phone": result["data"]["user"]["mobile_no"].toString(),
            "userId": int.parse(result["data"]["user"]["id"].toString()),
            "deviceKey": deviceKey,
            "generatedOtp": otpCode.toString(),
          };

          final resData = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OTPVerificationScreen(verParam: verParam),
            ),
          );
          if (!mounted) return;
          print("resData $resData");
          if (resData == null) return;

          await StoreCredentials().saveUserData(result["data"]["user"]);
          routeProcess(result["data"]["user"]);
          return;
        }
        routeProcess(result["data"]["user"]);
        return;
      }
      _showErrorDialog(result["message"]);
      return;
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, AppColors.offWhite, const Color(0xFFFFF5F5)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo and Title Section
                    _buildLogoSection(),
                    const SizedBox(height: 30),

                    // Login Form Card
                    _buildLoginForm(),

                    const SizedBox(height: 20),

                    // Footer
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        // Animated Logo
        TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 800),
          curve: Curves.elasticOut,
          builder: (context, double scale, child) {
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: AppColors.redGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryRed.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Image(image: AssetImage("assets/bfp_logo.jpg")),
              ),
            );
          },
        ),
        const SizedBox(height: 20),

        // App Title
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'BFP ',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkRed,
                  letterSpacing: 1,
                ),
              ),
              TextSpan(
                text: 'Record',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryRed,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        Text(
          'Mapping System',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Fire Safety & Records Management',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.primaryRed,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AppColors.lightGrey.withOpacity(0.2),
            blurRadius: 30,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: AppColors.lightGrey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Welcome Text
          Text(
            'Welcome Back!',
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.darkRed,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Sign in to continue',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.grey,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),

          FormBuilder(
            key: _formKey,
            child: Column(
              children: [
                // Email Field
                FormBuilderTextField(
                  name: 'email',
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'Enter your email',
                    labelStyle: TextStyle(color: AppColors.darkGrey),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: AppColors.primaryRed,
                      size: 20,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: AppColors.lightGrey),
                    ),
                    enabledBorder: OutlineInputBorder(
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
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: AppColors.error),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: AppColors.error, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColors.offWhite,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(
                      errorText: 'Email is required',
                    ),
                    FormBuilderValidators.email(
                      errorText: 'Enter a valid email address',
                    ),
                  ]),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: 20),

                // Password Field
                FormBuilderTextField(
                  name: 'password',
                  obscureText: !_passwordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    labelStyle: TextStyle(color: AppColors.darkGrey),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: AppColors.primaryRed,
                      size: 20,
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
                    enabledBorder: OutlineInputBorder(
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
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: AppColors.error),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: AppColors.error, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColors.offWhite,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
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
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _isAgree ? _handleLogin() : null,
                ),

                const SizedBox(height: 12),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _handleForgotPassword,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryRed,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: AppColors.primaryRed,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Login Button
                SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading || !_isAgree ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_isAgree
                          ? AppColors.primaryRed.withValues(alpha: 0.5)
                          : AppColors.primaryRed,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shadowColor: AppColors.primaryRed.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.login, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                'Sign In',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // Divider
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        // Security Notice
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryRed.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.primaryRed.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.security, color: AppColors.primaryRed, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Official BFP personnel only. Unauthorized access is prohibited.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.darkRed,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Terms and Privacy
        Row(
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                setState(() {
                  _isAgree = !_isAgree;
                });
              },
              icon: Icon(
                _isAgree ? Icons.check_box : Icons.check_box_outline_blank,
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => BFPTermsDialog(
                        onAccept: (d) {
                          print("dd $d");
                          setState(() {
                            _isAgree = true;
                          });
                        },
                      ),
                    ),
                  );
                },
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.grey,
                      height: 1.4,
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
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Version
        Text(
          'Version 1.0.0',
          style: TextStyle(
            fontSize: 10,
            color: AppColors.grey.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
