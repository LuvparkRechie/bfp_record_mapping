// // establishment_screen.dart - Updated with complete form screen
// import 'dart:convert';

// import 'package:bfp_record_mapping/api/api_key.dart';
// import 'package:bfp_record_mapping/api/path_variables.dart';
// import 'package:bfp_record_mapping/customs/fsic_certificate.dart';
// import 'package:bfp_record_mapping/customs/loading_dialog.dart';
// import 'package:bfp_record_mapping/functions.dart';
// import 'package:bfp_record_mapping/screens/app_theme.dart';
// import 'package:bfp_record_mapping/shared_pref.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:url_launcher/url_launcher.dart';

// class EstablishmentScreen extends StatefulWidget {
//   const EstablishmentScreen({super.key});

//   @override
//   State<EstablishmentScreen> createState() => _EstablishmentScreenState();
// }

// class _EstablishmentScreenState extends State<EstablishmentScreen> {
//   int _selectedIndex = 0;
//   bool isUpdate = false;
//   bool _isLoading = false;
//   List _establishments = [];
//   String _searchQuery = '';
//   String _selectedFilter = 'All';
//   final ScrollController _scrollController = ScrollController();
//   Map<String, dynamic>? userData;
//   Map<String, dynamic> _selectedRow = {};

//   @override
//   void initState() {
//     super.initState();
//     loadUserData();
//     _loadEstablishments();
//   }

//   void loadUserData() async {
//     userData = await StoreCredentials().getUserData();

//     setState(() {});
//   }

//   Future<void> _loadEstablishments() async {
//     setState(() => _isLoading = true);
//     final result = await ApiPhp(tableName: "establishments").select();
//     _establishments = result["data"];
//     _establishments.sort((a, b) {
//       final dateA = DateTime.parse(a['created_at']);
//       final dateB = DateTime.parse(b['created_at']);
//       return dateB.compareTo(dateA);
//     });

//     setState(() => _isLoading = false);
//   }

//   List get _filteredEstablishments {
//     var filtered = _establishments;

//     if (_searchQuery.isNotEmpty) {
//       filtered = filtered.where((establishment) {
//         final businessName =
//             establishment['business_name']?.toLowerCase() ?? '';
//         final ownerName = establishment['owner_name']?.toLowerCase() ?? '';
//         final query = _searchQuery.toLowerCase();

//         return businessName.contains(query) || ownerName.contains(query);
//       }).toList();
//     }

//     if (_selectedFilter != 'All') {
//       filtered = filtered.where((establishment) {
//         return establishment['establishment_status'] ==
//             _selectedFilter.toUpperCase();
//       }).toList();
//     }

//     return filtered;
//   }

//   void _addNewEstablishment() async {
//     setState(() {
//       _selectedIndex = 1;
//       isUpdate = false;
//       _selectedRow = {};
//     });
//   }

//   void _editEstablishment(Map<String, dynamic> establishment) {
//     setState(() {
//       _selectedIndex = 1;
//       isUpdate = true;
//       _selectedRow = establishment;
//     });
//   }

//   Future<dynamic> showAssignInspectionDialog(
//     BuildContext context,
//     dynamic establishment,
//     List inspectorData,
//     Function cb,
//   ) async {
//     String? selectedInspectorId;
//     DateTime? _selectedScheduleDate = DateTime.now().add(Duration(days: 1));
//     String _remarks = '';

//     final _formKey = GlobalKey<FormState>();

//     Future<void> _selectDate(BuildContext context) async {
//       final DateTime? picked = await showDatePicker(
//         context: context,
//         initialDate: _selectedScheduleDate ?? DateTime.now(),
//         firstDate: DateTime.now(),
//         lastDate: DateTime.now().add(Duration(days: 365)),
//       );

//       if (picked != null) {
//         _selectedScheduleDate = picked;
//       }
//     }

//     showDialog(
//       context: context,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setState) {
//             final size = MediaQuery.of(context).size;
//             return SizedBox(
//               child: AlertDialog(
//                 title: Text('Assign New Inspection'),
//                 content: SizedBox(
//                   width: size.width * 0.3, // 70% of browser width
//                   height: size.height * 0.5, // 70% of browser height
//                   child: SingleChildScrollView(
//                     child: Form(
//                       key: _formKey,
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           SizedBox(height: 8),
//                           // Establishment Dropdown
//                           Text(
//                             "Establishment: ${establishment['business_name']}",
//                             style: TextStyle(
//                               fontSize: 18,

//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                           SizedBox(height: 16),

//                           // Inspector Dropdown
//                           DropdownButtonFormField<String>(
//                             value: selectedInspectorId,
//                             decoration: InputDecoration(
//                               labelText: 'Inspector',
//                               border: OutlineInputBorder(),
//                             ),
//                             items: inspectorData.map((inspector) {
//                               return DropdownMenuItem<String>(
//                                 value: inspector['id'].toString(),
//                                 child: Text(inspector['full_name']),
//                               );
//                             }).toList(),
//                             onChanged: (value) {
//                               setState(() {
//                                 selectedInspectorId = value;
//                               });
//                             },
//                             validator: (value) {
//                               if (value == null || value.isEmpty) {
//                                 return 'Please select inspector';
//                               }
//                               return null;
//                             },
//                           ),
//                           SizedBox(height: 16),

//                           // Schedule Date
//                           InkWell(
//                             onTap: () async {
//                               await _selectDate(context);
//                               setState(() {});
//                             },
//                             child: Container(
//                               padding: EdgeInsets.all(12),
//                               decoration: BoxDecoration(
//                                 border: Border.all(color: Colors.grey),
//                                 borderRadius: BorderRadius.circular(4),
//                               ),
//                               child: Row(
//                                 children: [
//                                   Icon(Icons.calendar_today, size: 20),
//                                   SizedBox(width: 12),
//                                   Text(
//                                     _selectedScheduleDate != null
//                                         ? '${_selectedScheduleDate!.day}/${_selectedScheduleDate!.month}/${_selectedScheduleDate!.year}'
//                                         : 'Select Schedule Date',
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                           SizedBox(height: 16),

//                           // Remarks
//                           TextFormField(
//                             decoration: InputDecoration(
//                               labelText: 'Remarks (Optional)',
//                               border: OutlineInputBorder(),
//                             ),
//                             maxLines: 2,
//                             onChanged: (value) {
//                               _remarks = value;
//                             },
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//                 actions: [
//                   TextButton(
//                     onPressed: () => Navigator.pop(context),
//                     child: Text('Cancel'),
//                   ),
//                   ElevatedButton(
//                     onPressed: () async {
//                       if (_formKey.currentState!.validate()) {
//                         final inspectionData = {
//                           'establishment_id':
//                               establishment['establishment_id'] ?? 0,
//                           'inspector_id': selectedInspectorId ?? 0,
//                           'schedule_date': _selectedScheduleDate != null
//                               ? _selectedScheduleDate.toString().split('.')[0]
//                               : '', // convert DateTime to string or empty
//                           'status': 'PENDING',
//                         };

//                         // Remove any null or empty fields if you want PHP to handle defaults
//                         inspectionData.removeWhere(
//                           (key, value) => value == null,
//                         );
//                         final response =
//                             await ApiPhp(
//                               tableName: "assigned_inspections",
//                               parameters: inspectionData,
//                             ).insert(
//                               subUrl:
//                                   '${ApiKeys.pathVariable}${ApiKeys.assignEstablishment}',
//                             );

//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(
//                             content: Text(response["message"]),
//                             backgroundColor: response["success"]
//                                 ? AppColors.success
//                                 : AppColors.accentRed,
//                           ),
//                         );
//                         if (response["success"]) {
//                           cb(true);
//                           Navigator.pop(context, true);
//                         }
//                       }
//                     },
//                     child: Text('Assign'),
//                   ),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   Future<String> generateFsic({
//     required String stationCode,
//     required String year,
//   }) async {
//     final response = await ApiPhp(tableName: "fsic_sequences").insert(
//       subUrl: '${ApiKeys.pathVariable}${ApiKeys.generateFsic}',
//       jsonParam: json.encode({"station_code": stationCode, "year": year}),
//     );
//     print("faf $response");
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(response["message"]),
//         backgroundColor: response["success"]
//             ? AppColors.success
//             : AppColors.accentRed,
//       ),
//     );
//     if (!response["success"]) {
//       return "";
//     }
//     return response["data"]["fsic_no"];
//   }

//   Future<dynamic> getMarshal() async {
//     final marshalData = await ApiPhp(tableName: "fire_marshals").select();

//     if (!marshalData["success"]) return;

//     return marshalData["data"][0]["name"];
//   }

//   Future<void> showPaymentDialog(data) async {
//     final returnData = await showDialog(
//       context: context,
//       builder: (context) {
//         Map<String, dynamic> fireCodeFee = {};
//         return Dialog(
//           backgroundColor:
//               Colors.transparent, // optional: remove default background
//           insetPadding: EdgeInsets.symmetric(
//             horizontal: 40, // control horizontal margin
//             vertical: 24, // control vertical margin
//           ),
//           child: StatefulBuilder(
//             builder: (context, setState) {
//               return SizedBox(
//                 width: MediaQuery.of(context).size.width * 0.3,
//                 height: MediaQuery.of(context).size.height * 0.6,
//                 child: Material(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(8),
//                   child: Padding(
//                     padding: const EdgeInsets.all(19.0),
//                     child: Form(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             "Payments",
//                             style: TextStyle(
//                               fontSize: 20,
//                               fontWeight: FontWeight.w700,
//                             ),
//                           ),
//                           SizedBox(height: 20),
//                           buildInputField(TextInputType.number, "Amount:", (
//                             data,
//                           ) {
//                             setState(() {
//                               fireCodeFee["amount"] = data;
//                             });
//                           }),
//                           buildInputField(TextInputType.text, "OR Number:", (
//                             data,
//                           ) {
//                             setState(() {
//                               fireCodeFee["or_no"] = data;
//                             });
//                           }),

