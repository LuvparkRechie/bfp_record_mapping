import 'package:flutter/material.dart';

class ApprovedReportDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> report;

  const ApprovedReportDetailsScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final reportData = report['report'] ?? {};
    final groupedAnswers = report['grouped_answers'] as Map? ?? {};
    print("reportData $reportData");
    print("groupedAnswers $groupedAnswers");

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
                      _buildStat(
                        'N/A',
                        '${reportData['na_items'] ?? 0}',
                        color: Colors.grey[700],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Checklist Sections - ONLY SHOWS ITEMS WITH ANSWERS
                ...groupedAnswers.entries.map(
                  (entry) => _buildSection(entry.key, entry.value),
                ),

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
    // ✅ FILTER ITEMS - ONLY SHOW THOSE WITH VALUES
    final filteredItems = items.where((item) {
      final key = item['key'] ?? '';
      final value = item['value'];

      // Skip if value is null or empty
      if (value == null) return false;

      // For text fields, check if there's actual text
      if (key.startsWith('text_')) {
        final textValue = value.toString().trim();
        return textValue.isNotEmpty && textValue != 'null';
      }

      // For checkboxes, check if any are checked
      if (key.startsWith('checkbox_') && value is List) {
        // Check if any checkbox is true
        return value.any((v) => v == true);
      }

      // For passed/failed values
      if (key.startsWith('passed_') || key.startsWith('failed_')) {
        return value == true;
      }

      // For measurements
      if (key.startsWith('measurement_')) {
        final measurement = value.toString().trim();
        return measurement.isNotEmpty && measurement != 'null';
      }

      // For remarks
      if (key.startsWith('remarks_')) {
        final remark = value.toString().trim();
        return remark.isNotEmpty && remark != 'null';
      }

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
    final type = item['type'] ?? '';
    final key = item['key'] ?? '';
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

    // TEXT INPUT
    if (key.startsWith('text_')) {
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                value?.toString() ?? '',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    // MEASUREMENT FIELDS
    if (key.startsWith('measurement_')) {
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
            Row(
              children: [
                const Icon(Icons.straighten, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  value?.toString() ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // PASSED/FAILED STATUS
    if (key.startsWith('passed_') && value == true) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.green[200]!),
          borderRadius: BorderRadius.circular(4),
          color: Colors.green[50],
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[700], size: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                question,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'PASSED',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (key.startsWith('failed_') && value == true) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red[200]!),
          borderRadius: BorderRadius.circular(4),
          color: Colors.red[50],
        ),
        child: Row(
          children: [
            Icon(Icons.cancel, color: Colors.red[700], size: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                question,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'FAILED',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // REMARKS
    if (key.startsWith('remarks_')) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue[200]!),
          borderRadius: BorderRadius.circular(4),
          color: Colors.blue[50],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.comment, color: Colors.blue[700], size: 16),
                const SizedBox(width: 8),
                Text(
                  'Remarks',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(value?.toString() ?? '', style: const TextStyle(fontSize: 13)),
          ],
        ),
      );
    }

    // CHECKBOX GROUP
    if (key.startsWith('checkbox_') && value is List && value.length > 1) {
      // Check if any checkbox is selected
      final hasSelected = value.any((v) => v == true);
      if (!hasSelected) return const SizedBox.shrink();

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

                // Only show selected options
                if (!isSelected) return const SizedBox.shrink();

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
                    color: index == 0
                        ? Colors.green[50]
                        : index == 1
                        ? Colors.red[50]
                        : Colors.grey[50],
                    border: Border.all(
                      color: index == 0
                          ? Colors.green[300]!
                          : index == 1
                          ? Colors.red[300]!
                          : Colors.grey[400]!,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    optionLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: index == 0
                          ? Colors.green[800]
                          : index == 1
                          ? Colors.red[800]
                          : Colors.grey[800],
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
      case 'APPROVED':
        return Colors.green[700]!;
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
