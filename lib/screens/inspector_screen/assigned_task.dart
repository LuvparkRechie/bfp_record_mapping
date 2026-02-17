import 'package:bfp_record_mapping/api/api_key.dart';
import 'package:bfp_record_mapping/screens/inspector_screen/checklist.dart';
import 'package:flutter/material.dart';

class InspAssignedTask extends StatefulWidget {
  const InspAssignedTask({super.key});

  @override
  State<InspAssignedTask> createState() => _InspAssignedTaskState();
}

class _InspAssignedTaskState extends State<InspAssignedTask> {
  bool isLoading = true;
  List assignedData = [];

  @override
  void initState() {
    super.initState();
    getAssignedSTask();
  }

  void getAssignedSTask() async {
    setState(() {
      isLoading = true;
    });
    try {
      final api = ApiPhp(tableName: 'assigned_inspections');

      final joinConfig = {
        'join':
            'INNER JOIN establishments e ON e.establishment_id = assigned_inspections.establishment_id',
        'columns': 'assigned_inspections.*, e.business_name',
        'where': 'assigned_inspections.inspector_id = ?',
        'where_params': [4],
        'orderBy': 'assigned_inspections.assigned_id DESC',
        'limit': 100,
      };

      final response = await api.selectWithJoin(joinConfig);
      print("response $response");
      if (response['success']) {
        setState(() {
          assignedData = response['data'];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Safe date formatting methods
  String _formatTime(dynamic dateValue) {
    print("dateValue $dateValue");
    if (dateValue == null) return '--:--';

    try {
      String dateStr = dateValue.toString().trim();

      // Handle empty string
      if (dateStr.isEmpty) return '--:--';

      // Handle common database formats (replace space with T for ISO format)
      if (dateStr.contains(' ')) {
        dateStr = dateStr.replaceFirst(' ', 'T');
      }

      // Remove timezone info if present
      if (dateStr.contains('+')) {
        dateStr = dateStr.split('+')[0];
      }
      if (dateStr.contains('Z')) {
        dateStr = dateStr.replaceAll('Z', '');
      }

      final date = DateTime.parse(dateStr);

      // Format time with AM/PM
      final hour = date.hour;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

      return '$displayHour:$minute $period';
    } catch (e) {
      print('Error formatting time: $e for value: $dateValue');
      return '--:--';
    }
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'Date N/A';

    try {
      String dateStr = dateValue.toString().trim();

      // Handle empty string
      if (dateStr.isEmpty) return 'Date N/A';

      // Handle common database formats
      if (dateStr.contains(' ')) {
        dateStr = dateStr.replaceFirst(' ', 'T');
      }

      // Remove timezone info if present
      if (dateStr.contains('+')) {
        dateStr = dateStr.split('+')[0];
      }
      if (dateStr.contains('Z')) {
        dateStr = dateStr.replaceAll('Z', '');
      }

      final date = DateTime.parse(dateStr);
      return '${date.day} ${_getMonthName(date.month)} ${date.year}';
    } catch (e) {
      print('Error formatting date: $e for value: $dateValue');
      return 'Date N/A';
    }
  }

  String _getMonthName(int month) {
    List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Upcoming Inspections',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Schedule',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '${assignedData.length} inspections scheduled',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            SizedBox(height: 20),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  getAssignedSTask();
                },
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : assignedData.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No inspections scheduled',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: assignedData.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final inspection = assignedData[index];

                          final formattedTime = _formatTime(
                            inspection['schedule_date'],
                          );
                          final formattedDate = _formatDate(
                            inspection['schedule_date'],
                          );

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: inspection["status"] != "IN_REVIEW"
                                  ? null
                                  : Border.all(
                                      color: Colors.blue.shade200,
                                      width: 1,
                                    ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 20,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Time Circle
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          formattedTime.contains('--')
                                              ? '--:--'
                                              : formattedTime.split(' ')[0],
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.blue.shade800,
                                          ),
                                        ),
                                        if (!formattedTime.contains('--'))
                                          Text(
                                            formattedTime.split(' ')[1],
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.blue.shade600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),

                                  SizedBox(width: 16),

                                  // Content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                inspection['business_name'] ??
                                                    'Unknown Business',
                                                style: TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.grey.shade900,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.orange.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                inspection["status"],
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      inspection["status"] !=
                                                          "PENDING"
                                                      ? Colors.red
                                                      : Colors.orange.shade700,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        SizedBox(height: 8),

                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today_outlined,
                                              size: 16,
                                              color: Colors.grey.shade500,
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              formattedDate,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            SizedBox(width: 16),
                                            Icon(
                                              Icons.access_time_outlined,
                                              size: 16,
                                              color: Colors.grey.shade500,
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              formattedTime,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),

                                        SizedBox(height: 16),
                                        if (inspection["status"] == "PENDING")
                                          Container(
                                            height: 44,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.redAccent,
                                                  Colors.redAccent.withValues(
                                                    alpha: 0.3,
                                                  ),
                                                ],
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: TextButton(
                                              onPressed: () async {
                                                final result = await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => ChecklistPage(
                                                      establishmentId:
                                                          inspection['establishment_id'],
                                                      inspectionId:
                                                          inspection['assigned_id'],
                                                    ),
                                                  ),
                                                );

                                                if (result == true) {
                                                  getAssignedSTask();
                                                }
                                              },
                                              style: TextButton.styleFrom(
                                                padding: EdgeInsets.zero,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.play_arrow_outlined,
                                                    size: 20,
                                                    color: Colors.white,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Start Inspection',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 15,
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
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