//                           buildInputField(TextInputType.none, "Section:", (
//                             data,
//                           ) {
//                             setState(() {
//                               fireCodeFee["section"] = data;
//                             });
//                           }),
//                           SizedBox(height: 30),
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.end,
//                             children: [
//                               TextButton(
//                                 onPressed: () {
//                                   Navigator.of(context).pop({});
//                                 },
//                                 child: Text(
//                                   "Cancel",
//                                   style: TextStyle(color: Colors.grey),
//                                 ),
//                               ),
//                               SizedBox(width: 10),
//                               TextButton(
//                                 onPressed: () async {
//                                   if (fireCodeFee.isEmpty) {
//                                     ScaffoldMessenger.of(context).showSnackBar(
//                                       SnackBar(
//                                         content: Text("Field is required"),
//                                         backgroundColor: Colors.red[700],
//                                         duration: const Duration(seconds: 2),
//                                       ),
//                                     );
//                                     return;
//                                   }
//                                   if (fireCodeFee["amount"] == null) {
//                                     ScaffoldMessenger.of(context).showSnackBar(
//                                       SnackBar(
//                                         content: Text("Amount is required"),
//                                         backgroundColor: Colors.red[700],
//                                         duration: const Duration(seconds: 2),
//                                       ),
//                                     );
//                                     return;
//                                   }
//                                   if (fireCodeFee["or_no"] == null) {
//                                     ScaffoldMessenger.of(context).showSnackBar(
//                                       SnackBar(
//                                         content: Text("OR Number is required"),
//                                         backgroundColor: Colors.red[700],
//                                         duration: const Duration(seconds: 2),
//                                       ),
//                                     );
//                                     return;
//                                   }

//                                   DateTime now = DateTime.now();
//                                   fireCodeFee["date"] = now.toString().split(
//                                     " ",
//                                   )[0];
//                                   final marshalName = await getMarshal();
//                                   fireCodeFee["marshalName"] = marshalName;
//                                   Navigator.of(context).pop(fireCodeFee);
//                                 },
//                                 child: Text(
//                                   "Save",
//                                   style: TextStyle(color: Colors.blue),
//                                 ),
//                               ),
//                             ],
//                           ),
//                           // Add more content here
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//         );
//       },
//     );

//     if (returnData.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Please continue payment to proceed"),
//           backgroundColor: Colors.orange[700],
//         ),
//       );
//       return;
//     }
//     final fsicRes = await generateFsic(stationCode: "HIN", year: "2026");

//     if (fsicRes.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Error please try again."),
//           backgroundColor: Colors.orange[700],
//         ),
//       );
//       return;
//     }
//     DateTime now = DateTime.now();
//     returnData["fsic_no"] = fsicRes;
//     returnData["establishment_id"] = data["establishment_id"];
//     returnData["type"] = "Business Permit";
//     returnData["establishment_name"] = data['business_name'];
//     returnData["business_owner"] = data["owner_name"];
//     returnData["business_address"] = data["street_address"];
//     returnData["description"] =
//         "One (1) year from the date of issuance unless sooner revoked or cancelled.";
//     returnData["validity"] = now
//         .add(const Duration(days: 365))
//         .toString()
//         .split(" ")[0]
//         .toString();

//     await Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => BondPaperWidget(fsicData: returnData)),
//     );
//   }

//   Widget buildInputField(
//     TextInputType action,
//     String label,
//     Function onChange,
//   ) {
//     return Padding(
//       padding: const EdgeInsets.only(top: 15.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             label,
//             style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
//           ),
//           SizedBox(height: 10),
//           Container(
//             decoration: BoxDecoration(
//               color: Colors.grey.shade100,
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: TextField(
//               keyboardType: action,
//               decoration: InputDecoration(
//                 contentPadding: EdgeInsets.all(5),
//                 border: InputBorder.none,
//                 hint: Text(
//                   "Field is required",
//                   style: TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.w500,
//                     color: Colors.grey,
//                   ),
//                 ),
//               ),
//               onChanged: (value) => onChange(value),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: _selectedIndex == 0 ? _buildListScreen() : _buildFormScreen(),
//       floatingActionButton: _selectedIndex == 0
//           ? FloatingActionButton(
//               onPressed: _addNewEstablishment,
//               backgroundColor: Colors.blue[700],
//               foregroundColor: Colors.white,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               tooltip: 'Add New Establishment',
//               child: Icon(Icons.add),
//             )
//           : null,
//     );
//   }

//   Widget _buildListScreen() {
//     DateTime now = DateTime.now();
//     final filteredEstablishments = _filteredEstablishments.map((e) {
//       if (e["fsic_expiry_date"] != null) {
//         DateTime expiryDate = DateTime.parse(e["fsic_expiry_date"]);
//         bool isExpired = expiryDate.isBefore(now);

//         if (isExpired) {
//           e["inspection_status"] = "EXPIRED";
//         }
//       }

//       return e;
//     }).toList();

//     return Column(
//       children: [
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             border: Border(
//               bottom: BorderSide(color: Colors.grey.shade200, width: 1),
//             ),
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Establishments',
//                     style: TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.w700,
//                       color: Colors.grey[900],
//                     ),
//                   ),
//                   SizedBox(height: 4),
//                   Text(
//                     'Manage business establishments and records',
//                     style: TextStyle(fontSize: 14, color: Colors.grey[600]),
//                   ),
//                 ],
//               ),
//               Container(
//                 padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                 decoration: BoxDecoration(
//                   color: Colors.blue[50],
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(Icons.bar_chart, size: 16, color: Colors.blue[700]),
//                     SizedBox(width: 6),
//                     Text(
//                       '${filteredEstablishments.length} establishments',
//                       style: TextStyle(
//                         color: Colors.blue[700],
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),

//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             border: Border(
//               bottom: BorderSide(color: Colors.grey.shade100, width: 1),
//             ),
//           ),
//           child: Row(
//             children: [
//               Expanded(
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: Colors.grey[50],
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(color: Colors.grey[200]!),
//                   ),
//                   child: TextField(
//                     onChanged: (value) {
//                       setState(() => _searchQuery = value);
//                     },
//                     decoration: InputDecoration(
//                       hintText: 'Search establishments...',
//                       hintStyle: TextStyle(color: Colors.grey[500]),
//                       border: InputBorder.none,
//                       prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
//                       contentPadding: EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 12,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//               SizedBox(width: 12),

//               Container(
//                 padding: EdgeInsets.symmetric(horizontal: 12),
//                 decoration: BoxDecoration(
//                   color: Colors.grey[50],
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.grey[200]!),
//                 ),
//                 child: DropdownButtonHideUnderline(
//                   child: DropdownButton<String>(
//                     value: _selectedFilter,
//                     icon: Icon(
//                       Icons.filter_list,
//                       size: 20,
//                       color: Colors.grey[600],
//                     ),
//                     style: TextStyle(color: Colors.grey[800], fontSize: 14),
//                     items: ['All', 'NEW', 'RENEWAL', 'CLOSED'].map((status) {
//                       return DropdownMenuItem(
//                         value: status,
//                         child: Row(
//                           children: [
//                             Container(
//                               width: 8,
//                               height: 8,
//                               decoration: BoxDecoration(
//                                 shape: BoxShape.circle,
//                                 color: _getStatusColor(status),
//                               ),
//                             ),
//                             SizedBox(width: 8),
//                             Text(status),
//                           ],
//                         ),
//                       );
//                     }).toList(),
//                     onChanged: (value) {
//                       setState(() => _selectedFilter = value!);
//                     },
//                   ),
//                 ),
//               ),
//               SizedBox(width: 12),

//               IconButton(
//                 onPressed: _loadEstablishments,
//                 icon: Icon(Icons.refresh, color: Colors.grey[600]),
//                 tooltip: 'Refresh',
//                 style: IconButton.styleFrom(
//                   backgroundColor: Colors.grey[50],
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                     side: BorderSide(color: Colors.grey[200]!),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),

