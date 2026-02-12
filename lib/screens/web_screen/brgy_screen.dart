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
    final result = await ApiPhp(tableName: "brgy").select();
    listOfBrgy = result["data"];
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

                // Folder Grid
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
                            onTap: () {
                              print('Tapped: ${barangay['brgy_name']}');
                            },
                            child: SizedBox(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Folder image
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
                                        constraints: BoxConstraints(
                                          maxWidth:
                                              100, // Adjust based on your folder image
                                        ),
                                        child: Text(
                                          barangay['brgy_name'] ?? 'Unknown',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
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
