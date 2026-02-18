import 'package:bfp_record_mapping/screens/app_theme.dart';
import 'package:bfp_record_mapping/screens/web_screen/brgy_screen.dart';
import 'package:bfp_record_mapping/screens/web_screen/establishments.dart';
import 'package:bfp_record_mapping/screens/web_screen/reports.dart';
import 'package:bfp_record_mapping/screens/web_screen/users.dart';
import 'package:flutter/material.dart';

class WebLandingPage extends StatefulWidget {
  const WebLandingPage({Key? key}) : super(key: key);

  @override
  _WebLandingPageState createState() => _WebLandingPageState();
}

class _WebLandingPageState extends State<WebLandingPage> {
  bool sidebarOpen = false;
  String selectedMenu = 'dashboard';

  final List<Map<String, dynamic>> menuItems = [
    {
      'id': 'reports',
      'icon': Icons.dashboard,
      'label': 'Reports',
      'widget': ReportsScreen(),
    },
    {
      'id': 'records',
      'icon': Icons.list_alt,
      'label': 'BFP Records',
      'widget': BrgyScreen(),
    },
    {
      'id': 'establishments',
      'icon': Icons.business,
      'label': 'Establishments',
      'widget': EstablishmentScreen(),
    },
    {
      'id': 'users',
      'icon': Icons.people,
      'label': 'Users',
      'widget': UsersScreen(),
    },
    {
      'id': 'settings',
      'icon': Icons.settings,
      'label': 'Settings',
      'widget': BrgyScreen(),
    },
  ];

  // Get current screen widget
  Widget get currentScreen {
    final item = menuItems.firstWhere(
      (item) => item['id'] == selectedMenu,
      orElse: () => menuItems[0],
    );
    return item['widget'] as Widget;
  }

  // Get current screen title
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
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Simplified Sidebar
          Container(
            width: sidebarOpen ? 220 : 70,
            height: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.primaryRed,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
              ],
            ),
            child: Column(
              children: [
                // Logo/Header - Simplified
                Container(
                  height: 80,
                  padding: EdgeInsets.symmetric(
                    horizontal: sidebarOpen ? 20 : 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: Colors.white,
                        size: 32,
                      ),
                      if (sidebarOpen) ...[
                        const SizedBox(width: 10),
                        Text(
                          'BFP',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Divider
                Container(
                  height: 1,
                  color: Colors.white.withOpacity(0.2),
                  margin: EdgeInsets.symmetric(
                    horizontal: sidebarOpen ? 16 : 8,
                  ),
                ),

                // Sidebar Menu Items - Simplified
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 20),
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

                // Logout Button
                Container(
                  margin: EdgeInsets.all(sidebarOpen ? 16 : 8),
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: sidebarOpen ? 16 : 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.darkRed,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout, color: Colors.white, size: 20),
                          if (sidebarOpen) ...[
                            const SizedBox(width: 10),
                            Text(
                              'Logout',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // Toggle Sidebar Button
                Container(
                  height: 50,
                  color: AppColors.darkRed,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        sidebarOpen = !sidebarOpen;
                      });
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          sidebarOpen
                              ? Icons.chevron_left
                              : Icons.chevron_right,
                          color: Colors.white,
                          size: 20,
                        ),
                        if (sidebarOpen) ...[
                          const SizedBox(width: 8),
                          Text(
                            'Collapse',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Content Area
          Expanded(child: currentScreen),
        ],
      ),
    );
  }

  // Simplified Sidebar Menu Item
  Widget _buildSidebarMenuItem({
    required IconData icon,
    required String label,
    bool isActive = false,
    required Function onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () {
          onTap();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: sidebarOpen ? 16 : 8,
            vertical: 12,
          ),
          child: Row(
            mainAxisAlignment: sidebarOpen
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              if (sidebarOpen) ...[
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