//         Expanded(
//           child: Container(
//             width: double.infinity, // Ensure container takes full width
//             decoration: BoxDecoration(
//               border: Border.all(color: Colors.grey[200]!),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: _isLoading
//                 ? Center(
//                     child: CircularProgressIndicator(color: Colors.blue[700]),
//                   )
//                 : filteredEstablishments.isEmpty
//                 ? Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Container(
//                           width: 120,
//                           height: 120,
//                           decoration: BoxDecoration(
//                             color: Colors.blue[50],
//                             shape: BoxShape.circle,
//                           ),
//                           child: Icon(
//                             Icons.business,
//                             size: 60,
//                             color: Colors.blue[300],
//                           ),
//                         ),
//                         SizedBox(height: 24),
//                         Text(
//                           'No establishments found',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.grey[700],
//                           ),
//                         ),
//                         SizedBox(height: 8),
//                         Text(
//                           'Add your first establishment to get started',
//                           style: TextStyle(color: Colors.grey[500]),
//                         ),
//                       ],
//                     ),
//                   )
//                 : Scrollbar(
//                     controller: _scrollController,
//                     child: SingleChildScrollView(
//                       controller: _scrollController,
//                       scrollDirection: Axis.horizontal,
//                       child: SingleChildScrollView(
//                         child: DataTable(
//                           headingRowColor: WidgetStateProperty.resolveWith(
//                             (states) => Colors.grey[50]!,
//                           ),
//                           headingRowHeight: 56,
//                           dataRowHeight: 64,
//                           horizontalMargin: 24,
//                           columnSpacing: 32,
//                           border: TableBorder(
//                             horizontalInside: BorderSide(
//                               color: Colors.grey[100]!,
//                               width: 1,
//                             ),
//                             bottom: BorderSide(color: Colors.grey[200]!),
//                           ),
//                           headingTextStyle: TextStyle(
//                             fontWeight: FontWeight.w600,
//                             color: Colors.grey[700],
//                             fontSize: 13,
//                           ),
//                           dataTextStyle: TextStyle(
//                             color: Colors.grey[800],
//                             fontSize: 14,
//                           ),
//                           columns: const [
//                             DataColumn(label: Text('BUSINESS NAME')),
//                             DataColumn(label: Text('OWNER')),
//                             DataColumn(label: Text('CONTACT')),
//                             DataColumn(label: Text('ESTABLISHMENT_STATUS')),
//                             DataColumn(label: Text('INSPECTION STATUS')),
//                             DataColumn(label: Text('ACTIVE')),
//                             DataColumn(label: Text('FSIC EXPIRY DATE')),
//                             DataColumn(label: Text('CREATED')),
//                             DataColumn(label: Text('ACTIONS')),
//                           ],
//                           rows: filteredEstablishments.map((establishment) {
//                             return DataRow(
//                               cells: [
//                                 DataCell(
//                                   Text(
//                                     establishment['business_name'],
//                                     style: TextStyle(
//                                       fontWeight: FontWeight.w600,
//                                       color: Colors.grey[900],
//                                     ),
//                                   ),
//                                 ),
//                                 DataCell(Text(establishment['owner_name'])),
//                                 DataCell(Text(establishment['contact_number'])),
//                                 DataCell(
//                                   Container(
//                                     padding: EdgeInsets.symmetric(
//                                       horizontal: 12,
//                                       vertical: 6,
//                                     ),
//                                     decoration: BoxDecoration(
//                                       color: _getStatusColor(
//                                         establishment['establishment_status'],
//                                       ),
//                                       borderRadius: BorderRadius.circular(20),
//                                     ),
//                                     child: Text(
//                                       establishment['establishment_status'],
//                                       style: TextStyle(
//                                         color: Colors.white,
//                                         fontSize: 12,
//                                         fontWeight: FontWeight.w600,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                                 DataCell(
//                                   Text(
//                                     establishment['inspection_status'],
//                                     style: TextStyle(
//                                       color: _getActionStatusColor(
//                                         establishment['inspection_status']
//                                             .toString()
//                                             .toLowerCase(),
//                                       ),
//                                       fontSize: 12,
//                                     ),
//                                   ),
//                                 ),

//                                 DataCell(
//                                   Container(
//                                     width: 24,
//                                     height: 24,
//                                     decoration: BoxDecoration(
//                                       shape: BoxShape.circle,
//                                       color: establishment['is_active'] == 'Y'
//                                           ? Colors.green[50]
//                                           : Colors.red[50],
//                                     ),
//                                     child: Icon(
//                                       establishment['is_active'] == 'Y'
//                                           ? Icons.check
//                                           : Icons.close,
//                                       size: 16,
//                                       color: establishment['is_active'] == 'Y'
//                                           ? Colors.green[700]
//                                           : Colors.red[700],
//                                     ),
//                                   ),
//                                 ),

//                                 DataCell(
//                                   Text(
//                                     establishment['fsic_expiry_date'] == null
//                                         ? ""
//                                         : establishment['fsic_expiry_date']
//                                               .toString(),
//                                   ),
//                                 ),

//                                 DataCell(
//                                   Text(
//                                     establishment['created_at'],
//                                     style: TextStyle(
//                                       fontSize: 13,
//                                       color: Colors.grey[600],
//                                     ),
//                                   ),
//                                 ),
//                                 DataCell(
//                                   Row(
//                                     children: [
//                                       if (establishment['establishment_status'] ==
//                                           "CLOSED") ...[
//                                         IconButton(
//                                           onPressed: () {
//                                             setState(() {
//                                               _selectedIndex = 1;
//                                               isUpdate = true;
//                                               _selectedRow = establishment;
//                                             });
//                                           },
//                                           icon: Icon(Icons.update, size: 20),
//                                           color: Colors.blue[600],
//                                           tooltip: 'Renew',
//                                         ),
//                                       ] else ...[
//                                         if (establishment["latitude"] != null &&
//                                             establishment["longitude"] != null)
//                                           IconButton(
//                                             onPressed: () {
//                                               Functions.viewOnMap({
//                                                 "latitude":
//                                                     establishment["latitude"],
//                                                 "longitude":
//                                                     establishment["longitude"],
//                                               }, context);
//                                             },
//                                             icon: Icon(
//                                               Icons.map_outlined,
//                                               size: 20,
//                                             ),
//                                             color: Colors.blue[600],
//                                             tooltip: 'View on map',
//                                           ),
//                                         if (establishment['inspection_status'] !=
//                                                 "PASSED" &&
//                                             establishment['inspection_status'] !=
//                                                 "EXPIRED")
//                                           IconButton(
//                                             onPressed: () => _editEstablishment(
//                                               establishment,
//                                             ),
//                                             icon: Icon(
//                                               Icons.edit_outlined,
//                                               size: 20,
//                                             ),
//                                             color: Colors.orange[600],
//                                             tooltip: 'Edit',
//                                           ),
//                                         if (establishment['inspection_status'] ==
//                                             "EXPIRED")
//                                           IconButton(
//                                             onPressed: () {
//                                               setState(() {
//                                                 _selectedIndex = 1;
//                                                 isUpdate = true;
//                                                 _selectedRow = establishment;
//                                               });
//                                             },
//                                             icon: Icon(Icons.update, size: 20),
//                                             color: Colors.blue[600],
//                                             tooltip: 'Renew',
//                                           ),

//                                         if (establishment['inspection_status']
//                                                     .toString()
//                                                     .trim()
//                                                     .toLowerCase() !=
//                                                 'passed' &&
//                                             establishment['inspection_status']
//                                                     .toString()
//                                                     .toLowerCase() !=
//                                                 "in progress" &&
//                                             userData!["role"] == "Admin")
//                                           IconButton(
//                                             onPressed: () async {
//                                               LoadingDialog.show(
//                                                 title: 'Loading',
//                                                 message: 'Please wait...',
//                                                 context: context,
//                                               );
//                                               final response =
//                                                   await ApiPhp(
//                                                     tableName: "users",
//                                                     whereClause: {
//                                                       "role": "Inspector",
//                                                     },
//                                                   ).selectColumns([
//                                                     "id",
//                                                     "full_name",
//                                                   ]);
//                                               Navigator.pop(context);
//                                               if (!response["success"]) {
//                                                 ScaffoldMessenger.of(
//                                                   context,
//                                                 ).showSnackBar(
//                                                   SnackBar(
//                                                     content: Text(
//                                                       response["message"],
//                                                     ),
//                                                     backgroundColor:
//                                                         AppColors.accentRed,
//                                                   ),
//                                                 );
//                                               }

//                                               showAssignInspectionDialog(
//                                                 context,
//                                                 establishment,
//                                                 response["data"],
//                                                 (data) {
//                                                   if (data) {
//                                                     _loadEstablishments();
//                                                   }
//                                                 },
//                                               );
//                                             },

//                                             icon: Icon(
//                                               Icons.person_add,
//                                               size: 20,
//                                             ),
//                                             color: Colors.grey[600],
//                                             tooltip: 'Assign inspector',
//                                           ),

//                                         if (establishment['fsic_file_path']
//                                                 .toString()
//                                                 .isEmpty &&
//                                             establishment['inspection_status'] ==
//                                                 "PASSED")
//                                           IconButton(
//                                             onPressed: () => showPaymentDialog(
//                                               establishment,
//                                             ),
//                                             icon: Icon(
//                                               Icons.file_present,
//                                               size: 20,
//                                             ),
//                                             color: Colors.orange[600],
//                                             tooltip: 'Generate FSIC',
//                                           ),
//                                       ],
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             );
//                           }).toList(),
//                         ),
//                       ),
//                     ),
//                   ),
//           ),
//         ),
//       ],
//     );
//   }

//   Color _getActionStatusColor(String status) {
//     switch (status) {
//       case 'passed':
//         return Colors.green[400]!;
//       case 'pending':
//         return Colors.orange[400]!;
//       case 'failed':
//         return Colors.red[400]!;
//       case 'expired':
//         return Colors.red[400]!;
//       default:
//         return Colors.blue[400]!;
//     }
//   }

//   Color _getStatusColor(String status) {
//     switch (status.toUpperCase()) {
//       case 'NEW':
//         return Colors.green[400]!;
//       case 'RENEWAL':
//         return Colors.orange[400]!;
//       case 'CLOSED':
//         return Colors.red[400]!;
//       default:
//         return Colors.grey[400]!;
//     }
//   }

//   // COMPLETE FORM SCREEN IMPLEMENTATION
//   Widget _buildFormScreen() {
//     return EstablishmentForm(
//       estlishmentData: _selectedRow,
//       isUpdate: isUpdate,
//       onBack: () => setState(() => _selectedIndex = 0),
//       onSave: () {
//         setState(() => _selectedIndex = 0);
//         _loadEstablishments();
//       },
//     );
//   }
// }

