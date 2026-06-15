import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'package:uum_net/model/user.dart';
import 'package:uum_net/myconfig.dart';

class ProfilePage extends StatefulWidget {
  User user;
  ProfilePage({super.key, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final usernameController = TextEditingController();
  final bioController = TextEditingController();
  final matricController = TextEditingController();

  bool isLoading = false;
  bool _isEditing = false;
  File? _image;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    usernameController.text = widget.user.username ?? '';
    bioController.text = widget.user.bio ?? '';
    matricController.text = widget.user.matric ?? '';
  }

  // --- FETCH PATTERNS FROM API ---
  Future<List<dynamic>> _fetchMyPatterns() async {
    try {
      final response = await http.post(
        Uri.parse("${MyConfig.baseUrl}/get_personal_patterns.php"),
        body: {"matric": widget.user.matric ?? ""},
      );
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return data['data'] ?? [];
        }
      }
    } catch (e) {
      print("Error fetching patterns: $e");
    }
    return [];
  }

  // --- BOTTOM SHEET IMAGE PICKER ---
  Future<void> _selectImage() async {
    if (!_isEditing) return;

    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          // 1. I removed the 'height: 180,' line from here
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            // 2. I added this line so it automatically wraps the content!
            mainAxisSize: MainAxisSize.min, 
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Text(
                "Select Profile Picture",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPickerOption(
                    Icons.camera_alt_rounded,
                    "Camera",
                    ImageSource.camera,
                    picker,
                  ),
                  _buildPickerOption(
                    Icons.photo_library_rounded,
                    "Gallery",
                    ImageSource.gallery,
                    picker,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPickerOption(
    IconData icon,
    String label,
    ImageSource source,
    ImagePicker picker,
  ) {
    return GestureDetector(
      onTap: () async {
        Navigator.pop(context);
        final pickedFile = await picker.pickImage(
          source: source,
          maxHeight: 800,
          maxWidth: 800,
          imageQuality: 50,
        );
        if (pickedFile != null) {
          setState(() {
            _image = File(pickedFile.path);
          });
        }
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30, color: Colors.deepPurple),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // --- UPDATE PROFILE LOGIC ---
  Future<void> _updateProfile() async {
    if (usernameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Username cannot be empty"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    String base64Image = "";
    if (_image != null) {
      base64Image = base64Encode(_image!.readAsBytesSync());
    }

    try {
      final response = await http.post(
        Uri.parse('${MyConfig.baseUrl}/update_profile.php'),
        body: {
          'matric': widget.user.matric,
          'username': usernameController.text.trim(),
          'bio': bioController.text.trim(),
          'image': base64Image,
        },
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            widget.user.username = usernameController.text.trim();
            widget.user.bio = bioController.text.trim();
            if (data['profile_pic'] != null) {
              widget.user.profilePic = data['profile_pic'];
            }
            _image = null;
            _isEditing = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Success! Profile updated."),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed: ${data['message']}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Server Error: ${response.statusCode}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    String imageUrl = "";
    if (widget.user.profilePic != null && widget.user.profilePic!.isNotEmpty) {
      String rootUrl = MyConfig.baseUrl.replaceAll("/api", "");
      imageUrl = "$rootUrl/${widget.user.profilePic}";
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      // We extend the body behind the app bar so our custom gradient header hits the very top
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close_rounded : Icons.edit_rounded),
            tooltip: _isEditing ? "Cancel" : "Edit Profile",
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                if (!_isEditing) {
                  _loadUserData();
                  _image = null;
                }
              });
            },
          ),
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {
                setState(() => _loadUserData());
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // --- THE HEADER OVERLAP ---
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    // Curved Purple Header
                    Container(
                      height: 240,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.deepPurple, Color(0xFF5E35B1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(40),
                          bottomRight: Radius.circular(40),
                        ),
                      ),
                      child: const SafeArea(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: EdgeInsets.only(top: 10.0),
                            child: Text(
                              "My Profile",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Avatar Overlapping the border
                    Positioned(
                      bottom: -60,
                      child: GestureDetector(
                        onTap: _selectImage,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 65,
                                backgroundColor: Colors.white,
                                backgroundImage: _image != null
                                    ? FileImage(_image!) as ImageProvider
                                    : (imageUrl.isNotEmpty
                                          ? NetworkImage(
                                              "$imageUrl?v=${DateTime.now().millisecondsSinceEpoch}",
                                            )
                                          : null),
                                child: (_image == null && imageUrl.isEmpty)
                                    ? const Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.deepPurple,
                                      )
                                    : null,
                              ),
                            ),
                            // Floating Camera Icon (only visible when editing)
                            if (_isEditing)
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 80), // Spacer for the overlapping avatar
                // --- MAIN CONTENT AREA ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // View Mode vs Edit Mode
                      _isEditing ? _buildEditForm() : _buildReadOnlyDashboard(),

                      const SizedBox(height: 30),

                      // --- LEARNED PATTERNS SECTION (Only in View Mode) ---
                      if (!_isEditing) ...[
                        const Row(
                          children: [
                            Icon(
                              Icons.psychology_rounded,
                              color: Colors.deepPurple,
                              size: 28,
                            ),
                            SizedBox(width: 10),
                            Text(
                              "My Usage Patterns",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Data-Driven Insights",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 20),

                        FutureBuilder<List<dynamic>>(
                          future: _fetchMyPatterns(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: CircularProgressIndicator(
                                    color: Colors.deepPurple,
                                  ),
                                ),
                              );
                            }

                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(25),
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.insights_rounded,
                                      color: Colors.deepPurple.shade200,
                                      size: 50,
                                    ),
                                    const SizedBox(height: 15),
                                    Text(
                                      "No patterns learned yet.\nRun more speed tests to generate insights!",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.deepPurple.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return Column(
                              children: snapshot.data!.map((p) {
                                double speed =
                                    double.tryParse(
                                      p['avg_speed'].toString(),
                                    ) ??
                                    0.0;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 15),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white,
                                        Colors.deepPurple.shade50.withOpacity(
                                          0.5,
                                        ),
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.orange
                                                    .withOpacity(0.2),
                                                blurRadius: 10,
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.auto_awesome_rounded,
                                            color: Colors.orange,
                                          ),
                                        ),
                                        const SizedBox(width: 15),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Best for ${p['activity_type']}",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Colors.deepPurple,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                "Go to ${p['location_name']} around ${p['display_time']}",
                                                style: TextStyle(
                                                  color: Colors.grey.shade700,
                                                  fontSize: 13,
                                                  height: 1.3,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  "Avg: ${speed.toStringAsFixed(1)} Mbps",
                                                  style: TextStyle(
                                                    color:
                                                        Colors.green.shade700,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                        const SizedBox(height: 40),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Loading Overlay
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  // --- MODERN READ-ONLY DASHBOARD ---
  Widget _buildReadOnlyDashboard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildListTile(
            Icons.person_rounded,
            "Username",
            widget.user.username ?? "Not set",
          ),
          const Divider(height: 1, indent: 60),
          _buildListTile(
            Icons.badge_rounded,
            "Matric Number",
            widget.user.matric ?? "Not set",
          ),
          const Divider(height: 1, indent: 60),
          _buildListTile(
            Icons.info_outline_rounded,
            "Bio",
            widget.user.bio == null || widget.user.bio!.isEmpty
                ? "Add a short bio to let others know you."
                : widget.user.bio!,
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, String subtitle) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade50,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.deepPurple),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // --- EDIT FORM ---
  Widget _buildEditForm() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Edit Details",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          _buildTextField("Username", Icons.person_rounded, usernameController),
          const SizedBox(height: 16),
          _buildTextField(
            "Matric Number (Read Only)",
            Icons.badge_rounded,
            matricController,
            enabled: false,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            "Bio / Description",
            Icons.info_outline_rounded,
            bioController,
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                elevation: 5,
                shadowColor: Colors.deepPurple.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _updateProfile,
              child: const Text(
                "Save Changes",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    IconData icon,
    TextEditingController controller, {
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      style: TextStyle(
        color: enabled ? Colors.black87 : Colors.grey.shade600,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: enabled ? Colors.deepPurple.shade300 : Colors.grey,
        ),
        prefixIcon: Icon(
          icon,
          color: enabled ? Colors.deepPurple : Colors.grey,
        ),
        filled: true,
        fillColor: enabled ? Colors.grey.shade100 : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
        ),
      ),
    );
  }
}
