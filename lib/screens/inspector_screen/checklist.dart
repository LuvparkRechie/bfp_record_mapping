import 'dart:convert';
import 'dart:typed_data';

import 'package:bfp_record_mapping/customs/loading_dialog.dart';
import 'package:bfp_record_mapping/database/checklist_db.dart';
import 'package:bfp_record_mapping/database/sqlite_database.dart';
import 'package:bfp_record_mapping/functions.dart';
import 'package:bfp_record_mapping/screens/signature/signature.dart';
import 'package:flutter/material.dart';

class ChecklistPage extends StatefulWidget {
  final String establishmentName, address;
  final int establishmentId, inspectionId;
  final Map userData;
  final Map<String, dynamic> inspectionData;
  const ChecklistPage({
    super.key,
    required this.establishmentId,
    required this.inspectionId,
    required this.establishmentName,
    required this.address,
    required this.userData,
    required this.inspectionData,
  });

  @override
  State<ChecklistPage> createState() => _ChecklistPageState();
}

class _ChecklistPageState extends State<ChecklistPage> {
  bool _loading = true;
  List<dynamic> _checklist = [];

  // PageView controller
  late PageController _pageController;
  int _currentSectionIndex = 0;
  List<String> _sectionOrder = [];
  Map<String, List<Map<String, dynamic>>> _groupedItems = {};

  // State management maps
  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, TextEditingController> _measurementControllers = {};
  final Map<String, TextEditingController> _remarksControllers = {};
  final Map<String, bool> _passedValues = {};
  final Map<String, bool> _failedValues = {};
  final Map<String, List<bool>> _checkboxGroupValues = {};

