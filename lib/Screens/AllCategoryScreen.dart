import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Api_Constant/ApiConstants.dart';
import '../Api_Constant/api_helper.dart';
import '../ConstantColors/Color_Constant.dart';
import '../Constant_font/FontStyles.dart';
import 'HomeScreen.dart';
import 'MainCategoryScreen.dart';
import 'NotificationScreen.dart';
class AllCategoryScreen extends StatefulWidget {
  const AllCategoryScreen({super.key});

  @override
  State<AllCategoryScreen> createState() => _AllCategoryScreenState();
}

class _AllCategoryScreenState extends State<AllCategoryScreen> {
  List catlist = [];
  String?  banner_baseUrl;
  @override
  void initState() {
    // TODO: implement initState
    category();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
          child: _buildGridItems()
      ),
    );
  }

  // App Bar
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text("Category", style: FontStyles.appbar_heading),
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context, 'updated'),
      ),
      // actions: [
      //   GestureDetector(
      //     onTap: () {
      //       Navigator.push(context,
      //           MaterialPageRoute(builder: (context) => NotificationScreen()));
      //     },
      //     child: Icon(Icons.notification_add_outlined, color: Color_Constant.black),
      //   ),
      // ],
    );
  }

  Widget _buildGridItems() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    double getAspectRatio(double height) {
      if (height > 801) return 1.3;
      else if (height <= 801) return 1.0;
      else return 0.8;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        // ✅ Sirf 6 item show thase (jo catlist < 6 hoy to jitli hoy tya sudhi)
        itemCount: catlist.length ,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: getAspectRatio(screenHeight),
        ),
        itemBuilder: (context, index) {
          final category = catlist[index] as Map<String, dynamic>;
          final imageUrl = "$banner_baseUrl/${category['image']}";
          final name = category['name'] ?? '';
          final catid = category['id'] ?? '';
          final color = category['color'].toString() ?? '';
          return _gridItem(imageUrl, name, catid.toString(),color);
        },
      ),
    );
  }




  Widget _gridItem(String imagePath, String label, String catid,String color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MainCategoryScreen(catid, label),
              ),
            );
            if (result == 'updated') {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              setState(() {
                // Refresh logic
                //callcartlist();
              });
            }
          },
          child: Column(
            children: [
              // Image part
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                child: SizedBox(
                  height: 125,
                  width: double.infinity,
                  child:
                  CachedNetworkImage(
                    imageUrl: imagePath,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.error),
                    ),
                  ),
                ),
              ),

              // Text with background
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                decoration: BoxDecoration(
                  //color: const Color(0xFFF3E0EC),
                  color: getColorFromHex(color.toString()),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
                child: Text(
                  label,
                  // style: FontStyles.offer_heading,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> category() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final body = {
      "user_id": prefs.getString("Uid").toString(),
    };

    final response = await ApiHelper().postRequest(ApiConstants.cat_list, body);
    print("category Request: $body");
    print("category Raw Response: ${response.toString()}");

    if (response != null && response.statusCode == 200) {
      final data = response.data; // this is already a Map

      if (data['status'] == "1") {
        print("✅ Parsed Category Response: $data");

        setState(() {
          catlist = data['data']; // Complete list
          //homeZeroList = catlist.where((item) => item['home'] == "1").toList(); // Filtered list
          banner_baseUrl = data['image_url'];
        });

        print("✅ catlist.length: ${catlist.length}");

      }
    } else {
      setState(() {
        catlist = [];
      });
      print('❌ Category load failed - server error or null response');
    }
  }
}
