import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ornatique/Login/ForgotPasswordScreen.dart';
import 'package:ornatique/Login/RegisterScreen.dart';
import 'package:ornatique/Screens/DashBoardScreen.dart';
import 'package:ornatique/Screens/HomeScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Api_Constant/ApiConstants.dart';
import '../Api_Constant/api_helper.dart';
import '../Constant_font/FontStyles.dart';
import '../LoadingDialog/LoadingDialog.dart';
import '../LoginOtpSingleScreen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      // Perform login action
      LoadingDialog.show(context, message: "Loading...");

      login();

    }
  }

  Future<void> login() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String Device_id = prefs.getString('Device_id').toString();
    String token = prefs.getString('fcm').toString();
    final body = {
      "number": _emailController.text,
      "password": _passwordController.text,
      "device_token": Device_id.toString(),
      "fcm_token": token.toString(),
    };

    final response = await ApiHelper().postRequest(ApiConstants.login, body);
    print("Login Request: $body");
    print("Login API URL: ${ApiConstants.login}");
    print("Login Response: ${response.toString()}");
    if (response != null && response.statusCode == 200) {
      await Future.delayed(Duration(milliseconds: 500)); // Simulate an API call
      LoadingDialog.hide(context);
      final data = response.data;
      final userData = data['data'];
      if (data['status'] == "1") {
        print('Login success: $data');
        print("Login API URL: ${ApiConstants.login}");
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('Uid', userData['id'].toString() ?? '');
        prefs.setString('name', userData['name'] ?? '');
        prefs.setString('email', userData['email'] ?? '');
        prefs.setString('number', userData['number'].toString() ?? '');
        prefs.setString('city', userData['city'] ?? '');
        prefs.setString('company_name', userData['company_name'] ?? 'Ahmedabad');
        prefs.setString('image', userData['image'] ?? '');
        prefs.setString('token', userData['token'] ?? '');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DashBoardScreen()),
        );
      } else {
        print('Login failed - status 0');
        if (data['status'] == "0" && data['message'] == "Already login from another device.") {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              title: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                  SizedBox(width: 10),
                  Text(
                    "Login Restricted",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: const Text(
                "Already login from another device.",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              actions: [
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Text("OK", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              title: Row(
                children: const [
                  Icon(Icons.lock_outline_rounded, color: Colors.orange, size: 28),
                  SizedBox(width: 10),
                  Text(
                    "Account Not Activated",
                    style: TextStyle(
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: Text(
                data['message'] ?? "Your account is inactive. Please activate to proceed.",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 📞 Call Button
                    TextButton.icon(
                      onPressed: () {
                        final phone = "tel:+91 9925823290"; // replace with actual number
                        launchUrl(Uri.parse(phone));
                      },
                      icon: const Icon(Icons.call, color: Colors.green),
                      label: const Text(
                        "Call",
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ),

                    // ✅ OK Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Text("OK", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }



      }
    }else if (response != null && response.statusCode == 401) {
      // ⚠️ Validation error response
      final data = response.data;
      LoadingDialog.hide(context);
      Fluttertoast.showToast(
        msg: data['message'],
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black87,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      // if (data['message'] == "Validation Error" && data['error'] != null) {
      //   final errors = data['error'] as Map<String, dynamic>;
      //
      //
      //   // 🔹 Get the first field and its first error message
      //   final firstField = errors.entries.first.key;
      //   final firstMessage = (errors.entries.first.value as List).first;
      //
      //   // 🔹 Show it in a dialog or toast
      //   Fluttertoast.showToast(
      //     msg: "$firstField: $firstMessage",
      //     toastLength: Toast.LENGTH_SHORT,
      //     gravity: ToastGravity.BOTTOM,
      //     backgroundColor: Colors.black87,
      //     textColor: Colors.white,
      //     fontSize: 16.0,
      //   );
      //
      //   // final errorMessages = errors.entries
      //   //     .map((entry) => "${entry.key}: ${entry.value.join(', ')}")
      //   //     .join('\n');
      //   //
      //   // showDialog(
      //   //   context: context,
      //   //   builder: (context) => AlertDialog(
      //   //     title: const Text("Validation Error"),
      //   //     content: Text(errorMessages),
      //   //     actions: [
      //   //       TextButton(
      //   //         onPressed: () => Navigator.of(context).pop(),
      //   //         child: const Text("OK"),
      //   //       ),
      //   //     ],
      //   //   ),
      //   // );
      // } else {
      //   Fluttertoast.showToast(
      //     msg: data['message'].toString(),
      //     toastLength: Toast.LENGTH_SHORT,
      //     gravity: ToastGravity.BOTTOM,
      //     backgroundColor: Colors.black87,
      //     textColor: Colors.white,
      //     fontSize: 16.0,
      //   );
      // }
    }else if (response != null && response.statusCode == 404) {
      // ⚠️ Validation error response
      final data = response.data;
      LoadingDialog.hide(context);
      Fluttertoast.showToast(
        msg: data['message'],
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black87,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      // if (data['message'] == "Validation Error" && data['error'] != null) {
      //   final errors = data['error'] as Map<String, dynamic>;
      //
      //
      //   // 🔹 Get the first field and its first error message
      //   final firstField = errors.entries.first.key;
      //   final firstMessage = (errors.entries.first.value as List).first;
      //
      //   // 🔹 Show it in a dialog or toast
      //   Fluttertoast.showToast(
      //     msg: "$firstField: $firstMessage",
      //     toastLength: Toast.LENGTH_SHORT,
      //     gravity: ToastGravity.BOTTOM,
      //     backgroundColor: Colors.black87,
      //     textColor: Colors.white,
      //     fontSize: 16.0,
      //   );
      //
      //   // final errorMessages = errors.entries
      //   //     .map((entry) => "${entry.key}: ${entry.value.join(', ')}")
      //   //     .join('\n');
      //   //
      //   // showDialog(
      //   //   context: context,
      //   //   builder: (context) => AlertDialog(
      //   //     title: const Text("Validation Error"),
      //   //     content: Text(errorMessages),
      //   //     actions: [
      //   //       TextButton(
      //   //         onPressed: () => Navigator.of(context).pop(),
      //   //         child: const Text("OK"),
      //   //       ),
      //   //     ],
      //   //   ),
      //   // );
      // } else {
      //   Fluttertoast.showToast(
      //     msg: data['message'].toString(),
      //     toastLength: Toast.LENGTH_SHORT,
      //     gravity: ToastGravity.BOTTOM,
      //     backgroundColor: Colors.black87,
      //     textColor: Colors.white,
      //     fontSize: 16.0,
      //   );
      // }
    }else if(response != null && response.statusCode == 426) {
      final data = response.data;
      if (data["status"] == false && data["code"] == "FORCE_UPDATE") {
        _showForceUpdateDialog(
          context,
          data["message"],
          data["store_url"],
        );
      }
      //setState(() => homeHeading = null);
    }else {
      LoadingDialog.hide(context);
      print("Status Code: ${response?.statusCode.toString() ?? 'No Response'}");

      if (response != null && response.data != null) {
        print("Message: ${response.data['message'] ?? 'No message from server'}");
      } else {
        print("No response data available");
      }

      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text("Login Failed")),
      // );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset('assets/logo.png',height: 150,).animate().fade(duration: 800.ms).moveY(begin: -30, end: 0),
                SizedBox(height: 20),
                // Title
                Text(
                  "Welcome Back!",
                 style:FontStyles.heading,
                ).animate().fade(delay: 300.ms),

                SizedBox(height: 10),

                // Subtitle
                Text(
                  "Login to continue",
                  style:FontStyles.greycolor_text,
                ).animate().fade(delay: 500.ms),

                SizedBox(height: 30),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: "Mobile Number",
                    counterText: "",
                    prefixIcon: Icon(Icons.call, color: Colors.blueAccent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter your Mobile Number";
                    }
                    // else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    //   return "Enter a valid email";
                    // }
                    else if (value.length!=10) {
                      return "Please enter your 10 digit Mobile Number";
                    }
                    return null;
                  },
                ).animate().fade(delay: 700.ms),

                SizedBox(height: 20),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: Icon(Icons.lock, color: Colors.blueAccent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.blueAccent,
                      ),
                      onPressed: _togglePasswordVisibility,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter your password";
                    } else if (value.length < 6) {
                      return "Password must be at least 6 characters";
                    }
                    return null;
                  },
                ).animate().fade(delay: 900.ms),
                SizedBox(height: 10),
                // Align(
                //   alignment: Alignment.topRight,
                //   child: GestureDetector(
                //     onTap: () {
                //       // Navigate to signup screen
                //       Navigator.push(context,
                //           MaterialPageRoute(builder:
                //               (context) =>
                //               ForgotPasswordScreen()
                //           )
                //       );
                //     },
                //     child: Text(
                //       "Forgot Password ?",
                //       style: GoogleFonts.poppins(
                //         fontSize: 14,
                //         color: Colors.blueAccent,
                //       ),
                //     ),
                //   ).animate().fade(delay: 1300.ms),
                // ),
                SizedBox(height: 20),
                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Login",
                      style: FontStyles.white_color,
                    ),
                  ),
                ).animate().fade(delay: 1100.ms).slideY(begin: 0.2, end: 0),
                SizedBox(height: 20),
                // Sign Up Text
                GestureDetector(
                  onTap: () {
                    // Navigate to signup screen
                    if (Platform.isIOS) {
                      // iOS હોય તો LoginOtpSingleScreen પર જવું
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RegisterScreen(),
                        ),
                      );
                    } else {
                      // બીજું device હોય તો RegisterScreen પર જવું
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RegisterScreen(),
                        ),
                      );
                  }
                    },
                  child: Text(
                    "Don't have an account? Sign up",
                    style: FontStyles.blue_accent,
                  ),
                ).animate().fade(delay: 1300.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openWhatsApp() async {
    final String phoneNumber = "919925823290"; // ✅ No + sign
    final String message = Uri.encodeComponent("Hello! I want to inquire about your products.");
    final Uri whatsappUrl = Uri.parse("https://wa.me/$phoneNumber?text=$message");

    // DEBUG PRINT actual URL
    debugPrint("Trying to launch: $whatsappUrl");

    final canLaunch = await canLaunchUrl(whatsappUrl);
    debugPrint("Can launch: $canLaunch");

    if (canLaunch) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      // fallback or error
      debugPrint("Could not launch WhatsApp");
      //_showErrorDialog();
    }
  }

  void _showForceUpdateDialog(
      BuildContext context,
      String message,
      String storeUrl,
      ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 12,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔵 ICON
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.system_update_alt,
                      color: Colors.blue,
                      size: 48,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 🟣 TITLE
                  const Text(
                    "Update Required",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 🟢 MESSAGE
                  Text(
                    //"We’ve improved performance and fixed important issues.\nPlease update the app to continue.",
                    message.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 🔥 UPDATE BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                      ),
                      onPressed: () async {
                        Navigator.of(context, rootNavigator: true).pop();
                        _openStore(storeUrl);
                          // final url = Uri.parse(
                          //   "https://play.google.com/store/apps/details?id=com.your.app",
                          // );
                          //
                          // await launchUrl(
                          //   url,
                          //   mode: LaunchMode.externalApplication,
                          // );
                      },
                      child: const Text(
                        "Update Now",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
    );

  }

  Future<void> _openStore(String url) async {
    final Uri uri = Uri.parse(url.trim());
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }
}
