// otp_verification_screen.dart
import 'dart:convert';

import 'package:bfp_record_mapping/api/api_key.dart';
import 'package:flutter/material.dart';

class OTPVerificationScreen extends StatefulWidget {
  final Map<String, dynamic> verParam;

  const OTPVerificationScreen({super.key, required this.verParam});

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  int _resendTimer = 60;
  bool _canResend = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    _canResend = false;
    _resendTimer = 60;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        if (_resendTimer > 0) {
          _resendTimer--;
        } else {
          _canResend = true;
        }
      });
      return _resendTimer > 0;
    });
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.length != 6) {
      setState(() {
        _errorMessage = 'Please enter 6-digit OTP';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiPhp(tableName: "").insert(
        subUrl: "http://192.168.11.150/mapping/verify_otp.php",
        jsonParam: jsonEncode({
          "user_id": widget.verParam["userId"],
          "otp": widget.verParam["generatedOtp"],
          "device_key": widget.verParam["deviceKey"],
        }),
      );
      print("result $result");

      setState(() => _isLoading = false);

      if (result["success"]) {
        _showSuccessDialog();
      } else {
        setState(() {
          _errorMessage = result["message"] ?? "Invalid OTP";
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Connection error";
      });
    }
  }

  Future<void> _resendOTP() async {
    // Your resend logic here
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 16),
            const Text(
              'Verified!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text('Your account has been successfully verified.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFFE31E24)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive layout
    final Size screenSize = MediaQuery.of(context).size;
    final bool isWeb = screenSize.width > 600;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF263238)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Verify OTP',
            style: TextStyle(
              color: Color(0xFF263238),
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: false,
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWeb ? constraints.maxWidth * 0.1 : 20,
                  vertical: 20,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 80,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (isWeb) ...[
                          const Center(
                            child: Icon(
                              Icons.smartphone,
                              color: Color(0xFFE31E24),
                              size: 80,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Header Text
                        Center(
                          child: Text(
                            'Enter Verification Code',
                            style: TextStyle(
                              fontSize: isWeb ? 32 : 28,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF263238),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'We sent a 6-digit code to',
                            style: TextStyle(
                              fontSize: isWeb ? 18 : 16,
                              color: const Color(0xFF607D8B),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Center(
                          child: Text(
                            widget.verParam["phone"] ?? '',
                            style: TextStyle(
                              fontSize: isWeb ? 20 : 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFE31E24),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // OTP Input
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _errorMessage != null
                                  ? const Color(0xFFE31E24)
                                  : Colors.transparent,
                            ),
                          ),
                          child: TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isWeb ? 40 : 32,
                              letterSpacing: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: const InputDecoration(
                              hintText: '------',
                              hintStyle: TextStyle(
                                color: Color(0xFFB0BEC5),
                                fontSize: 32,
                                letterSpacing: 8,
                              ),
                              border: InputBorder.none,
                              counterText: '',
                            ),
                            onChanged: (value) {
                              if (value.length == 6) {
                                _verifyOTP();
                              }
                            },
                          ),
                        ),

                        if (_errorMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Color(0xFFE31E24),
                              fontSize: 14,
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Verify Button
                        SizedBox(
                          height: isWeb ? 60 : 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _verifyOTP,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE31E24),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'VERIFY OTP',
                                    style: TextStyle(
                                      fontSize: isWeb ? 18 : 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Resend
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Didn't receive code? ",
                                style: TextStyle(
                                  fontSize: isWeb ? 16 : 14,
                                  color: const Color(0xFF607D8B),
                                ),
                              ),
                              GestureDetector(
                                onTap: _resendOTP,
                                child: Text(
                                  _canResend
                                      ? 'Resend'
                                      : 'Resend in $_resendTimer',
                                  style: TextStyle(
                                    fontSize: isWeb ? 16 : 14,
                                    color: _canResend
                                        ? const Color(0xFFE31E24)
                                        : const Color(0xFFB0BEC5),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (isWeb) ...[
                          const SizedBox(height: 40),
                          const Center(
                            child: Text(
                              'Having trouble? Contact BFP Support',
                              style: TextStyle(
                                color: Color(0xFF607D8B),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