// class EstablishmentForm extends StatefulWidget {
//   final bool isUpdate;
//   final Map<String, dynamic>? estlishmentData;
//   final VoidCallback onBack;
//   final VoidCallback onSave;

//   const EstablishmentForm({
//     super.key,
//     required this.onBack,
//     required this.onSave,
//     required this.isUpdate,
//     this.estlishmentData,
//   });

//   @override
//   State<EstablishmentForm> createState() => _EstablishmentFormState();
// }

// class _EstablishmentFormState extends State<EstablishmentForm> {
//   final _formKey = GlobalKey<FormState>();
//   final _scrollController = ScrollController();

//   // Text controllers for all fields
//   final TextEditingController _businessNameController = TextEditingController();
//   final TextEditingController _ownerNameController = TextEditingController();
//   final TextEditingController _representativeController =
//       TextEditingController();
//   final TextEditingController _contactNumberController =
//       TextEditingController();
//   final TextEditingController _streetAddressController =
//       TextEditingController();
//   final TextEditingController _townController = TextEditingController(
//     text: 'Hinigaran',
//   );

//   final TextEditingController _floorAreaController = TextEditingController();
//   final TextEditingController _storeysController = TextEditingController();
//   final TextEditingController _fsicExpiryController = TextEditingController();
//   final TextEditingController _latitude = TextEditingController();
//   final TextEditingController _longitude = TextEditingController();
//   final TextEditingController _occupancyType = TextEditingController();
//   // Variables for dropdowns and selections
//   String? _selectedBarangay;
//   String? _selectedStatus = 'NEW';
//   String? _mapUrl;
//   bool isActive = true;
//   DateTime? fsicExpDate;
//   List _barangays = [];

//   @override
//   void initState() {
//     super.initState();
//     _loadData();
//     _loadBrgy();
//   }

//   void _loadData() async {
//     // if (!widget.isUpdate) return;

//     Map<String, dynamic> data = widget.estlishmentData!;
//     if (data["fsic_expiry_date"] != null) {
//       // Your data is in YYYY-MM-DD format (with dashes)
//       fsicExpDate = DateTime.parse(data["fsic_expiry_date"].toString());
//       print("Parsed date: $fsicExpDate");
//     }

//     _selectedStatus = widget.estlishmentData!["inspection_status"] == "EXPIRED"
//         ? "RENEWAL"
//         : "NEW";
//     _businessNameController.text = data["business_name"];
//     _ownerNameController.text = data["owner_name"];
//     _representativeController.text = data["owner_name"];
//     _contactNumberController.text = data["representative_name"];
//     _streetAddressController.text = data["street_address"];
//     _townController.text = data["town"];
//     _occupancyType.text = data["occupancy_type"] ?? "";

//     _floorAreaController.text = data["floor_area"].toString();
//     _storeysController.text = data["no_of_storeys"].toString();
//     _latitude.text = data["latitude"].toString();
//     _longitude.text = data["longitude"].toString();
//     _selectedBarangay = data["brgy_id"].toString();
//     _mapUrl = "${_latitude.text},${_longitude.text}";
//     setState(() {});
//     print("_selectedStatus: $_selectedStatus");
//     print("fsicExpDatess $fsicExpDate");
//   }

//   void _loadBrgy() async {
//     final result = await ApiPhp(tableName: "brgy").select();
//     List brgyData = result["data"];
//     if (result["success"]) {
//       if (brgyData.isNotEmpty) {
//         for (var dataRow in brgyData) {
//           _barangays.add({
//             "value": dataRow["brgy_id"],
//             "label": dataRow["brgy_name"],
//           });
//         }
//       }
//       setState(() {
//         _barangays = result["data"];
//       });
//     }
//   }

//   Future<void> _submitForm() async {
//     if (_formKey.currentState!.validate()) {
//       try {
//         if (widget.isUpdate) {
//           final establishment = {
//             'business_name': _businessNameController.text,
//             'owner_name': _ownerNameController.text,
//             'representative_name': _representativeController.text,
//             'contact_number': _contactNumberController.text,
//             'brgy_id': _selectedBarangay,
//             'street_address': _streetAddressController.text,
//             'town': _townController.text,
//             'occupancy_type': _occupancyType.text,
//             'floor_area': double.tryParse(_floorAreaController.text),
//             'no_of_storeys': int.tryParse(_storeysController.text),
//             'latitude': _latitude.text,
//             'longitude': _longitude.text,
//             'establishment_status': _selectedStatus,
//             'is_active': "Y",
//             'fsic_expiry_date':
//                 (widget.isUpdate &&
//                         (widget.estlishmentData!["inspection_status"] ==
//                             "PASSED") ||
//                     widget.estlishmentData!["inspection_status"] == "EXPIRED")
//                 ? fsicExpDate!.add(Duration(days: 365)).toString().split(" ")[0]
//                 : null,
//             'inspection_status': widget.estlishmentData!["inspection_status"]
//                 .toString()
//                 .toUpperCase(),
//           };

//           final result = await ApiPhp(
//             tableName: "establishments",
//             parameters: establishment,
//             whereClause: {
//               "establishment_id": widget.estlishmentData!["establishment_id"],
//             },
//           ).update();

