import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ornatique/Api_Constant/api_helper.dart';
import 'package:ornatique/ConstantColors/Color_Constant.dart';
import 'package:ornatique/Login/login_screen.dart';
import 'package:ornatique/LoginOtpSingleScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Api_Constant/ApiConstants.dart';
import '../Constant_font/FontStyles.dart';
import '../LoadingDialog/LoadingDialog.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  TextEditingController emailController = TextEditingController();
  TextEditingController fullNameController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  TextEditingController stateController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController companyController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confrimpasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isconfirmPasswordVisible = false;
  File? _businessCard;
  final ImagePicker _picker = ImagePicker();
  bool _isCardMissing = false;
  String? _base64Image;

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _toggleconfirmPasswordVisibility() {
    setState(() {
      _isconfirmPasswordVisible = !_isconfirmPasswordVisible;
    });
  }
  void showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Choose Image Source",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Divider(),
              ListTile(
                leading: Icon(Icons.camera_alt_rounded, color: Colors.blue, size: 28),
                title: Text("Take Photo", style: TextStyle(fontSize: 16)),
                onTap: () {
                  Navigator.pop(context);
                  pickBusinessCard(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library_rounded, color: Colors.green, size: 28),
                title: Text("Choose from Gallery", style: TextStyle(fontSize: 16)),
                onTap: () {
                  Navigator.pop(context);
                  pickBusinessCard(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Crop Image Function
  Future<File?> _cropImage(File imageFile) async {
    CroppedFile? cropped = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Crop Image',
        ),
      ],
    );
    return cropped != null ? File(cropped.path) : null;
  }

  Future<void> pickBusinessCard(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 30, // Adjust this value (1 to 100) for desired quality
    );

    if (pickedFile != null) {
      File? croppedFile = await _cropImage(File(pickedFile.path));
      if (croppedFile != null) {
        // Calculate image size in MB
        int fileSizeInBytes = await croppedFile.length();
        double fileSizeInMB = fileSizeInBytes / (1024 * 1024);
        print("Selected Image Size: ${fileSizeInMB.toStringAsFixed(2)} MB");

        if (fileSizeInMB <= 2) {
          setState(() {
            _businessCard = croppedFile;
          });

          // Show image size in a toast (optional)
          Fluttertoast.showToast(
            msg: "Image Size: ${fileSizeInMB.toStringAsFixed(2)} MB",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.black87,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        } else {
          Fluttertoast.showToast(
            msg: "Image size exceeds 2 MB. Please try again.",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        }
      }
    }
  }
  // Future<void> pickBusinessCard(ImageSource source) async {
  //   final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
  //   if (pickedFile != null) {
  //     final file = File(pickedFile.path);
  //     final bytes = await file.length();
  //
  //     // Check if file is larger than 2MB
  //     if (bytes > 2 * 1024 * 1024) {
  //       if (!mounted) return;
  //       FocusScope.of(context).unfocus();  // Keyboard hide
  //       await Future.delayed(const Duration(milliseconds: 100)); // Smooth unfocus
  //       showDialog(
  //         context: context,
  //         builder: (context) => AlertDialog(
  //           title: const Text("Image Too Large"),
  //           content: const Text("Please select an image smaller than 2 MB."),
  //           actions: [
  //             TextButton(
  //               child: const Text("OK"),
  //               onPressed: () {
  //                 Navigator.of(context).pop();
  //               },
  //             ),
  //           ],
  //         ),
  //       );
  //       return;
  //     }
  //
  //     final fileBytes = await file.readAsBytes();
  //     setState(() {
  //       _businessCard = file;
  //       _base64Image = base64Encode(fileBytes);
  //       _isCardMissing = false;
  //     });
  //   }
  // }
  // Future<void> pickBusinessCard(ImageSource source) async {
  //   final pickedFile = await _picker.pickImage(source: source);
  //   if (pickedFile != null) {
  //     final file = File(pickedFile.path);
  //     final bytes = await file.length();
  //
  //     // Check if file is larger than 2MB
  //     if (bytes > 2 * 1024 * 1024) {
  //       if (!mounted) return;
  //       FocusScope.of(context).unfocus(); // Hide keyboard
  //       await Future.delayed(const Duration(milliseconds: 100)); // Smooth unfocus
  //       showDialog(
  //         context: context,
  //         builder: (context) => AlertDialog(
  //           title: const Text("Image Too Large"),
  //           content: const Text("Please select an image smaller than 2 MB."),
  //           actions: [
  //             TextButton(
  //               child: const Text("OK"),
  //               onPressed: () {
  //                 Navigator.of(context).pop();
  //               },
  //             ),
  //           ],
  //         ),
  //       );
  //       return; // Exit if file is too large
  //     }
  //
  //     // Proceed with cropping if image is valid
  //     File? croppedFile = await _cropImage(file);
  //     if (croppedFile != null) {
  //       // Double-check cropped image size
  //       final croppedBytes = await croppedFile.length();
  //       if (croppedBytes > 2 * 1024 * 1024) {
  //         showDialog(
  //           context: context,
  //           builder: (context) => AlertDialog(
  //             title: const Text("Image Too Large"),
  //             content: const Text("Cropped image exceeds 2 MB. Try cropping smaller."),
  //             actions: [
  //               TextButton(
  //                 child: const Text("OK"),
  //                 onPressed: () {
  //                   Navigator.of(context).pop();
  //                 },
  //               ),
  //             ],
  //           ),
  //         );
  //         return;
  //       }
  //
  //       setState(() {
  //         _businessCard = croppedFile;
  //       });
  //     }
  //   }
  // }


  Future<void> _validateAndSubmit() async {
    if (_formKey.currentState!.validate()) {
      if (_businessCard == null) {
        setState(() {
          _isCardMissing = true;
        });
        return;
      }
      if (passwordController.text != confrimpasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Passwords do not match")),
        );
        return;
      }

      // LoadingDialog.show(context, message: "Registering...");
      // await Future.delayed(const Duration(seconds: 1));
      // LoadingDialog.hide(context);
      signUp();
    }
  }

  Future<void> signUp() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String Device_id = prefs.getString('Device_id').toString();
    String? token = prefs.getString('fcm');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("FCM token not found. Please try again.")),
      );
      return;
    }

    final formData = FormData.fromMap({
      "name": fullNameController.text,
      "number": mobileController.text,
      "email": emailController.text,
      "city": cityController.text,
      "state": stateController.text,
      "company_name": companyController.text,
      "device_type": Platform.isAndroid ? "Android" : "Ios",
      "password": passwordController.text,
      "password_confirmation": confrimpasswordController.text,
      "device_token": Device_id.toString(),
      "token": token.toString(),
      if (_businessCard != null)
        "image": await MultipartFile.fromFile(
          _businessCard!.path,
          filename: _businessCard!.path.split('/').last,
        ),
    });

    try {
      LoadingDialog.show(context, message: "Loading...");
      final response = await ApiHelper().postRequest(ApiConstants.signup, formData);

      print("Sign up Request: $formData");
      print("Sign up Response: ${response?.statusCode}");
      formData.fields.forEach((field) {
        print("${field.key}: ${field.value}");
      });

      for (var file in formData.files) {
        print("File Field: ${file.key}");
        print("File Name: ${file.value.filename}");
        print("File Path: ${file.value.filename}");
      }
      log("👉 Response data: ${response?.data}");
      log("👉 Response data: $formData");
      if (response != null && response.statusCode == 200) {
        // ✅ Success response
        LoadingDialog.hide(context);
        Fluttertoast.showToast(
          msg: "Signup Successful",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LoginOtpSingleScreen(mobileController.text.toString())),
        );
      } else if (response != null && response.statusCode == 400) {
        // ⚠️ Validation error response
        final data = response.data;
        LoadingDialog.hide(context);
        if (data['message'] == "Validation Error" && data['error'] != null) {
          final errors = data['error'] as Map<String, dynamic>;


          // 🔹 Get the first field and its first error message
          final firstField = errors.entries.first.key;
          final firstMessage = (errors.entries.first.value as List).first;

          // 🔹 Show it in a dialog or toast

          Fluttertoast.showToast(
            msg: "$firstField: $firstMessage",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.black87,
            textColor: Colors.white,
            fontSize: 16.0,
          );

          // final errorMessages = errors.entries
          //     .map((entry) => "${entry.key}: ${entry.value.join(', ')}")
          //     .join('\n');
          //
          // showDialog(
          //   context: context,
          //   builder: (context) => AlertDialog(
          //     title: const Text("Validation Error"),
          //     content: Text(errorMessages),
          //     actions: [
          //       TextButton(
          //         onPressed: () => Navigator.of(context).pop(),
          //         child: const Text("OK"),
          //       ),
          //     ],
          //   ),
          // );
        } else {

          Fluttertoast.showToast(
            msg: data['message'].toString(),
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.black87,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        }
      } else {

        Fluttertoast.showToast(
          msg: "Error: ${response?.statusCode ?? 'No Response'}",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } catch (e, stackTrace) {
      print("❌ Signup Error: $e");
      print("Stack trace: $stackTrace");
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text("Signup Error")),
      // );
    }
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    const SizedBox(height: 50),
                    Image.asset('assets/logo.png', height: 150)
                        .animate()
                        .fade(duration: 800.ms)
                        .moveY(begin: -30, end: 0),
                    const SizedBox(height: 10),
                    Text(
                      "Register",
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ).animate().fade(delay: 300.ms).scale(duration: 400.ms),
                    const SizedBox(height: 20),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          buildTextField("Full Name", fullNameController, Icons.person),
                          buildTextField("Email", emailController, Icons.email, isEmail: true),
                          buildTextField("Mobile Number", mobileController, Icons.phone, isPhone: true),
                          buildTextField("City", cityController, Icons.location_city),
                          buildTextField("State", stateController, Icons.location_city),
                          buildTextField("Company Name", companyController, Icons.business),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              labelText: "Password",
                              prefixIcon: Icon(Icons.lock, color: Colors.blueAccent),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.blueAccent,
                                ),
                                onPressed: _togglePasswordVisibility,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return "Please enter your password";
                              if (value.length < 6) return "Password must be at least 6 characters";
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: confrimpasswordController,
                            obscureText: !_isconfirmPasswordVisible,
                            decoration: InputDecoration(
                              labelText: "Confirm Password",
                              prefixIcon: Icon(Icons.lock, color: Colors.blueAccent),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isconfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.blueAccent,
                                ),
                                onPressed: _toggleconfirmPasswordVisibility,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return "Please confirm your password";
                              if (value.length < 6) return "Password must be at least 6 characters";
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: showImagePickerSheet,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: _isCardMissing
                                          ? Color_Constant.red
                                          : Color_Constant.blue,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    color: Color_Constant.lightBlue50,
                                  ),
                                  child: _businessCard == null
                                      ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo, color: Color_Constant.blue, size: 40),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Upload Business Card",
                                        style: GoogleFonts.poppins(color: Color_Constant.blue, fontSize: 16),
                                      ),
                                    ],
                                  )
                                      : ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(_businessCard!, height: 150),
                                  ),
                                ),
                                if (_isCardMissing)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 5, left: 5),
                                    child: Text(
                                      "Business card is required!",
                                      style: GoogleFonts.poppins(color: Color_Constant.red, fontSize: 14),
                                    ),
                                  ),
                              ],
                            ),
                          ).animate().fade(delay: 300.ms).scale(duration: 400.ms),

                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _validateAndSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color_Constant.blue,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 50),
                              ),
                              child: Text("Register", style: FontStyles.white_color),
                            ),
                          ).animate().fade(delay: 300.ms).scale(duration: 400.ms),
                        ],
                      ),
                    ).animate().fade(duration: 800.ms).moveY(begin: -30, end: 0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextField(String hint, TextEditingController controller, IconData icon,
      {bool isEmail = false, bool isPhone = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        maxLength: isPhone ? 10 : 200,
        keyboardType: isEmail
            ? TextInputType.emailAddress
            : isPhone
            ? TextInputType.phone
            : TextInputType.text,
        validator: (value) {
          if (value == null || value.isEmpty) return "$hint is required";
          if (isEmail && !RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(value)) {
            return "Enter a valid email";
          }
          if (isPhone && !RegExp(r"^\d{10}$").hasMatch(value)) {
            return "Enter a valid 10-digit phone number";
          }
          return null;
        },
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Color_Constant.blue),
          hintText: hint,
          counterText: "",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
