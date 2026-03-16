import 'package:bfp_record_mapping/api/api_key.dart';
import 'package:bfp_record_mapping/api/path_variables.dart';
import 'package:flutter/material.dart';

class ReportDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> reportDetails;
  final VoidCallback onStatusUpdated;
  final Map<String, dynamic> reportsData;

  const ReportDetailsScreen({
    super.key,
    required this.reportDetails,
    required this.onStatusUpdated,
    required this.reportsData,
  });

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Debug the signature
    });
  }

  @override
  Widget build(BuildContext context) {
    final reportData = widget.reportDetails['report'] ?? {};
    final groupedAnswers =
        widget.reportDetails['grouped_answers'] as Map? ?? {};

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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
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

                  // Checklist Sections
                  ...groupedAnswers.entries.map(
                    (entry) => _buildSection(entry.key, entry.value),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(left: 19.0, right: 19),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                "Representative Signature: ${reportData["owner_signature_path"]}",
                              ),
                              Container(
                                margin: EdgeInsets.only(top: 0),
                                width: 150,
                                height: 50,
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: Colors.black54),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    "${ApiKeys.pathVariable}${ApiKeys.getImg}?file=${reportData["owner_signature_path"]}",
                                    fit: BoxFit.contain,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }
                                          return const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          );
                                        },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.white,
                                        child: Center(
                                          child: Icon(
                                            Icons.edit,
                                            size: 30,
                                            color: Colors.grey[400],
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
                        SizedBox(width: 10),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text("Inspector Signature:"),
                              Container(
                                margin: EdgeInsets.only(top: 0),
                                width: 150,
                                height: 50,
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: Colors.black54),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    "${ApiKeys.pathVariable}${ApiKeys.getImg}?file=${reportData["inspector_signature"]}",
                                    fit: BoxFit.contain,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }
                                          return const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          );
                                        },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.white,
                                        child: Center(
                                          child: Icon(
                                            Icons.edit,
                                            size: 30,
                                            color: Colors.grey[400],
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
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  _buildActionButtons(reportData, context),
                  const SizedBox(height: 30),
                ],
              ),
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
                //mobile
                return Column(
                  children: [
                    _buildActionButton(
                      label: 'Approve',
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                      onPressed: () =>
                          _approveReport(reportId, context, "approve"),
                      disabled: false,
                    ),
                    const SizedBox(height: 12),
                    _buildActionButton(
                      label: 'Decline',
                      icon: Icons.cancel_outlined,
                      color: Colors.red,
                      onPressed: currentStatus != 'FAILED'
                          ? () {
                              showSimpleDeclineDialog(context, reportId);
                            }
                          : null,
                      disabled: currentStatus == 'FAILED',
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
                        onPressed: () =>
                            _approveReport(reportId, context, "approve"),
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
                            ? () {
                                //    _approveReport(reportId, context, "decline");
                                showSimpleDeclineDialog(context, reportId);
                              }
                            : null,
                        disabled: currentStatus == 'FAILED',
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
    IconData? icon,
    required Color color,
    required VoidCallback? onPressed,
    required bool disabled,
    double? height,
  }) {
    return Container(
      height: height ?? 56, // Taller buttons
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
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 22, // Bigger icon
                    color: disabled ? Colors.grey[500] : color,
                  ),
                  const SizedBox(width: 10),
                ],

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

  // Usage
  void showSimpleDeclineDialog(BuildContext context, int reportId) {
    showDialog(
      context: context,
      builder: (context) => EnhancedDeclineDialog(
        reportId: reportId,
        onDecline: (reason) {
          _approveReport(reportId, context, "decline", note: reason);
        },
      ),
    );
  }

  // ✅ APPROVE REPORT - Updates both tables
  Future<void> _approveReport(
    int? reportId,
    BuildContext context,
    String status, {
    note,
  }) async {
    if (reportId == null) return;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final response = await ApiPhp(
        tableName: "inspection_reports",
        parameters: {'report_id': reportId, 'action': status, 'note': note},
      ).update(subUrl: '${ApiKeys.pathVariable}${ApiKeys.approveReports}');
      print(" response inspection $response");
      // Close loading dialog
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response["message"]),
          backgroundColor: Colors.green[700],
          duration: const Duration(seconds: 2),
        ),
      );

      if (response["success"] == true) {
        widget.onStatusUpdated();

        // ignore: use_build_context_synchronously
        Navigator.pop(context);
      } else {
        throw Exception(response["message"] ?? 'Failed to approve');
      }
    } catch (e) {
      // Close loading dialog if error
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
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

class EnhancedDeclineDialog extends StatelessWidget {
  final int reportId;
  final Function(String reason) onDecline;

  const EnhancedDeclineDialog({
    Key? key,
    required this.reportId,
    required this.onDecline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController reasonController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_rounded,
                      color: Colors.red.shade700,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Decline Report',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Report ID card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Report #$reportId',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You are about to decline this report',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Reason label
              const Text(
                'Reason for declining',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              // Reason text field
              TextFormField(
                controller: reasonController,
                maxLines: 6,
                minLines: 6,
                decoration: InputDecoration(
                  hintText: 'Please provide a detailed reason...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.red.shade700,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Reason is required';
                  }
                  if (value.trim().length < 10) {
                    return 'Please provide at least 10 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 8),

              // Character count
              Align(
                alignment: Alignment.centerRight,
                child: ValueListenableBuilder(
                  valueListenable: reasonController,
                  builder: (context, TextEditingValue value, child) {
                    return Text(
                      '${value.text.length}/500',
                      style: TextStyle(
                        fontSize: 12,
                        color: value.text.length > 500
                            ? Colors.red
                            : Colors.grey.shade600,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'CANCEL',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          onDecline(reasonController.text.trim());
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'DECLINE',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
