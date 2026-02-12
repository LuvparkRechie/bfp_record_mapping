import 'package:bfp_record_mapping/api/api_key.dart';
import 'package:bfp_record_mapping/screens/app_theme.dart';
import 'package:bfp_record_mapping/screens/web_screen/report_details.dart';
import 'package:flutter/material.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();
  List reportsData = [];

  final _scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
    loadBrgyData();
  }

  @override
  void dispose() {
    _scrollController.dispose();

    super.dispose();
  }

  void loadBrgyData() async {
    final result = await ApiPhp(tableName: "inspection_reports").select();

    reportsData = List.from(result["data"]);
    print("reportsData $reportsData");
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Center(child: CircularProgressIndicator(color: Colors.blue[700]))
        : Container(
            color: Colors.white,
            child: Column(
              children: [
                // Top Bar
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Reports',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkGrey,
                        ),
                      ),
                    ],
                  ),
                ),

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
                              DataColumn(
                                label: Text('REPORT NO'),
                                numeric: true,
                              ),
                              DataColumn(
                                label: Text('BUILDING NAME'),
                                tooltip: 'Building name or establishment',
                              ),
                              DataColumn(
                                label: Text('ADDRESS'),
                                tooltip: 'Complete address of the building',
                              ),
                              DataColumn(
                                label: Text('INSPECTOR'),
                                tooltip:
                                    'Name of the inspector who conducted the inspection',
                              ),
                              DataColumn(
                                label: Text('SUBMISSION DATE'),
                                tooltip: 'Date when the report was submitted',
                              ),
                              DataColumn(
                                label: Text('STATUS'),
                                tooltip: 'Active/Inactive status',
                              ),
                              DataColumn(
                                label: Text('ACTIONS'),
                                tooltip:
                                    'Actions you can perform on the report (e.g., view details, edit, delete)',
                              ),
                            ],
                            rows: reportsData.map((reports) {
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
                                        '#${reports["report_no"]}',
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
                                        reports['building_name'],
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
                                        reports['building_address'],
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
                                      "${reports['inspector_name']}",
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
                                        "${reports['submission_date']}",
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

                                      child: Text(
                                        "${reports['status']}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          onPressed: () =>
                                              _navigateToReportDetails(reports),
                                          icon: Icon(
                                            Icons.visibility_outlined,
                                            size: 20,
                                            color: Colors.blue[600],
                                          ),
                                          tooltip: 'View Details',
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
            ),
          );
  }

  void _navigateToReportDetails(Map<String, dynamic> report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportDetailsScreen(
          report: report, // Pass the entire report object
          onStatusUpdated: () {
            // Refresh your reports list when status is updated
          },
        ),
      ),
    );
  }
}
