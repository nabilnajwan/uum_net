import 'dart:io';
import 'dart:convert';
import 'dart:async'; // Required for StreamSubscription
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_internet_signal/flutter_internet_signal.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:typed_data';
import 'package:fl_chart/fl_chart.dart';
import 'package:uum_net/model/user.dart';
import 'package:uum_net/myconfig.dart';
import 'package:uum_net/mydrawer.dart';
import 'package:uum_net/pages/mapscreen.dart';
import 'package:uum_net/pages/tablescreen.dart';
import 'package:uum_net/pages/profilepage.dart';
import 'package:uum_net/pages/chatpage.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // Required to detect network switches

// 1. THE MAIN CONTAINER
class Homepage extends StatefulWidget {
  final User user;
  const Homepage({super.key, required this.user});
  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      SpeedTestView(user: widget.user),
      const MapScreen(),
      const TableScreen(),
      ProfilePage(user: widget.user),
    ];

    return Scaffold(
      appBar: _selectedIndex == 3
          ? null
          : AppBar(
              title: Text(
                _getTitle(_selectedIndex),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              elevation: 0,
              actions: [
                // --- MOVED AI CHAT ICON HERE ---
                IconButton(
                  icon: const Icon(Icons.auto_awesome, color: Colors.white),
                  tooltip: 'Network AI Assist',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ChatPage()),
                    );
                  },
                ),
                const SizedBox(width: 8), // Padding on the right
              ],
            ),
      drawer: MyDrawer(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),

      body: IndexedStack(index: _selectedIndex, children: screens),
      // Notice: floatingActionButton is completely removed!
    );
  }

  String _getTitle(int index) {
    if (index == 0) return "Hi, ${widget.user.username} 👋";
    if (index == 1) return "UUM Signal Map";
    if (index == 2) return "UUM Status Connection";
    if (index == 3) return "My Profile";
    return "UUM Network";
  }
}

// 2. THE SPEED TEST VIEW
class SpeedTestView extends StatefulWidget {
  final User user;
  const SpeedTestView({super.key, required this.user});
  @override
  State<SpeedTestView> createState() => _SpeedTestViewState();
}

