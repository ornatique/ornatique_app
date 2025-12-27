import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ornatique/ConstantColors/Color_Constant.dart';
import 'package:ornatique/Login/login_screen.dart';
import 'package:ornatique/Screens/DashBoardScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Api_Constant/ApiConstants.dart';
import '../Api_Constant/api_helper.dart';
import '../Constant_font/FontStyles.dart';
import '../LoadingDialog/LoadingDialog.dart';

class EditProfile extends StatefulWidget {
  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController(); // Scroll Controller

  // Controllers
  TextEditingController emailController = TextEditingController();
  TextEditingController fullNameController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController companyController = TextEditingController();

  File? _businessCard;
  final ImagePicker _picker = ImagePicker();
  bool _isCardMissing = false;

  Future<void> pickBusinessCard() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _businessCard = File(pickedFile.path);
        imagePath = null; // 🌟 URL clear karu, new local image display karva mate
        _isCardMissing = false;
      });
    }
  }
  String? imagePath;
  Future<void> _validateAndSubmit() async {
    if (_formKey.currentState!.validate()) {
      if (_businessCard == null && (imagePath == null || imagePath!.isEmpty)) {
        setState(() {
          _isCardMissing = true;
        });
      } else {
        LoadingDialog.show(context, message: "Loading...");
        await Future.delayed(Duration(seconds: 1)); // Simulate API call
        LoadingDialog.hide(context);
        signUp();
      }
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    fullNameController.text = prefs.getString('name') ?? '';
    emailController.text = prefs.getString('email') ?? '';
    mobileController.text = prefs.getString('number') ?? '';
    cityController.text = prefs.getString('city') ?? '';
    companyController.text = prefs.getString('company_name') ?? '';

    String? savedImagePath = "https://ornatique.co/portal/public/assets/images/users/"+prefs.getString('image').toString();
    print("📂 Image path from SharedPreferences: $savedImagePath");

    if (savedImagePath != null && savedImagePath.isNotEmpty) {
      setState(() {
        if (savedImagePath.startsWith("http")) {
          _businessCard = null; // Network image use thase
          imagePath = savedImagePath;
          _isCardMissing = false;
        } else {
          final file = File(savedImagePath);
          if (file.existsSync()) {
            _businessCard = file;
          } else {
            print("❌ Local file not found at path: $savedImagePath");
          }
        }
      });
    }
  }


  Future<void> signUp() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('Uid');  // Stored UID fetch
    final formData = FormData.fromMap({
      "user_id":  userId ?? "",  // fallback if null
      "name": fullNameController.text,
      "number": mobileController.text,
      "email": emailController.text,
      "city": cityController.text,
      //"company_name": companyController.text,
      "device_type": "Android",
      // "password": "123456",
      // "password_confirmation": "123456",
      // "token": "hoiyiowyiwuyoiwuoiwuiwij",
      if (_businessCard != null)
        "image": await MultipartFile.fromFile(
          _businessCard!.path,
          filename: _businessCard!.path.split('/').last,

        ),
    });

    print("Sign up Request: $formData");

    try {
      final response = await ApiHelper().postRequest(ApiConstants.updateprofie, formData);

      // Check if response is valid
      if (response != null && response.statusCode == 200) {
        print("Sign up Response: ${response.data}");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Updated Successfully")),
        );

        final data = response.data;
        final userData = data['data'];
        print(data["user"]['name'].toString());
        SharedPreferences prefs = await SharedPreferences.getInstance();
        setState(() {
          prefs.setString('Uid', data['user']['id'].toString() ?? '');
          prefs.setString('name', data['user']['name'].toString() ?? '');
          prefs.setString('email', data['user']['email'] ?? '');
          prefs.setString('number', data['user']['number'].toString() ?? '');
          prefs.setString('city', data['user']['city'] ?? '');
          prefs.setString('company_name', data['user']['company_name'] ?? 'Ahmedabad');
          prefs.setString('image', data['user']['image'] ?? '');
          // prefs.setString('token', userData['token'] ?? '');
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DashBoardScreen()),
          );
        });

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Signup Failed")),
        );
      }
    } catch (e, stackTrace) {
      print("❌ Signup Error: $e");
      print("Stack trace: $stackTrace");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Signup Error")),
      );
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
                    const SizedBox(height: 10),

                    // SVG Logo Animation
                    Image.asset('assets/logo.png', height: 150)
                        .animate()
                        .fade(duration: 800.ms)
                        .moveY(begin: -30, end: 0),
                    const SizedBox(height: 10),

                    // Title Animation
                    Text(
                      "EditProfile",
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ).animate().fade(delay: 300.ms).scale(duration: 400.ms),

                    const SizedBox(height: 20),

                    // Registration Form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          buildTextField("Full Name", fullNameController, Icons.person),
                          buildTextField("Email", emailController, Icons.email, isEmail: true),
                          buildTextField("Mobile Number", mobileController, Icons.phone, isPhone: true),
                          buildTextField("City", cityController, Icons.location_city),
                          buildTextField("Company Name", companyController, Icons.business),

                          const SizedBox(height: 10),

                          // Business Card Upload
                          GestureDetector(
                            onTap: (){
                              //pickBusinessCard();
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: _isCardMissing ?Color_Constant.red: Color_Constant.blue),
                                    borderRadius: BorderRadius.circular(10),
                                    color: Color_Constant.lightBlue50,
                                  ),
                                  child: imagePath != null && imagePath!.startsWith("http")
                                      ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      imagePath!,
                                     // fit: BoxFit.cover,
                                      width: double.infinity, // ✅ add this
                                      height: 150,
                                    ),
                                  )
                                      : (_businessCard != null
                                      ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(
                                      _businessCard!,
                                      //fit: BoxFit.cover,
                                      width: double.infinity, // ✅ add this
                                      height: 150,
                                    ),
                                  )
                                      : Column(
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

                          // Submit Button
                          // SizedBox(
                          //   width: double.infinity,
                          //   child: ElevatedButton(
                          //     onPressed: _validateAndSubmit,
                          //     style: ElevatedButton.styleFrom(
                          //       backgroundColor: Color_Constant.blue,
                          //       shape: RoundedRectangleBorder(
                          //         borderRadius: BorderRadius.circular(10),
                          //       ),
                          //       padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 50),
                          //     ),
                          //     child: Text(
                          //       "Update",
                          //       style: FontStyles.white_color,
                          //     ),
                          //   ),
                          // ).animate().fade(delay: 300.ms).scale(duration: 400.ms),
                        ],
                      ),
                    ).animate()
                        .fade(duration: 800.ms)
                        .moveY(begin: -30, end: 0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Reusable Text Field Widget
  Widget buildTextField(String hint, TextEditingController controller, IconData icon,
      {bool isEmail = false, bool isPhone = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        enabled: false,
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
