import 'package:bfp_record_mapping/api/api_key.dart' show ApiPhp;
import 'package:bfp_record_mapping/screens/inspection_order_view.dart';
import 'package:bfp_record_mapping/screens/signature/signature.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class InspectionOrderScreen extends StatefulWidget {
  const InspectionOrderScreen({super.key});

  @override
  State<InspectionOrderScreen> createState() => _InspectionOrderScreenState();
}

class _InspectionOrderScreenState extends State<InspectionOrderScreen> {
  final ScrollController _scrollController = ScrollController();
  bool isLoading = true;
  List orders = [];
  Map<String, dynamic> genOrParam = {};

  @override
  void initState() {
    super.initState();
    getOrders();
  }

  void getOrders() async {
    setState(() {
      isLoading = true;
    });
    final inspResponse = await ApiPhp(tableName: "inspection_orders").select();

    setState(() {
      isLoading = false;
      orders = inspResponse["data"] ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: Scrollbar(
        controller: _scrollController,
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
              headingRowColor: WidgetStateProperty.resolveWith(
                (states) => Colors.grey[50]!,
              ),
              headingRowHeight: 56,
              dataRowHeight: 64,
              horizontalMargin: 24,
              columnSpacing: 32,
              border: TableBorder(
                horizontalInside: BorderSide(
                  color: Colors.grey[100]!,
                  width: 1,
                ),
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
              headingTextStyle: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 13,
              ),
              columns: const [
                DataColumn(label: Text('BUSINESS NAME')),
                DataColumn(label: Text('OWNER NAME'), tooltip: ''),

                DataColumn(label: Text('INSPECTOR NAME'), tooltip: ''),

                DataColumn(label: Text('ADDRESS'), tooltip: ''),

                DataColumn(label: Text('CREATED'), tooltip: 'Creation date'),
                DataColumn(label: Text('RECOMENDED BY'), tooltip: ''),
                DataColumn(label: Text('APPROVED BY'), tooltip: ''),
                DataColumn(label: Text('ACTION'), tooltip: 'User actions'),
              ],
              rows: orders.map((order) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        order['business_name'],
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[900],
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        order['owner_name'],
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        "${order['inspector_name']}",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Text(
                          "${order['address']}",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),

                    DataCell(
                      Text(
                        order['created_at'],
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    DataCell(
                      Center(
                        child: IconButton(
                          onPressed:
                              order["rec_signature"].toString().isNotEmpty
                              ? () {}
                              : () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SignatureScreen(),
                                    ),
                                  );

                                  if (result != null) {
                                    uploadSignature(
                                      result,
                                      "rec_signature_${order["establishment_id"]}.png",
                                      "rec_signature",
                                      order["id"],
                                    );
                                  }
                                },
                          icon: Icon(
                            order["rec_signature"].toString().isNotEmpty
                                ? Icons.remove_red_eye_sharp
                                : Icons.photo,
                            color: Colors.red,
                          ),
                          tooltip:
                              '${order["rec_signature"].toString().isNotEmpty ? 'View' : "Upload"} signature',
                        ),
                      ),
                    ),
                    DataCell(
                      Center(
                        child: IconButton(
                          onPressed:
                              order["approved_signature"].toString().isNotEmpty
                              ? () {}
                              : () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SignatureScreen(),
                                    ),
                                  );

                                  if (result != null) {
                                    uploadSignature(
                                      result,
                                      "approved_signature_${order["establishment_id"]}.png",
                                      "approved_signature",
                                      order["id"],
                                    );
                                  }
                                },
                          icon: Icon(
                            order["approved_signature"].toString().isNotEmpty
                                ? Icons.remove_red_eye_sharp
                                : Icons.photo,
                            color: Colors.red,
                          ),
                          tooltip:
                              '${order["approved_signature"].toString().isNotEmpty ? "View" : "Upload"} Signature',
                        ),
                      ),
                    ),
                    DataCell(
                      IconButton(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  InspOrderView(inspectionData: order),
                            ),
                          );
                        },
                        icon: Icon(Icons.file_present, color: Colors.red),
                        tooltip: 'Generate Order',
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  void uploadSignature(Uint8List signature, fileName, colName, orderId) async {
    await ApiPhp.uploadPngFile(
      signatureBytes: signature,
      fileName: fileName,
    ).then((value) async {
      if (value!["success"]) {
        final result = await ApiPhp(
          tableName: "inspection_orders",
          parameters: {colName: fileName},
          whereClause: {"id": orderId},
        ).update();

        if (result["success"]) {
          getOrders();
        }
      }
    });
  }
}