class _SpeedTestViewState extends State<SpeedTestView>
    with SingleTickerProviderStateMixin {
  final String testFileUrl =
      "https://upload.wikimedia.org/wikipedia/commons/3/3a/Cat03.jpg";

  String? selectedTelco;
  String statusText = "Ready to test";
  bool isTesting = false;

  String ping = "--";
  String dl = "--";
  String ul = "--";
  String dbm = "0";

  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  final List<Map<String, dynamic>> uumLocations = [
    // --- MICRO ZONES (0m - 25m Radius) ---
    // Tiny specific spots like cafes, junctions, and small offices
    {
      "name": "ZUS COFFEE UUM",
      "lat": 6.460792353694749,
      "lng": 100.50519449288234,
      "radius": 5,
    },
    {"name": "DKG 1", "lat": 6.465475, "lng": 100.508209, "radius": 17},
    {
      "name": "Pusat Pendidikan Profesional Dan Lanjutan (PACE)",
      "lat": 6.465577,
      "lng": 100.509620,
      "radius": 18,
    },
    {
      "name": "Alumni Junction",
      "lat": 6.465689,
      "lng": 100.509329,
      "radius": 20,
    },
    {
      "name": "INASIS BANK RAKYAT",
      "lat": 6.441183919636562,
      "lng": 100.52811222121672,
      "radius": 20,
    },
    {
      "name": "INASIS SME BANK",
      "lat": 6.4382837007731,
      "lng": 100.53103085555874,
      "radius": 20,
    },
    {"name": "UUMIT", "lat": 6.464224, "lng": 100.507090, "radius": 25},
    {"name": "HEP UUM", "lat": 6.461109, "lng": 100.504391, "radius": 25},
    {
      "name": "UUMIT (new building)",
      "lat": 6.459221,
      "lng": 100.505053,
      "radius": 25,
    },

    // --- SMALL ZONES (30m - 40m Radius) ---
    // Specific buildings, cafes, lounges, and faculties
    {
      "name": "Pejabat Kor Suksis UUM",
      "lat": 6.474983,
      "lng": 100.507134,
      "radius": 30,
    },
    {
      "name": "School of Social Development",
      "lat": 6.466135,
      "lng": 100.508469,
      "radius": 30,
    },
    {
      "name": "Academic Affairs Department",
      "lat": 6.462115917235543,
      "lng": 100.50619241261577,
      "radius": 30,
    },
    {"name": "U-ASSIST UUM", "lat": 6.461262, "lng": 100.505298, "radius": 30},
    {
      "name": "Centre For Foundation Studies in Management",
      "lat": 6.455147718714052,
      "lng": 100.50697539367702,
      "radius": 30,
    },
    {
      "name": "UUM CAFE DKG 6",
      "lat": 6.452953266236119,
      "lng": 100.5076049167696,
      "radius": 30,
    },
    {
      "name": "Kopi Mesin UUM",
      "lat": 6.452281967605717,
      "lng": 100.50669868242741,
      "radius": 30,
    },
    {
      "name": "SUBAIDAH BISTRO UUM",
      "lat": 6.459384155615774,
      "lng": 100.50267084216865,
      "radius": 30,
    },
    {
      "name": "INASIS TRADEWINS BLOCK 3C",
      "lat": 6.4600291257515545,
      "lng": 100.5023969482514,
      "radius": 30,
    },
    {
      "name": "UPC TRADEWINDS",
      "lat": 6.460219261295907,
      "lng": 100.50208928659306,
      "radius": 30,
    },
    {
      "name": "Dewan TRADEWINDS",
      "lat": 6.460683415421543,
      "lng": 100.50191669589888,
      "radius": 30,
    },
    {
      "name": "INASIS TRADEWINDS BLOCK 3D",
      "lat": 6.460875,
      "lng": 100.501461,
      "radius": 30,
    },
    {
      "name": "SAC/MPP LOUNGE",
      "lat": 6.461171065184111,
      "lng": 100.50259086415907,
      "radius": 30,
    },
    {
      "name": "ART AND CULTURE CENTRE",
      "lat": 6.46154529360173,
      "lng": 100.50150260544561,
      "radius": 30,
    },
    {
      "name": "INASIS TRADEWINS",
      "lat": 6.456216812332843,
      "lng": 100.50446340074869,
      "radius": 35,
    },
    {
      "name": "FOODCOURT VARSITY MALL",
      "lat": 6.4626046422362995,
      "lng": 100.50218042067077,
      "radius": 40,
    },
    {"name": "DKG 3", "lat": 6.465423, "lng": 100.506141, "radius": 40},
    {"name": "DKG 2", "lat": 6.464003, "lng": 100.508093, "radius": 40},
    {
      "name": "Dewan Bunga Raya Mas Bawah",
      "lat": 6.455351253478179,
      "lng": 100.50560064726533,
      "radius": 40,
    },
    {
      "name": "ISLAMIC CENTRE",
      "lat": 6.460664650382592,
      "lng": 100.49911696654773,
      "radius": 40,
    },
    {
      "name": "MASJID SULTAN BADLISHAH",
      "lat": 6.462194458641968,
      "lng": 100.49906868677465,
      "radius": 40,
    },
    {
      "name": "CAFE BANK ISLAM",
      "lat": 6.464951,
      "lng": 100.499175,
      "radius": 40,
    },
    {
      "name": "INASIS BSN (cafe area)",
      "lat": 6.470628234498296,
      "lng": 100.5007445837307,
      "radius": 40,
    },
    {
      "name": "INASIS MISC (Block E)",
      "lat": 6.471444136927856,
      "lng": 100.50092916949853,
      "radius": 40,
    },
    {
      "name": "SISIRAN SINTOK",
      "lat": 6.447621,
      "lng": 100.512558,
      "radius": 40,
    },

    // --- MEDIUM ZONES (50m - 80m Radius) ---
    // Medium structures, large blocks, and mid-sized faculties
    {
      "name": "UUM Varsity Mall",
      "lat": 6.462519356951098,
      "lng": 100.50148036411815,
      "radius": 50,
    },
    {
      "name": "Markas Palapes UUM",
      "lat": 6.473999,
      "lng": 100.507925,
      "radius": 50,
    },
    {
      "name": "Pusat Kokurikulum",
      "lat": 6.475683,
      "lng": 100.507613,
      "radius": 50,
    },
    {
      "name": "Lapang Sasar Memanah",
      "lat": 6.475350,
      "lng": 100.506353,
      "radius": 50,
    },
    {
      "name": "SCIMPA",
      "lat": 6.455658823906036,
      "lng": 100.507727750544,
      "radius": 50,
    },
    {
      "name": "School Of Quantitative Science (SQS)",
      "lat": 6.454641698659621,
      "lng": 100.50771751439689,
      "radius": 50,
    },
    {
      "name": "INASIS TRADEWINDS BLOCK A",
      "lat": 6.458685340552126,
      "lng": 100.50276607366497,
      "radius": 50,
    },
    {
      "name": "INASIS PETRONAS (OFFICE AREA)",
      "lat": 6.46425818853819,
      "lng": 100.50074239054588,
      "radius": 50,
    },
    {
      "name": "TAMAN UNIVERSITI UUM",
      "lat": 6.4470019917858705,
      "lng": 100.47862001237148,
      "radius": 50,
    },
    {
      "name": "DTSO",
      "lat": 6.465309342521687,
      "lng": 100.50373827814764,
      "radius": 50,
    },
    {"name": "Pusat Sukan", "lat": 6.473677, "lng": 100.504371, "radius": 60},
    {
      "name": "School of Education and Modern Languages",
      "lat": 6.465946,
      "lng": 100.507172,
      "radius": 60,
    },
    {
      "name": "School of Economics, Finance and Banking",
      "lat": 6.464733,
      "lng": 100.506226,
      "radius": 60,
    },
    {
      "name": "SMMTC",
      "lat": 6.456070759040329,
      "lng": 100.50776101802413,
      "radius": 60,
    },
    {
      "name": "School Of Technology Management and Logistics",
      "lat": 6.453644913943724,
      "lng": 100.50778404935383,
      "radius": 60,
    },
    {
      "name": "Department of Development and Maintenance UUM",
      "lat": 6.450591314231362,
      "lng": 100.50815861488898,
      "radius": 60,
    },
    {
      "name": "INASIS BANK ISLAM",
      "lat": 6.466531,
      "lng": 100.498455,
      "radius": 60,
    },
    {
      "name": "Faculty of Accounting",
      "lat": 6.464719,
      "lng": 100.507725,
      "radius": 65,
    },
    {
      "name": "School of Business Management",
      "lat": 6.463621,
      "lng": 100.507073,
      "radius": 70,
    },
    {
      "name": "DKG 6/5",
      "lat": 6.455967685480512,
      "lng": 100.50652946937957,
      "radius": 80,
    },
    {
      "name": "Inasis Mas Bawah",
      "lat": 6.454623083789974,
      "lng": 100.50521695619273,
      "radius": 80,
    },

    // --- LARGE ZONES (100m - 200m Radius) ---
    // Entire Inasis areas, libraries, complexes, and big fields
    {
      "name": "Padang Kawad Universiti Utara Malaysia",
      "lat": 6.472771,
      "lng": 100.507445,
      "radius": 100,
    },
    {
      "name": "Pusat Kesihatan Universiti Utara Malaysia",
      "lat": 6.471654,
      "lng": 100.507080,
      "radius": 100,
    },
    {"name": "Arena Sukan", "lat": 6.474865, "lng": 100.503366, "radius": 100},
    //{"name": "SOC UUM", "lat": 6.30, "lng": 100.307401, "radius": 20},
    {
      "name": "Student Lounge SOC",
      "lat": 6.46743861926153,      
      "lng": 100.507401,
      "radius": 100,          
    },
    {
      "name": "Perpusatakaan Sultanah Bahiyah",
      "lat": 6.463011,
      "lng": 100.504924,
      "radius": 100,
    },
    {
      "name": "Pusat Konvensyen UUM",
      "lat": 6.459808,
      "lng": 100.506781,
      "radius": 100,
    },
    {
      "name": "School Of Law",
      "lat": 6.457847,
      "lng": 100.506814,
      "radius": 100,
    },
    {
      "name": "Anjung Tamu UUM",
      "lat": 6.448424463655558,
      "lng": 100.5093553770994,
      "radius": 100,
    },
    {
      "name": "INASIS MAS",
      "lat": 6.456216812332843,
      "lng": 100.50446340074869,
      "radius": 100,
    },
    {
      "name": "INASIS TNB",
      "lat": 6.457820775009778,
      "lng": 100.50338728567053,
      "radius": 100,
    },
    {
      "name": "INASIS TNB BLOK E",
      "lat": 6.456801765433259,
      "lng": 100.50303526051911,
      "radius": 100,
    },
    {
      "name": "INASIS SIME DARBY",
      "lat": 6.466531,
      "lng": 100.498455,
      "radius": 100,
    },
    {"name": "INASIS BSN", "lat": 6.469762, "lng": 100.499440, "radius": 100},
    {
      "name": "INASIS MISC (Office Area)",
      "lat": 6.471657,
      "lng": 100.499585,
      "radius": 100,
    },
    {
      "name": "DEWAN MUADZAM SHAH",
      "lat": 6.467380,
      "lng": 100.505252,
      "radius": 100,
    },
    {
      "name": "INASIS PETRONAS (CAFE AREA)",
      "lat": 6.465847,
      "lng": 100.500293,
      "radius": 105,
    },
    {"name": "INASIS TM", "lat": 6.470288, "lng": 100.497195, "radius": 120},
    {
      "name": "INASIS Muamalat",
      "lat": 6.478800,
      "lng": 100.509450,
      "radius": 130,
    },
    {
      "name": "DKG 6/21",
      "lat": 6.454684926509767,
      "lng": 100.50658897910132,
      "radius": 130,
    },
    {
      "name": "UUM INTERNATIONAL SCHOOL",
      "lat": 6.463214953322111,
      "lng": 100.49812607249153,
      "radius": 130,
    },
    {"name": "INASIS YAB", "lat": 6.481016, "lng": 100.509116, "radius": 140},
    {
      "name": "INASIS MAYBANK",
      "lat": 6.466670,
      "lng": 100.495728,
      "radius": 200,
    },
  ];

  @override
  void initState() {
    super.initState();
    // Auto-detect the provider as soon as the screen loads
    _autoDetectProvider();

    // Start listening for network changes (e.g., user turns off WiFi)
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
      // Re-run the detection when the hardware reports a network switch
      _autoDetectProvider();
    });
  }

  @override
  void dispose() {
    // Always cancel listeners when leaving the screen to save battery!
    _connectivitySubscription.cancel();
    super.dispose();
  }

  // --- ADD THIS HELPER FUNCTION ---
  // This checks if the user is inside any of your custom zones
  String? _getCustomCampusLocation(double userLat, double userLng) {
    for (var loc in uumLocations) {
      double distanceInMeters = Geolocator.distanceBetween(
        userLat,
        userLng,
        loc["lat"],
        loc["lng"],
      );

      // If the user is within the radius, return the custom name!
      if (distanceInMeters <= loc["radius"]) {
        return loc["name"];
      }
    }
    return null; // User is not in any custom zone
  }

  Map<String, dynamic>? nearestSuggestion;
  List<dynamic> predictions = [];
  Position? _lastKnownPosition;
  String _lastTestedLocationName = "Unknown Area";

  String selectedActivity = "General";
  final List<String> activities = [
    "General",
    "Studying",
    "Gaming",
    "Streaming",
    "Social Media",
  ];

  // --- NEW: AUTO DETECT NETWORK PROVIDER (LIKE OOKLA) ---
 // --- NEW: AUTO DETECT NETWORK PROVIDER (LIKE OOKLA) ---
  Future<void> _autoDetectProvider() async {
    setState(() {
      statusText = "Detecting network provider...";
    });

    try {
      // Use a free IP-API to get ISP information
      final response = await http.get(Uri.parse('http://ip-api.com/json/'));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Convert to lowercase for easier matching
        String ispName = data['isp']?.toString().toLowerCase() ?? '';
        String orgName = data['org']?.toString().toLowerCase() ?? '';

        String detectedTelco = "Other";

        // Map the ISP name to your specific database labels
        if (ispName.contains('universiti utara') || orgName.contains('universiti utara') || ispName.contains('uum')) {
          detectedTelco = "UUM WiFi";
        } else if (ispName.contains('maxis')) {
          detectedTelco = "Maxis";
        } else if (ispName.contains('celcom') || ispName.contains('digi')) {
          detectedTelco = "CelcomDigi";
        } else if (ispName.contains('u mobile')) {
          detectedTelco = "U Mobile";
        } else if (ispName.contains('telekom') || ispName.contains('unifi') || ispName.contains('tm')) {
          detectedTelco = "Unifi Mobile";
        } else if (ispName.contains('ytl') || ispName.contains('yes')) {
          detectedTelco = "Yes 4G";
        }

        // Update the state with the auto-detected telco
        setState(() {
          selectedTelco = detectedTelco;
          // --- UPDATED LINE BELOW ---
          statusText = "Network provider detected: $detectedTelco"; 
        });
      }
    } catch (e) {
      print("Auto-detect failed: $e");
      // If detection fails, default to "Other" so the test can still run
      setState(() {
        selectedTelco = "Other"; 
        statusText = "Ready to test"; // Fallback text if it fails
      });
    }
  }
  // --- 1. FUNCTION TO CHECK INTERNET CONNECTION ---
  Future<bool> _hasInternet() async {
    try {
      // Tries to look up Google's IP address. If it fails, there's no internet.
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false; // Caught an error, meaning no internet
    }
  }

  // --- 2. FUNCTION TO SHOW ERROR POP-UP ---
  void _showNoInternetDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.wifi_off_rounded, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text(
                "No Connection",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            "You are not connected to the internet. Please turn on your Wi-Fi or Mobile Data to run the network test.",
            style: TextStyle(color: Colors.black87, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> startTest() async {
    setState(() {
      isTesting = true;
    });

    // --- 1. AUTO-DETECT PROVIDER IF NOT SELECTED ---
    if (selectedTelco == null) {
      await _autoDetectProvider();
    }

    // --- 2. INTERNET CHECK LOGIC STARTS HERE ---
    setState(() {
      statusText = "Checking connection..."; 
    });

    bool hasInternet = await _hasInternet();

    if (!hasInternet) {
      // If no internet, stop the test and show the pop-up
      setState(() {
        isTesting = false;
        statusText = "Ready to test";
      });
      _showNoInternetDialog();
      return; // <--- This stops the rest of the code from running
    }

    // If they DO have internet, proceed to GPS
    setState(() {
      statusText = "Acquiring GPS...";
      nearestSuggestion = null;
    });
    // --- NEW LOGIC ENDS HERE ---

    await [Permission.location, Permission.phone].request();

    try {
      // 1. Acquire GPS
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // ... the rest of your custom location and signal code continues here ...
      String addressName =
          "${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}";

      // --- NEW LOGIC: CHECK CUSTOM UUM LOCATIONS FIRST ---
      String? customLocation = _getCustomCampusLocation(
        pos.latitude,
        pos.longitude,
      );

      if (customLocation != null) {
        // We found a match in your custom list!
        addressName = customLocation;
      } else {
        // BACKUP: If they are not near your custom pins, use Google Geocoding
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            pos.latitude,
            pos.longitude,
          );
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks[0];
            List<String> addressParts = [];

            // Helper to ignore Google Plus Codes (like FGJ5+HW)
            bool isPlusCode(String s) => s.contains('+') && s.length <= 9;

            if (place.name != null &&
                place.name!.isNotEmpty &&
                !isPlusCode(place.name!)) {
              addressParts.add(place.name!);
            }
            if (place.street != null &&
                place.street!.isNotEmpty &&
                !isPlusCode(place.street!) &&
                place.street != place.name) {
              addressParts.add(place.street!);
            }
            if (place.subLocality != null && place.subLocality!.isNotEmpty) {
              addressParts.add(place.subLocality!);
            }

            if (addressParts.isNotEmpty) {
              addressName = addressParts.take(2).join(", ");
            }
          }
        } catch (e) {
          print("Geocoding Failed: $e");
        }
      }

      // 2. CHECK SIGNAL (dBm)
      setState(() => statusText = "Checking Signal...");
      final FlutterInternetSignal internetSignal = FlutterInternetSignal();
      int? signalDbm = await internetSignal.getMobileSignalStrength();
      String detectedType = "Mobile";
      if (signalDbm == null || signalDbm == 0 || signalDbm > 0) {
        var wifiInfo = await internetSignal.getWifiSignalInfo();
        signalDbm = wifiInfo?.dbm;
        detectedType = "WiFi";
      }

      if (signalDbm != null && signalDbm > 0) signalDbm = -signalDbm;

      // 3. UPGRADED PING TEST
      setState(() => statusText = "Pinging Server...");
      final String pingUrl = "https://www.gstatic.com/generate_204";
      List<int> pings = [];

      for (int i = 0; i < 3; i++) {
        final stopwatch = Stopwatch()..start();
        try {
          await http
              .head(
                Uri.parse(
                  "$pingUrl?t=${DateTime.now().millisecondsSinceEpoch}",
                ),
              )
              .timeout(const Duration(seconds: 2));
          stopwatch.stop();
          pings.add(stopwatch.elapsedMilliseconds);
        } catch (e) {
          // Ignore failed ping attempts
        }
      }

      int pingMs = 999;
      if (pings.isNotEmpty) {
        pings.sort();
        pingMs = pings.first;
      }

      // 4. UPGRADED DOWNLOAD TEST (OVH Endpoint)
      setState(() => statusText = "Testing Download...");

      final String largeFileUrl = "https://proof.ovh.net/files/100Mb.dat";

      int downloadedBytes = 0;
      bool stopDl = false;
      final swDl = Stopwatch()..start();

      Future<void> downloadTask() async {
        final dlClient = http.Client();
        try {
          final dlRequest = http.Request('GET', Uri.parse(largeFileUrl));
          final dlResponse = await dlClient.send(dlRequest);

          if (dlResponse.statusCode != 200) {
            print("DOWNLOAD REJECTED: Status Code ${dlResponse.statusCode}");
          }

          await for (var chunk in dlResponse.stream) {
            if (stopDl) {
              dlClient.close();
              break;
            }
            downloadedBytes += chunk.length;
          }
        } catch (e) {
          print("DOWNLOAD ERROR: $e");
        } finally {
          dlClient.close();
        }
      }

      List<Future> dlTasks = List.generate(4, (_) => downloadTask());

      await Future.any([
        Future.delayed(const Duration(seconds: 7)),
        Future.wait(dlTasks),
      ]);
      stopDl = true;
      swDl.stop();

      double dlSpeed = 0.0;
      if (swDl.elapsedMilliseconds > 0) {
        dlSpeed =
            (downloadedBytes * 8) / (swDl.elapsedMilliseconds / 1000) / 1000000;
      }

      // 5. UPGRADED UPLOAD TEST (Cloudflare Endpoint - Bypasses your firewall!)
      setState(() => statusText = "Testing Upload...");
      int uploadedBytes = 0;
      bool stopUl = false;
      final swUl = Stopwatch()..start();

      final dummyData = Uint8List(256 * 1024);
      // FIX: Use Cloudflare's professional upload endpoint instead of your PHP server
      final String uploadUrl = "https://speed.cloudflare.com/__up";

      Future<void> uploadTask() async {
        final ulClient = http.Client();
        while (!stopUl && swUl.elapsedMilliseconds < 7000) {
          try {
            final response = await ulClient
                .post(
                  Uri.parse(uploadUrl),
                  body: dummyData,
                  headers: {'Content-Type': 'application/octet-stream'},
                )
                .timeout(const Duration(seconds: 10));

            if (response.statusCode == 200) {
              uploadedBytes += dummyData.lengthInBytes;
            } else {
              print("UPLOAD REJECTED: Status Code ${response.statusCode}");
            }
          } catch (e) {
            print("UPLOAD ERROR: $e");
            continue;
          }
        }
        ulClient.close();
      }

      List<Future> ulTasks = List.generate(2, (_) => uploadTask());
      await Future.any([
        Future.delayed(const Duration(seconds: 7)),
        Future.wait(ulTasks),
      ]);
      stopUl = true;
      swUl.stop();

      double ulSpeed = 0.0;
      if (swUl.elapsedMilliseconds > 0) {
        ulSpeed =
            (uploadedBytes * 8) / (swUl.elapsedMilliseconds / 1000) / 1000000;
      }

      // 6. SAVE RESULTS (Still safely using your database)
      setState(() => statusText = "Saving Results...");
      await saveData(
        pos.latitude,
        pos.longitude,
        pingMs,
        dlSpeed,
        ulSpeed,
        signalDbm ?? 0,
        detectedType,
        addressName,
        selectedActivity,
      );

      _lastKnownPosition = pos;
      _lastTestedLocationName = addressName;
      await _fetchNearestGoodConnection(
        pos.latitude,
        pos.longitude,
        selectedTelco!,
      );

      setState(() {
        ping = "$pingMs ms";
        dl = "${dlSpeed.toStringAsFixed(1)} Mbps";
        ul = "${ulSpeed.toStringAsFixed(1)} Mbps";
        dbm = "$signalDbm";
        statusText = "Test Complete!";
        isTesting = false;
      });
    } catch (e) {
      setState(() {
        statusText = "Error: $e";
        isTesting = false;
      });
    }
  }

  Future<void> saveData(
    double lat,
    double long,
    int p,
    double d,
    double u,
    int dbm,
    String realNetType,
    String locName,
    String activity,
  ) async {
    try {
      await http.post(
        Uri.parse("${MyConfig.baseUrl}/save_test.php"),
        body: {
          "matric": widget.user.matric ?? "Unknown",
          "telco": selectedTelco ?? "Unknown",
          "lat": lat.toString(),
          "long": long.toString(),
          "netType": realNetType,
          "ping": p.toString(),
          "dl": d.toStringAsFixed(2),
          "ul": u.toStringAsFixed(2),
          "dbm": dbm.toString(),
          "locName": locName,
          "activity": activity,
        },
      );
    } catch (e) {
      print("Save Data Error: $e");
    }
  }

  Future<void> _fetchNearestGoodConnection(
    double lat,
    double lng,
    String telco,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("${MyConfig.baseUrl}/suggest_nearest.php"),
        body: {'lat': lat.toString(), 'long': lng.toString(), 'telco': telco},
      );
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['found'] == true) {
          setState(() {
            nearestSuggestion = data;
          });
        } else {
          setState(() => nearestSuggestion = null);
        }
      }
    } catch (e) {
      print("Suggestion Error: $e");
    }
  }

  void _fetchPrediction() {
    if (_lastKnownPosition == null || selectedTelco == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please run a speed test first to get your location."),
        ),
      );
      return;
    }
    _showPredictionBottomSheet();
  }

  void _showPredictionBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return FutureBuilder<http.Response>(
          future: http.post(
            Uri.parse("${MyConfig.baseUrl}/predict_8hours.php"),
            body: {
              'lat': _lastKnownPosition!.latitude.toString(),
              'long': _lastKnownPosition!.longitude.toString(),
              'telco': selectedTelco,
            },
          ),
          builder: (context, snapshot) {
            bool isLoading =
                snapshot.connectionState == ConnectionState.waiting;
            List<dynamic> sheetPredictions = [];

            if (snapshot.hasData && snapshot.data!.statusCode == 200) {
              var data = jsonDecode(snapshot.data!.body);
              sheetPredictions = data['predictions'] ?? [];
            }

            return Container(
              padding: const EdgeInsets.all(20),
              height: 400,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "🔮 8-Hour Performance Forecast",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const Text(
                    "Based on past 7 days of data in this area.",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.deepPurple,
                            ),
                          )
                        : ListView.builder(
                            itemCount: sheetPredictions.length,
                            itemBuilder: (context, index) {
                              var p = sheetPredictions[index];
                              bool hasData = p['expected_dl'] != "Unknown";

                              double expectedSpeed = 0.0;
                              if (hasData) {
                                expectedSpeed =
                                    double.tryParse(
                                      p['expected_dl'].toString(),
                                    ) ??
                                    0.0;
                              }
                              bool isGoodSpeed = expectedSpeed >= 5.0;

                              return ListTile(
                                leading: Icon(
                                  Icons.access_time,
                                  color: Colors.deepPurple.shade300,
                                ),
                                title: Text(
                                  p['time'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  hasData
                                      ? "Speed: ${p['expected_dl']} Mbps | Signal: ${p['expected_dbm']} dBm\nConfidence: ${p['confidence']}"
                                      : "Not enough historical data",
                                ),
                                trailing: Icon(
                                  hasData
                                      ? (isGoodSpeed
                                            ? Icons.wifi
                                            : Icons.signal_wifi_bad)
                                      : Icons.wifi_off,
                                  color: hasData
                                      ? (isGoodSpeed
                                            ? Colors.green
                                            : Colors.red)
                                      : Colors.grey,
                                ),
                                isThreeLine: true,
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- CONGESTION GRAPH LOGIC ---
  int _calculateQualityScore(double dl, double ul, double ping, double dbm) {
    int score = 0;

    if (dbm >= -85)
      score += 3;
    else if (dbm >= -105)
      score += 2;
    else
      score += 1;

    if (dl >= 10)
      score += 3;
    else if (dl >= 5)
      score += 2;
    else
      score += 1;

    if (ping > 0 && ping <= 150)
      score += 3;
    else if (ping <= 200)
      score += 2;
    else
      score += 1;

    if (ul >= 10)
      score += 3;
    else if (ul >= 4)
      score += 2;
    else
      score += 1;

    // Convert 4 to 12 point scale into a 0 - 100 Percentage
    return ((score / 12) * 100).toInt();
  }

  void _showCongestionGraph() {
    if (_lastTestedLocationName == "Unknown Area" || selectedTelco == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please run a test to locate your area first."),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return FutureBuilder<http.Response>(
          future: http.post(
            Uri.parse("${MyConfig.baseUrl}/get_hourly_congestion.php"),
            body: {'location': _lastTestedLocationName, 'telco': selectedTelco},
          ),
          builder: (context, snapshot) {
            bool isLoading =
                snapshot.connectionState == ConnectionState.waiting;
            List<FlSpot> chartSpots = [];

            if (snapshot.hasData && snapshot.data!.statusCode == 200) {
              try {
                var jsonResponse = jsonDecode(snapshot.data!.body);
                if (jsonResponse['status'] == 'success') {
                  List<dynamic> data = jsonResponse['data'];
                  for (var row in data) {
                    double hour = double.parse(row['hour'].toString());
                    int score = _calculateQualityScore(
                      double.parse(row['dl'].toString()),
                      double.parse(row['ul'].toString()),
                      double.parse(row['ping'].toString()),
                      double.parse(row['dbm'].toString()),
                    );
                    chartSpots.add(FlSpot(hour, score.toDouble()));
                  }
                }
              } catch (e) {
                print("Error parsing chart data: $e");
              }
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "📈 24-Hour Congestion: $_lastTestedLocationName",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Overall Network Quality (%) for $selectedTelco. Dips indicate high network congestion / peak hours.",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 40),

                  Expanded(
                    child: isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.deepPurple,
                            ),
                          )
                        : (chartSpots.isEmpty
                              ? const Center(
                                  child: Text(
                                    "Not enough historical data for this exact location to draw a graph.",
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  child: Container(
                                    width: 800,
                                    padding: const EdgeInsets.only(
                                      right: 20,
                                      top: 10,
                                    ), // FIX: Added padding so top points are not cut
                                    child: LineChart(
                                      LineChartData(
                                        minX: 0,
                                        maxX: 23,
                                        minY: 0,
                                        maxY:
                                            105, // FIX: Increased to 105 for headroom
                                        gridData: const FlGridData(
                                          show: true,
                                          drawVerticalLine: true,
                                        ),
                                        titlesData: FlTitlesData(
                                          topTitles: const AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: false,
                                            ),
                                          ),
                                          rightTitles: const AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: false,
                                            ),
                                          ),
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              interval: 1,
                                              getTitlesWidget: (value, meta) {
                                                int hour = value.toInt();
                                                String suffix = hour >= 12
                                                    ? 'PM'
                                                    : 'AM';
                                                int displayHour = hour > 12
                                                    ? hour - 12
                                                    : (hour == 0 ? 12 : hour);
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 8.0,
                                                      ),
                                                  child: Text(
                                                    "$displayHour$suffix",
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          leftTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize:
                                                  45, // FIX: Increased to give text more width
                                              getTitlesWidget: (value, meta) {
                                                if (value > 100 ||
                                                    value % 25 != 0)
                                                  return const SizedBox.shrink(); // FIX: Hide > 100
                                                return Text(
                                                  "${value.toInt()}%",
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        borderData: FlBorderData(show: false),
                                        lineBarsData: [
                                          LineChartBarData(
                                            spots: chartSpots,
                                            isCurved: true,
                                            color: Colors.deepPurple,
                                            barWidth: 4,
                                            isStrokeCapRound: true,
                                            dotData: const FlDotData(
                                              show: true,
                                            ),
                                            belowBarData: BarAreaData(
                                              show: true,
                                              color: Colors.deepPurple
                                                  .withOpacity(0.15),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Close",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if we are ready to interact with results
    bool hasResults = ping != "--" && !isTesting;

    return Container(
      color: Colors.grey.shade50,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          // REDUCED: vertical padding from 20.0 to 12.0 to push everything up
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            children: [
              // --- 1. TOP: NETWORK & ACTIVITY SELECTOR ---
              Row(
                children: [
                // Network Display (Auto-Detected, No Dropdown)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: selectedTelco == null
                              ? Colors.orange.shade400
                              : Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.cell_tower,
                                  color: Colors.deepPurple,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Network",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          
                          // --- REPLACED DROPDOWN WITH STATIC DISPLAY ---
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 12, // Taller padding to match Activity dropdown height
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    selectedTelco ?? "Detecting...",
                                    style: TextStyle(
                                      color: selectedTelco == null 
                                          ? Colors.grey.shade600 
                                          : Colors.black87,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (selectedTelco == null)
                                  const SizedBox(
                                    height: 14,
                                    width: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.deepPurple,
                                    ),
                                  )
                                else
                                  Icon(
                                    Icons.verified, // Gives a nice "auto-detected" feel
                                    color: Colors.green.shade600,
                                    size: 16,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Activity Dropdown
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.psychology,
                                  color: Colors.orange,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Activity",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedActivity,
                                isExpanded: true,
                                isDense: true,
                                dropdownColor: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                                items: activities
                                    .map(
                                      (String value) => DropdownMenuItem(
                                        value: value,
                                        child: Text(
                                          value,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) =>
                                    setState(() => selectedActivity = val!),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // REDUCED: Space between dropdowns and pill from 20 to 12
              const SizedBox(height: 12),

              // --- 2. STATUS INDICATOR PILL ---
              AnimatedOpacity(
                opacity: statusText == "Ready to test" && !isTesting
                    ? 0.0
                    : 1.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isTesting
                        ? Colors.orange.shade50
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isTesting)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.orange,
                          ),
                        ),
                      if (!isTesting && statusText != "Ready to test")
                        Icon(
                          Icons.check_circle,
                          color: Colors.green.shade600,
                          size: 16,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: isTesting
                              ? Colors.orange.shade800
                              : Colors.green.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // REDUCED: Space between pill and GO button from 20 to 12
              const SizedBox(height: 12),

              // --- 3. GO BUTTON ---
              GestureDetector(
                onTap: isTesting ? null : startTest,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 160,
                  width: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isTesting
                        ? Colors.deepPurple.shade300
                        : Colors.deepPurple,
                    boxShadow: [
                      BoxShadow(
                        color: isTesting
                            ? Colors.deepPurple.withOpacity(0.2)
                            : Colors.deepPurple.withOpacity(0.4),
                        blurRadius: isTesting ? 10 : 25,
                        spreadRadius: isTesting ? 2 : 8,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 8,
                    ),
                  ),
                  child: Center(
                    child: isTesting
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                              SizedBox(height: 10),
                              Text(
                                "TESTING",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          )
                        : const Text(
                            "GO",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                            ),
                          ),
                  ),
                ),
              ),

              // REDUCED: Space between GO button and suggestion from 25 to 15
              const SizedBox(height: 15),

              // --- 4. SUGGESTION CARD (ALWAYS VISIBLE) ---
              Container(
                padding: const EdgeInsets.all(
                  12,
                ), // Reduced slightly to save space
                margin: const EdgeInsets.only(
                  bottom: 12,
                ), // REDUCED margin from 20 to 12
                decoration: BoxDecoration(
                  color: hasResults ? Colors.blue.shade50 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: hasResults
                        ? Colors.blue.shade200
                        : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.assistant_direction,
                      color: hasResults ? Colors.blue : Colors.grey.shade400,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Better Connection Nearby",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: hasResults
                                  ? Colors.blue
                                  : Colors.grey.shade500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            !hasResults
                                ? (isTesting
                                      ? "Scanning for nearby networks..."
                                      : "Run a test to see nearby suggestions.")
                                : (nearestSuggestion != null
                                      ? "Try moving to ${nearestSuggestion!['location']}. It is ${nearestSuggestion!['distance_km']}km away and gets ${nearestSuggestion!['speed']} Mbps."
                                      : "You are currently in the best spot!"),
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.3,
                              color: hasResults
                                  ? Colors.black87
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // --- 5. RESULTS DASHBOARD ---
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio:
                    2.0, // Flattens the boxes slightly to save vertical space
                mainAxisSpacing: 10, // Tighter spacing
                crossAxisSpacing: 10,
                children: [
                  _modernResultCard(
                    "Ping",
                    ping,
                    Icons.compare_arrows,
                    Colors.blue,
                  ),
                  _modernResultCard(
                    "Download",
                    dl,
                    Icons.arrow_downward,
                    Colors.green,
                  ),
                  _modernResultCard(
                    "Upload",
                    ul,
                    Icons.arrow_upward,
                    Colors.orange,
                  ),
                  _modernResultCard(
                    "Signal",
                    dbm == "0" ? "-- dBm" : "$dbm dBm",
                    Icons.network_cell,
                    Colors.red,
                  ),
                ],
              ),

              // REDUCED: Space between dashboard and bottom buttons from 25 to 15
              const SizedBox(height: 15),

              // --- 6. ACTION BUTTONS (ALWAYS VISIBLE) ---
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade500,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ), // Reduced slightly
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: hasResults ? _showCongestionGraph : null,
                      icon: const Icon(Icons.show_chart, size: 20),
                      label: const Text(
                        "Congestion",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ), // Reduced slightly
                        side: BorderSide(
                          color: hasResults
                              ? Colors.deepPurple
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                        foregroundColor: Colors.deepPurple,
                        disabledForegroundColor: Colors.grey.shade500,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: hasResults ? _fetchPrediction : null,
                      icon: Icon(
                        Icons.auto_graph,
                        size: 20,
                        color: hasResults
                            ? Colors.deepPurple
                            : Colors.grey.shade400,
                      ),
                      label: const Text(
                        "Predict 8 Hrs",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- MODERN RESULT CARD WITH BORDER ---
  Widget _modernResultCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        // --- Added consistent borderline here ---
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: color, size: 14),
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
