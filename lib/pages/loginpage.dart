import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // REQUIRED for input formatters
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uum_net/model/user.dart';
import 'package:uum_net/pages/homepage.dart';
import 'package:uum_net/pages/registerpage.dart';
import 'package:uum_net/myconfig.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController matricController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool rememberMe = false;
  bool passwordVisible = true;
  bool isLoading = false;
  late User user;

  @override
  void initState() {
    super.initState();
    loadPreferences();
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
              height: 300,
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
              child: const SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_tethering, size: 80, color: Colors.white),
                    SizedBox(height: 10),
                    Text(
                      "UUM Network",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Monitor & Analyze",
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // --- OVERLAPPING FORM CARD ---
            Container(
              transform: Matrix4.translationValues(0.0, -50.0, 0.0),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Welcome Back",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Login to your account",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 30),

                  // MATRIC FIELD (Strict: Numbers only, exactly 6 digits)
                  TextField(
                    controller: matricController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly, // Only numbers
                      LengthLimitingTextInputFormatter(6),    // Max 6 digits
                    ],
                    decoration: const InputDecoration(
                      labelText: "Matric Number",
                      hintText: "Enter 6-digit matric",
                      prefixIcon: Icon(Icons.badge),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // PASSWORD FIELD
                  TextField(
                    controller: passwordController,
                    obscureText: passwordVisible,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          passwordVisible ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () =>
                            setState(() => passwordVisible = !passwordVisible),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // REMEMBER ME
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: rememberMe,
                          activeColor: Colors.deepPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (val) {
                            setState(() => rememberMe = val!);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Remember Me",
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // LOGIN BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : loginUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shadowColor: Colors.deepPurple.withOpacity(0.5),
                        elevation: 8, 
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Login",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            // --- REGISTER LINK ---
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterPage()),
                );
              },
              child: RichText(
                text: TextSpan(
                  text: "Don't have an account? ",
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
                  children: const [
                    TextSpan(
                      text: "Register here",
                      style: TextStyle(
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void loginUser() async {
    String matric = matricController.text.trim();
    String password = passwordController.text.trim();

    if (matric.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in Matric and Password"), backgroundColor: Colors.red),
      );
      return;
    }

    if (matric.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Matric number must be exactly 6 digits"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("${MyConfig.baseUrl}/login.php"),
        body: {'matric': matric, 'password': password},
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);

        if (jsonResponse['status'] == 'success') {
          if (rememberMe) {
            savePreferences(matric, password);
          } else {
            clearPreferences();
          }

          user = User.fromJson(jsonResponse);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Login Successful!"), backgroundColor: Colors.green),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Homepage(user: user)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(jsonResponse['message'] ?? "Login failed"), backgroundColor: Colors.red),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Server Error: ${response.statusCode}"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connection Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void savePreferences(String m, String p) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('matric', m);
    prefs.setString('password', p);
    prefs.setBool('remember', true);
  }

  void clearPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('matric');
    prefs.remove('password');
    prefs.remove('remember');
  }

  void loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('remember') ?? false) {
      matricController.text = prefs.getString('matric') ?? "";
      passwordController.text = prefs.getString('password') ?? "";
      setState(() => rememberMe = true);
    }
  }
}