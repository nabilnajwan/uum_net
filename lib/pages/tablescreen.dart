import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uum_net/myconfig.dart';

class TableScreen extends StatefulWidget {
  const TableScreen({super.key});

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  List<dynamic> allData = [];
  List<dynamic> filteredData = [];
  bool isLoading = true;

  TextEditingController searchController = TextEditingController();
  
  // --- NEW: Separate state for Place and Activity ---
  String selectedActivityFilter = "All";
  String selectedPlaceFilter = "All Places";

  final List<String> activityOptions = [
    "All",
    "Hanging out",
    "Watch movies",
    "Playing games",
    "Studying",
  ];

  final List<String> placeOptions = [
    "All Places",
    "Inasis",
    "School",
    "DKG",
    "Others",
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final response = await http.get(
        Uri.parse("${MyConfig.baseUrl}/get_all_results.php"),
      );
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          setState(() {
            allData = jsonResponse['data'];
            _runFilter(""); 
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      }
    } catch (e) {
      print("Error: $e");
      setState(() => isLoading = false);
    }
  }

  // --- Helper Methods ---

  String _getLocationName(dynamic row) {
    if (row['location_name'] != null &&
        row['location_name'] != "Unknown Area") {
      return row['location_name'].toString().trim();
    }
    return "${row['latitude']}, ${row['longitude']}";
  }

  // --- NEW: Categorize the location based on keywords ---
  String _getPlaceCategory(String locationName) {
    String upper = locationName.toUpperCase();
    if (upper.contains("INASIS") || upper.contains("TRADEWIND")) {
      return "Inasis";
    }
    if (upper.contains("SCHOOL") || upper.contains("SCIMPA") || 
        upper.contains("SMMTC") || upper.contains("SQS") || 
        upper.contains("FACULTY")) {
      return "School";
    }
    if (upper.contains("DKG")) {
      return "DKG";
    }
    return "Others";
  }

  int _calculateScore(dynamic row) {
    double dl = double.tryParse(row['download_speed'].toString()) ?? 0.0;
    int ping = int.tryParse(row['ping_ms'].toString()) ?? 999;
    int dbm = int.tryParse(row['signal_dbm'].toString()) ?? -120;

    int score = 0;
    // Signal
    if (dbm >= -85) score += 3;
    else if (dbm >= -105) score += 2;
    else score += 1;
    // Download
    if (dl >= 10) score += 3;
    else if (dl >= 5) score += 2;
    else score += 1;
    // Ping
    if (ping > 0 && ping <= 150) score += 3;
    else if (ping <= 200) score += 2;
    else score += 1;

    return score; // Max score is 9
  }

  String _getQualityString(int score) {
    if (score >= 8) return "Excellent";
    if (score >= 6) return "Good";
    if (score >= 4) return "Average";
    return "Poor";
  }

  List<String> _getSuitableActivities(dynamic row) {
    double dl = double.tryParse(row['download_speed'].toString()) ?? 0.0;
    double ul = double.tryParse(row['upload_speed'].toString()) ?? 0.0;
    int ping = int.tryParse(row['ping_ms'].toString()) ?? 999;

    List<String> activities = [];
    if (dl >= 0.5) activities.add("Hanging out");
    if (dl >= 2.0 && ul >= 1.0) activities.add("Studying");
    if (dl >= 5.0) activities.add("Watch movies");
    if (ping > 0 && ping <= 150 && dl >= 2.0) activities.add("Playing games");
    if (activities.isEmpty) activities.add("None");

    return activities;
  }

  void _runFilter(String keyword) {
    Map<String, dynamic> uniqueLocationsMap = {};
    for (var row in allData) {
      String locName = _getLocationName(row);
      String key = locName.toLowerCase(); 

      if (!uniqueLocationsMap.containsKey(key)) {
        uniqueLocationsMap[key] = row; 
      }
    }

    List<dynamic> uniqueData = uniqueLocationsMap.values.toList();
    List<dynamic> results = [];

    if (keyword.isEmpty && selectedActivityFilter == "All" && selectedPlaceFilter == "All Places") {
      results = List.from(uniqueData);
    } else {
      results = uniqueData.where((row) {
        // Check Activity Match
        List<String> activities = _getSuitableActivities(row);
        bool matchesActivity = (selectedActivityFilter == "All") || activities.contains(selectedActivityFilter);

        // Check Place Match
        String locName = _getLocationName(row);
        String placeCategory = _getPlaceCategory(locName);
        bool matchesPlace = (selectedPlaceFilter == "All Places") || (placeCategory == selectedPlaceFilter);

        // Check Search Match
        String searchLower = keyword.toLowerCase();
        bool matchesSearch = locName.toLowerCase().contains(searchLower);

        return matchesActivity && matchesPlace && matchesSearch;
      }).toList();
    }

    results.sort((a, b) {
      int scoreA = _calculateScore(a);
      int scoreB = _calculateScore(b);
      return scoreB.compareTo(scoreA); 
    });

    setState(() {
      filteredData = results;
    });
  }

