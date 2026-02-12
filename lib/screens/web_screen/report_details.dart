import 'dart:convert';

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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Inspection Report',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black87,
        actions: [
          // Status Badge
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _getStatusColor().withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(_getStatusIcon(), size: 16, color: _getStatusColor()),
                const SizedBox(width: 6),
                Text(
                  report['overall_status'] ?? 'PENDING',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report Header Card
            _buildHeaderCard(),
            const SizedBox(height: 16),

            // Statistics Card
            _buildStatisticsCard(),
            const SizedBox(height: 16),

            // Checklist Responses Card
            _buildChecklistCard(),
            const SizedBox(height: 16),

            // Notes Card
            if (report['notes'] != null &&
                report['notes'].toString().isNotEmpty)
              _buildNotesCard(),
            const SizedBox(height: 16),

            // Action Buttons
            _buildActionButtons(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Header Card
  Widget _buildHeaderCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.description,
                    color: Color(0xFFD32F2F),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report['report_no'] ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDateTime(report['submission_date']),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Establishment Info
            Row(
              children: [
                Icon(Icons.business, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report['building_name'] ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      if (report['building_address'] != null)
                        Text(
                          report['building_address'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Inspector and Date
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Inspector',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              report['inspector_name'] ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Inspection Date',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              _formatDate(report['inspection_date']),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Statistics Card
  Widget _buildStatisticsCard() {
    final total = report['total_items'] ?? 0;
    final passed = report['passed_items'] ?? 0;
    final failed = report['failed_items'] ?? 0;
    final na = report['na_items'] ?? 0;
    final compliance = total > 0
        ? (passed / total * 100).toStringAsFixed(1)
        : '0';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Inspection Summary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),

            // Stats Row
            Row(
              children: [
                _buildStatItem('Total', '$total', Icons.list, Colors.blue),
                _buildStatItem(
                  'Passed',
                  '$passed',
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatItem('Failed', '$failed', Icons.cancel, Colors.red),
                _buildStatItem('N/A', '$na', Icons.help_outline, Colors.grey),
              ],
            ),
            const SizedBox(height: 16),

            // Compliance Rate
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.analytics, color: Colors.green.shade700, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Compliance Rate',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$compliance%',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Text(
                      '${report['overall_status'] ?? 'PENDING'}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(),
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
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // Checklist Card - Parse and display the answers JSON
  Widget _buildChecklistCard() {
    try {
      Map<String, dynamic> answers = {};

      // Parse answers JSON
      if (report['answers'] is String) {
        answers = jsonDecode(report['answers']);
      } else if (report['answers'] is Map) {
        answers = report['answers'];
      }

      if (answers.isEmpty) {
        return _buildEmptyChecklist();
      }

      // Group answers by type
      final textAnswers = <String, String>{};
      final checkboxAnswers = <String, List<bool>>{};
      final measurementAnswers = <String, String>{};
      final remarksAnswers = <String, String>{};

      answers.forEach((key, value) {
        if (key.startsWith('text_')) {
          textAnswers[key] = value.toString();
        } else if (key.startsWith('checkbox_')) {
          if (value is List) {
            checkboxAnswers[key] = List<bool>.from(value);
          }
        } else if (key.startsWith('measurement_')) {
          measurementAnswers[key] = value.toString();
        } else if (key.startsWith('remarks_')) {
          remarksAnswers[key] = value.toString();
        }
      });

      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Checklist Responses',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),

              // Text Answers
              if (textAnswers.isNotEmpty) ...[
                _buildSectionHeader(
                  'Text Inputs',
                  Icons.text_fields,
                  Colors.blue,
                ),
                const SizedBox(height: 8),
                ...textAnswers.entries.map(
                  (e) => _buildTextItem(e.key, e.value),
                ),
                const SizedBox(height: 16),
              ],

              // Measurements
              if (measurementAnswers.isNotEmpty) ...[
                _buildSectionHeader(
                  'Measurements',
                  Icons.straighten,
                  Colors.orange,
                ),
                const SizedBox(height: 8),
                ...measurementAnswers.entries.map(
                  (e) => _buildTextItem(e.key, e.value),
                ),
                const SizedBox(height: 16),
              ],

              // Checkbox Items
              if (checkboxAnswers.isNotEmpty) ...[
                _buildSectionHeader(
                  'Checklist Items',
                  Icons.check_box,
                  Colors.green,
                ),
                const SizedBox(height: 8),
                ...checkboxAnswers.entries.map(
                  (e) => _buildCheckboxItem(e.key, e.value),
                ),
                const SizedBox(height: 16),
              ],

              // Remarks
              if (remarksAnswers.isNotEmpty) ...[
                _buildSectionHeader('Remarks', Icons.comment, Colors.purple),
                const SizedBox(height: 8),
                ...remarksAnswers.entries.map(
                  (e) => _buildTextItem(e.key, e.value),
                ),
              ],
            ],
          ),
        ),
      );
    } catch (e) {
      return _buildErrorChecklist(e.toString());
    }
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTextItem(String key, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              key.split('_').last,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildCheckboxItem(String key, List<bool> values) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Item ${key.split('_').last}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final isPassed = entry.value;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isPassed ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isPassed
                        ? Colors.green.shade200
                        : Colors.red.shade200,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPassed ? Icons.check_circle : Icons.cancel,
                      size: 14,
                      color: isPassed
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Option $index: ${isPassed ? 'Passed' : 'Failed'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isPassed
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChecklist() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.inbox, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No checklist responses',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorChecklist(String error) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.shade200),
      ),
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Error loading responses',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF991B1B),
                    ),
                  ),
                  Text(
                    error,
                    style: TextStyle(fontSize: 12, color: Colors.red.shade800),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Notes Card
  Widget _buildNotesCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.shade200),
      ),
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.note_alt, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Remarks',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9A3412),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report['notes'],
                    style: TextStyle(color: Colors.orange.shade900),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Action Buttons
  Widget _buildActionButtons() {
    final currentStatus =
        report['overall_status']?.toString().toUpperCase() ?? 'PENDING';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),

            // Status Update Buttons
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    label: 'PASSED',
                    icon: Icons.check_circle,
                    color: Colors.green,
                    isEnabled: currentStatus != 'PASSED',
                    onPressed: currentStatus != 'PASSED'
                        ? () => _updateStatus('PASSED')
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    label: 'FAILED',
                    icon: Icons.cancel,
                    color: Colors.red,
                    isEnabled: currentStatus != 'FAILED',
                    onPressed: currentStatus != 'FAILED'
                        ? () => _updateStatus('FAILED')
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    label: 'PENDING',
                    icon: Icons.pending,
                    color: Colors.orange,
                    isEnabled: currentStatus != 'PENDING',
                    onPressed: currentStatus != 'PENDING'
                        ? () => _updateStatus('PENDING')
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isEnabled,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isEnabled ? color : Colors.grey.shade300,
        foregroundColor: isEnabled ? Colors.white : Colors.grey.shade600,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: isEnabled ? 2 : 0,
      ),
    );
  }

  // Helper Methods
  Future<void> _updateStatus(String newStatus) async {
    // Your API call to update status
    // This will be implemented with your ApiPhp class
    print('Updating status to: $newStatus');

    // After successful update:
    onStatusUpdated();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  Color _getStatusColor() {
    final status = report['overall_status']?.toString().toUpperCase();
    switch (status) {
      case 'PASSED':
        return Colors.green;
      case 'FAILED':
        return Colors.red;
      case 'PENDING':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    final status = report['overall_status']?.toString().toUpperCase();
    switch (status) {
      case 'PASSED':
        return Icons.check_circle;
      case 'FAILED':
        return Icons.cancel;
      case 'PENDING':
        return Icons.pending;
      default:
        return Icons.help;
    }
  }
}
