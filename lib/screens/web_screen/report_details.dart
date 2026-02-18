import 'package:bfp_record_mapping/api/api_key.dart';
import 'package:flutter/material.dart';

class ReportDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> report;
  final VoidCallback onStatusUpdated;

  const ReportDetailsScreen({
    super.key,
    required this.report,
    required this.onStatusUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final reportData = report['report'] ?? {};
    final groupedAnswers = report['grouped_answers'] as Map? ?? {};
    print('All sections: ${groupedAnswers.keys.toList()}');
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          reportData['report_no'] ?? 'Inspection Report',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black87,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(
                reportData['overall_status'],
              ).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              reportData['overall_status'] ?? 'PENDING',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _getStatusColor(reportData['overall_status']),
              ),
            ),
          ),
        ],
      ),
      body: groupedAnswers.isEmpty
          ? Center(
              child: Text('No data', style: TextStyle(color: Colors.grey[600])),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reportData['building_name'] ?? 'Unknown Building',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reportData['building_address'] ?? '',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Inspector: ${reportData['inspector_name'] ?? 'N/A'}',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ),
                          Text(
                            'Date: ${_formatDate(reportData['inspection_date'])}',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Stats
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat('Total', '${reportData['total_items'] ?? 0}'),
                      _buildStat(
                        'Passed',
                        '${reportData['passed_items'] ?? 0}',
                        color: Colors.green[700],
                      ),
                      _buildStat(
                        'Failed',
                        '${reportData['failed_items'] ?? 0}',
                        color: Colors.red[700],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Checklist Sections
                ...groupedAnswers.entries.map(
                  (entry) => _buildSection(entry.key, entry.value),
                ),

                // ✅ APPROVE/DECLINE BUTTONS
                const SizedBox(height: 24),
                _buildActionButtons(reportData, context),
                const SizedBox(height: 30),
              ],
            ),
    );
  }

  Widget _buildStat(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildSection(String sectionName, List items) {
    // ✅ FILTER OUT DUPLICATE CHECKBOXES THAT HAVE NO VALUE
    final filteredItems = items.where((item) {
      final key = item['key'] ?? '';
      final value = item['value'];

      // ✅ KEEP text_ fields (they have the answers)
      if (key.startsWith('text_')) return true;

      // ✅ KEEP checkbox groups (multiple options)
      if (key.startsWith('checkbox_') && value is List && value.length > 1) {
        return true;
      }

      // ✅ KEEP checkbox if it's the only one AND it has a value (true/false matters)
      if (key.startsWith('checkbox_') && value is List && value.length == 1) {
        // BUT HIDE if there's a corresponding text_ field with the same ID
        final id = key.split('_').last;
        final hasTextField = items.any((i) => i['key'] == 'text_$id');
        return !hasTextField; // Only show if NO matching text field exists
      }

      // ❌ HIDE everything else (duplicate checkboxes)
      return false;
    }).toList();

    // If no items left after filtering, don't show the section
    if (filteredItems.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            color: Colors.grey[100],
            child: Text(
              sectionName,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),

          // Questions - ONLY the filtered ones
          ...filteredItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildQuestion(item),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion(Map<String, dynamic> item) {
    final key = item['key'] ?? ''; // ADD THIS LINE
    final type = item['type'] ?? '';
    final value = item['value'];
    var question = item['item_text'] ?? 'Unknown Item';
    final options = item['checkbox_options'] as List?;

    // ✅ REMOVE ALL UNDERSCORES AND DASHES
    question = question
        .replaceAll('__________________________', '')
        .replaceAll('________________', '')
        .replaceAll('__________', '')
        .replaceAll('____________', '')
        .replaceAll('_________', '')
        .replaceAll('________', '')
        .replaceAll('_______', '')
        .replaceAll('______', '')
        .replaceAll('_____', '')
        .replaceAll('____', '')
        .replaceAll('___', '')
        .replaceAll('__', '')
        .replaceAll('_', '')
        .replaceAll('---', '')
        .replaceAll('--', '')
        .replaceAll('-', '')
        .trim();

    // Add this before your other type checks
    if (type.contains('inline_text_with_date') ||
        key.contains('_text') ||
        key.contains('_date')) {
      // Skip individual text/date items - they will be handled together
      return const SizedBox.shrink();
    }

    // TEXT INPUT
    if (type.contains('text')) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(value?.toString() ?? '', style: const TextStyle(fontSize: 13)),
          ],
        ),
      );
    }

    // SINGLE CHECKBOX
    if (type.contains('checkbox') && value is List && value.length == 1) {
      final isPassed = value[0] == true;
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Text(
              isPassed ? '✓' : '✗',
              style: TextStyle(
                color: isPassed ? Colors.green[700] : Colors.red[700],
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(question, style: const TextStyle(fontSize: 13)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isPassed ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                isPassed ? 'PASSED' : 'FAILED',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isPassed ? Colors.green[800] : Colors.red[800],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // CHECKBOX GROUP
    if (type.contains('checkbox') && value is List && value.length > 1) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: value.asMap().entries.map((entry) {
                final index = entry.key;
                final isSelected = entry.value;
                final optionLabel = options != null && index < options.length
                    ? options[index].toString().replaceAll('\\/', '/')
                    : index == 0
                    ? 'Passed'
                    : index == 1
                    ? 'Failed'
                    : 'N/A';

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (index == 0
                              ? Colors.green[50]
                              : index == 1
                              ? Colors.red[50]
                              : Colors.grey[50])
                        : Colors.grey[100],
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    optionLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? (index == 0
                                ? Colors.green[800]
                                : index == 1
                                ? Colors.red[800]
                                : Colors.grey[800])
                          : Colors.grey[600],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // ✅ ENHANCED - Bigger, More Visible Buttons
  Widget _buildActionButtons(
    Map<String, dynamic> report,
    BuildContext context,
  ) {
    final currentStatus =
        report['overall_status']?.toString().toUpperCase() ?? 'PENDING';
    final reportId = report['report_id']; // Get the report ID

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 0),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review Report',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          // Stack buttons vertically on smaller screens
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 500) {
                return Column(
                  children: [
                    _buildActionButton(
                      label: 'Approve',
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                      onPressed: () => _approveReport(reportId, context),
                      disabled: false,
                    ),
                    const SizedBox(height: 12),
                    _buildActionButton(
                      label: 'Decline',
                      icon: Icons.cancel_outlined,
                      color: Colors.red,
                      onPressed: currentStatus != 'FAILED'
                          ? () => _declineReport(reportId, context)
                          : null,
                      disabled: currentStatus == 'FAILED',
                    ),
                    const SizedBox(height: 12),
                    _buildActionButton(
                      label: 'Pending',
                      icon: Icons.access_time,
                      color: Colors.orange,
                      onPressed: currentStatus != 'PENDING'
                          ? () => _pendingReport(reportId, context)
                          : null,
                      disabled: currentStatus == 'PENDING',
                    ),
                  ],
                );
              } else {
                return Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        label: 'Approve',
                        icon: Icons.check_circle_outline,
                        color: Colors.green,
                        onPressed: () => _approveReport(reportId, context),
                        disabled: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        label: 'Decline',
                        icon: Icons.cancel_outlined,
                        color: Colors.red,
                        onPressed: currentStatus != 'FAILED'
                            ? () => _declineReport(reportId, context)
                            : null,
                        disabled: currentStatus == 'FAILED',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        label: 'Pending',
                        icon: Icons.access_time,
                        color: Colors.orange,
                        onPressed: currentStatus != 'PENDING'
                            ? () => _pendingReport(reportId, context)
                            : null,
                        disabled: currentStatus == 'PENDING',
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // Helper method to build consistent action buttons
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    required bool disabled,
  }) {
    return Container(
      height: 56, // Taller buttons
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: disabled
            ? null
            : [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        color: disabled ? Colors.grey[200] : color.withOpacity(0.05),
        child: InkWell(
          onTap: disabled ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: disabled ? Colors.grey[300]! : color.withOpacity(0.5),
                width: 1.5, // Thicker border
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 22, // Bigger icon
                  color: disabled ? Colors.grey[500] : color,
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16, // Bigger text
                    fontWeight: FontWeight.w600,
                    color: disabled ? Colors.grey[500] : color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ APPROVE REPORT - Updates both tables
  Future<void> _approveReport(int? reportId, BuildContext context) async {
    print("reportId $reportId");
    if (reportId == null) return;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final response =
          await ApiPhp(
            tableName: "inspection_reports",
            parameters: {'report_id': reportId},
          ).update(
            subUrl: 'https://luvpark.ph/luvtest/mapping/approve_reports.php',
          );

      // Close loading dialog
      Navigator.pop(context);

      print('Approve response: $response');

      if (response["success"] == true) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Report approved successfully'),
            backgroundColor: Colors.green[700],
            duration: const Duration(seconds: 2),
          ),
        );

        // Refresh the reports list
        onStatusUpdated();

        // Close the details screen and go back
        Navigator.pop(context);
      } else {
        throw Exception(response["message"] ?? 'Failed to approve');
      }
    } catch (e) {
      // Close loading dialog if error
      Navigator.pop(context);

      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  // ✅ DECLINE REPORT
  Future<void> _declineReport(int? reportId, BuildContext context) async {
    if (reportId == null) return;

    // TODO: Implement decline API call
    print('Declining report: $reportId');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Decline functionality coming soon'),
        backgroundColor: Colors.orange[700],
      ),
    );
    onStatusUpdated();
  }

  // ✅ PENDING REPORT
  Future<void> _pendingReport(int? reportId, BuildContext context) async {
    if (reportId == null) return;

    // TODO: Implement pending API call
    print('Marking as pending: $reportId');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Marked as pending'),
        backgroundColor: Colors.orange[700],
      ),
    );
    onStatusUpdated();
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return 'N/A';
    try {
      final d = DateTime.parse(date);
      return '${d.day}/${d.month}/${d.year}';
    } catch (e) {
      return date;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'PASSED':
        return Colors.green[700]!;
      case 'FAILED':
        return Colors.red[700]!;
      case 'PENDING':
        return Colors.orange[700]!;
      default:
        return Colors.grey[700]!;
    }
  }
}
