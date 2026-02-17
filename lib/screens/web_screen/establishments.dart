// establishment_screen.dart - Updated with complete form screen
import 'package:bfp_record_mapping/api/api_key.dart';
import 'package:bfp_record_mapping/customs/loading_dialog.dart';
import 'package:bfp_record_mapping/screens/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class EstablishmentScreen extends StatefulWidget {
  const EstablishmentScreen({super.key});

  @override
  State<EstablishmentScreen> createState() => _EstablishmentScreenState();
}

class _EstablishmentScreenState extends State<EstablishmentScreen> {
  int _selectedIndex = 0;
  bool _isLoading = false;
  List _establishments = [];
  String _searchQuery = '';
  String _selectedFilter = 'All';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadEstablishments();
  }

  Future<void> _loadEstablishments() async {
    setState(() => _isLoading = true);
    final result = await ApiPhp(tableName: "establishments").select();
    _establishments = result["data"];

    setState(() => _isLoading = false);
  }

  List get _filteredEstablishments {
    var filtered = _establishments;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((establishment) {
        final businessName =
            establishment['business_name']?.toLowerCase() ?? '';
        final ownerName = establishment['owner_name']?.toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();

        return businessName.contains(query) || ownerName.contains(query);
      }).toList();
    }

    if (_selectedFilter != 'All') {
      filtered = filtered.where((establishment) {
        return establishment['establishment_status'] ==
            _selectedFilter.toUpperCase();
      }).toList();
    }

    return filtered;
  }

  void _addNewEstablishment() {
    setState(() => _selectedIndex = 1);
  }

  void _editEstablishment(Map<String, dynamic> establishment) {
    setState(() => _selectedIndex = 1);
  }

  void _viewDetails(Map<String, dynamic> establishment) {
    showDialog(
      context: context,
      builder: (context) => _buildDetailDialog(establishment),
    );
  }

  Future<dynamic> showAssignInspectionDialog(
    BuildContext context,
    dynamic establishment,
    List inspectorData,
    Function cb,
  ) async {
    String? selectedInspectorId;
    DateTime? _selectedScheduleDate = DateTime.now().add(Duration(days: 1));
    String _remarks = '';

    final _formKey = GlobalKey<FormState>();

    Future<void> _selectDate(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedScheduleDate ?? DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(Duration(days: 365)),
      );

      if (picked != null) {
        _selectedScheduleDate = picked;
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final size = MediaQuery.of(context).size;
            return SizedBox(
              child: AlertDialog(
                title: Text('Assign New Inspection'),
                content: SizedBox(
                  width: size.width * 0.3, // 70% of browser width
                  height: size.height * 0.5, // 70% of browser height
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 8),
                          // Establishment Dropdown
                          Text(
                            "Establishment: ${establishment['business_name']}",
                            style: TextStyle(
                              fontSize: 18,

                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 16),

                          // Inspector Dropdown
                          DropdownButtonFormField<String>(
                            value: selectedInspectorId,
                            decoration: InputDecoration(
                              labelText: 'Inspector',
                              border: OutlineInputBorder(),
                            ),
                            items: inspectorData.map((inspector) {
                              return DropdownMenuItem<String>(
                                value: inspector['id'].toString(),
                                child: Text(inspector['full_name']),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedInspectorId = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select inspector';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),

                          // Schedule Date
                          InkWell(
                            onTap: () async {
                              await _selectDate(context);
                              setState(() {});
                            },
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 20),
                                  SizedBox(width: 12),
                                  Text(
                                    _selectedScheduleDate != null
                                        ? '${_selectedScheduleDate!.day}/${_selectedScheduleDate!.month}/${_selectedScheduleDate!.year}'
                                        : 'Select Schedule Date',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 16),

                          // Remarks
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Remarks (Optional)',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                            onChanged: (value) {
                              _remarks = value;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final inspectionData = {
                          'establishment_id':
                              establishment['establishment_id'] ?? 0,
                          'inspector_id': selectedInspectorId ?? 0,
                          'schedule_date': _selectedScheduleDate != null
                              ? _selectedScheduleDate.toString().split('.')[0]
                              : '', // convert DateTime to string or empty
                          'status': 'PENDING',
                        };

                        // Remove any null or empty fields if you want PHP to handle defaults
                        inspectionData.removeWhere(
                          (key, value) => value == null,
                        );
                        final response =
                            await ApiPhp(
                              tableName: "assigned_inspections",
                              parameters: inspectionData,
                            ).insert(
                              subUrl:
                                  'https://luvpark.ph/luvtest/mapping/assign_establishment.php',
                            );

                        print("response $response");
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(response["message"]),
                            backgroundColor: response["success"]
                                ? AppColors.success
                                : AppColors.accentRed,
                          ),
                        );
                        if (response["success"]) {
                          cb(true);
                          Navigator.pop(context, true);
                        }
                      }
                    },
                    child: Text('Assign'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailDialog(Map<String, dynamic> establishment) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.business, size: 28, color: Colors.blue[700]),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Establishment Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.grey[500]),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Divider(height: 1, color: Colors.grey[200]),
              SizedBox(height: 20),

              Wrap(
                spacing: 24,
                runSpacing: 20,
                children: [
                  _buildDetailItem(
                    label: 'Business Name',
                    value: establishment['business_name'],
                    icon: Icons.store,
                  ),
                  _buildDetailItem(
                    label: 'Owner Name',
                    value: establishment['owner_name'],
                    icon: Icons.person,
                  ),
                  _buildDetailItem(
                    label: 'Status',
                    value: establishment['establishment_status'],
                    icon: Icons.start,
                    isStatus: true,
                  ),
                ],
              ),

              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      side: BorderSide(color: Colors.grey[300]!),
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text('Close'),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _editEstablishment(establishment);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text('Edit'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required String label,
    required String? value,
    required IconData icon,
    bool isStatus = false,
  }) {
    final width = MediaQuery.of(context).size.width > 600 ? 200.0 : 160.0;

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey[600]),
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          if (isStatus)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(value ?? ''),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                value ?? 'N/A',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Text(
              value ?? 'N/A',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _selectedIndex == 0 ? _buildListScreen() : _buildFormScreen(),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: _addNewEstablishment,
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              tooltip: 'Add New Establishment',
              child: Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildListScreen() {
    final filteredEstablishments = _filteredEstablishments;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Establishments',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[900],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Manage business establishments and records',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bar_chart, size: 16, color: Colors.blue[700]),
                    SizedBox(width: 6),
                    Text(
                      '${filteredEstablishments.length} establishments',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade100, width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search establishments...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),

              Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedFilter,
                    icon: Icon(
                      Icons.filter_list,
                      size: 20,
                      color: Colors.grey[600],
                    ),
                    style: TextStyle(color: Colors.grey[800], fontSize: 14),
                    items: ['All', 'NEW', 'RENEWAL', 'CLOSED'].map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _getStatusColor(status),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(status),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedFilter = value!);
                    },
                  ),
                ),
              ),
              SizedBox(width: 12),

              IconButton(
                onPressed: _loadEstablishments,
                icon: Icon(Icons.refresh, color: Colors.grey[600]),
                tooltip: 'Refresh',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: Container(
            width: double.infinity, // Ensure container takes full width
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[200]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: Colors.blue[700]),
                  )
                : filteredEstablishments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.business,
                            size: 60,
                            color: Colors.blue[300],
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          'No establishments found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Add your first establishment to get started',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : Scrollbar(
                    controller: _scrollController,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
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
                          dataTextStyle: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 14,
                          ),
                          columns: const [
                            DataColumn(label: Text('BUSINESS NAME')),
                            DataColumn(label: Text('OWNER')),
                            DataColumn(label: Text('CONTACT')),
                            DataColumn(label: Text('ESTABLISHMENT_STATUS')),
                            DataColumn(label: Text('INSPECTION STATUS')),
                            DataColumn(label: Text('ACTIVE')),

                            DataColumn(label: Text('CREATED')),
                            DataColumn(label: Text('ACTIONS')),
                          ],
                          rows: filteredEstablishments.map((establishment) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    establishment['business_name'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[900],
                                    ),
                                  ),
                                ),
                                DataCell(Text(establishment['owner_name'])),
                                DataCell(Text(establishment['contact_number'])),
                                DataCell(
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(
                                        establishment['establishment_status'],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      establishment['establishment_status'],
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    width: 100,
                                    height: 24,

                                    child: Text(
                                      establishment['inspection_status'],
                                    ),
                                  ),
                                ),

                                DataCell(
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: establishment['is_active'] == 'Y'
                                          ? Colors.green[50]
                                          : Colors.red[50],
                                    ),
                                    child: Icon(
                                      establishment['is_active'] == 'Y'
                                          ? Icons.check
                                          : Icons.close,
                                      size: 16,
                                      color: establishment['is_active'] == 'Y'
                                          ? Colors.green[700]
                                          : Colors.red[700],
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    establishment['created_at'],
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () =>
                                            _viewDetails(establishment),
                                        icon: Icon(
                                          Icons.visibility_outlined,
                                          size: 20,
                                        ),
                                        color: Colors.blue[600],
                                        tooltip: 'View Details',
                                      ),
                                      IconButton(
                                        onPressed: () =>
                                            _editEstablishment(establishment),
                                        icon: Icon(
                                          Icons.edit_outlined,
                                          size: 20,
                                        ),
                                        color: Colors.orange[600],
                                        tooltip: 'Edit',
                                      ),

                                      if (establishment['inspection_status']
                                              .toString()
                                              .trim()
                                              .toLowerCase() ==
                                          'pending')
                                        IconButton(
                                          onPressed: () async {
                                            LoadingDialog.show(
                                              title: 'Loading',
                                              message: 'Please wait...',
                                              context: context,
                                            );
                                            final response =
                                                await ApiPhp(
                                                  tableName: "users",
                                                  whereClause: {
                                                    "role": "Inspector",
                                                  },
                                                ).selectColumns([
                                                  "id",
                                                  "full_name",
                                                ]);
                                            Navigator.pop(context);
                                            if (!response["success"]) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    response["message"],
                                                  ),
                                                  backgroundColor:
                                                      AppColors.accentRed,
                                                ),
                                              );
                                            }

                                            showAssignInspectionDialog(
                                              context,
                                              establishment,
                                              response["data"],
                                              (data) {
                                                if (data) {
                                                  _loadEstablishments();
                                                }
                                              },
                                            );
                                          },

                                          icon: Icon(
                                            Icons.person_add,
                                            size: 20,
                                          ),
                                          color: Colors.grey[600],
                                          tooltip: 'Edit',
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
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'NEW':
        return Colors.green[400]!;
      case 'RENEWAL':
        return Colors.orange[400]!;
      case 'CLOSED':
        return Colors.red[400]!;
      default:
        return Colors.grey[400]!;
    }
  }

  // COMPLETE FORM SCREEN IMPLEMENTATION
  Widget _buildFormScreen() {
    return EstablishmentForm(
      onBack: () => setState(() => _selectedIndex = 0),
      onSave: () {
        setState(() => _selectedIndex = 0);
        _loadEstablishments();
      },
    );
  }
}

