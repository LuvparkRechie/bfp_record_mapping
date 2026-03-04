import 'dart:typed_data';

import 'package:bfp_record_mapping/api/api_key.dart' show ApiPhp;
import 'package:bfp_record_mapping/customs/loading_dialog.dart';
import 'package:bfp_record_mapping/screens/app_theme.dart';
import 'package:bfp_record_mapping/screens/signature/signature.dart';
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
            const SizedBox(height: 16),

            // DataTable with Scroll
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Scrollbar(
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
                              DataColumn(
                                label: Text('ROLE'),
                                tooltip: 'User role',
                              ),
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
                                          onPressed: () =>
                                              _viewUserDetails(user),
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
                                          onPressed: () => _toggleUserStatus(
                                            user['id'],
                                            user["signature_path"],
                                          ),
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
                    SizedBox(width: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                      ),
                      onPressed: () async {
                        // Navigate to the add user screen
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AddUserScreen(onUserAdded: _loadUsers),
                          ),
                        );
                      },
                      child: const Text(
                        'Add User',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
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
    LoadingDialog.show(
      title: 'Loading',
      message: 'Please wait...',
      context: context,
    );
  }

  // Toggle User Status
  void _toggleUserStatus(userId, signaturePath) async {
    LoadingDialog.show(
      title: 'Loading',
      message: 'Please wait...',
      context: context,
    );
    await ApiPhp.deleteSignatureFile(filePath: signaturePath);

    final response = await ApiPhp(
      tableName: "users",
      whereClause: {"id": userId},
    ).delete(); // Close loading dialog

    Navigator.of(context).pop();
    if (response["success"]) {
      _loadUsers();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

class AddUserScreen extends StatefulWidget {
  final Function() onUserAdded;

  const AddUserScreen({Key? key, required this.onUserAdded}) : super(key: key);

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _mobileController = TextEditingController();
  String _selectedRole = 'Admin';
  Uint8List? _repSignature;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _addUser() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate inspector signature
    if (_selectedRole.toLowerCase() == 'inspector' && _repSignature == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Signature is required for Inspector role'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final String fileName = _selectedRole.toLowerCase() == 'inspector'
        ? 'insp_signature_${_fullNameController.text.toLowerCase().replaceAll(" ", "").trim()}.png'
        : '';

    LoadingDialog.show(
      title: 'Loading',
      message: 'Please wait...',
      context: context,
    );

    try {
      String? signaturePath;

      // 1️⃣ FIRST: Upload signature if inspector (get the full path)
      if (_selectedRole.toLowerCase() == 'inspector' && _repSignature != null) {
        final uploadResult = await ApiPhp.uploadPngFile(
          signatureBytes: _repSignature!,
          fileName: fileName,
        );

        if (uploadResult != null && uploadResult["success"] == true) {
          signaturePath = uploadResult["file_path"];
        } else {
          // Close loading dialog
          Navigator.of(context).pop();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                uploadResult?["message"] ?? 'Signature upload failed',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
          return; // Stop if signature upload fails
        }
      }

      // 2️⃣ THEN: Create user with the full signature_path
      final newUser = {
        'full_name': _fullNameController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
        'mobile_no': _mobileController.text,
        'role': _selectedRole,
        'is_active': "Y",
        // ✅ Use the full path from upload, not just the filename
        'signature_path': signaturePath, // This is now the full path or null
      };

      final result = await ApiPhp(
        tableName: "users",
        parameters: newUser,
      ).insert();

      // Close loading dialog
      Navigator.of(context).pop();

      if (result["success"] == true) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'User "${_fullNameController.text}" added successfully!',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Refresh user list
        widget.onUserAdded();

        // Close this screen
        Navigator.pop(context);
      } else {
        // If user creation failed but signature was uploaded, clean up
        if (signaturePath != null) {
          await ApiPhp.deleteSignatureFile(
            filePath: signaturePath,
            isUpdate: true,
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${result["message"] ?? "Failed to add user"}',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenSize = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New User'),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Padding(
          padding: EdgeInsets.only(
            left: screenSize * 0.25,
            right: screenSize * 0.25,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 30),
                const Text(
                  "Users Registration",
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                    color: Colors.black45,
                  ),
                ),
                SizedBox(height: 30),
                // Full Name
                TextFormField(
                  controller: _fullNameController,
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

                // Email
                TextFormField(
                  controller: _emailController,
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

                // Password
                TextFormField(
                  controller: _passwordController,
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

                // Mobile Number
                TextFormField(
                  controller: _mobileController,
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

                // Role Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedRole,
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
                    setState(() {
                      _selectedRole = value!;
                    });
                  },
                ),

                if (_selectedRole.toLowerCase() == 'inspector') ...[
                  const SizedBox(height: 16),

                  // Signature Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Representative Signature",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignatureScreen(),
                              ),
                            );

                            if (result != null) {
                              setState(() {
                                _repSignature = result;
                              });
                            }
                          },
                          child: Container(
                            height: 100,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _repSignature == null
                                    ? Colors.grey.shade300
                                    : Colors.red.shade200,
                              ),
                            ),
                            child: _repSignature == null
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.draw_outlined,
                                        color: Colors.grey.shade600,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Tap to add signature",
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  )
                                : Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.memory(
                                          _repSignature!,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 4,
                                        right: 4,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: const Text(
                                            "Tap to change",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (_repSignature != null)
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _repSignature = null;
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.red.withOpacity(
                                                  0.8,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 30),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _addUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 30),
                        ),
                        child: const Text('Add User'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