//           if (result["success"]) {
//             widget.onSave();
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text(
//                   'Successfully ${widget.isUpdate ? "updated" : "added"}',
//                 ),
//                 backgroundColor: Colors.green,
//               ),
//             );
//           }
//           return;
//         }
//         final establishment = {
//           'business_name': _businessNameController.text,
//           'owner_name': _ownerNameController.text,
//           'representative_name': _representativeController.text,
//           'contact_number': _contactNumberController.text,
//           'brgy_id': _selectedBarangay,
//           'street_address': _streetAddressController.text,
//           'town': _townController.text,
//           'occupancy_type': _occupancyType.text,
//           'floor_area': double.tryParse(_floorAreaController.text),
//           'no_of_storeys': int.tryParse(_storeysController.text),
//           'latitude': _latitude.text,
//           'longitude': _longitude.text,
//           'establishment_status': _selectedStatus,
//           'fsic_file_path': "",
//           'cro_file_path': "",
//           'fca_file_path': "",
//           'is_active': "Y",
//         };

//         final result = await ApiPhp(
//           tableName: "establishments",
//           parameters: establishment,
//         ).insert();

//         if (result["success"]) {
//           widget.onSave();
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('Establishment added successfully!'),
//               backgroundColor: Colors.green,
//             ),
//           );
//         }
//       } catch (e) {
//         print("cathce $e");
//       }

//       // // Show success message
//       // ScaffoldMessenger.of(context).showSnackBar(
//       //   SnackBar(
//       //     content: Text('Establishment saved successfully!'),
//       //     backgroundColor: Colors.green[700],
//       //   ),
//       // );

//       // widget.onSave();
//     }
//   }

//   void _resetForm() {
//     _formKey.currentState?.reset();
//     setState(() {
//       _selectedBarangay = null;
//       _selectedStatus = 'NEW';

//       isActive = true;
//       _townController.text = 'Hinigaran';
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     print("estlishmentData ${widget.estlishmentData}");
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Column(
//         children: [
//           // Header with back button
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               border: Border(
//                 bottom: BorderSide(color: Colors.grey.shade200, width: 1),
//               ),
//             ),
//             child: Row(
//               children: [
//                 IconButton(
//                   onPressed: widget.onBack,
//                   icon: Icon(Icons.arrow_back, color: Colors.grey[700]),
//                   tooltip: 'Back to List',
//                 ),
//                 SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Establishment Registration',
//                         style: TextStyle(
//                           fontSize: 22,
//                           fontWeight: FontWeight.w700,
//                           color: Colors.grey[900],
//                         ),
//                       ),
//                       SizedBox(height: 4),
//                       Text(
//                         'Register new business establishment',
//                         style: TextStyle(fontSize: 14, color: Colors.grey[600]),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Form content
//           Expanded(
//             child: Scrollbar(
//               controller: _scrollController,
//               child: SingleChildScrollView(
//                 controller: _scrollController,
//                 padding: EdgeInsets.all(24),
//                 child: Form(
//                   key: _formKey,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Business Details Section
//                       _buildSectionHeader(
//                         icon: Icons.business,
//                         title: 'Business Details',
//                       ),
//                       SizedBox(height: 20),

//                       Wrap(
//                         spacing: 20,
//                         runSpacing: 20,
//                         children: [
//                           _buildTextField(
//                             controller: _businessNameController,
//                             label: 'Business Name *',
//                             width: 300,
//                             validator: (value) =>
//                                 value!.isEmpty ? 'Required' : null,
//                           ),
//                           _buildTextField(
//                             controller: _ownerNameController,
//                             label: 'Owner Name *',
//                             width: 300,
//                             validator: (value) =>
//                                 value!.isEmpty ? 'Required' : null,
//                           ),
//                           _buildTextField(
//                             controller: _representativeController,
//                             label: 'Representative Name',
//                             width: 300,
//                           ),
//                           _buildTextField(
//                             controller: _contactNumberController,
//                             label: 'Contact Number',
//                             width: 300,
//                             keyboardType: TextInputType.phone,
//                             inputFormatters: [
//                               FilteringTextInputFormatter.digitsOnly,
//                               LengthLimitingTextInputFormatter(11),
//                             ],
//                           ),
//                         ],
//                       ),

//                       SizedBox(height: 40),

//                       // Location Details Section
//                       _buildSectionHeader(
//                         icon: Icons.location_on,
//                         title: 'Location Details',
//                       ),
//                       SizedBox(height: 20),

//                       Wrap(
//                         spacing: 20,
//                         runSpacing: 20,
//                         children: [
//                           SizedBox(
//                             width: 300,
//                             child: _buildDropdown(
//                               isDisabled: false,
//                               value: _selectedBarangay,
//                               label: 'Barangay *',
//                               items: _barangays.map((barangay) {
//                                 return DropdownMenuItem<String>(
//                                   value: barangay['brgy_id'].toString(),
//                                   child: Text(barangay['brgy_name']),
//                                 );
//                               }).toList(),
//                               onChanged: (value) {
//                                 setState(() => _selectedBarangay = value);
//                               },
//                               validator: (value) =>
//                                   value == null ? 'Required' : null,
//                             ),
//                           ),
//                           _buildTextField(
//                             controller: _streetAddressController,
//                             label: 'Street Address *',
//                             width: 400,
//                             maxLines: 2,
//                             validator: (value) =>
//                                 value!.isEmpty ? 'Required' : null,
//                           ),
//                           _buildTextField(
//                             controller: _townController,
//                             label: 'Town',
//                             width: 300,
//                             enabled: false,
//                           ),
//                         ],
//                       ),

//                       SizedBox(height: 40),

//                       // Building Details Section
//                       _buildSectionHeader(
//                         icon: Icons.construction,
//                         title: 'Building Details',
//                       ),
//                       SizedBox(height: 20),

//                       Wrap(
//                         spacing: 20,
//                         runSpacing: 20,
//                         children: [
//                           _buildTextField(
//                             controller: _occupancyType,
//                             label: 'Occupancy Type',
//                             width: 200,
//                             keyboardType: TextInputType.text,

//                             validator: (value) =>
//                                 value!.isEmpty ? 'Required' : null,
//                           ),

//                           _buildTextField(
//                             controller: _floorAreaController,
//                             label: 'Floor Area (sqm)',
//                             width: 200,
//                             keyboardType: TextInputType.number,
//                             inputFormatters: [
//                               FilteringTextInputFormatter.allow(
//                                 RegExp(r'^\d+\.?\d{0,2}'),
//                               ),
//                             ],
//                             validator: (value) =>
//                                 value!.isEmpty ? 'Required' : null,
//                           ),
//                           _buildTextField(
//                             controller: _storeysController,
//                             label: 'Number of Storeys',
//                             width: 200,
//                             keyboardType: TextInputType.number,
//                             inputFormatters: [
//                               FilteringTextInputFormatter.digitsOnly,
//                             ],
//                             validator: (value) =>
//                                 value!.isEmpty ? 'Required' : null,
//                           ),
//                           SizedBox(
//                             width: 200,
//                             child: _buildDropdown(
//                               value: _selectedStatus,
//                               isDisabled:
//                                   widget
//                                       .estlishmentData!["inspection_status"] !=
//                                   "EXPIRED",
//                               label: 'Status',
//                               items: ['NEW', 'RENEWAL', 'CLOSED'].map((status) {
//                                 return DropdownMenuItem(
//                                   value: status,
//                                   child: Text(status),
//                                 );
//                               }).toList(),
//                               onChanged: (value) {
//                                 setState(() => _selectedStatus = value);
//                               },
//                               validator: (value) =>
//                                   value == null ? 'Required' : null,
//                             ),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 40),

//                       _buildSectionHeader(
//                         icon: Icons.location_on,
//                         title: 'Building Location',
//                         subText:
//                             "Click the button to open Google Maps and drop a pin",
//                       ),

//                       const SizedBox(height: 20),

//                       // Map URL Input + Open in Browser Button
//                       Container(
//                         padding: const EdgeInsets.all(16),
//                         decoration: BoxDecoration(
//                           color: Colors.grey.shade50,
//                           borderRadius: BorderRadius.circular(12),
//                           border: Border.all(color: Colors.grey.shade300),
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             // Instructions
//                             Row(
//                               children: [
//                                 Icon(
//                                   Icons.info_outline,
//                                   size: 20,
//                                   color: Colors.blue.shade600,
//                                 ),
//                                 const SizedBox(width: 8),
//                                 Expanded(
//                                   child: Text(
//                                     '1. Click "Open in Maps" to find your location\n2. Drop a pin and copy the URL\n3. Paste the URL below',
//                                     style: TextStyle(
//                                       color: Colors.grey.shade700,
//                                       fontSize: 13,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),

//                             const SizedBox(height: 16),

//                             // Open Maps Button
//                             Row(
//                               children: [
//                                 Expanded(
//                                   child: ElevatedButton.icon(
//                                     onPressed: _openGoogleMaps,
//                                     icon: const Icon(Icons.map),
//                                     label: const Text('Open in Google Maps'),
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor: Colors.blue,
//                                       foregroundColor: Colors.white,
//                                       padding: const EdgeInsets.symmetric(
//                                         vertical: 12,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),

//                             const SizedBox(height: 16),

//                             // URL Input Field
//                             TextFormField(
//                               controller: TextEditingController(text: _mapUrl),
//                               decoration: InputDecoration(
//                                 labelText: 'Coordinates',
//                                 hintText: 'Paste the copied coordinates here',
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                                 prefixIcon: const Icon(Icons.link),
//                                 suffixIcon: IconButton(
//                                   icon: const Icon(Icons.paste),
//                                   onPressed: _pasteFromClipboard,
//                                   tooltip: 'Paste from clipboard',
//                                 ),
//                               ),
//                               onChanged: (value) {
//                                 _mapUrl = value;
//                                 _extractCoordinatesFromUrl(value);
//                               },
//                             ),

//                             const SizedBox(height: 8),
//                           ],
//                         ),
//                       ),

//                       // Hidden form fields for validation
//                       TextFormField(
//                         controller: _latitude,
//                         style: const TextStyle(fontSize: 0, height: 0),
//                         decoration: const InputDecoration(
//                           border: InputBorder.none,
//                         ),
//                         validator: (value) => value!.isEmpty
//                             ? 'Please add a location from Google Maps'
//                             : null,
//                       ),

//                       TextFormField(
//                         controller: _longitude,
//                         style: const TextStyle(fontSize: 0, height: 0),
//                         decoration: const InputDecoration(
//                           border: InputBorder.none,
//                         ),
//                       ),
//                       SizedBox(height: 40),

//                       // Action Buttons
//                       Container(
//                         padding: EdgeInsets.symmetric(vertical: 20),
//                         decoration: BoxDecoration(
//                           border: Border(
//                             top: BorderSide(color: Colors.grey[200]!, width: 1),
//                           ),
//                         ),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.end,
//                           children: [
//                             if (!widget.isUpdate)
//                               OutlinedButton(
//                                 onPressed: _resetForm,
//                                 style: OutlinedButton.styleFrom(
//                                   foregroundColor: Colors.grey[700],
//                                   side: BorderSide(color: Colors.grey[400]!),
//                                   padding: EdgeInsets.symmetric(
//                                     horizontal: 32,
//                                     vertical: 12,
//                                   ),
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                 ),
//                                 child: Text('Reset Form'),
//                               ),
//                             SizedBox(width: 16),
//                             ElevatedButton(
//                               onPressed: _submitForm,
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.red[700],
//                                 foregroundColor: Colors.white,
//                                 padding: EdgeInsets.symmetric(
//                                   horizontal: 32,
//                                   vertical: 25,
//                                 ),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                               ),
//                               child: Text(
//                                 '${widget.isUpdate ? "Update" : "Save"} Establishment',
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSectionHeader({
//     required IconData icon,
//     required String title,
//     String? subText,
//   }) {
//     return Container(
//       padding: EdgeInsets.only(bottom: 12),
//       decoration: BoxDecoration(
//         border: Border(bottom: BorderSide(color: Colors.blue[100]!, width: 2)),
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: Colors.blue[50],
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Icon(icon, size: 24, color: Colors.blue[700]),
//           ),
//           SizedBox(width: 12),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 title,
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.w700,
//                   color: Colors.grey[900],
//                 ),
//               ),
//               if (subText != null) ...[
//                 SizedBox(height: 4),
//                 Text(
//                   subText,
//                   style: TextStyle(fontSize: 14, color: Colors.grey[600]),
//                 ),
//               ],
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     required double width,
//     String? Function(String?)? validator,
//     TextInputType? keyboardType,
//     List<TextInputFormatter>? inputFormatters,
//     int maxLines = 1,
//     bool enabled = true,
//     bool readOnly = false,
//     Widget? suffixIcon,
//   }) {
//     return SizedBox(
//       width: width,
//       child: TextFormField(
//         controller: controller,
//         decoration: InputDecoration(
//           labelText: label,
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(8),
//             borderSide: BorderSide(color: Colors.grey[400]!),
//           ),
//           enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(8),
//             borderSide: BorderSide(color: Colors.grey[300]!),
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(8),
//             borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
//           ),
//           filled: true,
//           fillColor: enabled && !readOnly ? Colors.white : Colors.grey[100],
//           contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//           suffixIcon: suffixIcon,
//           floatingLabelStyle: TextStyle(),
//         ),
//         style: TextStyle(fontSize: 16, color: Colors.black),
//         validator: validator,
//         keyboardType: keyboardType,
//         inputFormatters: inputFormatters,

//         maxLines: maxLines,
//         enabled: enabled,
//         readOnly: readOnly,
//       ),
//     );
//   }

//   Widget _buildDropdown({
//     required String? value,
//     required String label,
//     required List<DropdownMenuItem<String>> items,
//     required void Function(String?) onChanged,
//     String? Function(String?)? validator,
//     bool? isDisabled = false,
//   }) {
//     return DropdownButtonFormField<String>(
//       initialValue: value,
//       decoration: InputDecoration(
//         labelText: label,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8),
//           borderSide: BorderSide(color: Colors.grey[400]!),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8),
//           borderSide: BorderSide(color: Colors.grey[300]!),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8),
//           borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
//         ),
//         filled: true,
//         fillColor: Colors.white,
//         contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//       ),
//       items: items,

//       onChanged: isDisabled! ? null : onChanged,
//       validator: validator,
//       dropdownColor: Colors.white,
//       icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
//     );
//   }

//   // Open Google Maps in browser
//   void _openGoogleMaps() async {
//     // You can customize this URL based on your needs
//     const mapsUrl = 'https://www.google.com/maps';
//     final Uri uri = Uri.parse(mapsUrl);
//     if (await canLaunchUrl(uri)) {
//       await launchUrl(uri, mode: LaunchMode.externalApplication);
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Could not open Google Maps')),
//       );
//     }
//   }

//   // Paste from clipboard
//   void _pasteFromClipboard() async {
//     final clipboardData = await Clipboard.getData('text/plain');
//     if (clipboardData?.text != null) {
//       setState(() {
//         _mapUrl = clipboardData!.text;
//       });
//       _extractCoordinatesFromUrl(_mapUrl!);
//     }
//   }

//   // Extract coordinates from Google Maps URL
//   void _extractCoordinatesFromUrl(String url) {
//     double lat = double.parse(
//       url.toString().substring(0, url.length - 4).split(",")[0].trim(),
//     );
//     double lng = double.parse(
//       url.toString().substring(0, url.length - 4).split(",")[1].trim(),
//     );
//     _latitude.text = lat.toString();
//     _longitude.text = lng.toString();
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Coordinates extracted: $lat, $lng'),
//         backgroundColor: Colors.green,
//         duration: const Duration(seconds: 2),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     _businessNameController.dispose();
//     _ownerNameController.dispose();
//     _representativeController.dispose();
//     _contactNumberController.dispose();
//     _streetAddressController.dispose();
//     _townController.dispose();

//     _floorAreaController.dispose();
//     _storeysController.dispose();
//     _fsicExpiryController.dispose();
//     super.dispose();
//   }
// }

// establishment_screen.dart - Updated with complete form screen
import 'dart:convert';

import 'package:bfp_record_mapping/api/api_key.dart';
import 'package:bfp_record_mapping/api/path_variables.dart';
import 'package:bfp_record_mapping/customs/fsic_certificate.dart';
import 'package:bfp_record_mapping/customs/loading_dialog.dart';
import 'package:bfp_record_mapping/functions.dart';
import 'package:bfp_record_mapping/screens/app_theme.dart';
import 'package:bfp_record_mapping/shared_pref.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class EstablishmentScreen extends StatefulWidget {
  const EstablishmentScreen({super.key});

  @override
  State<EstablishmentScreen> createState() => _EstablishmentScreenState();
}

class _EstablishmentScreenState extends State<EstablishmentScreen> {
  int _selectedIndex = 0;
  bool isUpdate = false;
  bool _isLoading = false;
  List _establishments = [];
  String _searchQuery = '';
  String _selectedFilter = 'All';
  final ScrollController _scrollController = ScrollController();
  Map<String, dynamic>? userData;
  Map<String, dynamic> _selectedRow = {};

  @override
  void initState() {
    super.initState();
    loadUserData();
    _loadEstablishments();
  }

  void loadUserData() async {
    userData = await StoreCredentials().getUserData();
    setState(() {});
  }

  Future<void> _loadEstablishments() async {
    setState(() => _isLoading = true);
    final result = await ApiPhp(tableName: "establishments").select();
    _establishments = result["data"];
    _establishments.sort((a, b) {
      final dateA = DateTime.parse(a['created_at']);
      final dateB = DateTime.parse(b['created_at']);
      return dateB.compareTo(dateA);
    });

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

  void _addNewEstablishment() async {
    setState(() {
      _selectedIndex = 1;
      isUpdate = false;
      _selectedRow = {};
    });
  }

  void _editEstablishment(Map<String, dynamic> establishment) {
    setState(() {
      _selectedIndex = 1;
      isUpdate = true;
      _selectedRow = establishment;
    });
  }

  void _renewEstablishment(Map<String, dynamic> establishment) {
    setState(() {
      _selectedIndex = 1;
      isUpdate = true;
      _selectedRow = establishment;
    });
  }

  Future<dynamic> showAssignInspectionDialog(
    BuildContext context,
    dynamic establishment,
    List inspectorData,
    Function cb,
  ) async {
    String? selectedInspectorId;
    DateTime? _selectedScheduleDate = DateTime.now().add(
      const Duration(days: 1),
    );
    String _remarks = '';

    final _formKey = GlobalKey<FormState>();

    Future<void> _selectDate(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedScheduleDate ?? DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
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
                title: const Text('Assign New Inspection'),
                content: SizedBox(
                  width: size.width * 0.3,
                  height: size.height * 0.5,
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            "Establishment: ${establishment['business_name']}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: selectedInspectorId,
                            decoration: const InputDecoration(
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
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () async {
                              await _selectDate(context);
                              setState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 20),
                                  const SizedBox(width: 12),
                                  Text(
                                    _selectedScheduleDate != null
                                        ? '${_selectedScheduleDate!.day}/${_selectedScheduleDate!.month}/${_selectedScheduleDate!.year}'
                                        : 'Select Schedule Date',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: const InputDecoration(
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
                    child: const Text('Cancel'),
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
                              : '',
                          'status': 'PENDING',
                        };

                        inspectionData.removeWhere(
                          (key, value) => value == null,
                        );
                        final response =
                            await ApiPhp(
                              tableName: "assigned_inspections",
                              parameters: inspectionData,
                            ).insert(
                              subUrl:
                                  '${ApiKeys.pathVariable}${ApiKeys.assignEstablishment}',
                            );

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
                    child: const Text('Assign'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<String> generateFsic({
    required String stationCode,
    required String year,
  }) async {
    final response = await ApiPhp(tableName: "fsic_sequences").insert(
      subUrl: '${ApiKeys.pathVariable}${ApiKeys.generateFsic}',
      jsonParam: json.encode({"station_code": stationCode, "year": year}),
    );
    print("faf $response");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response["message"]),
        backgroundColor: response["success"]
            ? AppColors.success
            : AppColors.accentRed,
      ),
    );
    if (!response["success"]) {
      return "";
    }
    return response["data"]["fsic_no"];
  }

  Future<dynamic> getMarshal() async {
    final marshalData = await ApiPhp(tableName: "fire_marshals").select();

    if (!marshalData["success"]) return;

    return marshalData["data"][0]["name"];
  }

  Future<void> showPaymentDialog(data) async {
    final returnData = await showDialog(
      context: context,
      builder: (context) {
        Map<String, dynamic> fireCodeFee = {};
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 40,
            vertical: 24,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: MediaQuery.of(context).size.width * 0.3,
                height: MediaQuery.of(context).size.height * 0.6,
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(19.0),
                    child: Form(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Payments",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 20),
                          buildInputField(TextInputType.number, "Amount:", (
                            data,
                          ) {
                            setState(() {
                              fireCodeFee["amount"] = data;
                            });
                          }),
                          buildInputField(TextInputType.text, "OR Number:", (
                            data,
                          ) {
                            setState(() {
                              fireCodeFee["or_no"] = data;
                            });
                          }),
                          buildInputField(TextInputType.none, "Section:", (
                            data,
                          ) {
                            setState(() {
                              fireCodeFee["section"] = data;
                            });
                          }),
                          const SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop({});
                                },
                                child: const Text(
                                  "Cancel",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              const SizedBox(width: 10),
                              TextButton(
                                onPressed: () async {
                                  if (fireCodeFee.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          "Field is required",
                                        ),
                                        backgroundColor: Colors.red[700],
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                    return;
                                  }
                                  if (fireCodeFee["amount"] == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          "Amount is required",
                                        ),
                                        backgroundColor: Colors.red[700],
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                    return;
                                  }
                                  if (fireCodeFee["or_no"] == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          "OR Number is required",
                                        ),
                                        backgroundColor: Colors.red[700],
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                    return;
                                  }

                                  DateTime now = DateTime.now();
                                  fireCodeFee["date"] = now.toString().split(
                                    " ",
                                  )[0];
                                  final marshalName = await getMarshal();
                                  fireCodeFee["marshalName"] = marshalName;
                                  Navigator.of(context).pop(fireCodeFee);
                                },
                                child: const Text(
                                  "Save",
                                  style: TextStyle(color: Colors.blue),
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
            },
          ),
        );
      },
    );

    if (returnData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please continue payment to proceed"),
          backgroundColor: Colors.orange[700],
        ),
      );
      return;
    }
    final fsicRes = await generateFsic(stationCode: "HIN", year: "2026");

    if (fsicRes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Error please try again."),
          backgroundColor: Colors.orange[700],
        ),
      );
      return;
    }
    DateTime now = DateTime.now();
    returnData["fsic_no"] = fsicRes;
    returnData["establishment_id"] = data["establishment_id"];
    returnData["type"] = "Business Permit";
    returnData["establishment_name"] = data['business_name'];
    returnData["business_owner"] = data["owner_name"];
    returnData["business_address"] = data["street_address"];
    returnData["description"] =
        "One (1) year from the date of issuance unless sooner revoked or cancelled.";
    returnData["validity"] = now
        .add(const Duration(days: 365))
        .toString()
        .split(" ")[0]
        .toString();

    final resGen = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BondPaperWidget(fsicData: returnData)),
    );

    if (resGen != null) {
      _loadEstablishments();
    }
  }

  Widget buildInputField(
    TextInputType action,
    String label,
    Function onChange,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              keyboardType: action,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(5),
                border: InputBorder.none,
                hint: const Text(
                  "Field is required",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ),
              onChanged: (value) => onChange(value),
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
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildListScreen() {
    DateTime now = DateTime.now();
    final filteredEstablishments = _filteredEstablishments.map((e) {
      if (e["fsic_expiry_date"] != null &&
          e["fsic_expiry_date"].toString().isNotEmpty) {
        try {
          DateTime expiryDate = DateTime.parse(e["fsic_expiry_date"]);
          bool isExpired = expiryDate.isBefore(now);

          if (isExpired && e["inspection_status"] != "CLOSED") {
            e["inspection_status"] = "EXPIRED";
          }
        } catch (e) {
          print("Error parsing expiry date: $e");
        }
      }

      return e;
    }).toList();

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
                  const SizedBox(height: 4),
                  Text(
                    'Manage business establishments and records',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bar_chart, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 6),
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
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
                            const SizedBox(width: 8),
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
              const SizedBox(width: 12),
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
            width: double.infinity,
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
                        const SizedBox(height: 24),
                        Text(
                          'No establishments found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
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
                            DataColumn(label: Text('FSIC EXPIRY DATE')),
                            DataColumn(label: Text('CREATED')),
                            DataColumn(label: Text('ACTIONS')),
                          ],
                          rows: filteredEstablishments.map((establishment) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    establishment['business_name'] ?? '',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[900],
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(establishment['owner_name'] ?? ''),
                                ),
                                DataCell(
                                  Text(establishment['contact_number'] ?? ''),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(
                                        establishment['establishment_status'] ??
                                            'NEW',
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      establishment['establishment_status'] ??
                                          'NEW',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getInspectionStatusColor(
                                            establishment['inspection_status']
                                                    ?.toString()
                                                    .toLowerCase() ??
                                                '',
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          establishment['inspection_status'] ??
                                              '',
                                          style: TextStyle(
                                            color: _getInspectionStatusColor(
                                              establishment['inspection_status']
                                                      ?.toString()
                                                      .toLowerCase() ??
                                                  '',
                                            ),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),

                                      if (establishment['notes'] != null) ...[
                                        SizedBox(width: 10),
                                        IconButton(
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('Note'),
                                                content: Text(
                                                  establishment['notes'],
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                    child: const Text('CLOSE'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                          icon: Icon(
                                            Icons.note_alt_outlined,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ],
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
                                    establishment['fsic_expiry_date'] == null
                                        ? ""
                                        : establishment['fsic_expiry_date']
                                              .toString(),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    establishment['created_at'] ?? '',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      if (establishment['establishment_status'] ==
                                          "CLOSED") ...[
                                        IconButton(
                                          onPressed: () => _renewEstablishment(
                                            establishment,
                                          ),
                                          icon: const Icon(
                                            Icons.update,
                                            size: 20,
                                          ),
                                          color: Colors.blue[600],
                                          tooltip: 'Renew',
                                        ),
                                      ] else ...[
                                        if (establishment["latitude"] != null &&
                                            establishment["longitude"] !=
                                                null &&
                                            establishment["latitude"]
                                                .toString()
                                                .isNotEmpty &&
                                            establishment["longitude"]
                                                .toString()
                                                .isNotEmpty)
                                          IconButton(
                                            onPressed: () {
                                              Functions.viewOnMap({
                                                "latitude":
                                                    establishment["latitude"],
                                                "longitude":
                                                    establishment["longitude"],
                                              }, context);
                                            },
                                            icon: const Icon(
                                              Icons.map_outlined,
                                              size: 20,
                                            ),
                                            color: Colors.blue[600],
                                            tooltip: 'View on map',
                                          ),
                                        if (establishment['inspection_status'] !=
                                                "PASSED" &&
                                            establishment['inspection_status'] !=
                                                "EXPIRED" &&
                                            establishment['inspection_status'] !=
                                                "CLOSED")
                                          IconButton(
                                            onPressed: () => _editEstablishment(
                                              establishment,
                                            ),
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                              size: 20,
                                            ),
                                            color: Colors.orange[600],
                                            tooltip: 'Edit',
                                          ),
                                        if (establishment['inspection_status'] ==
                                            "EXPIRED")
                                          IconButton(
                                            onPressed: () =>
                                                _renewEstablishment(
                                                  establishment,
                                                ),
                                            icon: const Icon(
                                              Icons.update,
                                              size: 20,
                                            ),
                                            color: Colors.blue[600],
                                            tooltip: 'Renew',
                                          ),
                                        if (establishment['inspection_status']
                                                    .toString()
                                                    .trim()
                                                    .toLowerCase() !=
                                                'passed' &&
                                            establishment['inspection_status']
                                                    .toString()
                                                    .toLowerCase() !=
                                                "in progress" &&
                                            establishment['inspection_status'] !=
                                                "EXPIRED" &&
                                            userData != null &&
                                            userData!["role"] == "Admin")
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
                                            icon: const Icon(
                                              Icons.person_add,
                                              size: 20,
                                            ),
                                            color: Colors.grey[600],
                                            tooltip: 'Assign inspector',
                                          ),
                                        if (establishment['fsic_file_path']
                                                .toString()
                                                .isEmpty &&
                                            establishment['inspection_status'] ==
                                                "PASSED")
                                          IconButton(
                                            onPressed: () => showPaymentDialog(
                                              establishment,
                                            ),
                                            icon: const Icon(
                                              Icons.file_present,
                                              size: 20,
                                            ),
                                            color: Colors.orange[600],
                                            tooltip: 'Generate FSIC',
                                          ),
                                      ],
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

  Color _getInspectionStatusColor(String status) {
    switch (status) {
      case 'passed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'expired':
        return Colors.red;
      case 'in progress':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'NEW':
        return Colors.green;
      case 'RENEWAL':
        return Colors.orange;
      case 'CLOSED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildFormScreen() {
    return EstablishmentForm(
      estlishmentData: _selectedRow,
      isUpdate: isUpdate,
      onBack: () => setState(() => _selectedIndex = 0),
      onSave: () {
        setState(() => _selectedIndex = 0);
        _loadEstablishments();
      },
    );
  }
}

class EstablishmentForm extends StatefulWidget {
  final bool isUpdate;
  final Map<String, dynamic>? estlishmentData;
  final VoidCallback onBack;
  final VoidCallback onSave;

  const EstablishmentForm({
    super.key,
    required this.onBack,
    required this.onSave,
    required this.isUpdate,
    this.estlishmentData,
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
  final TextEditingController _floorAreaController = TextEditingController();
  final TextEditingController _storeysController = TextEditingController();
  final TextEditingController _latitude = TextEditingController();
  final TextEditingController _longitude = TextEditingController();
  final TextEditingController _occupancyType = TextEditingController();

  // Variables for dropdowns and selections
  String? _selectedBarangay;
  String? _selectedStatus = 'NEW';
  String? _mapUrl;
  bool isActive = true;
  DateTime? fsicExpDate;
  List _barangays = [];

  @override
  void initState() {
    super.initState();
    _loadBrgy();
    if (widget.isUpdate && widget.estlishmentData != null) {
      _loadData();
    }
  }

  void _loadData() {
    Map<String, dynamic> data = widget.estlishmentData!;

    // Determine if this is a renewal
    bool isExpired = data["inspection_status"] == "EXPIRED";
    bool isClosed = data["establishment_status"] == "CLOSED";

    // Set status based on condition
    if (isExpired || isClosed) {
      _selectedStatus = "RENEWAL";
    } else {
      _selectedStatus = data["establishment_status"] ?? "NEW";
    }

    // Parse FSIC expiry date if exists
    if (data["fsic_expiry_date"] != null &&
        data["fsic_expiry_date"].toString().isNotEmpty) {
      try {
        fsicExpDate = DateTime.parse(data["fsic_expiry_date"].toString());
        print("Parsed date: $fsicExpDate");
      } catch (e) {
        print("Error parsing date: $e");
        fsicExpDate = null;
      }
    }

    // Load all text fields
    _businessNameController.text = data["business_name"] ?? '';
    _ownerNameController.text = data["owner_name"] ?? '';
    _representativeController.text = data["representative_name"] ?? '';
    _contactNumberController.text = data["contact_number"] ?? '';
    _streetAddressController.text = data["street_address"] ?? '';
    _townController.text = data["town"] ?? 'Hinigaran';
    _occupancyType.text = data["occupancy_type"] ?? '';
    _floorAreaController.text = data["floor_area"]?.toString() ?? '';
    _storeysController.text = data["no_of_storeys"]?.toString() ?? '';
    _latitude.text = data["latitude"]?.toString() ?? '';
    _longitude.text = data["longitude"]?.toString() ?? '';
    _selectedBarangay = data["brgy_id"]?.toString();

    if (_latitude.text.isNotEmpty && _longitude.text.isNotEmpty) {
      _mapUrl = "${_latitude.text},${_longitude.text}";
    }

    setState(() {});

    print("Status set to: $_selectedStatus");
    print("Is Renewal: ${isExpired || isClosed}");
  }

  void _loadBrgy() async {
    final result = await ApiPhp(tableName: "brgy").select();
    if (result["success"]) {
      setState(() {
        _barangays = result["data"];
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        if (widget.isUpdate) {
          // Determine new inspection status based on renewal
          String newInspectionStatus;
          bool isRenewal = _selectedStatus == "RENEWAL";

          if (isRenewal) {
            // For renewal, reset inspection status to PENDING
            newInspectionStatus = "PENDING";
          } else {
            // Keep original status for regular edits
            newInspectionStatus =
                widget.estlishmentData!["inspection_status"]
                    ?.toString()
                    .toUpperCase() ??
                "PENDING";
          }

          // Calculate new expiry date for renewals
          String? newExpiryDate;
          if (isRenewal) {
            DateTime baseDate = fsicExpDate ?? DateTime.now();
            newExpiryDate = baseDate
                .add(const Duration(days: 365))
                .toString()
                .split(" ")[0];
          } else {
            // Keep existing expiry date for regular edits
            newExpiryDate = widget.estlishmentData!["fsic_expiry_date"]
                ?.toString();
          }

          final establishment = {
            'business_name': _businessNameController.text,
            'owner_name': _ownerNameController.text,
            'representative_name': _representativeController.text,
            'contact_number': _contactNumberController.text,
            'brgy_id': _selectedBarangay,
            'street_address': _streetAddressController.text,
            'town': _townController.text,
            'occupancy_type': _occupancyType.text,
            'floor_area': double.tryParse(_floorAreaController.text),
            'no_of_storeys': int.tryParse(_storeysController.text),
            'latitude': _latitude.text.isEmpty
                ? null
                : double.tryParse(_latitude.text),
            'longitude': _longitude.text.isEmpty
                ? null
                : double.tryParse(_longitude.text),
            'establishment_status': _selectedStatus,
            'is_active': "Y",
            'fsic_expiry_date': newExpiryDate,
            'inspection_status': newInspectionStatus,
          };

          // Remove null values
          establishment.removeWhere((key, value) => value == null);

          final result = await ApiPhp(
            tableName: "establishments",
            parameters: establishment,
            whereClause: {
              "establishment_id": widget.estlishmentData!["establishment_id"],
            },
          ).update();

          if (result["success"]) {
            widget.onSave();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isRenewal
                      ? 'Establishment renewed successfully!'
                      : 'Establishment updated successfully!',
                ),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result["message"] ?? 'Update failed'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // New establishment
        final establishment = {
          'business_name': _businessNameController.text,
          'owner_name': _ownerNameController.text,
          'representative_name': _representativeController.text,
          'contact_number': _contactNumberController.text,
          'brgy_id': _selectedBarangay,
          'street_address': _streetAddressController.text,
          'town': _townController.text,
          'occupancy_type': _occupancyType.text,
          'floor_area': double.tryParse(_floorAreaController.text),
          'no_of_storeys': int.tryParse(_storeysController.text),
          'latitude': _latitude.text.isEmpty
              ? null
              : double.tryParse(_latitude.text),
          'longitude': _longitude.text.isEmpty
              ? null
              : double.tryParse(_longitude.text),
          'establishment_status': _selectedStatus,
          'fsic_file_path': "",
          'cro_file_path': "",
          'fca_file_path': "",
          'is_active': "Y",
          'inspection_status': "PENDING",
        };

        // Remove null values
        establishment.removeWhere((key, value) => value == null);

        final result = await ApiPhp(
          tableName: "establishments",
          parameters: establishment,
        ).insert();

        if (result["success"]) {
          widget.onSave();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Establishment added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result["message"] ?? 'Insert failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        print("Error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _selectedBarangay = null;
      _selectedStatus = 'NEW';
      isActive = true;
      _townController.text = 'Hinigaran';
      _businessNameController.clear();
      _ownerNameController.clear();
      _representativeController.clear();
      _contactNumberController.clear();
      _streetAddressController.clear();
      _occupancyType.clear();
      _floorAreaController.clear();
      _storeysController.clear();
      _latitude.clear();
      _longitude.clear();
      _mapUrl = null;
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isUpdate
                            ? (_selectedStatus == "RENEWAL"
                                  ? 'Renew Establishment'
                                  : 'Edit Establishment')
                            : 'New Establishment',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedStatus == "RENEWAL"
                            ? 'Update information and extend FSIC validity'
                            : widget.isUpdate
                            ? 'Update establishment information'
                            : 'Register new business establishment',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (_selectedStatus == "RENEWAL")
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'RENEWAL MODE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
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
                padding: const EdgeInsets.all(24),
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
                      const SizedBox(height: 20),

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

                      const SizedBox(height: 40),

                      // Location Details Section
                      _buildSectionHeader(
                        icon: Icons.location_on,
                        title: 'Location Details',
                      ),
                      const SizedBox(height: 20),

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
                                  child: Text(barangay['brgy_name'] ?? ''),
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

                      const SizedBox(height: 40),

                      // Building Details Section
                      _buildSectionHeader(
                        icon: Icons.construction,
                        title: 'Building Details',
                      ),
                      const SizedBox(height: 20),

                      Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        children: [
                          _buildTextField(
                            controller: _occupancyType,
                            label: 'Occupancy Type',
                            width: 200,
                            keyboardType: TextInputType.text,
                            validator: (value) =>
                                value!.isEmpty ? 'Required' : null,
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
                            validator: (value) =>
                                value!.isEmpty ? 'Required' : null,
                          ),
                          _buildTextField(
                            controller: _storeysController,
                            label: 'Number of Storeys',
                            width: 200,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) =>
                                value!.isEmpty ? 'Required' : null,
                          ),
                          SizedBox(
                            width: 200,
                            child: _buildDropdown(
                              value: _selectedStatus,
                              isDisabled: true, // Status is auto-set by system
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
                              validator: (value) =>
                                  value == null ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      _buildSectionHeader(
                        icon: Icons.location_on,
                        title: 'Building Location',
                        subText:
                            "Click the button to open Google Maps and drop a pin",
                      ),

                      const SizedBox(height: 20),

                      // Map URL Input + Open in Browser Button
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: Colors.blue.shade600,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '1. Click "Open in Maps" to find your location\n2. Drop a pin and copy the URL\n3. Paste the URL below',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _openGoogleMaps,
                                    icon: const Icon(Icons.map),
                                    label: const Text('Open in Google Maps'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: TextEditingController(text: _mapUrl),
                              decoration: InputDecoration(
                                labelText: 'Coordinates',
                                hintText: 'Paste the copied coordinates here',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(Icons.link),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.paste),
                                  onPressed: _pasteFromClipboard,
                                  tooltip: 'Paste from clipboard',
                                ),
                              ),
                              onChanged: (value) {
                                _mapUrl = value;
                                _extractCoordinatesFromUrl(value);
                              },
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),

                      // Hidden form fields for validation
                      TextFormField(
                        controller: _latitude,
                        style: const TextStyle(fontSize: 0, height: 0),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please add a location from Google Maps';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _longitude,
                        style: const TextStyle(fontSize: 0, height: 0),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Action Buttons
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.grey[200]!, width: 1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (!widget.isUpdate)
                              OutlinedButton(
                                onPressed: _resetForm,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey[700],
                                  side: BorderSide(color: Colors.grey[400]!),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Reset Form'),
                              ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedStatus == "RENEWAL"
                                    ? Colors.orange[700]
                                    : Colors.red[700],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 25,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                _selectedStatus == "RENEWAL"
                                    ? 'Renew Establishment'
                                    : widget.isUpdate
                                    ? 'Update Establishment'
                                    : 'Save Establishment',
                              ),
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

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    String? subText,
  }) {
    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.blue[100]!, width: 2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 24, color: Colors.blue[700]),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[900],
                ),
              ),
              if (subText != null) ...[
                const SizedBox(height: 4),
                Text(
                  subText,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ],
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          suffixIcon: suffixIcon,
        ),
        style: const TextStyle(fontSize: 16, color: Colors.black),
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
    bool isDisabled = false,
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
        fillColor: isDisabled ? Colors.grey[100] : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      items: items,
      onChanged: isDisabled ? null : onChanged,
      validator: validator,
      dropdownColor: Colors.white,
      icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
    );
  }

  void _openGoogleMaps() async {
    const mapsUrl = 'https://www.google.com/maps';
    final Uri uri = Uri.parse(mapsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps')),
      );
    }
  }

  void _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData('text/plain');
    if (clipboardData?.text != null) {
      setState(() {
        _mapUrl = clipboardData!.text;
      });
      _extractCoordinatesFromUrl(_mapUrl!);
    }
  }

  void _extractCoordinatesFromUrl(String url) {
    try {
      // Try to extract coordinates from various Google Maps URL formats
      RegExp coordRegex = RegExp(r'@(-?\d+\.\d+),(-?\d+\.\d+)');
      RegExpMatch? match = coordRegex.firstMatch(url);

      if (match != null) {
        double lat = double.parse(match.group(1)!);
        double lng = double.parse(match.group(2)!);
        _latitude.text = lat.toString();
        _longitude.text = lng.toString();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Coordinates extracted: $lat, $lng'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // Fallback to simple comma-separated format
        List<String> parts = url.split(',');
        if (parts.length >= 2) {
          double lat = double.parse(parts[0].trim());
          double lng = double.parse(parts[1].trim());
          _latitude.text = lat.toString();
          _longitude.text = lng.toString();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Coordinates extracted: $lat, $lng'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not extract coordinates: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
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
    _floorAreaController.dispose();
    _storeysController.dispose();
    _latitude.dispose();
    _longitude.dispose();
    _occupancyType.dispose();
    super.dispose();
  }
}
