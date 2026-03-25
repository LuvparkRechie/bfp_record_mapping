import 'dart:async';

import 'package:bfp_record_mapping/api/path_variables.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class InspOrderView extends StatefulWidget {
  final Map<String, dynamic> inspectionData;
  const InspOrderView({super.key, required this.inspectionData});

  @override
  State<InspOrderView> createState() => _InspOrderViewState();
}

class _InspOrderViewState extends State<InspOrderView> {
  bool isPrinting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: _body(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isPrinting ? null : () => _printInspectionOrder(context),
        icon: isPrinting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.print),
        label: Text(isPrinting ? 'Printing...' : 'Print'),
      ),
    );
  }

  Widget _body() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: 8.5 * 96,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: InspectionOrderForm(inspectionData: widget.inspectionData),
        ),
      ),
    );
  }

  Future<Uint8List?> _loadImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return null;

    try {
      final url = "${ApiKeys.pathVariable}${ApiKeys.getImg}?file=$imagePath";
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      print('Error loading image: $e');
      return null;
    }
  }

  Future<Uint8List?> _loadAssetImage(String assetPath) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      return data.buffer.asUint8List();
    } catch (e) {
      print('Error loading asset: $e');
      return null;
    }
  }

  Future<void> _printInspectionOrder(BuildContext context) async {
    setState(() {
      isPrinting = true;
    });

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final dilgLogo = await _loadAssetImage('assets/dilg.jpg');
      final bfpLogo = await _loadAssetImage('assets/bfp_logo.jpg');
      final recSignatureBytes = await _loadImage(
        widget.inspectionData["rec_signature"],
      );
      final appSignatureBytes = await _loadImage(
        widget.inspectionData["approved_signature"],
      );
      final repSignatureBytes = await _loadImage(
        widget.inspectionData["rep_signature"],
      );

      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.letter,
          margin: const pw.EdgeInsets.all(25),
          build: (pw.Context context) {
            return pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.start,
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                _buildHeader(dilgLogo, bfpLogo),
                pw.SizedBox(height: 12),
                _buildDateSection(),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'INSPECTION ORDER',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          decoration: pw.TextDecoration.underline,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Number: ${widget.inspectionData["inspection_number"] ?? "RO6-2023-11-0725"}',
                        style: pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 8),
                _buildMainTable(),
                pw.SizedBox(height: 20),
                _buildSignatories(recSignatureBytes, appSignatureBytes),
                pw.SizedBox(height: 20),
                _buildAcknowledgement(repSignatureBytes),
                pw.SizedBox(height: 12),
                _buildFooter(),
              ],
            );
          },
        ),
      );

      if (mounted) Navigator.pop(context);

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        format: PdfPageFormat.letter,
        name:
            'Inspection_Order_${widget.inspectionData["inspection_number"] ?? "document"}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Print job sent successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Print error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isPrinting = false);
    }
  }

  pw.Widget _buildHeader(Uint8List? dilgLogo, Uint8List? bfpLogo) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 65,
          height: 65,
          child: dilgLogo != null
              ? pw.Image(pw.MemoryImage(dilgLogo), fit: pw.BoxFit.contain)
              : pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey),
                    shape: pw.BoxShape.circle,
                  ),
                  child: pw.Center(
                    child: pw.Text('DILG', style: pw.TextStyle(fontSize: 11)),
                  ),
                ),
        ),
        pw.Expanded(
          child: pw.Column(
            children: [
              pw.Text(
                'Republic of the Philippines',
                style: pw.TextStyle(fontSize: 9),
              ),
              pw.Text(
                'Department of the Interior and Local Government',
                style: pw.TextStyle(fontSize: 8),
              ),
              pw.Text(
                'BUREAU OF FIRE PROTECTION',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text('Regional Office 6', style: pw.TextStyle(fontSize: 8)),
              pw.Text(
                'Negros Occidental Provincial Office',
                style: pw.TextStyle(fontSize: 8),
              ),
              pw.Text(
                'HINIGARAN FIRE STATION',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Burgos Street, Barangay III, Hinigaran, Negros Occidental',
                style: pw.TextStyle(fontSize: 7),
              ),
              pw.Text(
                'Cellphone No.: 0945-842-6367; Email Add: hinigaranfs@gmail.com',
                style: pw.TextStyle(fontSize: 6),
              ),
            ],
          ),
        ),
        pw.Container(
          width: 65,
          height: 65,
          child: bfpLogo != null
              ? pw.Image(pw.MemoryImage(bfpLogo), fit: pw.BoxFit.contain)
              : pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey),
                    shape: pw.BoxShape.circle,
                  ),
                  child: pw.Center(
                    child: pw.Text('BFP', style: pw.TextStyle(fontSize: 11)),
                  ),
                ),
        ),
      ],
    );
  }

  pw.Widget _buildDateSection() {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 130,
        child: pw.Column(
          children: [
            pw.Text(
              "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
            pw.Container(height: 1, color: PdfColors.black),
            pw.Text('Date', style: pw.TextStyle(fontSize: 8)),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildMainTable() {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black),
      ),
      child: pw.Column(
        children: [
          _buildTableRow(
            'TO',
            widget.inspectionData["owner_name"]?.toString() ?? "",
          ),
          _buildTableRow(
            'PROCEED TO',
            widget.inspectionData["address"]?.toString() ?? "",
          ),
          _buildTableRow(
            'PURPOSE',
            'To conduct Fire Safety Inspection pursuant to Sec.9.0.2.4 of the RIRR of RA 9514 prior to the issuance of Fire Safety Inspection Certificate.',
          ),
          _buildTableRow('DURATION', 'Valid within three (3) working days.'),
          _buildTableRow(
            'REMARKS OR\nADDITIONAL\nINSTRUCTION',
            widget.inspectionData["remarks"]?.toString() ??
                'Be in GOA uniform. Coordinate with the owner/ authorized representative prior to the conduct of fire safety inspection and submit After Inspection Report (AIR) to the undersigned.',
            isLast: true,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTableRow(String label, String value, {bool isLast = false}) {
    return pw.Container(
      decoration: isLast
          ? null
          : pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black)),
            ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 110,
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border(right: pw.BorderSide(color: PdfColors.black)),
            ),
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            ),
          ),
          pw.Container(
            width: 15,
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              ':',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(value, style: pw.TextStyle(fontSize: 9)),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSignatories(
    Uint8List? recSignature,
    Uint8List? appSignature,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Expanded(
          child: _buildSignatoryColumn(
            'RECOMMEND APPROVAL:',
            'SFO1 Rudy D Genoche',
            'Chief, Fire Safety Enforcement Section',
            recSignature,
          ),
        ),
        pw.SizedBox(width: 30),
        pw.Expanded(
          child: _buildSignatoryColumn(
            'APPROVED:',
            'SFO3 Francisco O Arevalo II',
            'Acting Municipal Fire Marshal',
            appSignature,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSignatoryColumn(
    String title,
    String name,
    String position,
    Uint8List? signature,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        ),
        pw.SizedBox(height: 25),
        pw.Center(
          child: pw.Column(
            children: [
              if (signature != null)
                pw.Container(
                  height: 35,
                  width: 130,
                  child: pw.Image(
                    pw.MemoryImage(signature),
                    fit: pw.BoxFit.contain,
                  ),
                )
              else
                pw.Container(
                  height: 35,
                  width: 130,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Center(
                    child: pw.Icon(pw.IconData(0xe145), size: 18),
                  ),
                ),
              pw.SizedBox(height: 4),
              pw.Text(
                name,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                ),
              ),
              pw.Container(height: 1, width: 130, color: PdfColors.black),
              pw.Text(position, style: pw.TextStyle(fontSize: 7)),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildAcknowledgement(Uint8List? repSignature) {
    return pw.Column(
      children: [
        pw.Text(
          'ACKNOWLEDGEMENT',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          'This is to acknowledge that permission was granted to the above named Fire Safety Inspector/s accompanied by authorized representative to conduct Fire Safety Inspection within the premises in accordance to law.',
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontSize: 8),
        ),
        pw.SizedBox(height: 15),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 2,
              child: pw.Column(
                children: [
                  if (repSignature != null)
                    pw.Container(
                      height: 30,
                      child: pw.Image(
                        pw.MemoryImage(repSignature),
                        fit: pw.BoxFit.contain,
                      ),
                    )
                  else
                    pw.Container(
                      height: 30,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                      ),
                      child: pw.Center(
                        child: pw.Icon(pw.IconData(0xe145), size: 18),
                      ),
                    ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    widget.inspectionData["owner_name"]?.toString() ?? "",
                    style: pw.TextStyle(
                      fontStyle: pw.FontStyle.italic,
                      fontSize: 9,
                    ),
                  ),
                  pw.Container(height: 1, color: PdfColors.black),
                  pw.Text(
                    'Signature Over Printed Name/Authorized Representative',
                    style: pw.TextStyle(fontSize: 7),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 30),
            pw.Expanded(
              flex: 1,
              child: pw.Column(
                children: [
                  pw.Text(
                    "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}\n${DateTime.now().hour}:${DateTime.now().minute}",
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 4),
                  pw.Container(height: 1, color: PdfColors.black),
                  pw.Text('DATE/TIME', style: pw.TextStyle(fontSize: 7)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Center(
          child: pw.Text(
            'Paalala: Mahigpit na ipinagbabawal ng pamunuan ng Bureau of Fire Protection sa mga kawani nito\nang magbenta o magrekomenda ng anumang brand ng Fire Extinguisher.',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              color: PdfColors.red,
              fontSize: 7,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Center(
          child: pw.Text(
            '"FIRE SAFETY IS OUR MAIN CONCERN"',
            style: pw.TextStyle(
              color: PdfColors.blue,
              fontWeight: pw.FontWeight.bold,
              fontSize: 8,
            ),
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'DISTRIBUTION:',
                  style: pw.TextStyle(
                    fontSize: 6,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Original (Applicant/Owner\'s Copy)',
                  style: pw.TextStyle(fontSize: 6),
                ),
                pw.Text(
                  'Duplicate (BFP Copy)',
                  style: pw.TextStyle(fontSize: 6),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'FSIC 110801-N702',
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'BFP-QSF-FSED-009 Rev.01(07.05.19)',
                  style: pw.TextStyle(fontSize: 6),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// Keep your existing InspectionOrderForm class exactly as it was originally
class InspectionOrderForm extends StatelessWidget {
  final Map<String, dynamic> inspectionData;
  const InspectionOrderForm({super.key, required this.inspectionData});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildDateSection(),
          const SizedBox(height: 10),
          const Text(
            'INSPECTION ORDER',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Text(
            'Number: ${inspectionData["inspection_number"] ?? "RO6-2023-11-0725"}',
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          _buildMainTable(),
          const SizedBox(height: 30),
          _buildSignatories(),
          const SizedBox(height: 30),
          _buildAcknowledgement(),
          const SizedBox(height: 20),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(width: 70),
        Image.asset(
          'assets/dilg.jpg',
          width: 80,
          height: 80,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 80,
              height: 80,
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image),
            );
          },
        ),
        const Expanded(
          child: Column(
            children: [
              Text(
                'Republic of the Philippines',
                style: TextStyle(fontSize: 12),
              ),
              Text(
                'Department of the Interior and Local Government',
                style: TextStyle(fontSize: 10),
              ),
              Text(
                'BUREAU OF FIRE PROTECTION',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Text('Regional Office 6', style: TextStyle(fontSize: 10)),
              Text(
                'Negros Occidental Provincial Office',
                style: TextStyle(fontSize: 10),
              ),
              Text(
                'HINIGARAN FIRE STATION',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              Text(
                'Burgos Street, Barangay III, Hinigaran, Negros Occidental',
                style: TextStyle(fontSize: 9),
              ),
              Text(
                'Cellphone No.: 0945-842-6367; Email Add: hinigaranfs@gmail.com',
                style: TextStyle(fontSize: 8),
              ),
            ],
          ),
        ),
        Image.asset(
          'assets/bfp_logo.jpg',
          width: 80,
          height: 80,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 80,
              height: 80,
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image),
            );
          },
        ),
        const SizedBox(width: 70),
      ],
    );
  }

  Widget _buildDateSection() {
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 200,
        child: Column(
          children: [
            Text(
              "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            Container(height: 1, color: Colors.black),
            const Text('Date', style: TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildMainTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Column(
        children: [
          _buildTableRow('TO', inspectionData["owner_name"]?.toString() ?? ""),
          _buildTableRow(
            'PROCEED TO',
            inspectionData["address"]?.toString() ?? "",
          ),
          _buildTableRow(
            'PURPOSE',
            'To conduct Fire Safety Inspection pursuant to Sec.9.0.2.4 of the RIRR of RA 9514 prior to the issuance of Fire Safety Inspection Certificate.',
          ),
          _buildTableRow('DURATION', 'Valid within three (3) working days.'),
          _buildTableRow(
            'REMARKS OR\nADDITIONAL\nINSTRUCTION',
            inspectionData["remarks"]?.toString() ??
                'Be in GOA uniform. Coordinate with the owner/ authorized representative prior to the conduct of fire safety inspection and submit After Inspection Report (AIR) to the undersigned.',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(String label, String value, {bool isLast = false}) {
    return Container(
      decoration: isLast
          ? null
          : const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black)),
            ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 120,
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: Colors.black)),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
            Container(
              width: 20,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: Colors.black)),
              ),
              child: const Center(
                child: Text(':', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(value, style: const TextStyle(fontSize: 11)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignatories() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildSignatoryColumn(
            'RECOMMEND APPROVAL:',
            'SFO1 Rudy D Genoche',
            'Chief, Fire Safety Enforcement Section',
            inspectionData["rec_signature"],
          ),
        ),
        const SizedBox(width: 40),
        Expanded(
          child: _buildSignatoryColumn(
            'APPROVED:',
            'SFO3 Francisco O Arevalo II',
            'Acting Municipal Fire Marshal',
            inspectionData["approved_signature"],
          ),
        ),
      ],
    );
  }

  Widget _buildSignatoryColumn(
    String title,
    String name,
    String position,
    dynamic signature,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        ),
        const SizedBox(height: 35),
        Center(
          child: Column(
            children: [
              if (signature != null && signature.toString().isNotEmpty)
                Container(
                  height: 40,
                  child: Image.network(
                    "${ApiKeys.pathVariable}${ApiKeys.getImg}?file=$signature",
                    fit: BoxFit.contain,
                    width: 150,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.edit, color: Colors.grey),
                  ),
                )
              else
                Container(
                  height: 40,
                  color: Colors.grey[100],
                  child: const Icon(Icons.edit, color: Colors.grey),
                ),
              const SizedBox(height: 5),
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              Container(height: 1, width: 180, color: Colors.black),
              Text(position, style: const TextStyle(fontSize: 9)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAcknowledgement() {
    return Column(
      children: [
        const Text(
          'ACKNOWLEDGEMENT',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(height: 10),
        const Text(
          'This is to acknowledge that permission was granted to the above named Fire Safety Inspector/s accompanied by authorized representative to conduct Fire Safety Inspection within the premises in accordance to law.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10),
        ),
        const SizedBox(height: 30),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  if (inspectionData["rep_signature"] != null &&
                      inspectionData["rep_signature"].toString().isNotEmpty)
                    SizedBox(
                      height: 30,
                      child: Image.network(
                        "${ApiKeys.pathVariable}${ApiKeys.getImg}?file=${inspectionData["rep_signature"]}",
                        fit: BoxFit.contain,
                        width: 200,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.edit, color: Colors.grey),
                      ),
                    )
                  else
                    Container(
                      height: 30,
                      color: Colors.grey[100],
                      child: const Icon(Icons.edit, color: Colors.grey),
                    ),
                  const SizedBox(height: 5),
                  Text(
                    inspectionData["owner_name"]?.toString() ?? "",
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                    ),
                  ),
                  Container(height: 1, color: Colors.black),
                  const Text(
                    'Signature Over Printed Name/Authorized Representative',
                    style: TextStyle(fontSize: 9),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 50),
            Expanded(
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  Text(
                    "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}/${DateTime.now().hour}:${DateTime.now().minute}",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(height: 1, color: Colors.black),
                  const Text('DATE/TIME', style: TextStyle(fontSize: 9)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            'Paalala: Mahigpit na ipinagbabawal ng pamunuan ng Bureau of Fire Protection sa mga kawani nito\nang magbenta o magrekomenda ng anumang brand ng Fire Extinguisher.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.red,
              fontSize: 9,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(height: 5),
        const Center(
          child: Text(
            '"FIRE SAFETY IS OUR MAIN CONCERN"',
            style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DISTRIBUTION:',
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Original (Applicant/Owner\'s Copy)',
                  style: TextStyle(fontSize: 8),
                ),
                Text('Duplicate (BFP Copy)', style: TextStyle(fontSize: 8)),
              ],
            ),
            Text(
              'FSIC 110801-N702',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 5),
        const Text(
          'BFP-QSF-FSED-009 Rev.01(07.05.19)',
          style: TextStyle(fontSize: 8),
        ),
      ],
    );
  }
}
