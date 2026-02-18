import 'package:bfp_record_mapping/api/api_key.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ApprovedReportDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> report;
  final VoidCallback? onStatusUpdated;

  const ApprovedReportDetailsScreen({
    super.key,
    required this.report,
    this.onStatusUpdated,
  });

  @override
  State<ApprovedReportDetailsScreen> createState() =>
      _ApprovedReportDetailsScreenState();
}

class _ApprovedReportDetailsScreenState
    extends State<ApprovedReportDetailsScreen> {
  Future<void> _printReport(
    BuildContext context,
    Map<String, dynamic> report,
  ) async {
    try {
      final reportData = report['report'] ?? {};
      final groupedAnswers = report['grouped_answers'] as Map? ?? {};

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Create PDF document
      final pdf = pw.Document();

      // Add PDF page
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(bottom: 20),
            child: pw.Column(
              children: [
                pw.Text(
                  'BFP FIRE SAFETY INSPECTION REPORT',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  reportData['report_no'] ?? 'N/A',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          footer: (context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 20),
            child: pw.Text(
              'Generated on: ${_formatDateForPdf(DateTime.now())}',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
            ),
          ),
          build: (context) => [
            // Building Information
            _buildPdfSection('BUILDING INFORMATION', [
              _buildPdfRow(
                'Building Name',
                reportData['building_name'] ?? 'N/A',
              ),
              _buildPdfRow('Address', reportData['building_address'] ?? 'N/A'),
              _buildPdfRow('Inspector', reportData['inspector_name'] ?? 'N/A'),
              _buildPdfRow(
                'Inspection Date',
                _formatDateForPdf(reportData['inspection_date']),
              ),
            ]),

            pw.SizedBox(height: 20),

            // Statistics
            _buildPdfSection('INSPECTION SUMMARY', [
              pw.Row(
                children: [
                  _buildPdfStatBox(
                    'Total Items',
                    '${reportData['total_items'] ?? 0}',
                    PdfColors.blue,
                  ),
                  pw.SizedBox(width: 10),
                  _buildPdfStatBox(
                    'Passed',
                    '${reportData['passed_items'] ?? 0}',
                    PdfColors.green,
                  ),
                  pw.SizedBox(width: 10),
                  _buildPdfStatBox(
                    'Failed',
                    '${reportData['failed_items'] ?? 0}',
                    PdfColors.red,
                  ),
                ],
              ),
            ]),

            pw.SizedBox(height: 20),

            // Checklist Sections
            ...groupedAnswers.entries.map((entry) {
              final sectionName = entry.key;
              final items = entry.value as List;

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    color: PdfColors.grey300,
                    child: pw.Text(
                      sectionName,
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  ...items.map((item) => _buildPdfQuestion(item)).toList(),
                  pw.SizedBox(height: 16),
                ],
              );
            }).toList(),

            pw.SizedBox(height: 30),

            // Signatures
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Inspector:'),
                    pw.SizedBox(height: 30),
                    pw.Text(
                      reportData['inspector_name'] ?? '_____________________',
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Date:'),
                    pw.SizedBox(height: 30),
                    pw.Text(_formatDateForPdf(DateTime.now())),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      // Close loading dialog
      Navigator.pop(context);

      // Print the PDF
      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'Inspection_Report_${reportData['report_no'] ?? 'N/A'}',
      );
    } catch (e) {
      // Close loading dialog if error
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Print error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper method to build PDF section
  pw.Container _buildPdfSection(String title, List<pw.Widget> children) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.Divider(),
          pw.SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  // Helper method to build PDF row
  pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        children: [
          pw.Container(
            width: 120,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  // Helper method to build PDF stat box
  pw.Expanded _buildPdfStatBox(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color),
          borderRadius: pw.BorderRadius.circular(5),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
            pw.Text(label, style: pw.TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // Helper method to build PDF question
  pw.Widget _buildPdfQuestion(Map<String, dynamic> item) {
    final type = item['type'] ?? '';
    final value = item['value'];
    var question = item['item_text'] ?? 'Unknown Item';

    // Clean question text
    question = question
        .replaceAll('__________________________', '')
        .replaceAll('________________', '')
        .replaceAll('__________', '')
        .replaceAll('_____', '')
        .replaceAll('____', '')
        .replaceAll('___', '')
        .replaceAll('__', '')
        .replaceAll('_', '')
        .replaceAll('---', '')
        .replaceAll('--', '')
        .replaceAll('-', '')
        .trim();

    // Text answers
    if (type.contains('text') ||
        type.contains('number') ||
        type.contains('measurement')) {
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 8),
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              question,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 5),
            pw.Text(value?.toString() ?? ''),
          ],
        ),
      );
    }

    // Single checkbox
    if (type.contains('checkbox') && value is List && value.length == 1) {
      final isPassed = value[0] == true;
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 8),
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(
            color: isPassed ? PdfColors.green : PdfColors.red,
          ),
          borderRadius: pw.BorderRadius.circular(4),
          color: isPassed ? PdfColors.green50 : PdfColors.red50,
        ),
        child: pw.Row(
          children: [
            pw.Text(
              isPassed ? '✓' : '✗',
              style: pw.TextStyle(
                color: isPassed ? PdfColors.green : PdfColors.red,
                fontSize: 16,
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(child: pw.Text(question)),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: pw.BoxDecoration(
                color: isPassed ? PdfColors.green100 : PdfColors.red100,
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Text(
                isPassed ? 'PASSED' : 'FAILED',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: isPassed ? PdfColors.green : PdfColors.red,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Checkbox group
    if (type.contains('checkbox') && value is List && value.length > 1) {
      final selectedIndices = [];
      for (int i = 0; i < value.length; i++) {
        if (value[i] == true) selectedIndices.add(i);
      }

      if (selectedIndices.isEmpty) {
        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 8),
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(4),
            color: PdfColors.grey50,
          ),
          child: pw.Row(
            children: [
              pw.Text(
                'No selection',
                style: pw.TextStyle(color: PdfColors.grey),
              ),
            ],
          ),
        );
      }

      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 8),
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              question,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Wrap(
              spacing: 8,
              children: selectedIndices.map((index) {
                final isPassed = index == 0;
                return pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: pw.BoxDecoration(
                    color: isPassed ? PdfColors.green50 : PdfColors.red50,
                    borderRadius: pw.BorderRadius.circular(12),
                    border: pw.Border.all(
                      color: isPassed ? PdfColors.green200 : PdfColors.red200,
                    ),
                  ),
                  child: pw.Text(
                    isPassed ? 'PASSED' : 'FAILED',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: isPassed ? PdfColors.green : PdfColors.red,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    }

    return pw.SizedBox.shrink();
  }

  // Helper method to format date for PDF
  String _formatDateForPdf(dynamic date) {
    if (date == null) return 'N/A';
    try {
      if (date is String) {
        final d = DateTime.parse(date);
        return '${d.day}/${d.month}/${d.year}';
      } else if (date is DateTime) {
        return '${date.day}/${date.month}/${date.year}';
      }
      return date.toString();
    } catch (e) {
      return date.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportData = widget.report['report'] ?? {};
    final groupedAnswers = widget.report['grouped_answers'] as Map? ?? {};

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              _printReport(context, widget.report);
            },
          ),
          // Status Chip
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

                const SizedBox(height: 24),
                if (widget.onStatusUpdated != null)
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
    final key = item['key'] ?? '';
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

  // Action Buttons (only shown if onStatusUpdated is provided)
  Widget _buildActionButtons(
    Map<String, dynamic> report,
    BuildContext context,
  ) {
    final currentStatus =
        report['overall_status']?.toString().toUpperCase() ?? 'PENDING';
    final reportId = report['report_id'];

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
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 500) {
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
                          ? () => _approveReport(reportId, context, "decline")
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
                            ? () => _approveReport(reportId, context, "decline")
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

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    required bool disabled,
  }) {
    return Container(
      height: 56,
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
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: disabled ? Colors.grey[500] : color,
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
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

  Future<void> _approveReport(
    int? reportId,
    BuildContext context,
    String status,
  ) async {
    if (reportId == null) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final response =
          await ApiPhp(
            tableName: "inspection_reports",
            parameters: {'report_id': reportId, 'action': status},
          ).update(
            subUrl: 'https://luvpark.ph/luvtest/mapping/approve_reports.php',
          );

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response["message"]),
          backgroundColor: response["success"] == true
              ? Colors.green[700]
              : Colors.red[700],
          duration: const Duration(seconds: 2),
        ),
      );

      if (response["success"] == true) {
        if (widget.onStatusUpdated != null) {
          widget.onStatusUpdated!();
        }
        Navigator.pop(context);
      }
    } catch (e) {
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
      case 'APPROVED':
        return Colors.green[700]!;
      case 'FAILED':
      case 'DECLINED':
        return Colors.red[700]!;
      case 'PENDING':
        return Colors.orange[700]!;
      default:
        return Colors.grey[700]!;
    }
  }
}
