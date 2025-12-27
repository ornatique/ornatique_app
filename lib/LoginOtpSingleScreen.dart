// import 'package:flutter/material.dart';
// import 'package:pinput/pinput.dart';
//
// import 'Login/RegisterScreen.dart';
//
// class LoginOtpSingleScreen extends StatefulWidget {
//   const LoginOtpSingleScreen({super.key});
//
//   @override
//   State<LoginOtpSingleScreen> createState() => _LoginOtpSingleScreenState();
// }
//
// class _LoginOtpSingleScreenState extends State<LoginOtpSingleScreen> {
//   final TextEditingController _phoneController = TextEditingController();
//   final TextEditingController _otpController = TextEditingController();
//
//   bool _showOtp = false;
//   bool _isVerifying = false;
//   bool _isResending = false;
//
//   @override
//   void dispose() {
//     _phoneController.dispose();
//     _otpController.dispose();
//     super.dispose();
//   }
//
//   // Simulate sending OTP (replace with your API)
//   Future<void> _sendOtp() async {
//     final phone = _phoneController.text.trim();
//     if (phone.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please enter your mobile number')),
//       );
//       return;
//     }
//
//     // Validate basic +91 style or digits - adapt as needed
//     if (phone.replaceAll(RegExp(r'\D'), '').length < 10) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Enter a valid mobile number')),
//       );
//       return;
//     }
//
//     setState(() => _isResending = true);
//     await Future.delayed(const Duration(seconds: 1)); // simulate network
//     setState(() {
//       _isResending = false;
//       _showOtp = true;
//     });
//
//     // Focus OTP automatically (if needed)
//     // You can also call your SMS auto retrieval logic here
//   }
//
//   // Simulate OTP verification
//   Future<void> _verifyOtp() async {
//     final otp = _otpController.text.trim();
//     if (otp.length < 4) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please enter the full OTP')),
//       );
//       return;
//     }
//
//     setState(() => _isVerifying = true);
//     await Future.delayed(const Duration(seconds: 1)); // simulate network
//     setState(() => _isVerifying = false);
//
//     // On success show success dialog
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // replace with your success illustration if available
//             SizedBox(
//               height: 120,
//               child: Image.asset('assets/otp_logo.png', fit: BoxFit.contain),
//             ),
//             const SizedBox(height: 12),
//             const Text(
//               'Login Successful',
//               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
//             ),
//             const SizedBox(height: 8),
//             const Text(
//               'You are now logged in. Click OK to continue.',
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//         actions: [
//           Center(
//             child: ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF00BFA6),
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12)),
//               ),
//               onPressed: (){
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => RegisterScreen(),
//                   ),
//                 );
//                },
//               child: const Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//                 child: Text('OK'),
//               ),
//             ),
//           ),
//         ],
//       ),
//     ).then((_) {
//       // Optionally reset screen or navigate to home
//       setState(() {
//         _showOtp = false;
//         _otpController.clear();
//         _phoneController.clear();
//       });
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     const accent = Color(0xFF00BFA6); // mint/teal accent
//     final size = MediaQuery.of(context).size;
//
//     final defaultPinTheme = PinTheme(
//       width: 56,
//       height: 60,
//       textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
//       decoration: BoxDecoration(
//         color: Colors.grey[100],
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey.shade300),
//       ),
//     );
//
//     return Scaffold(
//       backgroundColor: Colors.grey.shade50,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: Padding(
//             padding:
//             const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
//             child: Column(
//               children: [
//                 // Top illustration card
//                 Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(18),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(18),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.04),
//                         blurRadius: 12,
//                         offset: const Offset(0, 6),
//                       )
//                     ],
//                   ),
//                   child: Column(
//                     children: [
//                       // Illustration image (replace asset)
//                       SizedBox(
//                         height: size.height * 0.26,
//                         child: Image.asset(
//                           'assets/otp_logo.png',
//                           fit: BoxFit.contain,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         _showOtp ? 'Enter the verification code' : 'Welcome',
//                         style: const TextStyle(
//                             fontSize: 20, fontWeight: FontWeight.w700),
//                       ),
//                       const SizedBox(height: 6),
//                       Text(
//                         _showOtp
//                             ? 'Code sent to ${_phoneController.text.isEmpty ? "+91 1234567890" : _phoneController.text}'
//                             : 'Sign in with your mobile number to continue',
//                         style: TextStyle(
//                           color: Colors.grey.shade600,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 const SizedBox(height: 20),
//
//                 // Animated content: phone input OR OTP input
//                 AnimatedSwitcher(
//                   duration: const Duration(milliseconds: 350),
//                   switchInCurve: Curves.easeOutBack,
//                   child: _showOtp ? _buildOtpCard(accent, defaultPinTheme) : _buildPhoneCard(accent),
//                 ),
//
//                 const SizedBox(height: 18),
//
//                 // Optional small footer text / terms
//                 Text(
//                   'By continuing you agree to the Terms & Privacy Policy',
//                   style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
//                   textAlign: TextAlign.center,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildPhoneCard(Color accent) {
//     return Container(
//       key: const ValueKey('phone'),
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.03),
//             blurRadius: 10,
//             offset: const Offset(0, 6),
//           )
//         ],
//       ),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               const Icon(Icons.phone_android, size: 28, color: Colors.grey),
//               const SizedBox(width: 12),
//               const Text('Mobile Number',
//                   style: TextStyle(fontWeight: FontWeight.w600)),
//             ],
//           ),
//           const SizedBox(height: 12),
//           TextField(
//             controller: _phoneController,
//             keyboardType: TextInputType.phone,
//             decoration: InputDecoration(
//               prefixText: '+91 ',
//               hintText: '1234567890',
//               filled: true,
//               fillColor: Colors.grey[50],
//               border:
//               OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//             ),
//           ),
//           const SizedBox(height: 16),
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               onPressed: _isResending ? null : _sendOtp,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: accent,
//                 padding: const EdgeInsets.symmetric(vertical: 14),
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12)),
//                 elevation: 0,
//               ),
//               child: _isResending
//                   ? const SizedBox(
//                 height: 16,
//                 width: 16,
//                 child: CircularProgressIndicator(strokeWidth: 2.2),
//               )
//                   : const Text(
//                 'CONTINUE',
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildOtpCard(Color accent, PinTheme defaultPinTheme) {
//     return Container(
//       key: const ValueKey('otp'),
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.03),
//             blurRadius: 10,
//             offset: const Offset(0, 6),
//           )
//         ],
//       ),
//       child: Column(
//         children: [
//           // OTP boxes
//           Pinput(
//             controller: _otpController,
//             length: 4,
//             defaultPinTheme: defaultPinTheme,
//             focusedPinTheme: defaultPinTheme.copyWith(
//               decoration: defaultPinTheme.decoration!.copyWith(
//                 border: Border.all(color: accent, width: 2),
//                 color: Colors.white,
//               ),
//             ),
//             //androidSmsAutofillMethod:
//             //AndroidSmsAutofillMethod.smsUserConsentApi,
//             onCompleted: (pin) {
//               // auto verify on complete if wanted
//             },
//           ),
//           const SizedBox(height: 12),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               TextButton(
//                 onPressed: _isResending ? null : _sendOtp,
//                 child: _isResending
//                     ? const SizedBox(
//                   width: 16,
//                   height: 16,
//                   child: CircularProgressIndicator(strokeWidth: 2.0),
//                 )
//                     : const Text('Resend'),
//               ),
//               TextButton(
//                 onPressed: () {
//                   // Option to edit phone — go back to phone input
//                   setState(() {
//                     _showOtp = false;
//                     _otpController.clear();
//                   });
//                 },
//                 child: const Text('Edit'),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               onPressed: _isVerifying ? null : _verifyOtp,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: accent,
//                 padding: const EdgeInsets.symmetric(vertical: 14),
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12)),
//               ),
//               child: _isVerifying
//                   ? const SizedBox(
//                 width: 18,
//                 height: 18,
//                 child: CircularProgressIndicator(strokeWidth: 2.0),
//               )
//                   : const Text('VERIFY & LOGIN',
//                   style:
//                   TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ornatique/Login/login_screen.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'Api_Constant/ApiConstants.dart';
import 'Api_Constant/api_helper.dart';
import 'Constant_font/FontStyles.dart';
import 'LoadingDialog/LoadingDialog.dart';
import 'Login/RegisterScreen.dart';
import 'Screens/DashBoardScreen.dart';

