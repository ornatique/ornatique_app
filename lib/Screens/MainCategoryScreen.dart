import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:ornatique/ConstantColors/Color_Constant.dart';
import 'package:ornatique/Screens/JewelleryScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import '../Api_Constant/ApiConstants.dart';
import '../Api_Constant/api_helper.dart';
import '../Constant_font/FontStyles.dart';
import '../LoadingDialog/LoadingDialog.dart';
import 'CartScreen.dart';
import 'HomeScreen.dart';
import 'ProductDetailScreen.dart';

class MainCategoryScreen extends StatefulWidget {
  String catid,catname;
  MainCategoryScreen(this.catid,this.catname,{super.key});

  @override
  State<MainCategoryScreen> createState() => _MainCategoryScreenState();
}

class _MainCategoryScreenState extends State<MainCategoryScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _bannerTimer;

  final List<String> banners = [
    "assets/banner.jpg",
    "assets/banner.jpg",
    "assets/banner.jpg",
    "assets/banner.jpg",
  ];
  List bannerlist = [];
  List catlist = [];
  String?  banner_baseUrl;
  int cartCount = 0;
  Future<void> addToCart(int productId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      // if (cartItems.containsKey(productId)) {
      //   cartItems[productId] = cartItems[productId]! + 1;
      // } else {
      //   cartItems[productId] = 1;
      // }
      // cartCount++;
      cartCount = int.parse(prefs.getString('cart_count').toString());
    });
  }
  Color? appBarColor;
  @override
  void initState() {
    super.initState();
    //addToCart(0);
    _loadAppBarColor();
    getbanner();
    signUp();
    // Auto-scroll banners every 3 seconds
    _bannerTimer = Timer.periodic(Duration(seconds: 3), (Timer timer) {
      if (_currentPage < bannerlist.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });

    // Track manual scrolling for banners
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!.round();
      });
    });
  }

  Future<void> _loadAppBarColor() async {
    appBarColor = await AppColorHelper.getAppBarColor();
    setState(() {});
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          _buildBannerCarousel(),
          SizedBox(height: 10),
          _buildDotIndicator(),
          SizedBox(height: 20),
        //  _buildSectionTitle("Ornatique Essentials"),
          SizedBox(height: 10),
          Expanded(child: _buildGridItems()),
        ],
      ),
    );
  }

  // App Bar
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: appBarColor ?? Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () {
          Navigator.pop(context, 'updated');
        },
      ),
      title: Text(widget.catname.toString(), style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),),
      actions: [
        // Icon(Icons.favorite_border, color: Colors.white),
        // SizedBox(width:0),


        Stack(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CartScreen()),
                );
              },
              child: Icon(Icons.shopping_cart_outlined, color: Color_Constant.black),
            ),
          ],
        ),
        SizedBox(width: 10),




        SizedBox(width: 10),
      ],
    );

  }

  // Banner Carousel
  Widget _buildBannerCarousel() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.22, // 28% of screen height
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.horizontal,
        itemCount: bannerlist.length,
        itemBuilder: (context, index) {
          final banner = bannerlist[index];
          final product = banner['product'];
          final String? categoryId = product?['category_id']?.toString();
          final String? subcategoryId = product?['subcategory_id']?.toString();
          return GestureDetector(
            onTap: () {
              if (categoryId != null && subcategoryId != null) {
                final productId = product?['id']?.toString();
                final productName = product?['name']?.toString();

                if (productId != null && productName != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailScreen(
                        productId,
                        productName,
                        "0"
                      ),
                    ),
                  );
                } else {
                  // Handle case where product data is incomplete
                  // ScaffoldMessenger.of(context).showSnackBar(
                  //   SnackBar(content: Text('Product information is missing')),
                  // );
                }
              }
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child:
               // Image.network( bannerlist[index], fit: BoxFit.cover),
                CachedNetworkImage(
                  //width: double.infinity,
                  imageUrl:banner['imageUrl'],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => Center(
                    child: Icon(Icons.error),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Dot Indicator
  Widget _buildDotIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(bannerlist.length, (index) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 2),
          width: _currentPage == index ? 10 : 10,
          height: _currentPage == index ? 5 : 5,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: _currentPage == index ? Color(0xFFF3E0EC) : Colors.grey,
          ),
        );
      }),
    );
  }

  // Essentials Section
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: Text(
          title,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Grid Items (Fixed)
  Widget _buildGridItems() {
    if (catlist.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 150),
          // child: Text(
          //   "No SubCategory Found",
          //   style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          // ),
        ),
      );
    }
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    double getAspectRatio(BuildContext context) {
      final size = MediaQuery.of(context).size;
      final height = size.height;
      final width = size.width;
      final ratio = width / height;

      // Foldables / Tablets (wider screens)
      if (height >= 2000 || ratio > 0.7) return 1.5;

      // Very tall / tablet type
      else if (height >= 900) return 1.27;

      // Large phones
      else if (height >= 850) return 1.3;

      // Normal phones
      else if (height >= 800) return 1.0;

      // Small phones
      else return 0.9;
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: GridView.builder(
        shrinkWrap: true,
       // physics: NeverScrollableScrollPhysics(),
        //physics: NeverScrollableScrollPhysics(),
        itemCount:catlist.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: getAspectRatio(context),
        ),
        itemBuilder: (context, index) {
          final category = catlist[index] as Map<String, dynamic>;
          final imageUrl = "$banner_baseUrl/${category['image']}";
          final name = category['name'] ?? '';
          final subcat_id = category['id'] ?? '';
          final color = category['color'].toString() ?? '';
          return _gridItem(imageUrl, name,subcat_id.toString(),color);
        },
      ),
    );
  }

  // Fixed Grid Item
  Widget _gridItem(String imagePath, String label,String subcat_id,String color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () async {
            final result = await Navigator.push(context,
                MaterialPageRoute(builder:
                    (context) =>
                    JewelleryScreen(widget.catid.toString(),subcat_id.toString(),label)
                )
            );
            if (result == 'updated') {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              // setState(() {
              //   // તારી refresh logic અહીં લાવ (example: fetchProductList())
              //   cartCount = int.parse(prefs.getString("cart_count").toString());
              // });
            }
          },
          child: SizedBox(
            height: 125, // Fixed height instead of Expanded
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              child:
              //Image.network(imagePath, fit: BoxFit.cover, width: double.infinity),
              CachedNetworkImage(
                width: double.infinity,
                imageUrl:imagePath,
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => Center(
                  child: Icon(Icons.error),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 0),
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
            child: Text(label, style: TextStyle(
              fontSize: 16,
              overflow: TextOverflow.ellipsis,
              fontWeight: FontWeight.bold,
            ), textAlign: TextAlign.center)),

      ],
    );
  }

  Future<void> signUp() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final formData = FormData.fromMap({
      "user_id": prefs.getString("Uid").toString(),
      "category_id": widget.catid.toString(),
    });

    try {
      //LoadingDialog.show(context, message: "Loading...");
      final response = await ApiHelper().postRequest(ApiConstants.subcat_list, formData);
      print("Category Request: $formData");
      print("Category Response: ${response?.data}");

      if (response != null && response.statusCode == 200) {
        // await Future.delayed(Duration(seconds: 1)); // Simulate an API call
        // LoadingDialog.hide(context);
        final data = response.data;
        //final userData = data['data'];
        if (data['status'] == "1") {
          print("✅ Parsed Category Response: $data");
          print("✅ Parsed Category Response: "+widget.catid.toString());

          setState(() {
            catlist = data['data'];
            banner_baseUrl = data['image_url'];
          });

          print("✅ catlist.length: ${catlist.length}");
          print("🖼️ First image: $banner_baseUrl/${catlist[0]['image']}");
        }


      } else {
        setState(() {
          catlist = [];
        });
        LoadingDialog.hide(context);
      }
    } catch (e, stackTrace) {
      print("❌ Signup Error: $e");
      print("Stack trace: $stackTrace");
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text("Signup Error")),
      // );
    }

  }

  Future<void> getbanner() async {
    final response = await ApiHelper().postRequest(ApiConstants.home_banner, {});

    print("Banner Request: {}");
    print("Banner Response: ${response.toString()}");

    if (response != null && response.statusCode == 200) {
      final data = response.data;

      if (data['status'] == "1") {
        final List<dynamic> banners = data['data'];
        final String baseUrl = data['image_url'];

        // Build a list of full image URLs
        setState(() {
          bannerlist = banners.map((item) {
            return {
              "imageUrl": baseUrl + "/" + item['image'].toString(),
              "product": item['product']
            };
          }).toList();
        });
        //_startAutoScroll();
      }
    } else {
      print('Banner fetch failed - server error or null response');
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text("Failed to load banners")),
      // );
    }
  }
}











