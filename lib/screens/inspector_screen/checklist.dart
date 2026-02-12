import 'dart:convert';

import 'package:bfp_record_mapping/api/api_key.dart';
import 'package:flutter/material.dart';

class ChecklistPage extends StatefulWidget {
  final int establishmentId, inspectionId;
  const ChecklistPage({
    super.key,
    required this.establishmentId,
    required this.inspectionId,
  });

  @override
  State<ChecklistPage> createState() => _ChecklistPageState();
}

class _ChecklistPageState extends State<ChecklistPage> {
  bool _loading = true;
  List<dynamic> _checklist = [];

  // State management maps
  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, TextEditingController> _measurementControllers = {};
  final Map<String, TextEditingController> _remarksControllers = {};
  final Map<String, bool> _passedValues = {};
  final Map<String, bool> _failedValues = {};
  final Map<String, List<bool>> _checkboxGroupValues = {};

  final Map<String, bool> _evacuationCheckboxes = {};
  final Map<String, bool> _evacuationSecondCheckboxes = {};

  @override
  void initState() {
    super.initState();
    _fetchChecklist();
    _initializeEvacuationCheckboxes();
  }

  void _initializeEvacuationCheckboxes() {
    _evacuationCheckboxes['overall'] = false;
    _evacuationSecondCheckboxes['overall_failed'] = false;
  }

