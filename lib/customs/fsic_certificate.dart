import 'dart:async';

import 'package:bfp_record_mapping/api/api_key.dart';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
// Import your API service

class BondPaperWidget extends StatefulWidget {
  final double maxWidth;
  final EdgeInsets padding;
  final Map<String, dynamic> fsicData;

  const BondPaperWidget({
    super.key,
    this.maxWidth = 1200,
    this.padding = const EdgeInsets.all(24.0),
    required this.fsicData,
  });

  @override
  State<BondPaperWidget> createState() => _BondPaperWidgetState();
}

class _BondPaperWidgetState extends State<BondPaperWidget> {
  String pathName = "";
  String filePath = "";

  Future<void> updateEstablishment(data) async {
    print("data $data");
    DateTime now = DateTime.now().add(Duration(days: 365));
    final result = await ApiPhp(
      tableName: "establishments",
      parameters: {
        "fsic_file_path": data["path"],
        "fsic_expiry_date": now.toString().split(" ")[0],
      },
      whereClause: {"establishment_id": data["establishment_id"]},
    ).update();

    if (result["success"]) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Certificate uploaded successfully generated}'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result["msg"]}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadCertificate(BuildContext context) async {
    print("pathName.isNotEmpty ${pathName.isNotEmpty}");
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating certificate...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      if (pathName.isEmpty) {
        String fileName =
            "fsic_${widget.fsicData['fsic_no'] ?? 'certificate'}_${widget.fsicData["establishment_id"]}.png";

        final imageBytes = await ScreenshotController()
            .captureFromWidget(
              Container(color: Colors.white, child: _buildCertificateContent()),
              delay: const Duration(seconds: 1),
              pixelRatio: 2.0,
            )
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                throw TimeoutException('Screenshot capture timed out');
              },
            );

        if (!context.mounted) return;

        final result = await ApiPhp.uploadPngFile(
          signatureBytes: imageBytes,
          fileName: fileName,
        );
        print("result $result");
        if (context.mounted) {
          if (result != null && result['success'] == true) {
            setState(() {
              filePath = result["file_path"];
            });

            updateEstablishment({
              "path": result["file_path"],
              "establishment_id": widget.fsicData["establishment_id"],
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result?['message'] ?? 'Upload failed'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        return;
      }
      updateEstablishment({
        "path": filePath,
        "establishment_id": widget.fsicData["establishment_id"],
      });
    } catch (e) {
      print("Error capturing/uploading certificate: $e");

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: _buildCertificateContent(),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onPressed: () => _uploadCertificate(context),
              label: const Text("Upload Certificate"),
              icon: const Icon(Icons.upload_file),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateContent() {
    return Wrap(
      children: [
        Container(
          width: 800,

          color: Colors.white,
          child: Container(
            padding: const EdgeInsets.fromLTRB(25.0, 10.0, 25.0, 10.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                const SizedBox(height: 5),
                _buildFsicNumberAndDate(),
                const SizedBox(height: 10),
                _buildTitle(),
                const SizedBox(height: 10),
                _buildCheckboxes(),
                const SizedBox(height: 20),
                _buildBodyText(),
                const SizedBox(height: 20),
                _buildValiditySection(),
                const SizedBox(height: 20),
                _buildWarningSection(),
                const SizedBox(height: 10),
                _buildFooterSignatures(),
                const SizedBox(height: 30),
                _buildBottomNotes(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
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
        Expanded(
          child: Column(
            children: const [
              Text(
                'Republic of the Philippines',
                style: TextStyle(fontSize: 14),
              ),
              Text(
                'Department of the Interior and Local Government',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                'BUREAU OF FIRE PROTECTION',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF003366),
                ),
              ),
              Text('(Region)'),
              Text('(District/Provincial Office)'),
              Text('(Station)'),
              Text('(Station Address)'),
              Text('(Telephone No./Email Address)'),
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
      ],
    );
  }

  Widget _buildFsicNumberAndDate() {
    return Row(
      children: [
        Row(
          children: [
            const Text(
              'FSIC NO. R ',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 5.0),
              child: Container(
                width: 200,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.red, width: 1),
                  ),
                ),
                child: Center(
                  child: Text(
                    widget.fsicData['fsic_no'] ?? 'N/A',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
        Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 150,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.black, width: 1),
                ),
              ),
              child: Center(
                child: Text(
                  widget.fsicData['date'] ?? 'N/A',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const Text(
              'Date ',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return const Text(
      'FIRE SAFETY INSPECTION CERTIFICATE',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF003366),
      ),
    );
  }

  Widget _buildCheckboxes() {
    final String type = widget.fsicData["type"]?.toString().toLowerCase() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ...[
          'FOR CERTIFICATE OF OCCUPANCY',
          'FOR BUSINESS PERMIT (NEW/RENEWAL)',
          'OTHERS _________________________',
        ].map((label) => _checkboxRow(label, type)).toList(),
      ],
    );
  }

  Widget _checkboxRow(String label, String type) {
    return Padding(
      padding: const EdgeInsets.only(left: 150.0, bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(border: Border.all(color: Colors.black)),
            child: label.toLowerCase().contains(type)
                ? const Icon(Icons.check, size: 18)
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'TO WHOM IT MAY CONCERN:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: Text.rich(
            TextSpan(
              text:
                  'By virtue of the provisions of RA 9514 otherwise known as the Fire Code of the Philippines of 2008, the application for ',
              style: const TextStyle(fontSize: 14, color: Colors.black),
              children: const [
                TextSpan(
                  text:
                      '        FIRE     SAFETY      INSPECTION      CERTIFICATE',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: '        of                     '),
              ],
            ),
            textAlign: TextAlign.justify,
          ),
        ),
        _underlineField(
          '(Name of Establishment)',
          widget.fsicData['establishment_name'] ?? 'N/A',
        ),
        Row(
          children: [
            const Text('owned and managed by '),
            Expanded(
              child: _underlineField(
                '(Name of Owner/Representative)',
                widget.fsicData['business_owner'] ?? 'N/A',
              ),
            ),
            const Text(' with postal address at'),
          ],
        ),
        _underlineField(
          '(Address)',
          widget.fsicData['business_address'] ?? 'N/A',
        ),
        const SizedBox(height: 10),
        Text.rich(
          TextSpan(
            text: 'is hereby ',
            style: const TextStyle(fontSize: 14, color: Colors.black),
            children: const [
              TextSpan(
                text: ' GRANTED ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                style: TextStyle(fontSize: 14, color: Colors.black),
                text:
                    'after said building structure or facility has been duly inspected with the finding that it has fully complied with the fire safety and protection requirements of the Fire Code of the Philippines of 2008 and its Revised Implementing Rules and Regulations.',
              ),
            ],
          ),
          textAlign: TextAlign.justify,
        ),
      ],
    );
  }

  Widget _underlineField(String sublabel, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5.0),
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black, width: 1)),
            ),
            child: Center(
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
        Text(
          sublabel,
          style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Widget _buildValiditySection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Row(
            children: [
              const Text(
                'This certification is valid for',
                style: TextStyle(fontSize: 14, color: Colors.black),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 5.0),
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.black, width: 1),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        widget.fsicData["description"] ?? 'N/A',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Text(
          '(Description)',
          style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
        ),
        Row(
          children: [
            const Expanded(flex: 3, child: SizedBox()),
            const Text('valid until'),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.black, width: 1),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      widget.fsicData["validity"] ?? 'N/A',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWarningSection() {
    return const Text(
      'Violation of Fire Code provisions shall cause this certificate null and void after appropriate proceeding and shall hold the owner liable to the penalties provided for by the said Fire Code.',
      textAlign: TextAlign.center,
      style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
    );
  }

  Widget _buildFooterSignatures() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Fire Code Fees:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  const Text('Amount Paid:'),
                  const SizedBox(width: 5),
                  Padding(
                    padding: const EdgeInsets.only(top: 3.0),
                    child: Container(
                      width: 130,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.black, width: 1),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "₱ ${widget.fsicData["amount"] ?? '0.00'}",
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              Row(
                children: [
                  const Text('O.R. Number:'),
                  const SizedBox(width: 5),
                  Padding(
                    padding: const EdgeInsets.only(top: 3.0),
                    child: Container(
                      width: 130,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.black, width: 1),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          widget.fsicData["or_no"] ?? 'N/A',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              Row(
                children: [
                  const Text('Date:'),
                  const SizedBox(width: 5),
                  Padding(
                    padding: const EdgeInsets.only(top: 3.0),
                    child: Container(
                      width: 130,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.black, width: 1),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          widget.fsicData["validity"] ?? 'N/A',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'RECOMMEND APPROVAL:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text('CHIEF, Fire Safety Enforcement Section'),
              const SizedBox(height: 20),
              const Text('APPROVED:'),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.black, width: 1),
                  ),
                ),
                child: Center(
                  child: Text(
                    widget.fsicData["marshalName"] ?? 'N/A',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const Text('CITY/MUNICIPAL FIRE MARSHAL'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNotes() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'NOTE: "This Certificate does not take the place of any license required by law and is not\ntransferable. Any change in the use of occupancy of the premises shall require a new certificate."',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          'THIS CERTIFICATE SHALL BE POSTED CONSPICUOUSLY',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        const Text(
          'PAALALA: "MAHIGPIT NA IPINAGBABAWAL NG PAMUNUAN NG BUREAU OF FIRE PROTECTION SA MGA KAWANI NITO\nANG MAGBENTA O MAGREKOMENDA NG ANUMANG BRAND NG FIRE EXTINGUISHER"',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.red,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(4),
          color: Colors.cyan[50],
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Applicant/Owner\'s COPY',
                style: TextStyle(
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '"FIRE SAFETY IS OUR MAIN CONCERN"',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(width: 20),
            ],
          ),
        ),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'BFP-QSF-FSED-005 Rev. 03 (03.03.20)',
            style: TextStyle(fontSize: 8),
          ),
        ),
      ],
    );
  }
}
