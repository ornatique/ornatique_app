import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ornatique/Screens/DashBoardScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Api_Constant/ApiConstants.dart';
import '../Api_Constant/api_helper.dart';
import '../ConstantColors/Color_Constant.dart';
import '../Constant_font/FontStyles.dart';
import '../LoadingDialog/LoadingDialog.dart';

class CustomizeEstimateScreen extends StatefulWidget {
  @override
  _CustomizeEstimateScreenState createState() => _CustomizeEstimateScreenState();
}

class _CustomizeEstimateScreenState extends State<CustomizeEstimateScreen> {
  TextEditingController _remarksController = TextEditingController();
  File? _businessCard;
  final ImagePicker _picker = ImagePicker();
  Color? appBarColor;
  // Show Bottom Sheet for Image Selection
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

  // Pick Image from Camera or Gallery
  // Future<void> pickBusinessCard(ImageSource source) async {
  //   final pickedFile = await _picker.pickImage(source: source);
  //   if (pickedFile != null) {
  //     File? croppedFile = await _cropImage(File(pickedFile.path));
  //     if (croppedFile != null) {
  //       setState(() {
  //         _businessCard = croppedFile;
  //       });
  //     }
  //   }
  // }
  Future<void> pickBusinessCard(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 50, // Adjust this value (1 to 100) for desired quality
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




  Future<void> callproductlist() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('Uid');  // Stored UID fetch
    final formData = FormData.fromMap({
      "user_id":  userId ?? "",  // fallback if null
      "remarks": _remarksController.text ?? "",
      if (_businessCard != null)
        "image": await MultipartFile.fromFile(
          _businessCard!.path,
          filename: _businessCard!.path.split('/').last,

        ),
    });

    try {
      LoadingDialog.show(context, message: "Loading...");
      final response = await ApiHelper().postRequest(ApiConstants.customize_add, formData);
      print("Customize  Request: $formData");
      print("Customize Response: ${response?.data}");

      if (response != null && response.statusCode == 200) {
        await Future.delayed(Duration(seconds: 1));
        LoadingDialog.hide(context);
        final data = response.data;
        if (data['status'] == "1") {
          setState(() {
            // ScaffoldMessenger.of(context).showSnackBar(
            //   const SnackBar(content: Text("Custom Order Added Sucessfully.")),
            // );
            Navigator.push(context,
                MaterialPageRoute(builder:
                    (context) =>
                    DashBoardScreen()
                )
            );
          });
        } else {
          setState(() {

          });
        }
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
      }else {
        LoadingDialog.hide(context);
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text("Failed to load products")),
        // );
      }
    } catch (e, stackTrace) {
      LoadingDialog.hide(context);
      print("❌ Product List Error: $e");
      print("Stack trace: $stackTrace");
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text("Error loading products")),
      // );
    }
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
  Future<void> _loadAppBarColor() async {
    appBarColor = await AppColorHelper.getAppBarColor();
    setState(() {});
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadAppBarColor();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text("Customize Estimate", style: FontStyles.appbar_heading),
        backgroundColor: appBarColor ?? Colors.white,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          // IconButton(
          //   icon: Icon(Icons.shopping_cart_outlined),
          //   onPressed: () {},
          // ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Add Image From Your Gallery or Take a Photo for Customization Order",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              SizedBox(height: 10),
              GestureDetector(
                onTap: showImagePickerSheet,
                child: Container(
                  width: double.infinity,
                  height: 190,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _businessCard == null
                        ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/logo_silver.png',
                          height: 120,
                        ).animate().fade(duration: 800.ms).moveY(begin: -30, end: 0),
                        SizedBox(height: 5),
                        TextButton(
                          onPressed: showImagePickerSheet,
                          child: Text("Add Photo", style: FontStyles.white_color),
                        ),
                      ],
                    )
                        : ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        _businessCard!,
                        height: 150,
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text("Remarks", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _remarksController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Enter your remarks here...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_businessCard == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Please upload an image for customization.")),
                      );
                      return;
                    }
                    callproductlist();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color_Constant.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text("Submit", style: FontStyles.white_color),
                ),
              ),
            ],
          ).animate().fade(duration: 800.ms).moveY(begin: -30, end: 0),
        ),
      ),

    );
  }
}
