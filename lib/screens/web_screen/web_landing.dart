import 'package:bfp_record_mapping/screens/app_theme.dart';
import 'package:bfp_record_mapping/screens/web_screen/bfp_records.dart';
import 'package:bfp_record_mapping/screens/web_screen/establishments.dart';
import 'package:bfp_record_mapping/screens/web_screen/reports.dart';
import 'package:bfp_record_mapping/screens/web_screen/users.dart';
import 'package:flutter/material.dart';

class WebLandingPage extends StatefulWidget {
  final Map<String, dynamic> userData; // Add user data parameter

  const WebLandingPage({Key? key, required this.userData}) : super(key: key);

  @override
  _WebLandingPageState createState() => _WebLandingPageState();
}

class _WebLandingPageState extends State<WebLandingPage> {
  bool sidebarOpen = true; // Start open for web
  String selectedMenu = 'reports';

  final List<Map<String, dynamic>> menuItems = [
    {
      'id': 'reports',
      'icon': Icons.dashboard,
      'label': 'Reports',
      'widget': const ReportsScreen(),
    },
    {
      'id': 'records',
      'icon': Icons.list_alt,
      'label': 'BFP Records',
      'widget': const BrgyScreen(),
    },
    {
      'id': 'establishments',
      'icon': Icons.business,
      'label': 'Establishments',
      'widget': const EstablishmentScreen(),
    },
    {
      'id': 'users',
      'icon': Icons.people,
      'label': 'Users',
      'widget': const UsersScreen(),
    },
    {
      'id': 'settings',
      'icon': Icons.settings,
      'label': 'Settings',
      'widget': const BrgyScreen(),
    },
  ];

  Widget get currentScreen {
    final item = menuItems.firstWhere(
      (item) => item['id'] == selectedMenu,
      orElse: () => menuItems[0],
    );
    return item['widget'] as Widget;
  }

  String get currentTitle {
    final item = menuItems.firstWhere(
      (item) => item['id'] == selectedMenu,
      orElse: () => menuItems[0],
    );
    return item['label'] as String;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Row(
        children: [
          // Enhanced Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: sidebarOpen ? 280 : 80,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.primaryRed, AppColors.darkRed],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                // Enhanced Header with Logo and User Info
                Container(
                  padding: EdgeInsets.all(sidebarOpen ? 20 : 12),
                  child: Column(
                    children: [
                      // Logo Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                "assets/bfp_logo.jpg",
                                width: sidebarOpen ? 50 : 35,
                                height: sidebarOpen ? 50 : 35,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: sidebarOpen ? 50 : 35,
                                    height: sidebarOpen ? 50 : 35,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.local_fire_department,
                                      color: AppColors.primaryRed,
                                      size: sidebarOpen ? 30 : 20,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          if (sidebarOpen) ...[
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'BFP',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                                Text(
                                  'Bureau of Fire Protection',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),

                      if (sidebarOpen) ...[
                        const SizedBox(height: 20),

                        // 👤 USER INFO SECTION - ENHANCED
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              // User Avatar
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.person_outline,
                                  color: Colors.amber.shade300,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // User Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.userData['full_name'] ??
                                          'Admin User',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            widget.userData['role'] == 'Admin'
                                            ? Colors.purple.withOpacity(0.2)
                                            : Colors.blue.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        widget.userData['role'] ?? 'Admin',
                                        style: TextStyle(
                                          color:
                                              widget.userData['role'] == 'Admin'
                                              ? Colors.purple.shade200
                                              : Colors.blue.shade200,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Online Status
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.5),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Divider
                Container(
                  height: 1,
                  margin: EdgeInsets.symmetric(
                    horizontal: sidebarOpen ? 20 : 8,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                // Sidebar Menu Items - Enhanced
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    children: menuItems.map((item) {
                      return _buildSidebarMenuItem(
                        icon: item['icon'] as IconData,
                        label: item['label'] as String,
                        isActive: selectedMenu == item['id'],
                        onTap: () {
                          setState(() {
                            selectedMenu = item['id'] as String;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),

                // Logout Button - Enhanced
                Container(
                  margin: EdgeInsets.all(sidebarOpen ? 16 : 8),
                  child: InkWell(
                    onTap: () => _showLogoutDialog(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: sidebarOpen ? 20 : 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red.shade800, Colors.red.shade900],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          if (sidebarOpen) ...[
                            const SizedBox(width: 12),
                            Text(
                              'Logout',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Content Area with Header
          Expanded(
            child: Column(
              children: [
                // Top Bar with Page Title and Quick Actions
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        menuItems.firstWhere(
                          (item) => item['id'] == selectedMenu,
                        )['icon'],
                        color: AppColors.primaryRed,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        currentTitle,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      // Quick Actions
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.notifications_none,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryRed,
                                shape: BoxShape.circle,
                              ),
                              child: const Text(
                                '3',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Page Content
                Expanded(child: currentScreen),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced Sidebar Menu Item
  Widget _buildSidebarMenuItem({
    required IconData icon,
    required String label,
    bool isActive = false,
    required Function onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: isActive
            ? LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: sidebarOpen ? 16 : 8,
              vertical: 14,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: isActive
                        ? Colors.white
                        : Colors.white.withOpacity(0.8),
                    size: 22,
                  ),
                ),
                if (sidebarOpen) ...[
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isActive
                            ? Colors.white
                            : Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (isActive)
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Logout Confirmation Dialog
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: Text(
          'Are you sure you want to logout, ${widget.userData['full_name']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Implement logout logic
              Navigator.pop(context);
              // Navigate to login screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