  final Map<String, bool> _evacuationCheckboxes = {};
  final Map<String, bool> _evacuationSecondCheckboxes = {};
  Uint8List? repSignature;
  final _chkListDbHelper = ChecklistDatabase.instance;
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fetchChecklist();
    _initializeEvacuationCheckboxes();
  }

  @override
  void dispose() {
    _pageController.dispose();
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

  void _initializeEvacuationCheckboxes() {
    _evacuationCheckboxes['overall'] = false;
    _evacuationSecondCheckboxes['overall_failed'] = false;
  }

  Future<void> _fetchChecklist() async {
    _checklist = await _chkListDbHelper.getAllItems();

    setState(() {});

    _groupItemsBySection();
    _loading = false;
    _initializeControllers();
  }

  void _groupItemsBySection() {
    _groupedItems = {};

    for (var item in _checklist) {
      final section = _getString(item, 'section') ?? 'General';
      final fieldType = _getFieldType(item);

      if (fieldType == 'section_header') {
        continue;
      }

      if (!_groupedItems.containsKey(section)) {
        _groupedItems[section] = [];
      }
      _groupedItems[section]!.add(Map<String, dynamic>.from(item));
    }

    _sectionOrder = _groupedItems.keys.toList();
  }

  void _initializeControllers() {
    for (var item in _checklist) {
      final String id = _getId(item);
      final String fieldType = _getFieldType(item);
      final String itemText = _getString(item, 'item_text') ?? '';

      switch (fieldType) {
        case 'inline_text':
        case 'inline_date':
        case 'inline_text_with_date':
        case 'inline_checkbox_with_text':
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
          final items = itemText.split('/');
          int checkboxCount = 0;
          for (var textItem in items) {
            final cleanItem = textItem.replaceAll('[   ]', '').trim();
            if (cleanItem.isNotEmpty) {
              checkboxCount++;
            }
          }
          _checkboxGroupValues[id] = List<bool>.filled(
            checkboxCount > 0 ? checkboxCount : 2,
            false,
          );
          break;

        case 'label':
          break;
      }
    }

    for (var item in _checklist) {
      final String id = _getId(item);
      final String fieldType = _getFieldType(item);
      if (fieldType == 'inline_text_with_date') {
        _textControllers['${id}_text'] = TextEditingController();
        _textControllers['${id}_date'] = TextEditingController();
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

  Future<void> _selectDate(String id, BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        final formattedDate =
            "${picked.day.toString().padLeft(2, '0')}/"
            "${picked.month.toString().padLeft(2, '0')}/"
            "${picked.year}";

        if (_textControllers.containsKey(id)) {
          _textControllers[id]?.text = formattedDate;
        } else {}
      });
    }
  }

  Widget _buildInlineDateField({required String id, required String text}) {
    if (!_textControllers.containsKey(id)) {
      _textControllers[id] = TextEditingController();
    }

    final parts = text.split('________________');
    final label = parts[0].trim();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
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
    if (!_textControllers.containsKey(id)) {
      _textControllers[id] = TextEditingController();
    }

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

  Widget _buildInlineTextWithDate({required String id, required String text}) {
    final textId = '${id}_text';
    final dateId = '${id}_date';

    if (!_textControllers.containsKey(textId)) {
      _textControllers[textId] = TextEditingController();
    }
    if (!_textControllers.containsKey(dateId)) {
      _textControllers[dateId] = TextEditingController();
    }

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('- ', style: TextStyle(fontSize: 14)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        textLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _textControllers[textId],
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        dateLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectDate(dateId, context),
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
                                  _textControllers[dateId]?.text.isEmpty ?? true
                                      ? 'Select date'
                                      : _textControllers[dateId]!.text,
                                  style: TextStyle(
                                    color:
                                        _textControllers[dateId]
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

    switch (fieldType) {
      case 'section_header':
        return _buildSectionHeader(itemText);
      case 'sub_section_header':
        return _buildSubSectionHeader(itemText);
      case 'label':
        return _buildLabel(text: itemText);
      case 'note':
        return _buildNote(text: itemText);
      case 'inline_text':
        return _buildInlineTextField(id: id, text: itemText);
      case 'text':
        return _buildTextField(id: id, text: itemText);
      case 'textarea':
        return _buildTextArea(id: id, text: itemText);
      case 'multiline_text':
        return _buildMultilineText(id: id, text: itemText);
      case 'inline_date':
        return _buildInlineDateField(id: id, text: itemText);
      case 'date':
        return _buildDateField(id: id, text: itemText);
      case 'inline_number':
        return _buildInlineNumber(id: id, text: itemText);
      case 'inline_checkbox':
        return _buildInlineCheckbox(id: id, text: itemText);
      case 'checkbox':
        return _buildSingleCheckbox(id: id, text: itemText);
      case 'inline_checkbox_group':
        return _buildInlineCheckboxGroup(id: id, text: itemText);
      case 'checkbox_group':
        final options = _getCheckboxOptions(item);
        return _buildCheckboxGroup(
          id: id,
          text: itemText,
          options: options ?? ['Passed', 'Failed'],
        );
      case 'inline_checkbox_with_text':
        return _buildInlineCheckboxWithText(id: id, text: itemText);
      case 'inline_text_with_date':
        return _buildInlineTextWithDate(id: id, text: itemText);
      case 'inline_yes_no':
        return _buildInlineYesNo(id: id, text: itemText);
      case 'text_with_checkbox':
        return _buildTextWithCheckbox(id: id, text: itemText);
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
      case 'table_header':
        return _buildTableHeader();
      case 'signature':
        return _buildSignatureField(id: id, text: itemText);
      default:
        return _buildSingleCheckbox(id: id, text: itemText);
    }
  }

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

  Widget _buildInlineTextField({required String id, required String text}) {
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
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
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
              controller: _textControllers[id] ??= TextEditingController(),
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
              controller: _textControllers[id] ??= TextEditingController(),
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
              controller: _textControllers[id] ??= TextEditingController(),
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

  Widget _buildInlineNumber({required String id, required String text}) {
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
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
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
    final displayText = text.replaceAll('[   ]', '').trim();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
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
            Expanded(
              child: Text(displayText, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

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
    final colonIndex = text.indexOf(':');
    String checkboxLabel = '';
    String placeholder = '';

    if (colonIndex != -1) {
      checkboxLabel = text.substring(0, colonIndex).trim();
      placeholder = text.substring(colonIndex + 1).trim();
    } else {
      checkboxLabel = text.trim();
    }

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
                Checkbox(
                  value: _checkboxGroupValues[id]?[0] ?? false,
                  onChanged: (value) {
                    setState(() {
                      if (_checkboxGroupValues[id] == null) {
                        _checkboxGroupValues[id] = [false];
                      }
                      _checkboxGroupValues[id]![0] = value ?? false;
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    checkboxLabel,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
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
              controller: _textControllers[id] ??= TextEditingController(),
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
              controller: _measurementControllers[id] ??=
                  TextEditingController(),
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
              controller: _measurementControllers[id] ??=
                  TextEditingController(),
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
              controller: _remarksControllers[id] ??= TextEditingController(),
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

  void _goToPreviousSection() {
    if (_currentSectionIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNextSection() {
    if (_currentSectionIndex < _sectionOrder.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

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
        appBar: AppBar(
          title: const Text('Fire Safety Checklist'),
          backgroundColor: Colors.red.shade50,
        ),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fire Safety Checklist'),
        backgroundColor: Colors.red.shade50,

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 18),
                  onPressed: _goToPreviousSection,
                  color: _currentSectionIndex > 0 ? Colors.red : Colors.grey,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // Show section selector dialog
                      _showSectionSelector(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              _sectionOrder[_currentSectionIndex],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_drop_down,
                            size: 20,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 18),
                  onPressed: _goToNextSection,
                  color: _currentSectionIndex < _sectionOrder.length - 1
                      ? Colors.red
                      : Colors.grey,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentSectionIndex = index;
          });
        },
        children: _sectionOrder.map((section) {
          final items = _groupedItems[section] ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section header
                if (section.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red, Colors.red.shade700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.checklist,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                section,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${items.length} items',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Checklist items
                ...items.map((item) => _buildChecklistItem(item)),
                if (_currentSectionIndex == _sectionOrder.length - 1) ...[
                  SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Representative Signature",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 10),
                        GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SignatureScreen(),
                              ),
                            );

                            if (result != null) {
                              setState(() {
                                repSignature = result;
                              });
                            }
                          },
                          child: repSignature == null
                              ? SizedBox(
                                  height: 80,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.draw_outlined,
                                        color: Colors.grey.shade600,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Tap to add signature",
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : SizedBox(
                                  height: 80,
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.memory(
                                          repSignature!,
                                          fit: BoxFit.contain,
                                          width: double.infinity,
                                          height: double.infinity,
                                        ),
                                      ),

                                      Positioned(
                                        bottom: 4,
                                        right: 4,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: const Text(
                                            "Tap to change",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 8,
                                            ),
                                          ),
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

                const SizedBox(height: 20),

                // Navigation buttons
                Row(
                  children: [
                    if (_currentSectionIndex > 0)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _goToPreviousSection,
                          icon: const Icon(Icons.arrow_back, size: 18),
                          label: const Text(
                            'Previous',
                            style: TextStyle(fontSize: 14),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            side: BorderSide(color: Colors.grey[300]!),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    if (_currentSectionIndex > 0 &&
                        _currentSectionIndex < _sectionOrder.length - 1)
                      const SizedBox(width: 12),
                    if (_currentSectionIndex < _sectionOrder.length - 1)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _goToNextSection,
                          icon: const Icon(Icons.arrow_forward, size: 18),
                          label: const Text(
                            'Next',
                            style: TextStyle(fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    if (_currentSectionIndex == _sectionOrder.length - 1) ...[
                      SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _saveChecklist,
                          icon: const Icon(Icons.save, size: 18),
                          label: const Text(
                            'Submit',
                            style: TextStyle(fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showSectionSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Section',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ..._sectionOrder.asMap().entries.map((entry) {
                        final index = entry.key;
                        final section = entry.value;
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 15,
                            backgroundColor: index == _currentSectionIndex
                                ? Colors.red
                                : Colors.grey[300],
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                color: index == _currentSectionIndex
                                    ? Colors.white
                                    : Colors.grey[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            section,
                            style: TextStyle(
                              fontWeight: index == _currentSectionIndex
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: index == _currentSectionIndex
                                  ? Colors.red
                                  : Colors.black,
                            ),
                          ),
                          subtitle: Text(
                            '${_groupedItems[section]?.length ?? 0} items',
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _saveChecklist() async {
    LoadingDialog.show(
      title: 'Loading',
      message: 'Please wait...',
      context: context,
    );
    final coordinate = await Functions.getLocation();

    if (coordinate == null) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enable location '),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    double distance = Functions.calculateDistanceMeters(
      coordinate.latitude,
      coordinate.longitude,
      double.parse(widget.inspectionData["latitude"].toString()),
      double.parse(widget.inspectionData["longitude"].toString()),
    );
    Navigator.of(context).pop();
    print("Ataya $distance");
    if (distance < 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please move closer to the location (within 2 meters) before submitting.\nThis helps us keep reports accurate and reliable.",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final Map<String, dynamic> checklistAnswers = {};

    _textControllers.forEach((id, controller) {
      if (controller.text.isNotEmpty) {
        checklistAnswers['text_$id'] = controller.text;
      }
    });

    _measurementControllers.forEach((id, controller) {
      if (controller.text.isNotEmpty) {
        checklistAnswers['measurement_$id'] = controller.text;
      }
    });

    _checkboxGroupValues.forEach((id, values) {
      checklistAnswers['checkbox_$id'] = values;
    });

    _passedValues.forEach((id, value) {
      if (value) checklistAnswers['passed_$id'] = true;
    });
    _failedValues.forEach((id, value) {
      if (value) checklistAnswers['failed_$id'] = true;
    });

    _remarksControllers.forEach((id, controller) {
      if (controller.text.isNotEmpty) {
        checklistAnswers['remarks_$id'] = controller.text;
      }
    });

    _evacuationCheckboxes.forEach((key, value) {
      if (value) checklistAnswers['evac_$key'] = true;
    });
    _evacuationSecondCheckboxes.forEach((key, value) {
      if (value) checklistAnswers['evac_${key}_2'] = true;
    });

    final passedCount = _passedValues.values.where((v) => v == true).length;
    final failedCount = _failedValues.values.where((v) => v == true).length;

    int naCount = 0;
    _checkboxGroupValues.forEach((key, values) {
      naCount += values.where((v) => v == false).length;
    });

    String overallStatus = 'PENDING';
    if (failedCount > 0) {
      overallStatus = 'FAILED';
    } else if (passedCount > 0 && failedCount == 0) {
      overallStatus = 'PASSED';
    }

    final timestamp = DateTime.now();
    final reportNo =
        'RPT-${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}-'
        '${timestamp.hour.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}${timestamp.second.toString().padLeft(2, '0')}';

    if (repSignature == null) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ No signature captured'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final String fileName = 'owner_signature_${widget.establishmentId}.png';

    // REMOVED: API upload call - now storing locally only

    // Main report data (without signature bytes)
    final reportData = {
      'report_no': reportNo,
      'building_name': widget.establishmentName,
      'building_address': widget.address,
      'inspector_name': widget.userData["full_name"],
      'inspection_date': DateTime.now().toString().split(' ')[0],
      'submission_date': DateTime.now().toString().split('.')[0],
      'status': 'PENDING',
      'total_items': _checklist.length,
      'passed_items': passedCount,
      'failed_items': failedCount,
      'na_items': naCount,
      'overall_status': overallStatus,
      'notes': 'Inspection completed via mobile app',
      'answers': jsonEncode(checklistAnswers),
      'owner_signature_path': fileName, // Store filename for reference
      'inspector_signature': widget.userData["signature_path"],
      'establishment_id': widget.establishmentId,
      'inspector_id': widget.userData["id"],
      'inspection_id': widget.inspectionId,
      'latitude': coordinate.latitude,
      'longitude': coordinate.longitude,
    };

    try {
      final dbHelper = DatabaseHelper.instance;

      // 1. Insert the main report
      int id = await dbHelper.insertInspectionReport(reportData);
      print('Report inserted successfully with ID: $id');

      // 2. Insert the signature in separate table (local SQLite)
      await dbHelper.insertSignature(
        reportNo: reportNo,
        signatureBytes: repSignature!, // Uint8List stored as BLOB
        fileName: fileName,
        id: widget.establishmentId,
      );
      print('Signature saved successfully to local database');

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Inspection report saved locally'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back or to next screen
      Navigator.pop(
        context,
        widget.inspectionId,
      ); // Return true to indicate success
    } catch (e) {
      print('Error inserting report: $e');

      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // void _saveChecklist() async {
  //   LoadingDialog.show(
  //     title: 'Loading',
  //     message: 'Please wait...',
  //     context: context,
  //   );
  //   final coordinate = await Functions.getLocation();

  //   if (coordinate == null) {
  //     Navigator.of(context).pop();
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Please enable location '),
  //         backgroundColor: Colors.orange,
  //         duration: Duration(seconds: 2),
  //       ),
  //     );
  //     return;
  //   }

  //   double distance = Functions.calculateDistanceMeters(
  //     coordinate.latitude,
  //     coordinate.longitude,
  //     double.parse(widget.inspectionData["latitude"].toString()),
  //     double.parse(widget.inspectionData["longitude"].toString()),
  //   );
  //   Navigator.of(context).pop();
  //   if (distance > 2) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(
  //           "Please move closer to the location (within 2 meters) before submitting.\nThis helps us keep reports accurate and reliable.",
  //         ),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //     return;
  //   }

  //   final Map<String, dynamic> checklistAnswers = {};

  //   _textControllers.forEach((id, controller) {
  //     if (controller.text.isNotEmpty) {
  //       checklistAnswers['text_$id'] = controller.text;
  //     }
  //   });

  //   _measurementControllers.forEach((id, controller) {
  //     if (controller.text.isNotEmpty) {
  //       checklistAnswers['measurement_$id'] = controller.text;
  //     }
  //   });

  //   _checkboxGroupValues.forEach((id, values) {
  //     checklistAnswers['checkbox_$id'] = values;
  //   });

  //   _passedValues.forEach((id, value) {
  //     if (value) checklistAnswers['passed_$id'] = true;
  //   });
  //   _failedValues.forEach((id, value) {
  //     if (value) checklistAnswers['failed_$id'] = true;
  //   });

  //   _remarksControllers.forEach((id, controller) {
  //     if (controller.text.isNotEmpty) {
  //       checklistAnswers['remarks_$id'] = controller.text;
  //     }
  //   });

  //   _evacuationCheckboxes.forEach((key, value) {
  //     if (value) checklistAnswers['evac_$key'] = true;
  //   });
  //   _evacuationSecondCheckboxes.forEach((key, value) {
  //     if (value) checklistAnswers['evac_${key}_2'] = true;
  //   });

  //   final passedCount = _passedValues.values.where((v) => v == true).length;
  //   final failedCount = _failedValues.values.where((v) => v == true).length;

  //   int naCount = 0;
  //   _checkboxGroupValues.forEach((key, values) {
  //     naCount += values.where((v) => v == false).length;
  //   });

  //   String overallStatus = 'PENDING';
  //   if (failedCount > 0) {
  //     overallStatus = 'FAILED';
  //   } else if (passedCount > 0 && failedCount == 0) {
  //     overallStatus = 'PASSED';
  //   }

  //   final timestamp = DateTime.now();
  //   final reportNo =
  //       'RPT-${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}-'
  //       '${timestamp.hour.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}${timestamp.second.toString().padLeft(2, '0')}';

  //   if (repSignature == null) {
  //     Navigator.of(context).pop();
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('✓ No signature captured'),
  //         backgroundColor: Colors.red,
  //         duration: Duration(seconds: 2),
  //       ),
  //     );
  //     return;
  //   }
  //   final String fileName = 'owner_signature_${widget.establishmentId}.png';
  //   final uploadResult = await ApiPhp.uploadPngFile(
  //     signatureBytes: repSignature!,
  //     fileName: fileName,
  //   );

  //   if (!uploadResult!["success"]) {
  //     Navigator.of(context).pop();
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(uploadResult["message"]),
  //         backgroundColor: Colors.red,
  //         duration: Duration(seconds: 2),
  //       ),
  //     );
  //     return;
  //   }

  //   final reportData = {
  //     'report_no': reportNo,
  //     'building_name': widget.establishmentName,
  //     'building_address': widget.address,
  //     'inspector_name': widget.userData["full_name"],
  //     'inspection_date': DateTime.now().toString().split(' ')[0],
  //     'submission_date': DateTime.now().toString().split('.')[0],
  //     'status': 'PENDING',
  //     'total_items': _checklist.length,
  //     'passed_items': passedCount,
  //     'failed_items': failedCount,
  //     'na_items': naCount,
  //     'overall_status': overallStatus,
  //     'notes': 'Inspection completed via mobile app',
  //     'answers': jsonEncode(checklistAnswers),
  //     'owner_signature_path': fileName,
  //     'inspector_signature': widget.userData["signature_path"],
  //     'establishment_id': widget.establishmentId,
  //     'inspector_id': widget.userData["id"],
  //     'inspection_id': widget.inspectionId,
  //     'latitude': coordinate.latitude,
  //     'longitude': coordinate.longitude,
  //   };

  //   // Insert the data
  //   try {
  //     int id = await DatabaseHelper.instance.insertInspectionReport(reportData);
  //     print('Report inserted successfully with ID: $id');

  //     // Optional: Show success message
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Inspection report saved locally')),
  //     );
  //   } catch (e) {
  //     print('Error inserting report: $e');
  //     // Handle error
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text('Error saving report: $e')));
  //   }

  //   // _callSubmitApi(reportData);
  // }
}
