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

                // Checklist Sections - JUST THE QUESTIONS AND ANSWERS
                ...groupedAnswers.entries.map(
                  (entry) => _buildSection(entry.key, entry.value),
                ),
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

          // Questions
          ...items.map(
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
    final value = item['value'];
    final question = item['item_text'] ?? 'Unknown Item';
    final options = item['checkbox_options'] as List?;

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
