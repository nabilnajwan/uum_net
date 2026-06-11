import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // REQUIRED for input formatters
import 'package:http/http.dart' as http;
import 'package:uum_net/myconfig.dart'; 

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController userCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController matricCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();

  bool passwordVisible = true;
  bool isLoading = false; 

  // Variables for Password Strength
  double _strength = 0.0;
  String _strengthText = "";
  Color _strengthColor = Colors.transparent;

  void _checkPasswordStrength(String password) {
    double strength = 0;
    if (password.length >= 6) strength += 0.25;
    if (password.length >= 8) strength += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.25;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.125;
    if (RegExp(r'[!@#\$&*~_\-\.]').hasMatch(password)) strength += 0.125;

    setState(() {
      _strength = strength;
      if (password.isEmpty) {
        _strengthText = "";
        _strengthColor = Colors.transparent;
      } else if (strength <= 0.25) {
        _strengthText = "Weak (Too short)";
        _strengthColor = Colors.red;
      } else if (strength < 0.75) {
        _strengthText = "Medium";
        _strengthColor = Colors.orange;
      } else {
        _strengthText = "Strong";
        _strengthColor = Colors.green;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- TOP HEADER ---
            Container(
              width: double.infinity,
              height: 280, 
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple, Color(0xFF5E35B1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(50),
                  bottomRight: Radius.circular(50),
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const Icon(Icons.person_add_alt_1, size: 60, color: Colors.white),
                    const SizedBox(height: 10),
                    const Text(
                      "Create Account",
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 5),
                    const Text("Join the UUM Network", style: TextStyle(fontSize: 15, color: Colors.white70)),
                  ],
                ),
              ),
            ),

            // --- OVERLAPPING FORM CARD ---
            Container(
              transform: Matrix4.translationValues(0.0, -40.0, 0.0),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, spreadRadius: 5, offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Student Details", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 25),

                  // USERNAME
                  TextField(
                    controller: userCtrl,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(20),
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^[a-zA-Z][a-zA-Z0-9 _\-]*'),
                      ),
                    ],
                    decoration: const InputDecoration(labelText: "Full Name", prefixIcon: Icon(Icons.person)),
                  ),
                  const SizedBox(height: 16), 

                  // EMAIL
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: "Email Address", prefixIcon: Icon(Icons.email)),
                  ),
                  const SizedBox(height: 16),

                  // MATRIC (Strict limit 6 numbers)
                  TextField(
                    controller: matricCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    decoration: const InputDecoration(
                      labelText: "Matric Number",
                      hintText: "Enter 6-digit matric",
                      prefixIcon: Icon(Icons.badge),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // PASSWORD
                  TextField(
                    controller: passCtrl,
                    obscureText: passwordVisible,
                    onChanged: (val) => _checkPasswordStrength(val), // Trigger strength check
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(passwordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                        onPressed: () => setState(() => passwordVisible = !passwordVisible),
                      ),
                    ),
                  ),
                  
                  // STRENGTH INDICATOR
                  if (passCtrl.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: _strength,
                              backgroundColor: Colors.grey.shade200,
                              color: _strengthColor,
                              minHeight: 5,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _strengthText, 
                            style: TextStyle(color: _strengthColor, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 35),

                  // SIGN UP BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : registerUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shadowColor: Colors.deepPurple.withOpacity(0.5),
                        elevation: 8,
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Create Account",
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void registerUser() async {
    String name = userCtrl.text.trim();
    String email = emailCtrl.text.trim();
    String matric = matricCtrl.text.trim();
    String password = passCtrl.text.trim();

    // 1. Basic Empty Validation
    if (name.isEmpty || email.isEmpty || matric.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill in all fields"), backgroundColor: Colors.red));
      return;
    }

    // 2. Strict Email Validation
    final emailRegExp = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    if (!emailRegExp.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a valid email address"), backgroundColor: Colors.red));
      return;
    }

    // 3. Strict Matric Validation
    if (matric.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Matric number must be exactly 6 digits"), backgroundColor: Colors.red));
      return;
    }

    // 4. Strict Password Validation (Must be at least Medium)
    if (_strength <= 0.25) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password is too weak. Must be at least 6 characters."), backgroundColor: Colors.red));
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("${MyConfig.baseUrl}/signup.php"),
        body: {
          'username': name,
          'email': email,
          'matric': matric,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        
        if (jsonResponse['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Registration Success! Please Login."), backgroundColor: Colors.green));
          
          Navigator.pop(context); 
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(jsonResponse['message']), backgroundColor: Colors.red));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Server Error: ${response.statusCode}"), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Connection Error: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => isLoading = false); 
    }
  }
}