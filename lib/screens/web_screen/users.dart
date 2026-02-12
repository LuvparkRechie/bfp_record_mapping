import 'package:bfp_record_mapping/api/api_key.dart' show ApiPhp;
import 'package:flutter/material.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  _UsersScreenState createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  // Sample users data
  List _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() async {
    final result = await ApiPhp(tableName: "users").select();

    if (result["success"]) {
      setState(() {
        _users = result["data"];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter users based on search
    final filteredUsers = _users.where((user) {
      if (_searchText.isEmpty) return true;
      final fullName = user['full_name'].toString().toLowerCase();
      final email = user['email'].toString().toLowerCase();
      final mobile = user['mobile_no'].toString().toLowerCase();
      final role = user['role'].toString().toLowerCase();
      final searchLower = _searchText.toLowerCase();

      return fullName.contains(searchLower) ||
          email.contains(searchLower) ||
          mobile.contains(searchLower) ||
          role.contains(searchLower);
    }).toList();

    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Search and Actions
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText:
                          'Search users by name, email, phone, or role...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchText = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                _buildFilterButton(),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showAddUserDialog(context),
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Add User'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    backgroundColor: Colors.green[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // DataTable with Scroll
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Scrollbar(
                  controller: _scrollController,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.resolveWith(
                          (states) => Colors.grey[50]!,
                        ),
                        headingRowHeight: 56,
                        dataRowHeight: 64,
                        horizontalMargin: 24,
                        columnSpacing: 32,
                        border: TableBorder(
                          horizontalInside: BorderSide(
                            color: Colors.grey[100]!,
                            width: 1,
                          ),
                          bottom: BorderSide(color: Colors.grey[200]!),
                        ),
                        headingTextStyle: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                          fontSize: 13,
                        ),
                        columns: const [
                          DataColumn(label: Text('ID'), numeric: true),
                          DataColumn(
                            label: Text('FULL NAME'),
                            tooltip: 'User full name',
                          ),
                          DataColumn(
                            label: Text('EMAIL'),
                            tooltip: 'Email address',
                          ),
                          DataColumn(
                            label: Text('MOBILE NO'),
                            tooltip: 'Mobile number',
                          ),
                          DataColumn(label: Text('ROLE'), tooltip: 'User role'),
                          DataColumn(
                            label: Text('STATUS'),
                            tooltip: 'Active/Inactive status',
                          ),
                          DataColumn(
                            label: Text('CREATED'),
                            tooltip: 'Creation date',
                          ),
                          DataColumn(
                            label: Text('ACTIONS'),
                            tooltip: 'User actions',
                          ),
                        ],
                        rows: filteredUsers.map((user) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '#${user['id'].toString().padLeft(3, '0')}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 180,
                                  child: Text(
                                    user['full_name'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[900],
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 200,
                                  child: Text(
                                    user['email'],
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  "${user['mobile_no']}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  // decoration: BoxDecoration(
                                  //   color: _getRoleColor(user['role']),
                                  //   borderRadius: BorderRadius.circular(20),
                                  // ),
                                  child: Text(
                                    "${user['role']}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),

                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [],
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  user['created_at'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () => _viewUserDetails(user),
                                      icon: Icon(
                                        Icons.visibility_outlined,
                                        size: 20,
                                        color: Colors.blue[600],
                                      ),
                                      tooltip: 'View Details',
                                    ),
                                    IconButton(
                                      onPressed: () => _editUser(user),
                                      icon: Icon(
                                        Icons.edit_outlined,
                                        size: 20,
                                        color: Colors.orange[600],
                                      ),
                                      tooltip: 'Edit User',
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          _toggleUserStatus(user['id']),
                                      icon: Icon(
                                        Icons.delete,
                                        size: 28,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Pagination/Footer
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Showing ${filteredUsers.length} of ${_users.length} users',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  Row(
                    children: [
                      Text(
                        'Rows per page:',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: 10,
                        items: [5, 10, 25, 50].map((int value) {
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text('$value'),
                          );
                        }).toList(),
                        onChanged: (value) {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Filter Button
  Widget _buildFilterButton() {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.filter_list, size: 18),
            SizedBox(width: 4),
            Text('Filter'),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'active',
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text('Active Users'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'inactive',
          child: Row(
            children: [
              Icon(Icons.pause_circle, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text('Inactive Users'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'admin',
          child: Row(
            children: [
              Icon(Icons.admin_panel_settings, color: Colors.purple, size: 20),
              SizedBox(width: 8),
              Text('Admins'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'user',
          child: Row(
            children: [
              Icon(Icons.person, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text('Regular Users'),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        // Handle filter selection
        print('Filter selected: $value');
      },
    );
  }

  // Show Add User Dialog
  void _showAddUserDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final fullNameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final mobileController = TextEditingController();
    String selectedRole = 'Admin';

    showDialog(
      context: context,

      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Add New User',
          style: TextStyle(color: Colors.black, fontSize: 20),
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: mobileController,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter mobile number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.assignment_ind),
                  ),
                  items: ['Admin', 'Staff', 'Inspector'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedRole = value!;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                // Add new user
                try {
                  final newUser = {
                    'full_name': fullNameController.text,
                    'email': emailController.text,
                    'password': passwordController.text,
                    'mobile_no': mobileController.text,
                    'role': selectedRole,
                    'is_active': "Y",
                    'created_at': DateTime.now().toString().split(' ')[0],
                  };
                  final result = await ApiPhp(
                    tableName: "users",
                    parameters: newUser,
                  ).insert();

                  if (result["success"]) {
                    _loadUsers();

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'User "${fullNameController.text}" added successfully!',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  print("cathce $e");
                }
                // print("result $result");
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600]),
            child: const Text('Add User'),
          ),
        ],
      ),
    );
  }

  // View User Details
  void _viewUserDetails(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('User Details: ${user['full_name']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Full Name', user['full_name'].toString()),
              _buildDetailRow('Email', user['email'].toString()),
              _buildDetailRow('Mobile No', user['mobile_no'].toString()),
              _buildDetailRow('Role', user['role'].toString()),
              _buildDetailRow('Status', user['is_active'].toString()),
              _buildDetailRow('Created At', user['created_at'].toString()),
              _buildDetailRow(
                'User ID',
                '#${user['id'].toString().padLeft(3, '0')}',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Build Detail Row
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }

  // Edit User
  void _editUser(Map<String, dynamic> user) {
    // Implement edit functionality
    print('Edit user: ${user['id']}');
  }

  // Toggle User Status
  void _toggleUserStatus(userId) {}

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