class EstablishmentForm extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onSave;

  const EstablishmentForm({
    super.key,
    required this.onBack,
    required this.onSave,
  });

  @override
  State<EstablishmentForm> createState() => _EstablishmentFormState();
}

class _EstablishmentFormState extends State<EstablishmentForm> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Text controllers for all fields
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _representativeController =
      TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();
  final TextEditingController _streetAddressController =
      TextEditingController();
  final TextEditingController _townController = TextEditingController(
    text: 'Hinigaran',
  );
  final TextEditingController _occupancyTypeController =
      TextEditingController();
  final TextEditingController _floorAreaController = TextEditingController();
  final TextEditingController _storeysController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _fsicExpiryController = TextEditingController();

  // Variables for dropdowns and selections
  String? _selectedBarangay;
  String? _selectedStatus = 'NEW';
  String? _fsicFilePath;
  String? _croFilePath;
  String? _fcaFilePath;
  bool _isActive = true;

  // Sample data
  List _barangays = [];

  @override
  void initState() {
    super.initState();
    _loadBrgy();
  }

  void _loadBrgy() async {
    final result = await ApiPhp(tableName: "brgy").select();
    List brgyData = result["data"];
    if (result["success"]) {
      if (brgyData.isNotEmpty) {
        for (var dataRow in brgyData) {
          _barangays.add({
            "value": dataRow["brgy_id"],
            "label": dataRow["brgy_name"],
          });
        }
      }
      setState(() {
        _barangays = result["data"];
      });
    }
    print("_barangays $_barangays");
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _fsicExpiryController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _pickFile(String type) async {
    setState(() {
      if (type == 'fsic') {
        _fsicFilePath = '/path/to/fsic_file.pdf';
      } else if (type == 'cro') {
        _croFilePath = '/path/to/cro_file.pdf';
      } else if (type == 'fca') {
        _fcaFilePath = '/path/to/fca_file.pdf';
      }
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Prepare establishment data

      try {
        final establishment = {
          'business_name': _businessNameController.text,
          'owner_name': _ownerNameController.text,
          'representative_name': _representativeController.text,
          'contact_number': _contactNumberController.text,
          'brgy_id': _selectedBarangay,
          'street_address': _streetAddressController.text,
          'town': _townController.text,
          'occupancy_type': _occupancyTypeController.text,
          'floor_area': double.tryParse(_floorAreaController.text),
          'no_of_storeys': int.tryParse(_storeysController.text),
          'latitude': "",
          'longitude': "",
          'establishment_status': _selectedStatus,
          'fsic_file_path': "",
          'fsic_expiry': "",
          'cro_file_path': "",
          'fca_file_path': "",
          'is_active': _isActive,
        };

        final result = await ApiPhp(
          tableName: "establishments",
          parameters: establishment,
        ).insert();
        if (result["success"]) {
          widget.onSave();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User " added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print("cathce $e");
      }

      // // Show success message
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('Establishment saved successfully!'),
      //     backgroundColor: Colors.green[700],
      //   ),
      // );

      // widget.onSave();
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _selectedBarangay = null;
      _selectedStatus = 'NEW';
      _fsicFilePath = null;
      _croFilePath = null;
      _fcaFilePath = null;
      _isActive = true;
      _townController.text = 'Hinigaran';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header with back button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: widget.onBack,
                  icon: Icon(Icons.arrow_back, color: Colors.grey[700]),
                  tooltip: 'Back to List',
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Establishment Registration',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[900],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Register new business establishment',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Form content
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Business Details Section
                      _buildSectionHeader(
                        icon: Icons.business,
                        title: 'Business Details',
                      ),
                      SizedBox(height: 20),

                      Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        children: [
                          _buildTextField(
                            controller: _businessNameController,
                            label: 'Business Name *',
                            width: 300,
                            validator: (value) =>
                                value!.isEmpty ? 'Required' : null,
                          ),
                          _buildTextField(
                            controller: _ownerNameController,
                            label: 'Owner Name *',
                            width: 300,
                            validator: (value) =>
                                value!.isEmpty ? 'Required' : null,
                          ),
                          _buildTextField(
                            controller: _representativeController,
                            label: 'Representative Name',
                            width: 300,
                          ),
                          _buildTextField(
                            controller: _contactNumberController,
                            label: 'Contact Number',
                            width: 300,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(11),
                            ],
                          ),
                        ],
                      ),

                      SizedBox(height: 40),

                      // Location Details Section
                      _buildSectionHeader(
                        icon: Icons.location_on,
                        title: 'Location Details',
                      ),
                      SizedBox(height: 20),

                      Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        children: [
                          SizedBox(
                            width: 300,
                            child: _buildDropdown(
                              value: _selectedBarangay,
                              label: 'Barangay *',
                              items: _barangays.map((barangay) {
                                return DropdownMenuItem<String>(
                                  value: barangay['brgy_id'].toString(),
                                  child: Text(barangay['brgy_name']),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedBarangay = value);
                              },
                              validator: (value) =>
                                  value == null ? 'Required' : null,
                            ),
                          ),
                          _buildTextField(
                            controller: _streetAddressController,
                            label: 'Street Address *',
                            width: 400,
                            maxLines: 2,
                            validator: (value) =>
                                value!.isEmpty ? 'Required' : null,
                          ),
                          _buildTextField(
                            controller: _townController,
                            label: 'Town',
                            width: 300,
                            enabled: false,
                          ),
                        ],
                      ),

                      SizedBox(height: 40),

                      // Building Details Section
                      _buildSectionHeader(
                        icon: Icons.construction,
                        title: 'Building Details',
                      ),
                      SizedBox(height: 20),

                      Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        children: [
                          _buildTextField(
                            controller: _occupancyTypeController,
                            label: 'Occupancy Type',
                            width: 300,
                          ),
                          _buildTextField(
                            controller: _floorAreaController,
                            label: 'Floor Area (sqm)',
                            width: 200,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'),
                              ),
                            ],
                          ),
                          _buildTextField(
                            controller: _storeysController,
                            label: 'Number of Storeys',
                            width: 200,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                          SizedBox(
                            width: 200,
                            child: _buildDropdown(
                              value: _selectedStatus,
                              label: 'Status',
                              items: ['NEW', 'RENEWAL', 'CLOSED'].map((status) {
                                return DropdownMenuItem(
                                  value: status,
                                  child: Text(status),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedStatus = value);
                              },
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 40),

                      // Action Buttons
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.grey[200]!, width: 1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: _resetForm,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey[700],
                                side: BorderSide(color: Colors.grey[400]!),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text('Reset Form'),
                            ),
                            SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[700],
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text('Save Establishment'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Container(
      padding: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.blue[100]!, width: 2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 24, color: Colors.blue[700]),
          ),
          SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.grey[900],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required double width,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    bool enabled = true,
    bool readOnly = false,
    Widget? suffixIcon,
  }) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
          ),
          filled: true,
          fillColor: enabled && !readOnly ? Colors.white : Colors.grey[100],
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: suffixIcon,
          floatingLabelStyle: TextStyle(),
        ),
        style: TextStyle(fontSize: 16, color: Colors.black),
        validator: validator,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,

        maxLines: maxLines,
        enabled: enabled,
        readOnly: readOnly,
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String label,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: items,
      onChanged: onChanged,
      validator: validator,
      dropdownColor: Colors.white,
      icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
    );
  }

  Widget _buildFileUploadRow({
    required String label,
    required String? filePath,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(Icons.upload_file, size: 20),
            label: Text('Upload $label'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[50],
              foregroundColor: Colors.blue[700],
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.blue[200]!),
              ),
            ),
          ),
          if (filePath != null) ...[
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 20, color: Colors.green[700]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'File Selected',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[800],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          filePath.split('/').last,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 16, color: Colors.grey[500]),
                    onPressed: () {
                      setState(() {
                        if (label.contains('FSIC')) {
                          _fsicFilePath = null;
                        } else if (label.contains('CRO')) {
                          _croFilePath = null;
                        } else if (label.contains('FCA')) {
                          _fcaFilePath = null;
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _representativeController.dispose();
    _contactNumberController.dispose();
    _streetAddressController.dispose();
    _townController.dispose();
    _occupancyTypeController.dispose();
    _floorAreaController.dispose();
    _storeysController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _fsicExpiryController.dispose();
    super.dispose();
  }
}
