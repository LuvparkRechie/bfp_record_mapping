import 'package:bfp_record_mapping/api/api_key.dart';
import 'package:bfp_record_mapping/screens/app_theme.dart';
import 'package:flutter/material.dart';

class BrgyScreen extends StatefulWidget {
  const BrgyScreen({super.key});

  @override
  State<BrgyScreen> createState() => _BrgyScreenState();
}

class _BrgyScreenState extends State<BrgyScreen> {
  List listOfBrgy = [];
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();
  List filteredBrgy = [];

  @override
  void initState() {
    super.initState();
    loadBrgyData();
  }

  void loadBrgyData() async {
    final result = await ApiPhp(
      tableName: "",
      parameters: {'filter': 'approved'},
    ).select(subURl: 'https://luvpark.ph/luvtest/mapping/brgy_reports.php');

    print("Brgy Response: $result");
    listOfBrgy = result["data"] ?? [];
    filteredBrgy = List.from(listOfBrgy);

    setState(() {
      isLoading = false;
    });
  }

  void filterBarangays(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredBrgy = List.from(listOfBrgy);
      } else {
        filteredBrgy = listOfBrgy.where((barangay) {
          final name = barangay['brgy_name']?.toString().toLowerCase() ?? '';
          return name.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _openBarangayFolder(Map<String, dynamic> barangay) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarangayYearScreen(brgyData: barangay),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Center(child: CircularProgressIndicator(color: Colors.blue[700]))
        : Container(
            color: Colors.white,
            child: Column(
              children: [
                // Top Bar
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Municipality of Hinigaran list of baranggay',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkGrey,
                        ),
                      ),
                      Row(
                        children: [
                          // Search Bar
                          Container(
                            width: 300,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.search,
                                  color: Colors.grey.shade500,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: searchController,
                                    onChanged: filterBarangays,
                                    decoration: InputDecoration(
                                      hintText: 'Search barangay...',
                                      hintStyle: TextStyle(
                                        color: Colors.grey.shade500,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
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

                // 📁 BARANGAY FOLDER GRID
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 0,
                            childAspectRatio: 0.85,
                          ),
                      itemCount: filteredBrgy.length,
                      itemBuilder: (context, index) {
                        final barangay = filteredBrgy[index];

                        return MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => _openBarangayFolder(barangay),
                            child: SizedBox(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // 📁 Folder image
                                  Container(
                                    child: Image.asset(
                                      "assets/folder.png",
                                      fit: BoxFit.contain,
                                    ),
                                  ),

                                  // Barangay name centered inside folder
                                  Positioned(
                                    top: 50,
                                    left: 0,
                                    right: 0,
                                    bottom: 0,
                                    child: Center(
                                      child: Container(
                                        constraints: const BoxConstraints(
                                          maxWidth: 100,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              barangay['brgy_name'] ??
                                                  'Unknown',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.black,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.blue[50],
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                '${barangay['total_establishments'] ?? 0} estab.',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.blue[700],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
  }
}

// ============================================
// 📁 BARANGAY YEAR FOLDER SCREEN
// ============================================
class BarangayYearScreen extends StatelessWidget {
  final Map<String, dynamic> brgyData;

  const BarangayYearScreen({super.key, required this.brgyData});

  @override
  Widget build(BuildContext context) {
    final brgyName = brgyData['brgy_name'] ?? 'Unknown';
    final years = brgyData['years'] as List? ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              brgyName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Text(
              '${years.length} years of approved inspections',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: years.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No approved reports yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(24),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 0,
                  childAspectRatio: 0.85,
                ),
                itemCount: years.length,
                itemBuilder: (context, index) {
                  final yearData = years[index];
                  final year = yearData['year']?.toString() ?? 'Unknown';
                  final totalEst = yearData['total_establishments'] ?? 0;

                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => YearEstablishmentsScreen(
                              brgyName: brgyName,
                              yearData: yearData,
                            ),
                          ),
                        );
                      },
                      child: SizedBox(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // 📁 SAME FOLDER DESIGN FOR YEARS
                            Container(
                              child: Image.asset(
                                "assets/folder.png",
                                fit: BoxFit.contain,
                              ),
                            ),

                            // Year label centered inside folder
                            Positioned(
                              top: 50,
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Center(
                                child: Container(
                                  constraints: const BoxConstraints(
                                    maxWidth: 100,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        year,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amber[50],
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          '$totalEst estab.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.amber[800],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

// ============================================
// 🏢 YEAR ESTABLISHMENTS LIST SCREEN
// ============================================
class YearEstablishmentsScreen extends StatelessWidget {
  final String brgyName;
  final Map<String, dynamic> yearData;

  const YearEstablishmentsScreen({
    super.key,
    required this.brgyName,
    required this.yearData,
  });

  @override
  Widget build(BuildContext context) {
    final year = yearData['year']?.toString() ?? 'Unknown';
    final establishments = yearData['establishments'] as List? ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$brgyName - $year',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Text(
              '${establishments.length} approved establishment${establishments.length != 1 ? 's' : ''}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: establishments.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No approved establishments for $year',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: establishments.length,
              itemBuilder: (context, index) {
                final est = establishments[index];
                return _buildEstablishmentCard(est);
              },
            ),
    );
  }

  Widget _buildEstablishmentCard(Map<String, dynamic> est) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.business, color: Colors.green[700], size: 22),
        ),
        title: Text(
          est['business_name'] ?? 'Unknown Business',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    est['street_address'] ?? 'No address',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Report #: ${est['report_no'] ?? 'N/A'}',
                style: TextStyle(fontSize: 11, color: Colors.blue[800]),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Owner', est['owner_name'] ?? 'N/A'),
                _buildInfoRow('Contact', est['contact_number'] ?? 'N/A'),
                _buildInfoRow('Occupancy', est['occupancy_type'] ?? 'N/A'),
                _buildInfoRow('Floor Area', '${est['floor_area'] ?? 0} sqm'),
                _buildInfoRow('Storeys', '${est['no_of_storeys'] ?? 0}'),
                const Divider(height: 24),
                _buildInfoRow('Report ID', '${est['report_id'] ?? 'N/A'}'),
                _buildInfoRow(
                  'Inspection Date',
                  est['inspection_date'] ?? 'N/A',
                ),
                _buildInfoRow(
                  'Approved Date',
                  est['approved_at']?.toString().split(' ')[0] ?? 'N/A',
                ),
                _buildInfoRow('Status', est['overall_status'] ?? 'PASSED'),
                _buildInfoRow(
                  'Compliance',
                  '${est['passed_items'] ?? 0}/${est['total_items'] ?? 0} passed',
                ),

                if (est['notes'] != null && est['notes'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.note, size: 16, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              est['notes'],
                              style: TextStyle(color: Colors.blue[900]),
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
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