  @override
  void dispose() {
    for (var c in _textControllers.values) {
      c.dispose();
    }
    for (var c in _measurementControllers.values) {
      c.dispose();
    }
    for (var c in _remarksControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchChecklist() async {
    try {
      final response = await ApiPhp(tableName: "checklist_templates").select(
        subURl: "https://luvpark.ph/luvtest/mapping/checklist_template.php",
      );

      print('API Response: $response');

      final bool success =
          response["success"] == true || response["status"] == "success";

      if (success) {
        final data = response["data"] ?? [];
        setState(() {
          _checklist = List<dynamic>.from(data);
          _loading = false;
          _initializeControllers();
          print('Loaded ${_checklist.length} items');
        });
      } else {
        throw Exception(response["message"] ?? "Unknown error");
      }
    } catch (e) {
      print("ERROR: $e");
      setState(() => _loading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorDialog(e.toString());
      });
    }
  }

  void _initializeControllers() {
    for (var item in _checklist) {
      final String id = _getId(item);
      final String fieldType = _getFieldType(item);
      final String itemText = _getString(item, 'item_text') ?? '';

      // Initialize based on field type
      switch (fieldType) {
        case 'inline_text':
        case 'inline_date':
        case 'inline_text_with_date':
        case 'inline_checkbox_with_text':
          _checkboxGroupValues[id] = [false];
          // Initialize text controller with the id
          _textControllers[id] = TextEditingController();
          break;
        case 'multiline_text':
        case 'inline_number':
        case 'text':
        case 'textarea':
        case 'date':
          _textControllers[id] = TextEditingController();
          break;

        case 'hybrid_measurement_passfail':
        case 'hybrid_measurement_passfail_remarks':
          _measurementControllers[id] = TextEditingController();
          _passedValues[id] = false;
          _failedValues[id] = false;
          if (fieldType == 'hybrid_measurement_passfail_remarks') {
            _remarksControllers[id] = TextEditingController();
          }
          break;

        case 'checkbox':
        case 'inline_checkbox':
          _checkboxGroupValues[id] = [false];
          break;

        case 'inline_yes_no':
          _checkboxGroupValues['${id}_yes'] = [false];
          _checkboxGroupValues['${id}_no'] = [false];
          break;

        case 'checkbox_group':
          final options = _getCheckboxOptions(item);
          _checkboxGroupValues[id] = List<bool>.filled(
            options?.length ?? 2,
            false,
          );
          break;

        case 'inline_checkbox_group':
          // Special handling for inline_checkbox_group
          // Parse the text to count how many checkboxes
          final items = itemText.split('/');
          int checkboxCount = 0;

          for (var textItem in items) {
            final cleanItem = textItem.replaceAll('[   ]', '').trim();
            if (cleanItem.isNotEmpty) {
              checkboxCount++;
            }
          }

          // Initialize with the correct number of checkboxes
          _checkboxGroupValues[id] = List<bool>.filled(
            checkboxCount > 0
                ? checkboxCount
                : 2, // Default to 2 if parsing fails
            false,
          );
        // In the _buildChecklistItem method, add this to the switch statement:
        case 'label':
          _buildLabel(text: itemText);
          break;
      }
    }
  }

  String _getId(dynamic item) {
    if (item is Map) {
      return item['template_id']?.toString() ?? 'unknown';
    }
    return 'unknown';
  }

  String _getFieldType(dynamic item) {
    if (item is Map) {
      return item['field_type']?.toString() ??
          item['input_type']?.toString() ??
          'checkbox';
    }
    return 'checkbox';
  }

  List<String>? _getCheckboxOptions(dynamic item) {
    if (item is Map) {
      final options = item['checkbox_options'] ?? item['options'];
      if (options is List) {
        return options.map((e) => e.toString()).toList();
      } else if (options is String) {
        try {
          final parsed = jsonDecode(options) as List<dynamic>;
          return parsed.map((e) => e.toString()).toList();
        } catch (e) {
          return options.split(',');
        }
      }
    }
    return null;
  }

  String? _getString(dynamic item, String key) {
    if (item is Map) {
      final value = item[key];
      if (value is String) return value;
      if (value != null) return value.toString();
    }
    return null;
  }

  // ============================================
  // DYNAMIC FIELD TYPE HANDLERS
  // ============================================
  Widget _buildLabel({required String text}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16, top: 12, bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildChecklistItem(Map<String, dynamic> item) {
    final String id = _getId(item);
    final String fieldType = _getFieldType(item);
    final String itemText = _getString(item, 'item_text') ?? '';
    final String section = _getString(item, 'section') ?? '';

    // Dynamic field type handling
    switch (fieldType) {
      // Headers
      case 'section_header':
        return _buildSectionHeader(itemText);
      case 'sub_section_header':
        return _buildSubSectionHeader(itemText);
      case 'label':
        return _buildLabel(text: itemText);
      // Notes
      case 'note':
        return _buildNote(text: itemText);

      // Text fields
      case 'inline_text':
        return _buildInlineTextField(id: id, text: itemText);
      case 'text':
        return _buildTextField(id: id, text: itemText);
      case 'textarea':
        return _buildTextArea(id: id, text: itemText);
      case 'multiline_text':
        return _buildMultilineText(id: id, text: itemText);

      // Date fields
      case 'inline_date':
        return _buildInlineDateField(id: id, text: itemText);
      case 'date':
        return _buildDateField(id: id, text: itemText);

      // Number fields
      case 'inline_number':
        return _buildInlineNumber(id: id, text: itemText);

      // Checkboxes
      case 'inline_checkbox':
        return _buildInlineCheckbox(id: id, text: itemText);
      case 'checkbox':
        return _buildSingleCheckbox(id: id, text: itemText);

      // Checkbox groups
      case 'inline_checkbox_group':
        return _buildInlineCheckboxGroup(id: id, text: itemText);
      case 'checkbox_group':
        final options = _getCheckboxOptions(item);
        return _buildCheckboxGroup(
          id: id,
          text: itemText,
          options: options ?? ['Passed', 'Failed'],
        );

      // Combined fields
      case 'inline_checkbox_with_text':
        return _buildInlineCheckboxWithText(id: id, text: itemText);
      case 'inline_text_with_date':
        return _buildInlineTextWithDate(id: id, text: itemText);
      case 'inline_yes_no':
        return _buildInlineYesNo(id: id, text: itemText);
      case 'text_with_checkbox':
        return _buildTextWithCheckbox(id: id, text: itemText);

      // Measurement fields
      case 'hybrid_measurement_passfail':
        return _buildHybridMeasurementPassFail(
          id: id,
          text: itemText,
          measurementLabel:
              _getString(item, 'measurement_label') ?? 'Actual Dim.',
          measurementUnit: _getString(item, 'measurement_unit'),
        );
      case 'hybrid_measurement_passfail_remarks':
        return _buildHybridMeasurementPassFailRemarks(
          id: id,
          text: itemText,
          measurementLabel:
              _getString(item, 'measurement_label') ?? 'Actual Dimensions',
          measurementUnit: _getString(item, 'measurement_unit'),
        );

      // Tables
      case 'table_header':
        return _buildTableHeader();

      // Signature
      case 'signature':
        return _buildSignatureField(id: id, text: itemText);

      default:
        return _buildSingleCheckbox(id: id, text: itemText);
    }
  }

  // ============================================
  // WIDGET BUILDERS
  // ============================================

  // Headers
  Widget _buildSectionHeader(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8, top: 8),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.red,
        ),
      ),
    );
  }

  Widget _buildSubSectionHeader(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8, top: 8),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.orange,
        ),
      ),
    );
  }

  // Notes
  Widget _buildNote({required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  // Text Fields
  Widget _buildInlineTextField({required String id, required String text}) {
    // Split text to get label and placeholder
    final parts = text.split('________________');
    final label = parts[0].trim();
    final placeholder = parts.length > 1 ? parts[1].trim() : '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label above
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),

            const SizedBox(height: 8),

            // Text field below
            TextField(
              controller: _textControllers[id] ??= TextEditingController(),
              decoration: InputDecoration(
                hintText: placeholder.isEmpty ? 'Enter here...' : placeholder,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required String id, required String text}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _textControllers[id],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter text here...',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextArea({required String id, required String text}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _textControllers[id],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter detailed information...',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultilineText({required String id, required String text}) {
    final parts = text.split(':');
    final label = parts[0].trim();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label:',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _textControllers[id],
              decoration: InputDecoration(
                hintText: 'Enter usage details for $label...',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.all(12),
              ),
              maxLines: 3,
              minLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineDateField({required String id, required String text}) {
    final parts = text.split('________________');
    final label = parts[0].trim();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label above
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),

            const SizedBox(height: 8),

            // Date field below
            InkWell(
              onTap: () => _selectDate(id, context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _textControllers[id]?.text.isEmpty ?? true
                            ? 'Select date'
                            : _textControllers[id]!.text,
                        style: TextStyle(
                          color: _textControllers[id]?.text.isEmpty ?? true
                              ? Colors.grey
                              : Colors.black,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.calendar_today,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField({required String id, required String text}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _textControllers[id],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
                hintText: 'Select date',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
              readOnly: true,
              onTap: () => _selectDate(id, context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineNumber({required String id, required String text}) {
    // Parse text like "Maximum Occupant Load: __________P/Floor"
    final parts = text.split('__________');
    final label = parts[0].trim();
    final suffix = parts.length > 1 ? parts[1] : '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label above
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),

            const SizedBox(height: 8),

            // Number input below
            TextField(
              controller: _textControllers[id] ??= TextEditingController(),
              decoration: InputDecoration(
                hintText: 'Enter number',
                border: const OutlineInputBorder(),
                suffixText: suffix,
                contentPadding: const EdgeInsets.all(12),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineCheckbox({required String id, required String text}) {
    // Remove [   ] placeholder from text
    final displayText = text.replaceAll('[   ]', '').trim();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Checkbox
            Checkbox(
              value: _checkboxGroupValues[id]?[0] ?? false,
              onChanged: (value) {
                setState(() {
                  if (_checkboxGroupValues[id] != null) {
                    _checkboxGroupValues[id]![0] = value ?? false;
                  }
                });
              },
            ),

            // Text
            Expanded(
              child: Text(displayText, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildSingleCheckbox({required String id, required String text}) {
  //   return Card(
  //     margin: const EdgeInsets.symmetric(vertical: 8),
  //     child: CheckboxListTile(
  //       title: Text(text, style: const TextStyle(fontSize: 15)),
  //       value: _checkboxGroupValues[id]?[0] ?? false,
  //       onChanged: (value) {
  //         setState(() {
  //           if (_checkboxGroupValues[id] != null) {
  //             _checkboxGroupValues[id]![0] = value ?? false;
  //           }
  //         });
  //       },
  //       controlAffinity: ListTileControlAffinity.leading,
  //     ),
  //   );
  // }
  Widget _buildSingleCheckbox({required String id, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Checkbox(
            value: _checkboxGroupValues[id]?[0] ?? false,
            onChanged: (value) {
              setState(() {
                if (_checkboxGroupValues[id] != null) {
                  _checkboxGroupValues[id]![0] = value ?? false;
                }
              });
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text.trim(), style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  // Checkbox Groups
  Widget _buildInlineCheckboxGroup({required String id, required String text}) {
    final items = text.split('/');
    final checkboxItems = <String>[];

    for (var item in items) {
      final cleanItem = item.replaceAll('[   ]', '').trim();
      if (cleanItem.isNotEmpty) {
        checkboxItems.add(cleanItem);
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 20,
          children: checkboxItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: _checkboxGroupValues[id]?[index] ?? false,
                  onChanged: (value) {
                    setState(() {
                      if (_checkboxGroupValues[id] != null) {
                        _checkboxGroupValues[id]![index] = value ?? false;
                      }
                    });
                  },
                ),
                Text(item, style: const TextStyle(fontSize: 13)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCheckboxGroup({
    required String id,
    required String text,
    required List<String> options,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (text.startsWith('• '))
                  const Text('• ', style: TextStyle(fontSize: 15)),
                Expanded(
                  child: Text(
                    text.replaceAll('• ', ''),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: options.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;

                Color? checkboxColor;
                if (option == 'Yes') checkboxColor = Colors.green;
                if (option == 'No') checkboxColor = Colors.red;
                if (option == 'N/A') checkboxColor = Colors.grey;
                if (option == 'Passed') checkboxColor = Colors.green;
                if (option == 'Failed') checkboxColor = Colors.red;

                return Card(
                  color: _checkboxGroupValues[id]?[index] == true
                      ? checkboxColor?.withOpacity(0.1)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: _checkboxGroupValues[id]?[index] == true
                          ? checkboxColor?.withOpacity(0.3) ?? Colors.grey[300]!
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: CheckboxListTile(
                    title: Text(
                      option,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: checkboxColor,
                      ),
                    ),
                    value: _checkboxGroupValues[id]?[index] ?? false,
                    onChanged: (value) {
                      setState(() {
                        if (_checkboxGroupValues[id] != null) {
                          _checkboxGroupValues[id]![index] = value ?? false;
                        }
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineCheckboxWithText({
    required String id,
    required String text,
  }) {
    // Parse text like "[   ] Others (Specify) : ________________________________________________________________"
    // Find where ":" is to separate checkbox label from textfield
    final colonIndex = text.indexOf(':');
    String checkboxLabel = '';
    String placeholder = '';

    if (colonIndex != -1) {
      checkboxLabel = text.substring(0, colonIndex).trim();
      placeholder = text.substring(colonIndex + 1).trim();
    } else {
      checkboxLabel = text.trim();
    }

    // Remove [   ] from checkbox label
    checkboxLabel = checkboxLabel.replaceAll('[   ]', '').trim();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Checkbox
                Checkbox(
                  value: _checkboxGroupValues[id]?[0] ?? false,
                  onChanged: (value) {
                    setState(() {
                      // Initialize if null
                      if (_checkboxGroupValues[id] == null) {
                        _checkboxGroupValues[id] = [false];
                      }
                      _checkboxGroupValues[id]![0] = value ?? false;
                    });
                  },
                ),

                // Checkbox label
                Expanded(
                  child: Text(
                    checkboxLabel,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),

            // Text field (show only if checkbox is checked)
            if (_checkboxGroupValues[id]?[0] == true) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _textControllers['${id}_text'] ??=
                    TextEditingController(),
                decoration: InputDecoration(
                  hintText: placeholder.isEmpty
                      ? 'Specify here...'
                      : placeholder,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInlineTextWithDate({required String id, required String text}) {
    // Parse text like "- FSEC No. : ____________ Date Issued :_____________"
    final parts = text.split('Date Issued');
    final textLabel = parts[0].replaceAll('-', '').trim();
    final dateLabel = 'Date Issued${parts.length > 1 ? parts[1] : ''}';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bullet point with label
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('- ', style: TextStyle(fontSize: 14)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text field section
                      Text(
                        textLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextField(
                        controller: _textControllers['${id}_text'] ??=
                            TextEditingController(),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(12),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Date field section
                      Text(
                        dateLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 8),

                      InkWell(
                        onTap: () => _selectDate('${id}_date', context),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _textControllers['${id}_date']
                                              ?.text
                                              .isEmpty ??
                                          true
                                      ? 'Select date'
                                      : _textControllers['${id}_date']!.text,
                                  style: TextStyle(
                                    color:
                                        _textControllers['${id}_date']
                                                ?.text
                                                .isEmpty ??
                                            true
                                        ? Colors.grey
                                        : Colors.black,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.calendar_today,
                                size: 20,
                                color: Colors.grey,
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
          ],
        ),
      ),
    );
  }

  Widget _buildInlineYesNo({required String id, required String text}) {
    final parts = text.split(':');
    final label = parts[0].trim();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Text('$label:', style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: _checkboxGroupValues['${id}_yes']?[0] ?? false,
                  onChanged: (value) {
                    setState(() {
                      _checkboxGroupValues['${id}_yes'] ??= [false];
                      _checkboxGroupValues['${id}_no'] ??= [false];
                      _checkboxGroupValues['${id}_yes']![0] = value ?? false;
                      if (value == true) {
                        _checkboxGroupValues['${id}_no']![0] = false;
                      }
                    });
                  },
                ),
                const Text('Yes', style: TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: _checkboxGroupValues['${id}_no']?[0] ?? false,
                  onChanged: (value) {
                    setState(() {
                      _checkboxGroupValues['${id}_yes'] ??= [false];
                      _checkboxGroupValues['${id}_no'] ??= [false];
                      _checkboxGroupValues['${id}_no']![0] = value ?? false;
                      if (value == true) {
                        _checkboxGroupValues['${id}_yes']![0] = false;
                      }
                    });
                  },
                ),
                const Text('No', style: TextStyle(fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextWithCheckbox({required String id, required String text}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Checkbox(
                  value: _checkboxGroupValues[id]?[0] ?? false,
                  onChanged: (value) {
                    setState(() {
                      if (_checkboxGroupValues[id] != null) {
                        _checkboxGroupValues[id]![0] = value ?? false;
                      }
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _textControllers[id],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Additional information...',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Measurement Fields
  Widget _buildHybridMeasurementPassFail({
    required String id,
    required String text,
    required String measurementLabel,
    String? measurementUnit,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _measurementControllers[id],
              decoration: InputDecoration(
                labelText: measurementLabel,
                hintText: measurementUnit ?? 'Enter measurement',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Card(
                    color: _passedValues[id] == true ? Colors.green[50] : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: _passedValues[id] == true
                            ? Colors.green[200]!
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: CheckboxListTile(
                      title: const Text(
                        'PASSED',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      value: _passedValues[id] ?? false,
                      onChanged: (value) {
                        setState(() {
                          _passedValues[id] = value ?? false;
                          if (value == true) _failedValues[id] = false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    color: _failedValues[id] == true ? Colors.red[50] : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: _failedValues[id] == true
                            ? Colors.red[200]!
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: CheckboxListTile(
                      title: const Text(
                        'FAILED',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      value: _failedValues[id] ?? false,
                      onChanged: (value) {
                        setState(() {
                          _failedValues[id] = value ?? false;
                          if (value == true) _passedValues[id] = false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHybridMeasurementPassFailRemarks({
    required String id,
    required String text,
    required String measurementLabel,
    String? measurementUnit,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _measurementControllers[id],
              decoration: InputDecoration(
                labelText: measurementLabel,
                hintText: measurementUnit ?? 'Enter measurement',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Card(
                    color: _passedValues[id] == true ? Colors.green[50] : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: _passedValues[id] == true
                            ? Colors.green[200]!
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: CheckboxListTile(
                      title: const Text(
                        'PASSED',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      value: _passedValues[id] ?? false,
                      onChanged: (value) {
                        setState(() {
                          _passedValues[id] = value ?? false;
                          if (value == true) _failedValues[id] = false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    color: _failedValues[id] == true ? Colors.red[50] : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: _failedValues[id] == true
                            ? Colors.red[200]!
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: CheckboxListTile(
                      title: const Text(
                        'FAILED',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      value: _failedValues[id] ?? false,
                      onChanged: (value) {
                        setState(() {
                          _failedValues[id] = value ?? false;
                          if (value == true) _passedValues[id] = false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _remarksControllers[id],
              decoration: const InputDecoration(
                labelText: 'Remarks / Corrective Action',
                border: OutlineInputBorder(),
                hintText: 'Enter remarks or corrective actions...',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  // Tables
  Widget _buildTableHeader() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Measurement Table',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Component')),
                  DataColumn(label: Text('Actual Dim.')),
                  DataColumn(label: Text('Passed')),
                  DataColumn(label: Text('Failed')),
                  DataColumn(label: Text('Remarks')),
                ],
                rows: const [],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Signature
  Widget _buildSignatureField({required String id, required String text}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Container(
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: TextButton.icon(
                  onPressed: () => _showSignatureDialog(context),
                  icon: const Icon(Icons.edit),
                  label: const Text('Tap to sign'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(String id, BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _textControllers[id]?.text =
            "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  void _showSignatureDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Signature'),
        content: const Text('Signature capture would be implemented here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text('Failed to load checklist: $error'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _fetchChecklist();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ============================================
  // BUILD METHOD
  // ============================================

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              const Text('Loading checklist...'),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _fetchChecklist,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_checklist.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Fire Safety Checklist')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning, size: 64, color: Colors.orange),
              const SizedBox(height: 20),
              const Text(
                'No checklist items found',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _fetchChecklist,
                child: const Text('Load Checklist'),
              ),
            ],
          ),
        ),
      );
    }

    // Group items by section
    final Map<String, List<Map<String, dynamic>>> groupedItems = {};
    for (var item in _checklist) {
      final section = _getString(item, 'section') ?? 'General';
      if (!groupedItems.containsKey(section)) {
        groupedItems[section] = [];
      }
      groupedItems[section]!.add(Map<String, dynamic>.from(item));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fire Safety Checklist'),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveChecklist,
            tooltip: 'Save',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchChecklist,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Scrollbar(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          size: 36,
                          color: Colors.red[700],
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'BFP Fire Safety Inspection',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Complete all sections below. For items with measurements:',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(Icons.straighten, size: 16, color: Colors.blue),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '1. Enter measurement in the text field',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.check_box, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            '2. Select PASSED or FAILED',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Checklist items grouped by section
            ...groupedItems.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (entry.key.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[100]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.folder_open,
                              color: Colors.red[700],
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                entry.key,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[800],
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red[100],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '${entry.value.length} items',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ...entry.value.map((item) => _buildChecklistItem(item)),
                  const SizedBox(height: 24),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _saveChecklist() {
    // 1. COLLECT CHECKLIST ANSWERS - this goes into 'answers' column
    final Map<String, dynamic> checklistAnswers = {};

    // Save text fields
    _textControllers.forEach((id, controller) {
      if (controller.text.isNotEmpty) {
        checklistAnswers['text_$id'] = controller.text;
      }
    });

    // Save measurements
    _measurementControllers.forEach((id, controller) {
      if (controller.text.isNotEmpty) {
        checklistAnswers['measurement_$id'] = controller.text;
      }
    });

    // Save checkboxes
    _checkboxGroupValues.forEach((id, values) {
      checklistAnswers['checkbox_$id'] = values;
    });

    // Save pass/fail values
    _passedValues.forEach((id, value) {
      if (value) checklistAnswers['passed_$id'] = true;
    });
    _failedValues.forEach((id, value) {
      if (value) checklistAnswers['failed_$id'] = true;
    });

    // Save remarks
    _remarksControllers.forEach((id, controller) {
      if (controller.text.isNotEmpty) {
        checklistAnswers['remarks_$id'] = controller.text;
      }
    });

    // Save evacuation diagram data
    _evacuationCheckboxes.forEach((key, value) {
      if (value) checklistAnswers['evac_$key'] = true;
    });
    _evacuationSecondCheckboxes.forEach((key, value) {
      if (value) checklistAnswers['evac_${key}_2'] = true;
    });

    // 2. CALCULATE STATISTICS
    final passedCount = _passedValues.values.where((v) => v == true).length;
    final failedCount = _failedValues.values.where((v) => v == true).length;

    int naCount = 0;
    _checkboxGroupValues.forEach((key, values) {
      naCount += values.where((v) => v == false).length;
    });

    // Determine overall status
    String overallStatus = 'PENDING';
    if (failedCount > 0) {
      overallStatus = 'FAILED';
    } else if (passedCount > 0 && failedCount == 0) {
      overallStatus = 'PASSED';
    }

    // 3. GENERATE REPORT NUMBER
    final timestamp = DateTime.now();
    final reportNo =
        'RPT-${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}-'
        '${timestamp.hour.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}${timestamp.second.toString().padLeft(2, '0')}';

    // 4. PREPARE REPORT DATA - THIS GOES TO inspection_reports TABLE
    final reportData = {
      'report_no': reportNo,
      'building_name': "Homeworld",
      'building_address': "Libaong National high school",
      'inspector_name': 'Inspector Name', // TODO: Get from session
      'inspection_date': DateTime.now().toString().split(' ')[0],
      'submission_date': DateTime.now().toString().split('.')[0],
      'status': 'pending',
      'total_items': _checklist.length,
      'passed_items': passedCount,
      'failed_items': failedCount,
      'na_items': naCount,
      'overall_status': overallStatus,
      'notes': 'Inspection completed via mobile app',
      'answers': jsonEncode(
        checklistAnswers,
      ), // ✅ CORRECT - encode the entire checklist data
      'establishment_id': widget.establishmentId,
      'inspector_id': 4, // TODO: Get from session
    };

    print('Checklist Answers: ${checklistAnswers.length} items');
    print('Checklist Answers Data: $checklistAnswers');
    print('Report Data: $reportData');

    // 5. SEND TO API
    _callSubmitApi(reportData);
  }

  Future<Map<String, dynamic>> _callSubmitApi(
    Map<String, dynamic> reportData,
  ) async {
    try {
      print('Submitting to API: ${reportData.length} fields');

      // Make sure answers is a String (already encoded)
      if (reportData['answers'] is Map) {
        reportData['answers'] = jsonEncode(reportData['answers']);
      }

      // Log the size
      print('Answers JSON length: ${reportData['answers'].length} characters');

      final response = await ApiPhp(
        tableName: "inspection_reports",
        parameters: reportData,
      ).insert(subUrl: 'https://luvpark.ph/luvtest/mapping/save_checklist.php');
      print("response $response");
      return response;
    } catch (e) {
      print('Submission error: $e');
      rethrow;
    }
  }
}