  Color _getQualityColor(String quality) {
    switch (quality) {
      case "Excellent": return Colors.green.shade600;
      case "Good": return Colors.teal.shade600;
      case "Average": return Colors.orange.shade600;
      default: return Colors.red.shade600;
    }
  }

  // --- UPDATED: Bottom Sheet with StatefulBuilder for multiple filters ---
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 5, margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  
                  // --- 1. FILTER BY PLACE ---
                  const Text("Filter by Place", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10.0, runSpacing: 10.0,
                    children: placeOptions.map((filter) {
                      bool isSelected = selectedPlaceFilter == filter;
                      return ChoiceChip(
                        label: Text(filter, style: TextStyle(color: isSelected ? Colors.white : Colors.deepPurple.shade700, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600)),
                        selected: isSelected,
                        selectedColor: Colors.deepPurple,
                        backgroundColor: Colors.deepPurple.shade50,
                        side: BorderSide.none, showCheckmark: false,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() => selectedPlaceFilter = filter);
                            setState(() => selectedPlaceFilter = filter);
                            _runFilter(searchController.text);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(height: 1),
                  ),

                  // --- 2. FILTER BY ACTIVITY ---
                  const Text("Filter by Activity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10.0, runSpacing: 10.0,
                    children: activityOptions.map((filter) {
                      bool isSelected = selectedActivityFilter == filter;
                      return ChoiceChip(
                        label: Text(filter, style: TextStyle(color: isSelected ? Colors.white : Colors.deepPurple.shade700, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600)),
                        selected: isSelected,
                        selectedColor: Colors.deepPurple,
                        backgroundColor: Colors.deepPurple.shade50,
                        side: BorderSide.none, showCheckmark: false,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() => selectedActivityFilter = filter);
                            setState(() => selectedActivityFilter = filter);
                            _runFilter(searchController.text);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 30),
                  
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Apply Filters", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool hasActiveFilter = selectedActivityFilter != "All" || selectedPlaceFilter != "All Places";

    return Scaffold(
      backgroundColor: Colors.grey.shade50, 
      body: Column(
        children: [
          // --- HEADER: SEARCH & FILTERS ---
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03), 
                  blurRadius: 10, offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "Search places (e.g., Library)",
                      prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
                      filled: true, fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    onChanged: (value) => _runFilter(value),
                  ),
                ),
                const SizedBox(width: 12),
                
                Container(
                  height: 50, width: 50,
                  decoration: BoxDecoration(
                    color: !hasActiveFilter ? Colors.grey.shade100 : Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: !hasActiveFilter ? Colors.transparent : Colors.deepPurple.shade200)
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.tune_rounded, color: !hasActiveFilter ? Colors.grey.shade700 : Colors.deepPurple),
                        onPressed: _showFilterBottomSheet,
                      ),
                      if (hasActiveFilter)
                        Positioned(
                          top: 10, right: 10,
                          child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- MAIN CONTENT: CARD LIST ---
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
                : filteredData.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(25),
                          decoration: BoxDecoration(color: Colors.deepPurple.shade50, shape: BoxShape.circle),
                          child: Icon(Icons.location_off_rounded, size: 70, color: Colors.deepPurple.shade200),
                        ),
                        const SizedBox(height: 20),
                        Text("No locations found", style: TextStyle(color: Colors.deepPurple.shade800, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text("Try adjusting your filters or searching for a different area.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 30),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredData.length,
                    itemBuilder: (context, index) {
                      var row = filteredData[index];
                      String locName = _getLocationName(row);
                      String placeCategory = _getPlaceCategory(locName);
                      int score = _calculateScore(row);
                      String quality = _getQualityString(score);
                      List<String> activities = _getSuitableActivities(row);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(locName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                                  ),
                                  // Small tag showing the category
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                                    child: Text(placeCategory, style: TextStyle(color: Colors.deepPurple.shade400, fontSize: 11, fontWeight: FontWeight.bold)),
                                  )
                                ],
                              ),
                              const SizedBox(height: 6),

                              Row(
                                children: [
                                  Icon(Icons.cell_tower, size: 16, color: Colors.grey.shade500),
                                  const SizedBox(width: 6),
                                  Text(row['telco_provider']?.toString() ?? "Unknown", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                                ],
                              ),

                              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Colors.black12)),

                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(color: _getQualityColor(quality).withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                                    child: Text(quality, style: TextStyle(color: _getQualityColor(quality), fontWeight: FontWeight.bold, fontSize: 13)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Wrap(
                                      spacing: 8, runSpacing: 8,
                                      children: activities.where((act) => act != "None").map((act) {
                                            return Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                                              child: Text(act, style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w600)),
                                            );
                                          }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}