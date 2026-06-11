import 'package:flutter/material.dart';
import 'package:uum_net/pages/loginpage.dart';

class MyDrawer extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const MyDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // 1. The Header (Modern Gradient Box)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 20, left: 20, right: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Color(0xFF5E35B1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              // Slight rounding at the bottom of the drawer header
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(30),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.wifi_tethering, size: 40, color: Colors.white),
                ),
                SizedBox(height: 15),
                Text(
                  "UUM Network",
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: 22, 
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Tools & Diagnostics",
                  style: TextStyle(
                    color: Colors.white70, 
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 10), // Breathing room after header

          // 2. Menu Items (Wrapped in Expanded to push logout to bottom if desired, or just standard list)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12), // Padding so highlights aren't edge-to-edge
              children: [
                _buildDrawerItem(
                  icon: Icons.speed,
                  title: 'Speed Test',
                  index: 0,
                  context: context,
                ),
                _buildDrawerItem(
                  icon: Icons.map,
                  title: 'Signal Heatmap',
                  index: 1,
                  context: context,
                ),
                _buildDrawerItem(
                  icon: Icons.table_chart,
                  title: 'Network Status',
                  index: 2,
                  context: context,
                ),
                _buildDrawerItem(
                  icon: Icons.person,
                  title: 'My Profile',
                  index: 3,
                  context: context,
                ),
              ],
            ),
          ),

          // 3. Logout Area (Sticks to bottom)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(color: Colors.black12, thickness: 1),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 20, top: 5),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.logout, color: Colors.red),
              ),
              title: const Text(
                'Logout', 
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                _showLogoutDialog(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER TO BUILD MENU ITEMS ---
  Widget _buildDrawerItem({
    required IconData icon, 
    required String title, 
    required int index, 
    required BuildContext context
  }) {
    bool isSelected = selectedIndex == index;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15), // Gives the pill-shape highlight
        ),
        selectedTileColor: Colors.deepPurple.shade50, // Soft background when selected
        leading: Icon(
          icon, 
          color: isSelected ? Colors.deepPurple : Colors.grey.shade600,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.deepPurple : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        selected: isSelected,
        onTap: () {
          onItemTapped(index);
          Navigator.pop(context); // Close drawer
        },
      ),
    );
  }

  // --- LOGOUT DIALOG ---
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text("Confirm Logout"),
            ],
          ),
          content: const Text(
            "Are you sure you want to log out of your account?",
            style: TextStyle(fontSize: 16),
          ),
          actionsPadding: const EdgeInsets.only(bottom: 15, right: 15),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () {
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                  (Route<dynamic> route) => false,
                );
              },
              child: const Text(
                "Logout",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }
}