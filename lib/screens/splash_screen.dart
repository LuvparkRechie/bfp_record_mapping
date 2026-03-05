import 'dart:async';

import 'package:bfp_record_mapping/api/api_key.dart';
import 'package:bfp_record_mapping/api/path_variables.dart';
import 'package:bfp_record_mapping/database/checklist_db.dart';
import 'package:bfp_record_mapping/screens/app_theme.dart';
import 'package:bfp_record_mapping/screens/login_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _chkListDbHelper = ChecklistDatabase.instance;
  bool isNetConn = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    if (kIsWeb) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
      return;
    }
    try {
      final response = await ApiPhp(
        tableName: "checklist_templates",
      ).select(subURl: '${ApiKeys.pathVariable}${ApiKeys.chkTmplList}');

      final bool success =
          response["success"] == true || response["status"] == "success";

      if (success) {
        final data = response["data"] ?? [];

        List<dynamic> checklist = List<dynamic>.from(data);
        for (var dataRow in checklist) {
          await _chkListDbHelper.insertItem(dataRow);
        }
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen()),
        );
        return;
      } else {
        setState(() {
          isNetConn = false;
        });

        return;
      }
    } catch (e) {
      setState(() {
        isNetConn = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorDialog(e.toString());
      });
    }
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text('Failed to load checklist: $error'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('ok'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: !isNetConn
          ? Center(
              child: GestureDetector(
                onTap: () async {
                  setState(() {
                    isNetConn = true;
                  });
                  await Future.delayed(Duration(milliseconds: 500));
                  _initializeApp();
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons
                          .signal_wifi_statusbar_connected_no_internet_4_outlined,
                      size: 40,
                      color: Colors.red,
                    ),
                    SizedBox(height: 30),
                    Text(
                      'Network error: Connection failed.',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Please tap to retry',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Color(0xFFFCE4EC)],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Logo Container
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        gradient: AppColors.redGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryRed.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Fire animation effect
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 2000),
                            tween: Tween(begin: 0.5, end: 1.0),

                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        AppColors.accentRed.withOpacity(0.3),
                                        AppColors.primaryRed.withOpacity(0.1),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          // Icon
                          Center(
                            child: Icon(
                              Icons.fireplace,
                              size: 70,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  blurRadius: 10,
                                  color: AppColors.darkRed.withOpacity(0.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // App Title with Red Accent
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 800),
                      tween: Tween(begin: 0.0, end: 1.0),
                      curve: Curves.easeInOut,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'BFP ',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: AppColors.darkRed,
                                letterSpacing: 1.5,
                              ),
                            ),
                            TextSpan(
                              text: 'Record\n',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primaryRed,
                                letterSpacing: 1.5,
                              ),
                            ),
                            TextSpan(
                              text: 'Mapping',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: AppColors.black,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Subtitle with Red Accent
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1000),
                      tween: Tween(begin: 0.0, end: 1.0),
                      curve: Curves.easeInOut,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        'Fire Safety & Records Management',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.grey,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 60),

                    SizedBox(
                      width: 60,
                      height: 60,
                      child: Stack(
                        children: [
                          // Outer ring
                          Center(
                            child: SizedBox(
                              width: 50,
                              height: 50,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.lightRed.withOpacity(0.3),
                                ),
                              ),
                            ),
                          ),
                          // Inner spinning fire icon
                          Center(
                            child: TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 1500),
                              tween: Tween(begin: 0.0, end: 1.0),

                              builder: (context, value, child) {
                                return Transform.rotate(
                                  angle: value * 2 * 3.1416,
                                  child: child,
                                );
                              },
                              child: Icon(
                                Icons.local_fire_department,
                                size: 24,
                                color: AppColors.primaryRed,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Loading Text with Pulsing Red Animation
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1200),
                      tween: Tween(begin: 0.5, end: 1.0),

                      builder: (context, value, child) {
                        return Opacity(opacity: value, child: child);
                      },
                      child: Text(
                        'Initializing Fire Safety System...',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.primaryRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Version Info with Red Accent
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Version 1.0.0 • BFP Official',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.darkRed,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }
}