class LoginOtpSingleScreen extends StatefulWidget {
  String mobile_no;
  LoginOtpSingleScreen(this.mobile_no,{super.key});

  @override
  State<LoginOtpSingleScreen> createState() => _LoginOtpSingleScreenState();
}

class _LoginOtpSingleScreenState extends State<LoginOtpSingleScreen> {
  final TextEditingController _otpController = TextEditingController();

  bool _isVerifying = false;
  bool _isResending = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }


  Future<void> verifyotp() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String Device_id = prefs.getString('Device_id').toString();
    String token = prefs.getString('fcm').toString();
    final body = {
      "number": widget.mobile_no.toString(),
      "otp": _otpController.text,
      // "device_token": Device_id.toString(),
      // "toStringoken": token.toString(),
    };

    final response = await ApiHelper().postRequest(ApiConstants.verify_otp, body);
    print("Login Request: $body");
    print("Login Response: ${response.toString()}");
    LoadingDialog.show(context, message: "Loading...");
    if (response != null && response.statusCode == 200) {
      await Future.delayed(Duration(milliseconds: 500)); // Simulate an API call
      LoadingDialog.hide(context);
      final data = response.data;
      final userData = data['data'];
      if (data['status'] == "1") {
        print('Login success: $data');
        // SharedPreferences prefs = await SharedPreferences.getInstance();
        // prefs.setString('Uid', userData['id'].toString() ?? '');
        // prefs.setString('name', userData['name'] ?? '');
        // prefs.setString('email', userData['email'] ?? '');
        // prefs.setString('number', userData['number'].toString() ?? '');
        // prefs.setString('city', userData['city'] ?? '');
        // prefs.setString('company_name', userData['company_name'] ?? 'Ahmedabad');
        // prefs.setString('image', userData['image'] ?? '');
        // prefs.setString('token', userData['token'] ?? '');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      } else {
        print('Login failed - status 0');
        // if (data['status'] == "0") {
        //   // showDialog(
        //   //   context: context,
        //   //   barrierDismissible: false,
        //   //   builder: (context) => AlertDialog(
        //   //     shape: RoundedRectangleBorder(
        //   //       borderRadius: BorderRadius.circular(10),
        //   //     ),
        //   //     title: Row(
        //   //       children: const [
        //   //         Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
        //   //         SizedBox(width: 10),
        //   //         Text(
        //   //           "Login Restricted",
        //   //           style: TextStyle(
        //   //             color: Colors.red,
        //   //             fontWeight: FontWeight.bold,
        //   //             fontSize: 18,
        //   //           ),
        //   //         ),
        //   //       ],
        //   //     ),
        //   //     content: const Text(
        //   //       "Already login from another device.",
        //   //       style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        //   //     ),
        //   //     actions: [
        //   //       Center(
        //   //         child: ElevatedButton(
        //   //           style: ElevatedButton.styleFrom(
        //   //             backgroundColor: Colors.blueAccent,
        //   //             shape: RoundedRectangleBorder(
        //   //               borderRadius: BorderRadius.circular(12),
        //   //             ),
        //   //           ),
        //   //           onPressed: () {
        //   //             Navigator.pop(context);
        //   //           },
        //   //           child: const Padding(
        //   //             padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        //   //             child: Text("OK", style: TextStyle(color: Colors.white)),
        //   //           ),
        //   //         ),
        //   //       ),
        //   //     ],
        //   //   ),
        //   // );
        //   showDialog(
        //     context: context,
        //     barrierDismissible: false,
        //     builder: (context) => AlertDialog(
        //       shape: RoundedRectangleBorder(
        //         borderRadius: BorderRadius.circular(10),
        //       ),
        //       title: Row(
        //         children: const [
        //           Icon(Icons.lock_outline_rounded, color: Colors.orange, size: 28),
        //           SizedBox(width: 10),
        //           Text(
        //             "Account Not Activated",
        //             style: TextStyle(
        //               color: Colors.deepOrange,
        //               fontWeight: FontWeight.bold,
        //               fontSize: 18,
        //             ),
        //           ),
        //         ],
        //       ),
        //       content: Text(
        //         data['message'] ?? "Your account is inactive. Please activate to proceed.",
        //         style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        //       ),
        //       actions: [
        //         Row(
        //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //           children: [
        //             // 📞 Call Button
        //             TextButton.icon(
        //               onPressed: () {
        //                 final phone = "tel:+91 9925823290"; // replace with actual number
        //                 launchUrl(Uri.parse(phone));
        //               },
        //               icon: const Icon(Icons.call, color: Colors.green),
        //               label: const Text(
        //                 "Call",
        //                 style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        //               ),
        //             ),
        //
        //             // ✅ OK Button
        //             ElevatedButton(
        //               style: ElevatedButton.styleFrom(
        //                 backgroundColor: Colors.blueAccent,
        //                 shape: RoundedRectangleBorder(
        //                   borderRadius: BorderRadius.circular(12),
        //                 ),
        //               ),
        //               onPressed: () {
        //                 Navigator.pop(context);
        //               },
        //               child: const Padding(
        //                 padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        //                 child: Text("OK", style: TextStyle(color: Colors.white)),
        //               ),
        //             ),
        //           ],
        //         ),
        //       ],
        //     ),
        //   );
        // } else {
        //   showDialog(
        //     context: context,
        //     barrierDismissible: false,
        //     builder: (context) => AlertDialog(
        //       shape: RoundedRectangleBorder(
        //         borderRadius: BorderRadius.circular(10),
        //       ),
        //       title: Row(
        //         children: const [
        //           Icon(Icons.lock_outline_rounded, color: Colors.orange, size: 28),
        //           SizedBox(width: 10),
        //           Text(
        //             "Account Not Activated",
        //             style: TextStyle(
        //               color: Colors.deepOrange,
        //               fontWeight: FontWeight.bold,
        //               fontSize: 18,
        //             ),
        //           ),
        //         ],
        //       ),
        //       content: Text(
        //         data['message'] ?? "Your account is inactive. Please activate to proceed.",
        //         style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        //       ),
        //       actions: [
        //         Row(
        //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //           children: [
        //             // 📞 Call Button
        //             TextButton.icon(
        //               onPressed: () {
        //                 final phone = "tel:+91 9925823290"; // replace with actual number
        //                 launchUrl(Uri.parse(phone));
        //               },
        //               icon: const Icon(Icons.call, color: Colors.green),
        //               label: const Text(
        //                 "Call",
        //                 style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        //               ),
        //             ),
        //
        //             // ✅ OK Button
        //             ElevatedButton(
        //               style: ElevatedButton.styleFrom(
        //                 backgroundColor: Colors.blueAccent,
        //                 shape: RoundedRectangleBorder(
        //                   borderRadius: BorderRadius.circular(12),
        //                 ),
        //               ),
        //               onPressed: () {
        //                 Navigator.pop(context);
        //               },
        //               child: const Padding(
        //                 padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        //                 child: Text("OK", style: TextStyle(color: Colors.white)),
        //               ),
        //             ),
        //           ],
        //         ),
        //       ],
        //     ),
        //   );
        // }
      }
    }else{
      await Future.delayed(Duration(milliseconds: 500)); // Simulate an API call
      LoadingDialog.hide(context);
      print('Login failed - status 0');
      Fluttertoast.showToast(
        msg: response!.data['message'],
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black87,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  // Simulate OTP resend
  Future<void> _sendOtp() async {
    setState(() => _isResending = true);
    await Future.delayed(const Duration(seconds: 1)); // simulate network
    setState(() => _isResending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OTP resent successfully')),
    );
  }

  // Simulate OTP verification
  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the full OTP')),
      );
      return;
    }

    setState(() => _isVerifying = true);
    await Future.delayed(const Duration(seconds: 1)); // simulate network
    setState(() => _isVerifying = false);

    // On success show success dialog
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 120,
              child: Image.asset('assets/otp_logo.png', fit: BoxFit.contain),
            ),
            const SizedBox(height: 12),
            const Text(
              'Login Successful',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'You are now logged in. Click OK to continue.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BFA6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RegisterScreen(),
                  ),
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text('OK'),
              ),
            ),
          ),
        ],
      ),
    ).then((_) {
      _otpController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00BFA6);
    final size = MediaQuery.of(context).size;

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        centerTitle: true,
        title: Text("Verify OTP", style: FontStyles.appbar_heading),
        //backgroundColor: appBarColor ?? Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        // actions: [
        //   IconButton(
        //     icon: Icon(Icons.shopping_cart_outlined,color: Colors.black,),
        //     onPressed: () {},
        //   ),
        // ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Column(
              children: [
                // Top illustration
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: size.height * 0.26,
                        child: Image.asset(
                          'assets/otp_logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Enter the verification code',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Code sent to +91 ' + widget.mobile_no.toString(),
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Direct OTP Input Card
                _buildOtpCard(accent, defaultPinTheme),

                const SizedBox(height: 18),

                Text(
                  'By continuing you agree to the Terms & Privacy Policy',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpCard(Color accent, PinTheme defaultPinTheme) {
    return Container(
      key: const ValueKey('otp'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        children: [
          // OTP boxes
          Pinput(
            controller: _otpController,
            length: 4,
            defaultPinTheme: defaultPinTheme,
            focusedPinTheme: defaultPinTheme.copyWith(
              decoration: defaultPinTheme.decoration!.copyWith(
                border: Border.all(color: accent, width: 2),
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _isResending ? null : _sendOtp,
                child: _isResending
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2.0),
                )
                    : const Text('Resend'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isVerifying
                  ? null
                  : () {
                if (_otpController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter OTP !'),
                      //backgroundColor: Colors.redAccent,
                    ),
                  );
                  return; // Stop here if OTP is empty
                }
                verifyotp(); // Call only if OTP not empty
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isVerifying
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.0),
              )
                  : const Text(
                'VERIFY & LOGIN',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          )

        ],
      ),
    );
  }
}
