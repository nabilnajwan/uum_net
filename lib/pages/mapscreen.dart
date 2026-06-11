import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:uum_net/myconfig.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng userLocation = const LatLng(6.4552, 100.5057);
  final MapController _mapController = MapController();

  List<SignalPoint> signalData = [];
  bool isLoading = true;

  // --- 1. NEW FILTER STATE (Default is UUM WiFi) ---
  String selectedTelco = "UUM WiFi";
  final List<String> telcoOptions = [
    "UUM WiFi",
    "Maxis",
    "CelcomDigi",
    "U Mobile",
    "Unifi Mobile",
    "Yes 4G",
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        userLocation = LatLng(position.latitude, position.longitude);
      });

      _mapController.move(userLocation, 14.0);
      _loadHeatmapData();
    } catch (e) {
      print("GPS Error: $e");
      _loadHeatmapData();
    }
  }

  // --- 2. UPDATED DATA FETCHING ---
  Future<void> _loadHeatmapData() async {
    setState(() => isLoading = true);
    try {
      // Pass the selected telco filter to the API
      final response = await http.get(
        Uri.parse(
          "${MyConfig.baseUrl}/get_heatmap_data.php?telco=$selectedTelco",
        ),
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          List<dynamic> rawList = jsonResponse['data'];
          setState(() {
            signalData = rawList
                .map(
                  (item) => SignalPoint(
                    item['location_name'].toString(),
                    double.parse(item['lat'].toString()),
                    double.parse(item['lng'].toString()),
                    int.parse(item['dbm'].toString()),
                    double.parse(item['dl'].toString()),
                    double.parse(item['ul'].toString()),
                    int.parse(item['ping'].toString()),
                    int.parse(item['response_count'].toString()),
                  ),
                )
                .toList();
          });
        } else {
          setState(() => signalData = []);
        }
      }
    } catch (e) {
      print("Error loading heatmap: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  int _calculateScore(SignalPoint p) {
    int score = 0;
    if (p.dbm >= -85)
      score += 3;
    else if (p.dbm >= -105)
      score += 2;
    else
      score += 1;
    if (p.dl >= 10)
      score += 3;
    else if (p.dl >= 5)
      score += 2;
    else
      score += 1;
    if (p.ul >= 10)
      score += 3;
    else if (p.ul >= 4)
      score += 2;
    else
      score += 1;
    if (p.ping <= 150)
      score += 3;
    else if (p.ping <= 200)
      score += 2;
    else
      score += 1;
    return score;
  }

  Color _getScoreColor(int score) {
    if (score >= 10) return Colors.green;
    if (score >= 7) return Colors.orangeAccent;
    return Colors.red;
  }

  // --- 3. TAP DETECTION LOGIC ---
  void _handleMapTap(double tapLat, double tapLng) {
    if (signalData.isEmpty) return;

    SignalPoint? closestPoint;
    double minDistance = 80.0; // Check within 80 meters (radius of circles)

    for (var p in signalData) {
      double distance = Geolocator.distanceBetween(
        tapLat,
        tapLng,
        p.lat,
        p.long,
      );
      if (distance < minDistance) {
        minDistance = distance;
        closestPoint = p;
      }
    }

    if (closestPoint != null) {
      _showAreaDetails(closestPoint);
    }
  }

  // --- 4. DETAILS BOTTOM SHEET ---
  void _showAreaDetails(SignalPoint p) {
    int score = _calculateScore(p);
    String qualityText = "Bad";
    Color qualityColor = Colors.red;
    IconData qualityIcon = Icons.signal_wifi_bad;

    if (score >= 10) {
      qualityText = "Good";
      qualityColor = Colors.green;
      qualityIcon = Icons.wifi;
    } else if (score >= 7) {
      qualityText = "Moderate";
      qualityColor = Colors.orangeAccent.shade700;
      qualityIcon = Icons.wifi_2_bar;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
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
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: qualityColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(qualityIcon, color: qualityColor, size: 28),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.locationName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "$selectedTelco Network",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDetailBox("Quality", qualityText, qualityColor),
                  _buildDetailBox(
                    "Responses",
                    "${p.responseCount} Tests",
                    Colors.blue,
                  ),
                  _buildDetailBox(
                    "Avg Speed",
                    "${p.dl.toStringAsFixed(1)} Mbps",
                    Colors.deepPurple,
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailBox(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: userLocation,
              initialZoom: 15.0, // Zoomed in slightly to make tapping easier
              onTap: (tapPosition, point) {
                // Link tap to our handler
                _handleMapTap(point.latitude, point.longitude);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.uum_net',
              ),

              CircleLayer(
                circles: signalData.map((point) {
                  int score = _calculateScore(point);
                  return CircleMarker(
                    point: LatLng(point.lat, point.long),
                    radius: 80,
                    useRadiusInMeter: true,
                    color: _getScoreColor(score).withOpacity(0.65),
                    borderStrokeWidth: 0,
                  );
                }).toList(),
              ),

              MarkerLayer(
                markers: [
                  Marker(
                    point: userLocation,
                    width: 80,
                    height: 80,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.withOpacity(0.2),
                          ),
                        ),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.shade600,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // --- 5. NEW FILTER BAR ---
          Positioned(
            top: 20, // Adjust this if it hits the app bar
            left: 0,
            right: 0,
            child: SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: telcoOptions.length,
                itemBuilder: (context, index) {
                  String telco = telcoOptions[index];
                  bool isSelected = selectedTelco == telco;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      label: Text(telco),
                      selected: isSelected,
                      selectedColor: Colors.deepPurple,
                      backgroundColor: Colors.white.withOpacity(0.9),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => selectedTelco = telco);
                          _loadHeatmapData();
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ),

          if (isLoading)
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Scanning network...",
                            style: TextStyle(
                              color: Colors.deepPurple.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          Positioned(
            bottom: 30,
            left: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Quality Score",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildLegendRow(Colors.green, "Good"),
                      const SizedBox(height: 4),
                      _buildLegendRow(Colors.orangeAccent, "Moderate"),
                      const SizedBox(height: 4),
                      _buildLegendRow(Colors.red, "Bad"),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        heroTag: "gps_fab",
        backgroundColor: Colors.deepPurple,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () {
          setState(() => isLoading = true);
          _getCurrentLocation();
        },
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }

  Widget _buildLegendRow(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

// --- 6. UPDATED SIGNAL POINT CLASS ---
class SignalPoint {
  final String locationName;
  final double lat, long, dl, ul;
  final int dbm, ping, responseCount;

  SignalPoint(
    this.locationName,
    this.lat,
    this.long,
    this.dbm,
    this.dl,
    this.ul,
    this.ping,
    this.responseCount,
  );
}
