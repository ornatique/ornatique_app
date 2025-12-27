import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ornatique/ConstantColors/Color_Constant.dart';
import 'package:ornatique/Screens/CartScreen.dart';
import 'package:ornatique/Screens/JewelleryScreen.dart';
import 'package:ornatique/Screens/MainCategoryScreen.dart';
import 'package:ornatique/Screens/ProductDetailScreen.dart';
import 'package:ornatique/Screens/WishlistScreen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../Api_Constant/ApiConstants.dart';
import '../Api_Constant/api_helper.dart';
import '../Constant_font/FontStyles.dart';
import '../GlobalDrawer.dart';
import 'AllCategoryScreen.dart';
import 'MediaPage.dart';
import 'NotificationScreen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  final PageController _offerPageController = PageController();
  int _currentPage = 0; // Tracks the current page index
  int _selectedIndex = 0;
  int _currentOfferIndex = 0;
  Timer? _bannerTimer; // Timer for automatic scrolling
  Timer? _offerTimer;
  List<dynamic> homeZeroList = [];
  late List<String> banners = [
    "assets/banner.jpg",
    "assets/banner.jpg",
    "assets/banner.jpg",
    "assets/banner.jpg",
  ];
  Map<String, dynamic>? homeHeading;
  List bannerlist = [];
  List storebannerlist = [];
  List<String> popuplist = [];
  List catlist = [];
  List topcollection_catlist = [];
  List subcatlist = [];
  List home_offer = [];
  List home_OrnatiueEssential = [];
  String?  banner_baseUrl;
  String?  collection_baseUrl;
  String?  subcat_baseUrl;
  String?  welcome_image;
  String? Dynamic_Color;
  List<Map<String, dynamic>> allProducts = [];
  List cartcatlist = [];
  String? appBarColor;
  String? appBGColor;
  String? appBottomColor;


  final List<String> offers = [
    "50% off on Making Charges",
    "Buy 1 Get 1 Free on Earrings!",
    "Special Discount on Women's Day",
    "Flat 20% Off on Gold Jewellery"
  ];
  // List homelayout = [];
  // List homeinside_App_layout = [];
  String? layoutShape; // globally define karis
  Color defaultBgColor = const Color(0xFFD2B48C); // default color (light brown)
  Color containerBgColor = const Color(0xFFD2B48C); // initial value

  List<dynamic> homelayout = [];
  List<dynamic> homeinside_App_layout = [];

  Widget? topLayoutWidget;
  Widget? bottomLayoutWidget;

  //Color defaultBgColor = Colors.white;
  String? layoutImage;
  Future<void> loadInitialData() async {
    await callheadind();
    await callGetLayout();
    await getwelcomepopup();
    await calloffer();
    await callcartlist();
    await getbanner();
    await category();
    await callornatique_essential();
    await getstorebanner();
    await topcollectioncategory();

  }



  Color getColorFromHex(String? hexColor) {
    if (hexColor == null || hexColor == "null") {
      return Color(0xFFF3E0EC); // Default color if null
    }
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor"; // Adding opacity (FF for full opacity)
    }
    return Color(int.parse(hexColor, radix: 16));
  }


  // 🔹 First API: layouts
  Future<void> callGetLayout() async {
    final response = await ApiHelper().getRequest(ApiConstants.layout);
    print("Layout Response: ${response.toString()}");

    if (response != null && response.statusCode == 200) {
      final data = response.data;

      if (data['status'] == true) {
        homelayout = data['data'];

        for (int i = 0; i < homelayout.length; i++) {
          final layout = homelayout[i];
          final shape = layout['shape'] ?? 'rectangle';
          final layoutId = layout['id']?.toString() ?? '';
          final layoutName = layout['name']?.toString() ?? '';
          Color containerBgColor = defaultBgColor;
          Color? borderColor;

          final colorHex = layout['color'] ?? '';
          final borderHex = layout['border'];

          try {
            if (colorHex.isNotEmpty) {
              containerBgColor =
                  Color(int.parse(colorHex.replaceFirst('#', '0xff')));
            }
            if (borderHex != null && borderHex.isNotEmpty) {
              borderColor =
                  Color(int.parse(borderHex.replaceFirst('#', '0xff')));
            }
          } catch (e) {
            containerBgColor = defaultBgColor;
            borderColor = null;
          }

          // 🔹 Fetch inside layout for horizontal list
          await callGetHomeInsideLayout(layoutId);

          // 🔹 Build widget
          final layoutWidget = buildLayoutWidget(layout,
              containerBgColor: containerBgColor, borderColor: borderColor);

          // 🔹 Assign top/bottom widget by index or shape
          if (i == 0 || shape == 'circle') {
            topLayoutWidget = layoutWidget;
          } else {
            bottomLayoutWidget = layoutWidget;
          }
        }

        setState(() {});
      }
    }
  }

  // 🔹 Second API: inside layout for horizontal list
  Future<void> callGetHomeInsideLayout(String layoutId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("Uid") ?? "";

    final uri = Uri.parse(ApiConstants.insideapplayout).replace(
      queryParameters: {
        "user_id": userId,
        "layout_id": layoutId,
      },
    );

    print("Inside App layout GET Request: $uri");

    final response = await ApiHelper().getRequest(uri.toString());

    print("Inside App layout GET Response: ${response.toString()}");

    if (response != null && response.statusCode == 200) {
      final data = response.data;

      setState(() {
        homeinside_App_layout = data['data'] ?? [];
      });

      print("✅ homeinside_App_layout: $homeinside_App_layout");
    } else {
      print("❌ GET request failed or server error");
    }
  }

  // 🔹 Layout builder
  Widget buildLayoutWidget(Map<String, dynamic> layout,
      {Color? containerBgColor, Color? borderColor}) {
    final shape = layout['shape'] ?? 'rectangle';
    final layoutImage = layout['image'] ?? '';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color:containerBgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Background image
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MainCategoryScreen(layout['category']["id"].toString(), layout['category']["name"].toString()),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: layoutImage.isNotEmpty
                      ? Image.network(
                    layoutImage,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.width * 1, // proportional height
                    fit: BoxFit.cover, // show full image without crop
                    alignment: Alignment.center,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      'assets/layout_2.png',
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.width * 0.9,
                      fit: BoxFit.contain,
                    ),
                  )
                      : Image.asset(
                    'assets/layout_2.png',
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.width * 0.9,
                    fit: BoxFit.contain,
                  ),
                )
              ),
              // Overlay text + button
              // Positioned(
              //   top: 50,
              //   left: 25,
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: const [
              //       Text(
              //         "Men’s",
              //         style: TextStyle(
              //           fontSize: 30,
              //           fontWeight: FontWeight.bold,
              //           color: Color(0xFF8C6A3E),
              //         ),
              //       ),
              //       SizedBox(height: 5),
              //       Text(
              //         "Collection",
              //         style: TextStyle(
              //           fontSize: 20,
              //           fontWeight: FontWeight.w500,
              //           color: Colors.black87,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              Positioned(
                bottom: 25,
                right: 10,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            MainCategoryScreen(layout['category']["id"].toString(), layout['category']["name"].toString()),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8C6A3E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 12),
                  ),
                  child: const Text(
                    "Explore",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Horizontal list for circle layout
          if (shape == 'circle' && homeinside_App_layout.isNotEmpty)
            buildCircleList(borderColor),

          if (shape == 'circle_with_border' && homeinside_App_layout.isNotEmpty)
            buildCircleborderList(borderColor),

          // Horizontal list for rectangle layout
          if (shape == 'rectangle' && homeinside_App_layout.isNotEmpty)
            buildRectangleList(borderColor),

          if (shape == 'rectangle_with_border' && homeinside_App_layout.isNotEmpty)
            buildRectangleborderList(borderColor),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget buildCircleList(Color? borderColor) {
    return Container(
      height: 125,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: homeinside_App_layout.length,
        itemBuilder: (context, index) {
          final category = homeinside_App_layout[index];
          final imageUrl = category['category']['image'] ?? '';
          final name = (category['subcategory'] != null && category['subcategory']['name'] != null)
                          ? category['subcategory']['name']   // subcategory exists → use it
                          : (category['category'] != null && category['category']['name'] != null)
                          ? category['category']['name']  // only category → use category
                          : '';
          final catid = category['category']['id'] ?? '';
          final bgcolor = category['bg_color'] ?? '';
          //print("cat Id --------------->"+ catid.toString());

          return Column(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MainCategoryScreen(catid.toString(), name),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // border: borderColor != null
                    //     ? Border.all(color: borderColor, width: 2)
                    //     : null,
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      height: 90,
                      width: 90,
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
             // Text(name.toString()),
              SizedBox(
                width: 120,
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildCircleborderList(Color? borderColor) {
    return Container(
      height: 125,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: homeinside_App_layout.length,
        itemBuilder: (context, index) {
          final category = homeinside_App_layout[index];
          final imageUrl = category['category']['image'] ?? '';
          final name = (category['subcategory'] != null && category['subcategory']['name'] != null)
              ? category['subcategory']['name']   // subcategory exists → use it
              : (category['category'] != null && category['category']['name'] != null)
              ? category['category']['name']  // only category → use category
              : '';
          final catid = category['category']['id'] ?? '';

          return Column(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MainCategoryScreen(catid.toString(), name),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: borderColor != null
                        ? Border.all(color: borderColor, width: 2)
                        : null,
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      height: 90,
                      width: 90,
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 120,
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildRectangleList(Color? borderColor) {
    return Container(
      height: 125,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: homeinside_App_layout.length,
        itemBuilder: (context, index) {
          final category = homeinside_App_layout[index];
          final imageUrl = category['category']['image'] ?? '';
          final name = (category['subcategory'] != null && category['subcategory']['name'] != null)
              ? category['subcategory']['name']   // subcategory exists → use it
              : (category['category'] != null && category['category']['name'] != null)
              ? category['category']['name']  // only category → use category
              : '';
          final catid = category['category']['id'] ?? '';

          return Column(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MainCategoryScreen(catid.toString(), name),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(10),
                    // border: borderColor != null
                    //     ? Border.all(color: borderColor, width: 2)
                    //     : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      height: 90,
                      width: 90,
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 120,
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildRectangleborderList(Color? borderColor) {
    return Container(
      height: 125,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: homeinside_App_layout.length,
        itemBuilder: (context, index) {
          final category = homeinside_App_layout[index];
          final imageUrl = category['category']['image'] ?? '';
          final name = (category['subcategory'] != null && category['subcategory']['name'] != null)
              ? category['subcategory']['name']   // subcategory exists → use it
              : (category['category'] != null && category['category']['name'] != null)
              ? category['category']['name']  // only category → use category
              : '';
          final catid = category['category']['id'] ?? '';

          return Column(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MainCategoryScreen(catid.toString(), name),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(10),
                    border: borderColor != null
                        ? Border.all(color: borderColor, width: 2)
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      height: 90,
                      width: 90,
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 120,
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  @override
  void initState() {
    super.initState();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   checkAppVersion(context);
    // });
    loadInitialData();
    // getwelcomepopup();
    // getbanner();
    // category();
    // calloffer();
    //subcategory();
   // callcartlist();
    // Future.delayed(Duration(seconds: 1), () {
    //   _checkAndShowPopup();
    // });

    // _bannerTimer = Timer.periodic(Duration(seconds: 3), (Timer timer) {
    //   if (banners.isEmpty) return;
    //
    //   setState(() {
    //     if (_currentPage < banners.length - 1) {
    //       _currentPage++;
    //     } else {
    //       _currentPage = 0;
    //     }
    //   });
    //
    //   _pageController.animateToPage(
    //     _currentPage,
    //     duration: Duration(milliseconds: 300),
    //     curve: Curves.easeInOut,
    //   );
    // });


    // Auto-scroll offer text every 3 seconds
    _offerTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      setState(() {
        _currentOfferIndex = (_currentOfferIndex + 1) % home_offer.length;
      });
    });

    // // Track manual scrolling for banners
    // _pageController.addListener(() {
    //   setState(() {
    //     _currentPage = _pageController.page!.round();
    //   });
    // });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _offerTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      if(index==0){
        // Navigator.push(context,
        //     MaterialPageRoute(builder:
        //         (context) =>
        //         NotificationScreen()
        //     )
        // );
      }else if(index==1){
        Navigator.push(context,
            MaterialPageRoute(builder:
                (context) =>
                NotificationScreen()
            )
        );
      }else if(index==2){
        Navigator.push(context,
            MaterialPageRoute(builder:
                (context) =>
                NotificationScreen()
            )
        );
      }else if(index==3){
        Navigator.push(context,
            MaterialPageRoute(builder:
                (context) =>
                NotificationScreen()
            )
        );
      }else{
        _selectedIndex = index;
      }

    });
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = (appBGColor != null && appBGColor!.isNotEmpty)
        ? getColorFromHex(appBGColor!)
        : Colors.white;
    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(),
      drawer: GlobalDrawer(), // Add the drawer here
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOfferBanner(),
            SizedBox(height: 10),
            _buildCategoryList(),
            SizedBox(height: 5),
            _buildBannerCarousel(),
            SizedBox(height: 10),
            _buildDotIndicator(),
            SizedBox(height: 10),
            // _buildSectionTitle("Ornatique Essentials"),
            // SizedBox(height: 5),
            _buildGridItems(),
            SizedBox(height: 10),
            Center(
              child: GestureDetector(
                onTap: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AllCategoryScreen()),
                  );
                },
                child: Container(
                  height: 50,
                  width: 100,
                  decoration: BoxDecoration(
                    color: getColorFromHex(Dynamic_Color.toString()),
                    borderRadius: BorderRadius.circular(10), // 👈 અહીં border radius
                  ),
                  child: Center(
                    child: Text(
                      "View All",
                      key: ValueKey(_currentOfferIndex),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  //color: Colors.purpleAccent.withOpacity(0.2),
                  //color: const Color(0xFFEBDDE3),
                  // color: const Color(0xFFF3E0EC),
                  color: getColorFromHex(
                    home_OrnatiueEssential.isNotEmpty
                        ? (home_OrnatiueEssential[0]['bg_color']?.toString() ?? "#F3E0EC")
                        : "#F3E0EC",
                  ),
                ),
                       // same light grey background
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Header
                Center(
                  child: Text(
                        homeHeading?['heading_one'] ?? "ORNATIQUE ESSENTIALS",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 2 Category Boxes side by side
                // Row(
                //   children: [
                //     // Left Box
                //     Expanded(
                //       child: Container(
                //         height: 200,
                //         decoration: BoxDecoration(
                //           borderRadius: BorderRadius.circular(12),
                //           border: Border.all(color: Colors.white),
                //         ),
                //         child: Column(
                //           crossAxisAlignment: CrossAxisAlignment.stretch,
                //           children: [
                //             // Image section
                //             ClipRRect(
                //               borderRadius: const BorderRadius.only(
                //                 topLeft: Radius.circular(12),
                //                 topRight: Radius.circular(12),
                //               ),
                //               child: Image.asset(
                //                 "assets/121.jpg",
                //                 height: 155,
                //                 fit: BoxFit.cover,
                //                 width: double.infinity,
                //               ),
                //             ),
                //
                //             SizedBox(height:0,),
                //             // Text section
                //             Container(
                //               padding: const EdgeInsets.all(10),
                //               decoration: const BoxDecoration(
                //                 color: Colors.black54,
                //                 borderRadius: BorderRadius.only(
                //                   bottomLeft: Radius.circular(12),
                //                   bottomRight: Radius.circular(12),
                //                 ),
                //               ),
                //               child: const Text(
                //                 "Category 1",
                //                 style: TextStyle(
                //                   color: Colors.white,
                //                   fontWeight: FontWeight.bold,
                //                   fontSize: 16,
                //                 ),
                //                 textAlign: TextAlign.center,
                //               ),
                //             ),
                //           ],
                //         ),
                //       ),
                //     ),
                //
                //     const SizedBox(width: 12),
                //
                //     // Right Box
                //     Expanded(
                //       child: Container(
                //         height: 200,
                //         decoration: BoxDecoration(
                //           borderRadius: BorderRadius.circular(12),
                //           border: Border.all(color: Colors.white),
                //         ),
                //         child: Column(
                //           crossAxisAlignment: CrossAxisAlignment.stretch,
                //           children: [
                //             // Image section
                //             ClipRRect(
                //               borderRadius: const BorderRadius.only(
                //                 topLeft: Radius.circular(12),
                //                 topRight: Radius.circular(12),
                //               ),
                //               child: Image.asset(
                //                 "assets/bannerimage.jpg",
                //                 height: 155,
                //                 fit: BoxFit.cover,
                //                 width: double.infinity,
                //               ),
                //             ),
                //
                //             SizedBox(height:0,),
                //             // Text section
                //             Container(
                //               padding: const EdgeInsets.all(10),
                //               decoration: const BoxDecoration(
                //                 color: Colors.black54,
                //                 borderRadius: BorderRadius.only(
                //                   bottomLeft: Radius.circular(12),
                //                   bottomRight: Radius.circular(12),
                //                 ),
                //               ),
                //               child: const Text(
                //                 "Category 1",
                //                 style: TextStyle(
                //                   color: Colors.white,
                //                   fontWeight: FontWeight.bold,
                //                   fontSize: 16,
                //                 ),
                //                 textAlign: TextAlign.center,
                //               ),
                //             ),
                //           ],
                //         ),
                //       ),
                //     ),
                //   ],
                // )
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: home_OrnatiueEssential.length > 5 ? 5 : home_OrnatiueEssential.length, // 🔹 total cards
                    itemBuilder: (context, index) {
                      final item = home_OrnatiueEssential[index] as Map<String, dynamic>;

                      String imageUrl = item['product']?['image_url'] ??
                          item['subcategory']?['image_url'] ??
                          item['category']?['image_url'] ??
                          "https://via.placeholder.com/150"; // fallback
                      //print("Image Url "+ imageUrl.toString());
                      // ✅ Color (fallback if null)
                      final colorHex = item['color']?.toString() ?? "#F3E0EC";
                      return GestureDetector(
                        onTap: (){
                          Navigator.push(context,
                              MaterialPageRoute(builder:
                                  (context) =>
                                  JewelleryScreen(item['category']?['id']?.toString(),item['subcategory']?['id'].toString(),item['subcategory']?['name']?.toString())
                              ));
                        },
                        child: _buildCollectionCard(
                          imageUrl, // asset/image url
                          item['category']?['name']?.toString() ?? item['subcategory']?['name']?.toString() ?? "No Name",
                          colorHex, // 🔹 Pass color to card
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

              ],
                        ),
                      ),
            ),
            SizedBox(height: 10),



            if (topLayoutWidget != null) topLayoutWidget!,
            // // New Layout @2=======================================================
            //
            // // 🔹 Top section with image and text overlay
            // layoutShape == "circle"
            //     ? Container(
            //   width: double.infinity,
            //   decoration: BoxDecoration(
            //     color: containerBgColor,
            //     borderRadius: const BorderRadius.only(
            //       bottomLeft: Radius.circular(20),
            //       bottomRight: Radius.circular(20),
            //       topLeft: Radius.circular(20),
            //       topRight: Radius.circular(20),
            //     ),
            //   ),
            //   child: Column(
            //     children: [
            //       Stack(
            //         alignment: Alignment.center,
            //         children: [
            //           // Background image section
            //           Container(
            //             decoration: BoxDecoration(
            //               color: Color(0xFFF7F2E7),
            //               borderRadius: const BorderRadius.only(
            //                 bottomLeft: Radius.circular(20),
            //                 bottomRight: Radius.circular(20),
            //                 topLeft: Radius.circular(20),
            //                 topRight: Radius.circular(20),
            //               ),
            //             ),
            //             child: ClipRRect(
            //               borderRadius: const BorderRadius.only(
            //                 bottomLeft: Radius.circular(20),
            //                 bottomRight: Radius.circular(20),
            //                 topLeft: Radius.circular(20),
            //                 topRight: Radius.circular(20),
            //               ),
            //               child: layoutImage != null && layoutImage!.isNotEmpty
            //                   ? Image.network(
            //                 layoutImage!,
            //                 fit: BoxFit.fill,
            //                 width: double.infinity,
            //                 height: 500,
            //                 errorBuilder: (context, error, stackTrace) {
            //                   return Image.asset(
            //                     'assets/layout_2.png',
            //                     fit: BoxFit.fill,
            //                     width: double.infinity,
            //                     height: 500,
            //                   );
            //                 },
            //               )
            //                   : Image.asset(
            //                 'assets/layout_2.png',
            //                 fit: BoxFit.fill,
            //                 width: double.infinity,
            //                 height: 500,
            //               ),
            //             ),
            //           ),
            //
            //           // Overlay text + button
            //           Positioned(
            //             top: 50,
            //             left: 25,
            //             child: Column(
            //               crossAxisAlignment: CrossAxisAlignment.start,
            //               children: const [
            //                 Text(
            //                   "Men’s",
            //                   style: TextStyle(
            //                     fontSize: 30,
            //                     fontWeight: FontWeight.bold,
            //                     color: Color(0xFF8C6A3E),
            //                   ),
            //                 ),
            //                 SizedBox(height: 5),
            //                 Text(
            //                   "Collection",
            //                   style: TextStyle(
            //                     fontSize: 20,
            //                     fontWeight: FontWeight.w500,
            //                     color: Colors.black87,
            //                   ),
            //                 ),
            //               ],
            //             ),
            //           ),
            //
            //           Positioned(
            //             bottom: 25,
            //             right: 10,
            //             child: ElevatedButton(
            //               onPressed: () {},
            //               style: ElevatedButton.styleFrom(
            //                 backgroundColor: const Color(0xFF8C6A3E),
            //                 shape: RoundedRectangleBorder(
            //                   borderRadius: BorderRadius.circular(15),
            //                 ),
            //                 padding: const EdgeInsets.symmetric(
            //                     horizontal: 28, vertical: 12),
            //               ),
            //               child: const Text(
            //                 "Explore",
            //                 style: TextStyle(
            //                   color: Colors.white,
            //                   fontSize: 16,
            //                   fontWeight: FontWeight.w600,
            //                 ),
            //               ),
            //             ),
            //           ),
            //         ],
            //       ),
            //       const SizedBox(height: 10),
            //       // 🔹 Bottom horizontal list
            //       Container(
            //         height: 125,
            //         child: ListView.builder(
            //           scrollDirection: Axis.horizontal,
            //           padding: const EdgeInsets.symmetric(horizontal: 10),
            //           itemCount: homeinside_App_layout.length,
            //           itemBuilder: (context, index) {
            //             final category = homeinside_App_layout[index] as Map<String, dynamic>;
            //             final imageUrl = "${category['category']['image']}";
            //             final name = (category['subcategory'] != null && category['subcategory']['name'] != null)
            //                 ? category['subcategory']['name']   // subcategory exists → use it
            //                 : (category['category'] != null && category['category']['name'] != null)
            //                 ? category['category']['name']  // only category → use category
            //                 : '';
            //
            //             final catid = category['category']['id'] ?? '';
            //            // final shape = category['shape'] ?? 'circle';
            //             final borderHex = category['border']; // e.g. "#993333"
            //
            //             Color? borderColor;
            //             if (borderHex != null && borderHex.isNotEmpty) {
            //               try {
            //                 borderColor = Color(int.parse(borderHex.replaceFirst('#', '0xff')));
            //               } catch (e) {
            //                 borderColor = null;
            //               }
            //             }
            //             return Column(
            //               children: [
            //                 GestureDetector(
            //                   onTap: () {
            //                     Navigator.push(
            //                       context,
            //                       MaterialPageRoute(
            //                         builder: (context) => MainCategoryScreen(
            //                           catid.toString(),
            //                           name.toString(),
            //                         ),
            //                       ),
            //                     );
            //                   },
            //                   child: layoutShape == "circle"?Container(
            //                     margin: const EdgeInsets.symmetric(horizontal: 10),
            //                     padding: const EdgeInsets.all(3),
            //                     decoration: BoxDecoration(
            //                       shape:  BoxShape.circle,
            //                       border: borderColor != null
            //                           ? Border.all(
            //                         color: borderColor,
            //                         width: 2,
            //                       )
            //                           : null, // hide if null
            //                     ),
            //                     child: ClipOval(
            //                       child: CachedNetworkImage(
            //                         height: 90,
            //                         width: 90,
            //                         imageUrl: imageUrl,
            //                         fit: BoxFit.cover,
            //                         useOldImageOnUrlChange: true,
            //                         memCacheHeight: 200,
            //                         memCacheWidth: 200,
            //                         placeholder: (context, url) =>
            //                         const Center(child: CircularProgressIndicator()),
            //                         errorWidget: (context, url, error) =>
            //                         const Center(child: Icon(Icons.error)),
            //                       ),
            //                     ),
            //                   ):Container(),
            //                 ),
            //                 Text(
            //                   name,
            //                   style: const TextStyle(
            //                     color: Colors.black,
            //                     fontSize: 15,
            //                     fontWeight: FontWeight.w400,
            //                   ),
            //                 ),
            //               ],
            //             );
            //           },
            //         ),
            //       ),
            //       const SizedBox(height: 10),
            //     ],
            //   ),
            // )
            //     : const SizedBox.shrink(), // 👈 hide container if shape != circle
            //
            // layoutShape == "circle_with_border"
            //     ? Container(
            //   width: double.infinity,
            //   decoration: BoxDecoration(
            //     color: containerBgColor,
            //     borderRadius: const BorderRadius.only(
            //       bottomLeft: Radius.circular(20),
            //       bottomRight: Radius.circular(20),
            //       topLeft: Radius.circular(20),
            //       topRight: Radius.circular(20),
            //     ),
            //   ),
            //   child: Column(
            //     children: [
            //       Stack(
            //         alignment: Alignment.center,
            //         children: [
            //           // Background image section
            //           Container(
            //             decoration: BoxDecoration(
            //               color: Color(0xFFF7F2E7),
            //               borderRadius: const BorderRadius.only(
            //                 bottomLeft: Radius.circular(20),
            //                 bottomRight: Radius.circular(20),
            //                 topLeft: Radius.circular(20),
            //                 topRight: Radius.circular(20),
            //               ),
            //             ),
            //             child: ClipRRect(
            //               borderRadius: const BorderRadius.only(
            //                 bottomLeft: Radius.circular(20),
            //                 bottomRight: Radius.circular(20),
            //                 topLeft: Radius.circular(20),
            //                 topRight: Radius.circular(20),
            //               ),
            //               child: layoutImage != null && layoutImage!.isNotEmpty
            //                   ? Image.network(
            //                 layoutImage!,
            //                 fit: BoxFit.fill,
            //                 width: double.infinity,
            //                 height: 500,
            //                 errorBuilder: (context, error, stackTrace) {
            //                   return Image.asset(
            //                     'assets/layout_2.png',
            //                     fit: BoxFit.fill,
            //                     width: double.infinity,
            //                     height: 500,
            //                   );
            //                 },
            //               )
            //                   : Image.asset(
            //                 'assets/layout_2.png',
            //                 fit: BoxFit.fill,
            //                 width: double.infinity,
            //                 height: 500,
            //               ),
            //             ),
            //           ),
            //
            //           // Overlay text + button
            //           Positioned(
            //             top: 50,
            //             left: 25,
            //             child: Column(
            //               crossAxisAlignment: CrossAxisAlignment.start,
            //               children: const [
            //                 Text(
            //                   "Men’s",
            //                   style: TextStyle(
            //                     fontSize: 30,
            //                     fontWeight: FontWeight.bold,
            //                     color: Color(0xFF8C6A3E),
            //                   ),
            //                 ),
            //                 SizedBox(height: 5),
            //                 Text(
            //                   "Collection",
            //                   style: TextStyle(
            //                     fontSize: 20,
            //                     fontWeight: FontWeight.w500,
            //                     color: Colors.black87,
            //                   ),
            //                 ),
            //               ],
            //             ),
            //           ),
            //
            //           Positioned(
            //             bottom: 25,
            //             right: 10,
            //             child: ElevatedButton(
            //               onPressed: () {},
            //               style: ElevatedButton.styleFrom(
            //                 backgroundColor: const Color(0xFF8C6A3E),
            //                 shape: RoundedRectangleBorder(
            //                   borderRadius: BorderRadius.circular(15),
            //                 ),
            //                 padding: const EdgeInsets.symmetric(
            //                     horizontal: 28, vertical: 12),
            //               ),
            //               child: const Text(
            //                 "Explore",
            //                 style: TextStyle(
            //                   color: Colors.white,
            //                   fontSize: 16,
            //                   fontWeight: FontWeight.w600,
            //                 ),
            //               ),
            //             ),
            //           ),
            //         ],
            //       ),
            //       const SizedBox(height: 10),
            //       // 🔹 Bottom horizontal list
            //       Container(
            //         height: 125,
            //         child: ListView.builder(
            //           scrollDirection: Axis.horizontal,
            //           padding: const EdgeInsets.symmetric(horizontal: 10),
            //           itemCount: homeinside_App_layout.length,
            //           itemBuilder: (context, index) {
            //             final category = homeinside_App_layout[index] as Map<String, dynamic>;
            //             final imageUrl = "${category['category']['image']}";
            //             final name = (category['subcategory'] != null && category['subcategory']['name'] != null)
            //                 ? category['subcategory']['name']   // subcategory exists → use it
            //                 : (category['category'] != null && category['category']['name'] != null)
            //                 ? category['category']['name']  // only category → use category
            //                 : '';
            //             final catid = category['category']['id'] ?? '';
            //             final borderHex = category['border_color']; // e.g. "#993333"
            //
            //             Color? borderColor;
            //             if (borderHex != null && borderHex.isNotEmpty) {
            //               try {
            //                 borderColor = Color(int.parse(borderHex.replaceFirst('#', '0xff')));
            //               } catch (e) {
            //                 borderColor = null;
            //               }
            //             }
            //             return Column(
            //               children: [
            //                 GestureDetector(
            //                   onTap: () {
            //                     Navigator.push(
            //                       context,
            //                       MaterialPageRoute(
            //                         builder: (context) => MainCategoryScreen(
            //                           catid.toString(),
            //                           name.toString(),
            //                         ),
            //                       ),
            //                     );
            //                   },
            //                   child: layoutShape == "circle_with_border"?Container(
            //                     margin: const EdgeInsets.symmetric(horizontal: 10),
            //                     padding: const EdgeInsets.all(3),
            //                     decoration: BoxDecoration(
            //                       shape:  BoxShape.circle,
            //                       border: borderColor != null
            //                           ? Border.all(
            //                         color: borderColor,
            //                         width: 2,
            //                       )
            //                           : null, // hide if null
            //                     ),
            //                     child: ClipOval(
            //                       child: CachedNetworkImage(
            //                         height: 90,
            //                         width: 90,
            //                         imageUrl: imageUrl,
            //                         fit: BoxFit.cover,
            //                         useOldImageOnUrlChange: true,
            //                         memCacheHeight: 200,
            //                         memCacheWidth: 200,
            //                         placeholder: (context, url) =>
            //                         const Center(child: CircularProgressIndicator()),
            //                         errorWidget: (context, url, error) =>
            //                         const Center(child: Icon(Icons.error)),
            //                       ),
            //                     ),
            //                   ):Container(),
            //                   // child: Container(
            //                   //   margin: const EdgeInsets.symmetric(horizontal: 10),
            //                   //   padding: const EdgeInsets.all(3),
            //                   //   decoration: BoxDecoration(
            //                   //     shape: BoxShape.circle,
            //                   //     border: Border.all(
            //                   //       color: Colors.brown,
            //                   //       width: 2,
            //                   //     ),
            //                   //   ),
            //                   //   child: ClipOval(
            //                   //     child: CachedNetworkImage(
            //                   //       height: 90,
            //                   //       width: 90,
            //                   //       imageUrl: imageUrl,
            //                   //       fit: BoxFit.cover,
            //                   //       useOldImageOnUrlChange: true,
            //                   //       memCacheHeight: 200,
            //                   //       memCacheWidth: 200,
            //                   //       placeholder: (context, url) =>
            //                   //       const Center(child: CircularProgressIndicator()),
            //                   //       errorWidget: (context, url, error) =>
            //                   //       const Center(child: Icon(Icons.error)),
            //                   //     ),
            //                   //   ),
            //                   // ),
            //                 ),
            //                 Text(
            //                   name.toString(),
            //                   style: const TextStyle(
            //                     color: Colors.black,
            //                     fontSize: 15,
            //                     fontWeight: FontWeight.w400,
            //                   ),
            //                 ),
            //               ],
            //             );
            //           },
            //         ),
            //       ),
            //       const SizedBox(height: 10),
            //     ],
            //   ),
            // )
            //     : const SizedBox.shrink(), // 👈 hide container if shape != circle
            //
            // layoutShape == "rectangle"
            //     ? Container(
            //   width: double.infinity,
            //   decoration: BoxDecoration(
            //     color: containerBgColor,
            //     borderRadius: const BorderRadius.only(
            //       bottomLeft: Radius.circular(20),
            //       bottomRight: Radius.circular(20),
            //       topLeft: Radius.circular(20),
            //       topRight: Radius.circular(20),
            //     ),
            //   ),
            //   child: Column(
            //     children: [
            //       Stack(
            //         alignment: Alignment.center,
            //         children: [
            //           // Background image section
            //           Container(
            //             decoration: BoxDecoration(
            //               color: Color(0xFFF7F2E7),
            //               borderRadius: const BorderRadius.only(
            //                 bottomLeft: Radius.circular(20),
            //                 bottomRight: Radius.circular(20),
            //                 topLeft: Radius.circular(20),
            //                 topRight: Radius.circular(20),
            //               ),
            //             ),
            //             child: ClipRRect(
            //               borderRadius: const BorderRadius.only(
            //                 bottomLeft: Radius.circular(20),
            //                 bottomRight: Radius.circular(20),
            //                 topLeft: Radius.circular(20),
            //                 topRight: Radius.circular(20),
            //               ),
            //               child: layoutImage != null && layoutImage!.isNotEmpty
            //                   ? Image.network(
            //                 layoutImage!,
            //                 fit: BoxFit.fill,
            //                 width: double.infinity,
            //                 height: 500,
            //                 errorBuilder: (context, error, stackTrace) {
            //                   return Image.asset(
            //                     'assets/layout_2.png',
            //                     fit: BoxFit.fill,
            //                     width: double.infinity,
            //                     height: 500,
            //                   );
            //                 },
            //               )
            //                   : Image.asset(
            //                 'assets/layout_2.png',
            //                 fit: BoxFit.fill,
            //                 width: double.infinity,
            //                 height: 500,
            //               ),
            //             ),
            //           ),
            //
            //           // Overlay text + button
            //           Positioned(
            //             top: 50,
            //             left: 25,
            //             child: Column(
            //               crossAxisAlignment: CrossAxisAlignment.start,
            //               children: const [
            //                 Text(
            //                   "Men’s",
            //                   style: TextStyle(
            //                     fontSize: 30,
            //                     fontWeight: FontWeight.bold,
            //                     color: Color(0xFF8C6A3E),
            //                   ),
            //                 ),
            //                 SizedBox(height: 5),
            //                 Text(
            //                   "Collection",
            //                   style: TextStyle(
            //                     fontSize: 20,
            //                     fontWeight: FontWeight.w500,
            //                     color: Colors.black87,
            //                   ),
            //                 ),
            //               ],
            //             ),
            //           ),
            //
            //           Positioned(
            //             bottom: 25,
            //             right: 10,
            //             child: ElevatedButton(
            //               onPressed: () {},
            //               style: ElevatedButton.styleFrom(
            //                 backgroundColor: const Color(0xFF8C6A3E),
            //                 shape: RoundedRectangleBorder(
            //                   borderRadius: BorderRadius.circular(15),
            //                 ),
            //                 padding: const EdgeInsets.symmetric(
            //                     horizontal: 28, vertical: 12),
            //               ),
            //               child: const Text(
            //                 "Explore",
            //                 style: TextStyle(
            //                   color: Colors.white,
            //                   fontSize: 16,
            //                   fontWeight: FontWeight.w600,
            //                 ),
            //               ),
            //             ),
            //           ),
            //         ],
            //       ),
            //       const SizedBox(height: 10),
            //       // 🔹 Bottom horizontal list
            //       Container(
            //         height: 125,
            //         child: ListView.builder(
            //           scrollDirection: Axis.horizontal,
            //           padding: const EdgeInsets.symmetric(horizontal: 10),
            //           itemCount: homeinside_App_layout.length,
            //           itemBuilder: (context, index) {
            //             final category = homeinside_App_layout[index] as Map<String, dynamic>;
            //             final imageUrl = "${category['category']['image']}";
            //             final name = (category['subcategory'] != null && category['subcategory']['name'] != null)
            //                 ? category['subcategory']['name']   // subcategory exists → use it
            //                 : (category['category'] != null && category['category']['name'] != null)
            //                 ? category['category']['name']  // only category → use category
            //                 : '';
            //             final catid = category['category']['id'] ?? '';
            //             // final shape = category['shape'] ?? 'circle';
            //             final borderHex = category['border']; // e.g. "#993333"
            //
            //             Color? borderColor;
            //             if (borderHex != null && borderHex.isNotEmpty) {
            //               try {
            //                 borderColor = Color(int.parse(borderHex.replaceFirst('#', '0xff')));
            //               } catch (e) {
            //                 borderColor = null;
            //               }
            //             }
            //             return Column(
            //               children: [
            //                 GestureDetector(
            //                   onTap: () {
            //                     Navigator.push(
            //                       context,
            //                       MaterialPageRoute(
            //                         builder: (context) => MainCategoryScreen(
            //                           catid.toString(),
            //                           name.toString(),
            //                         ),
            //                       ),
            //                     );
            //                   },
            //                   child: layoutShape == "rectangle"?Container(
            //                     margin: const EdgeInsets.symmetric(horizontal: 10),
            //                     padding: const EdgeInsets.all(3),
            //                     decoration: BoxDecoration(
            //                       shape:  BoxShape.rectangle,
            //                       border: borderColor != null
            //                           ? Border.all(
            //                         color: borderColor,
            //                         width: 2,
            //                       )
            //                           : null, // hide if null
            //
            //                     ),
            //                     child: ClipRRect(
            //                       borderRadius: BorderRadius.circular(10), // 👈 radius for image
            //                       child: CachedNetworkImage(
            //                         height: 90,
            //                         width: 90,
            //                         imageUrl: imageUrl,
            //                         fit: BoxFit.cover,
            //                         useOldImageOnUrlChange: true,
            //                         memCacheHeight: 200,
            //                         memCacheWidth: 200,
            //                         placeholder: (context, url) =>
            //                         const Center(child: CircularProgressIndicator()),
            //                         errorWidget: (context, url, error) =>
            //                         const Center(child: Icon(Icons.error)),
            //                       ),
            //                     ),
            //                   ):Container(),
            //                 ),
            //                 Text(
            //                   name,
            //                   style: const TextStyle(
            //                     color: Colors.black,
            //                     fontSize: 15,
            //                     fontWeight: FontWeight.w400,
            //                   ),
            //                 ),
            //               ],
            //             );
            //           },
            //         ),
            //       ),
            //       const SizedBox(height: 10),
            //     ],
            //   ),
            // )
            //     : const SizedBox.shrink(), // 👈 hide container if shape != circle
            //
            //
            //
            // layoutShape == "rectangle_with_border"
            //     ? Container(
            //   width: double.infinity,
            //   decoration: BoxDecoration(
            //     color: containerBgColor,
            //     borderRadius: const BorderRadius.only(
            //       bottomLeft: Radius.circular(20),
            //       bottomRight: Radius.circular(20),
            //       topLeft: Radius.circular(20),
            //       topRight: Radius.circular(20),
            //     ),
            //   ),
            //   child: Column(
            //     children: [
            //       Stack(
            //         alignment: Alignment.center,
            //         children: [
            //           // Background image section
            //           Container(
            //             decoration: BoxDecoration(
            //               color: Color(0xFFF7F2E7),
            //               borderRadius: const BorderRadius.only(
            //                 bottomLeft: Radius.circular(20),
            //                 bottomRight: Radius.circular(20),
            //                 topLeft: Radius.circular(20),
            //                 topRight: Radius.circular(20),
            //               ),
            //             ),
            //             child: ClipRRect(
            //               borderRadius: const BorderRadius.only(
            //                 bottomLeft: Radius.circular(20),
            //                 bottomRight: Radius.circular(20),
            //                 topLeft: Radius.circular(20),
            //                 topRight: Radius.circular(20),
            //               ),
            //               child: layoutImage != null && layoutImage!.isNotEmpty
            //                   ? Image.network(
            //                 layoutImage!,
            //                 fit: BoxFit.fill,
            //                 width: double.infinity,
            //                 height: 500,
            //                 errorBuilder: (context, error, stackTrace) {
            //                   return Image.asset(
            //                     'assets/layout_2.png',
            //                     fit: BoxFit.fill,
            //                     width: double.infinity,
            //                     height: 500,
            //                   );
            //                 },
            //               )
            //                   : Image.asset(
            //                 'assets/layout_2.png',
            //                 fit: BoxFit.fill,
            //                 width: double.infinity,
            //                 height: 500,
            //               ),
            //             ),
            //           ),
            //
            //           // Overlay text + button
            //           Positioned(
            //             top: 50,
            //             left: 25,
            //             child: Column(
            //               crossAxisAlignment: CrossAxisAlignment.start,
            //               children: const [
            //                 Text(
            //                   "Men’s",
            //                   style: TextStyle(
            //                     fontSize: 30,
            //                     fontWeight: FontWeight.bold,
            //                     color: Color(0xFF8C6A3E),
            //                   ),
            //                 ),
            //                 SizedBox(height: 5),
            //                 Text(
            //                   "Collection",
            //                   style: TextStyle(
            //                     fontSize: 20,
            //                     fontWeight: FontWeight.w500,
            //                     color: Colors.black87,
            //                   ),
            //                 ),
            //               ],
            //             ),
            //           ),
            //
            //           Positioned(
            //             bottom: 25,
            //             right: 10,
            //             child: ElevatedButton(
            //               onPressed: () {},
            //               style: ElevatedButton.styleFrom(
            //                 backgroundColor: const Color(0xFF8C6A3E),
            //                 shape: RoundedRectangleBorder(
            //                   borderRadius: BorderRadius.circular(15),
            //                 ),
            //                 padding: const EdgeInsets.symmetric(
            //                     horizontal: 28, vertical: 12),
            //               ),
            //               child: const Text(
            //                 "Explore",
            //                 style: TextStyle(
            //                   color: Colors.white,
            //                   fontSize: 16,
            //                   fontWeight: FontWeight.w600,
            //                 ),
            //               ),
            //             ),
            //           ),
            //         ],
            //       ),
            //       const SizedBox(height: 10),
            //       // 🔹 Bottom horizontal list
            //       Container(
            //         height: 125,
            //         child: ListView.builder(
            //           scrollDirection: Axis.horizontal,
            //           padding: const EdgeInsets.symmetric(horizontal: 10),
            //           itemCount: homeinside_App_layout.length,
            //           itemBuilder: (context, index) {
            //             final category = homeinside_App_layout[index] as Map<String, dynamic>;
            //             final imageUrl = "${category['category']['image']}";
            //             final name = (category['subcategory'] != null && category['subcategory']['name'] != null)
            //                 ? category['subcategory']['name']   // subcategory exists → use it
            //                 : (category['category'] != null && category['category']['name'] != null)
            //                 ? category['category']['name']  // only category → use category
            //                 : '';
            //             final catid = category['id'] ?? '';
            //             // final shape = category['shape'] ?? 'circle';
            //             final borderHex = category['border_color']; // e.g. "#993333"
            //
            //             Color? borderColor;
            //             if (borderHex != null && borderHex.isNotEmpty) {
            //               try {
            //                 borderColor = Color(int.parse(borderHex.replaceFirst('#', '0xff')));
            //               } catch (e) {
            //                 borderColor = null;
            //               }
            //             }
            //             return Column(
            //               children: [
            //                 GestureDetector(
            //                   onTap: () {
            //                     Navigator.push(
            //                       context,
            //                       MaterialPageRoute(
            //                         builder: (context) => MainCategoryScreen(
            //                           catid.toString(),
            //                           name.toString(),
            //                         ),
            //                       ),
            //                     );
            //                   },
            //                   child: layoutShape == "rectangle_with_border"?Container(
            //                     margin: const EdgeInsets.symmetric(horizontal: 10),
            //                     padding: const EdgeInsets.all(3),
            //                     decoration: BoxDecoration(
            //                       shape:  BoxShape.rectangle,
            //                       border: borderColor != null
            //                           ? Border.all(
            //                         color: borderColor,
            //                         width: 2,
            //                       )
            //                           : null, // hide if null
            //                       borderRadius: BorderRadius.circular(10), // 15 is radius in pixels
            //                     ),
            //                     child: ClipRRect(
            //                       borderRadius: BorderRadius.circular(10), // 👈 radius for image
            //                       child: CachedNetworkImage(
            //                         height: 90,
            //                         width: 90,
            //                         imageUrl: imageUrl,
            //                         fit: BoxFit.cover,
            //                         useOldImageOnUrlChange: true,
            //                         memCacheHeight: 200,
            //                         memCacheWidth: 200,
            //                         placeholder: (context, url) =>
            //                         const Center(child: CircularProgressIndicator()),
            //                         errorWidget: (context, url, error) =>
            //                         const Center(child: Icon(Icons.error)),
            //                       ),
            //                     ),
            //                   ):Container(),
            //                 ),
            //                 Text(
            //                   name,
            //                   style: const TextStyle(
            //                     color: Colors.black,
            //                     fontSize: 15,
            //                     fontWeight: FontWeight.w400,
            //                   ),
            //                 ),
            //               ],
            //             );
            //           },
            //         ),
            //       ),
            //       const SizedBox(height: 10),
            //     ],
            //   ),
            // )
            //     : const SizedBox.shrink(), // 👈 hide container if shape != circle
            //
            // SizedBox(height: 10),
            //
            // // New Layout @2   End =======================================================

            SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
              child: Text(
                homeHeading?['heading_two'] ?? "OUR STORE COLLECTIONS",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 5),
            _buildBannerlatestcollectonCarousel(),
            SizedBox(height: 10),
            // Heading
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
              child: Text(
                homeHeading?['heading_three'] ?? "TOP COLLECTIONS",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 5),



            // Horizontal list of collections
            // SizedBox(
            //   height: 150,
            //   child: ListView(
            //     scrollDirection: Axis.horizontal,
            //     children: [
            //       _buildCollectionCard(
            //         imageUrl // 🔴 replace with your asset
            //         name,
            //       ),
            //       _buildCollectionCard(
            //         "assets/jewellery-png-36043.png", // 💖 replace with your asset
            //         "Simply Hearts",
            //       ),
            //       _buildCollectionCard(
            //         "assets/jewellery-png-36043.png",
            //         "Sacred",
            //       ),
            //     ],
            //   ),
            // ),
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: topcollection_catlist.length, // 🔹 total cards
                itemBuilder: (context, index) {
                  final item = topcollection_catlist[index] as Map<String, dynamic>;

                  String imageUrl = item['product']?['image_url'] ??
                      item['subcategory']?['image_url'] ??
                      item['category']?['image_url'] ??
                      "https://via.placeholder.com/150"; // fallback
                  //print("Image Url "+ imageUrl.toString());
                  // ✅ Color (fallback if null)
                  final colorHex = item['color']?.toString() ?? "#F3E0EC";
                  return GestureDetector(
                    onTap: (){
                      Navigator.push(context,
                          MaterialPageRoute(builder:
                      (context) =>
                          JewelleryScreen(item['category']?['id']?.toString(),item['subcategory']?['id'].toString(),item['subcategory']?['name']?.toString())
                      ));
                    },
                    child: _buildCollectionCard(
                        imageUrl, // asset/image url
                        item['category']?['name']?.toString() ?? item['subcategory']?['name']?.toString() ?? "No Name",
                      colorHex, // 🔹 Pass color to card
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20,),

            if (bottomLayoutWidget != null) bottomLayoutWidget!,

            // // last New Layout @3=======================================================
            //
            // // 🔹 Top section with image and text overlay
            //
            // layoutShape == "rectangle"
            //     ? Container(
            //   width: double.infinity,
            //   decoration: BoxDecoration(
            //     color: containerBgColor,
            //     borderRadius: const BorderRadius.only(
            //       bottomLeft: Radius.circular(20),
            //       bottomRight: Radius.circular(20),
            //       topLeft: Radius.circular(20),
            //       topRight: Radius.circular(20),
            //     ),
            //   ),
            //   child: Column(
            //     children: [
            //       Stack(
            //         alignment: Alignment.center,
            //         children: [
            //           // Background image section
            //           Container(
            //             decoration: BoxDecoration(
            //               color: Color(0xFFF7F2E7),
            //               borderRadius: const BorderRadius.only(
            //                 bottomLeft: Radius.circular(20),
            //                 bottomRight: Radius.circular(20),
            //                 topLeft: Radius.circular(20),
            //                 topRight: Radius.circular(20),
            //               ),
            //             ),
            //             child: ClipRRect(
            //               borderRadius: const BorderRadius.only(
            //                 bottomLeft: Radius.circular(20),
            //                 bottomRight: Radius.circular(20),
            //                 topLeft: Radius.circular(20),
            //                 topRight: Radius.circular(20),
            //               ),
            //               child: layoutImage != null && layoutImage!.isNotEmpty
            //                   ? Image.network(
            //                 layoutImage!,
            //                 fit: BoxFit.fill,
            //                 width: double.infinity,
            //                 height: 500,
            //                 errorBuilder: (context, error, stackTrace) {
            //                   return Image.asset(
            //                     'assets/layout_2.png',
            //                     fit: BoxFit.fill,
            //                     width: double.infinity,
            //                     height: 500,
            //                   );
            //                 },
            //               )
            //                   : Image.asset(
            //                 'assets/layout_2.png',
            //                 fit: BoxFit.fill,
            //                 width: double.infinity,
            //                 height: 500,
            //               ),
            //             ),
            //           ),
            //
            //           // Overlay text + button
            //           Positioned(
            //             top: 50,
            //             left: 25,
            //             child: Column(
            //               crossAxisAlignment: CrossAxisAlignment.start,
            //               children: const [
            //                 Text(
            //                   "Men’s",
            //                   style: TextStyle(
            //                     fontSize: 30,
            //                     fontWeight: FontWeight.bold,
            //                     color: Color(0xFF8C6A3E),
            //                   ),
            //                 ),
            //                 SizedBox(height: 5),
            //                 Text(
            //                   "Collection",
            //                   style: TextStyle(
            //                     fontSize: 20,
            //                     fontWeight: FontWeight.w500,
            //                     color: Colors.black87,
            //                   ),
            //                 ),
            //               ],
            //             ),
            //           ),
            //
            //           Positioned(
            //             bottom: 25,
            //             right: 10,
            //             child: ElevatedButton(
            //               onPressed: () {},
            //               style: ElevatedButton.styleFrom(
            //                 backgroundColor: const Color(0xFF8C6A3E),
            //                 shape: RoundedRectangleBorder(
            //                   borderRadius: BorderRadius.circular(15),
            //                 ),
            //                 padding: const EdgeInsets.symmetric(
            //                     horizontal: 28, vertical: 12),
            //               ),
            //               child: const Text(
            //                 "Explore",
            //                 style: TextStyle(
            //                   color: Colors.white,
            //                   fontSize: 16,
            //                   fontWeight: FontWeight.w600,
            //                 ),
            //               ),
            //             ),
            //           ),
            //         ],
            //       ),
            //       const SizedBox(height: 10),
            //       // 🔹 Bottom horizontal list
            //       Container(
            //         height: 125,
            //         child: ListView.builder(
            //           scrollDirection: Axis.horizontal,
            //           padding: const EdgeInsets.symmetric(horizontal: 10),
            //           itemCount: homeinside_App_layout.length,
            //           itemBuilder: (context, index) {
            //             final category = homeinside_App_layout[index] as Map<String, dynamic>;
            //             final imageUrl = "${category['category']['image']}";
            //             final name = (category['subcategory'] != null && category['subcategory']['name'] != null)
            //                 ? category['subcategory']['name']   // subcategory exists → use it
            //                 : (category['category'] != null && category['category']['name'] != null)
            //                 ? category['category']['name']  // only category → use category
            //                 : '';
            //             final catid = category['category']['id'] ?? '';
            //             // final shape = category['shape'] ?? 'circle';
            //             final borderHex = category['border']; // e.g. "#993333"
            //
            //             Color? borderColor;
            //             if (borderHex != null && borderHex.isNotEmpty) {
            //               try {
            //                 borderColor = Color(int.parse(borderHex.replaceFirst('#', '0xff')));
            //               } catch (e) {
            //                 borderColor = null;
            //               }
            //             }
            //             return Column(
            //               children: [
            //                 GestureDetector(
            //                   onTap: () {
            //                     Navigator.push(
            //                       context,
            //                       MaterialPageRoute(
            //                         builder: (context) => MainCategoryScreen(
            //                           catid.toString(),
            //                           name.toString(),
            //                         ),
            //                       ),
            //                     );
            //                   },
            //                   child: layoutShape == "rectangle"?Container(
            //                     margin: const EdgeInsets.symmetric(horizontal: 10),
            //                     padding: const EdgeInsets.all(3),
            //                     decoration: BoxDecoration(
            //                       shape:  BoxShape.rectangle,
            //                       border: borderColor != null
            //                           ? Border.all(
            //                         color: borderColor,
            //                         width: 2,
            //                       )
            //                           : null, // hide if null
            //
            //                     ),
            //                     child: ClipRRect(
            //                       borderRadius: BorderRadius.circular(10), // 👈 radius for image
            //                       child: CachedNetworkImage(
            //                         height: 90,
            //                         width: 90,
            //                         imageUrl: imageUrl,
            //                         fit: BoxFit.cover,
            //                         useOldImageOnUrlChange: true,
            //                         memCacheHeight: 200,
            //                         memCacheWidth: 200,
            //                         placeholder: (context, url) =>
            //                         const Center(child: CircularProgressIndicator()),
            //                         errorWidget: (context, url, error) =>
            //                         const Center(child: Icon(Icons.error)),
            //                       ),
            //                     ),
            //                   ):Container(),
            //                 ),
            //                 Text(
            //                   name,
            //                   style: const TextStyle(
            //                     color: Colors.black,
            //                     fontSize: 15,
            //                     fontWeight: FontWeight.w400,
            //                   ),
            //                 ),
            //               ],
            //             );
            //           },
            //         ),
            //       ),
            //       const SizedBox(height: 10),
            //     ],
            //   ),
            // )
            //     : const SizedBox.shrink(), // 👈 hide container if shape != circle
            //
            //
            //
            // layoutShape == "rectangle_with_border"
            //     ? Container(
            //   width: double.infinity,
            //   decoration: BoxDecoration(
            //     color: containerBgColor,
            //     borderRadius: const BorderRadius.only(
            //       bottomLeft: Radius.circular(20),
            //       bottomRight: Radius.circular(20),
            //       topLeft: Radius.circular(20),
            //       topRight: Radius.circular(20),
            //     ),
            //   ),
            //   child: Column(
            //     children: [
            //       Stack(
            //         alignment: Alignment.center,
            //         children: [
            //           // Background image section
            //           Container(
            //             decoration: BoxDecoration(
            //               color: Color(0xFFF7F2E7),
            //               borderRadius: const BorderRadius.only(
            //                 bottomLeft: Radius.circular(20),
            //                 bottomRight: Radius.circular(20),
            //                 topLeft: Radius.circular(20),
            //                 topRight: Radius.circular(20),
            //               ),
            //             ),
            //             child: ClipRRect(
            //               borderRadius: const BorderRadius.only(
            //                 bottomLeft: Radius.circular(20),
            //                 bottomRight: Radius.circular(20),
            //                 topLeft: Radius.circular(20),
            //                 topRight: Radius.circular(20),
            //               ),
            //               child: layoutImage != null && layoutImage!.isNotEmpty
            //                   ? Image.network(
            //                 layoutImage!,
            //                 fit: BoxFit.fill,
            //                 width: double.infinity,
            //                 height: 500,
            //                 errorBuilder: (context, error, stackTrace) {
            //                   return Image.asset(
            //                     'assets/layout_2.png',
            //                     fit: BoxFit.fill,
            //                     width: double.infinity,
            //                     height: 500,
            //                   );
            //                 },
            //               )
            //                   : Image.asset(
            //                 'assets/layout_2.png',
            //                 fit: BoxFit.fill,
            //                 width: double.infinity,
            //                 height: 500,
            //               ),
            //             ),
            //           ),
            //
            //           // Overlay text + button
            //           Positioned(
            //             top: 50,
            //             left: 25,
            //             child: Column(
            //               crossAxisAlignment: CrossAxisAlignment.start,
            //               children: const [
            //                 Text(
            //                   "Men’s",
            //                   style: TextStyle(
            //                     fontSize: 30,
            //                     fontWeight: FontWeight.bold,
            //                     color: Color(0xFF8C6A3E),
            //                   ),
            //                 ),
            //                 SizedBox(height: 5),
            //                 Text(
            //                   "Collection",
            //                   style: TextStyle(
            //                     fontSize: 20,
            //                     fontWeight: FontWeight.w500,
            //                     color: Colors.black87,
            //                   ),
            //                 ),
            //               ],
            //             ),
            //           ),
            //
            //           Positioned(
            //             bottom: 25,
            //             right: 10,
            //             child: ElevatedButton(
            //               onPressed: () {},
            //               style: ElevatedButton.styleFrom(
            //                 backgroundColor: const Color(0xFF8C6A3E),
            //                 shape: RoundedRectangleBorder(
            //                   borderRadius: BorderRadius.circular(15),
            //                 ),
            //                 padding: const EdgeInsets.symmetric(
            //                     horizontal: 28, vertical: 12),
            //               ),
            //               child: const Text(
            //                 "Explore",
            //                 style: TextStyle(
            //                   color: Colors.white,
            //                   fontSize: 16,
            //                   fontWeight: FontWeight.w600,
            //                 ),
            //               ),
            //             ),
            //           ),
            //         ],
            //       ),
            //       const SizedBox(height: 10),
            //       // 🔹 Bottom horizontal list
            //       Container(
            //         height: 125,
            //         child: ListView.builder(
            //           scrollDirection: Axis.horizontal,
            //           padding: const EdgeInsets.symmetric(horizontal: 10),
            //           itemCount: homeinside_App_layout.length,
            //           itemBuilder: (context, index) {
            //             final category = homeinside_App_layout[index] as Map<String, dynamic>;
            //             final imageUrl = "${category['category']['image']}";
            //             final name = (category['subcategory'] != null && category['subcategory']['name'] != null)
            //                 ? category['subcategory']['name']   // subcategory exists → use it
            //                 : (category['category'] != null && category['category']['name'] != null)
            //                 ? category['category']['name']  // only category → use category
            //                 : '';
            //             final catid = category['id'] ?? '';
            //             // final shape = category['shape'] ?? 'circle';
            //             final borderHex = category['border_color']; // e.g. "#993333"
            //
            //             Color? borderColor;
            //             if (borderHex != null && borderHex.isNotEmpty) {
            //               try {
            //                 borderColor = Color(int.parse(borderHex.replaceFirst('#', '0xff')));
            //               } catch (e) {
            //                 borderColor = null;
            //               }
            //             }
            //             return Column(
            //               children: [
            //                 GestureDetector(
            //                   onTap: () {
            //                     Navigator.push(
            //                       context,
            //                       MaterialPageRoute(
            //                         builder: (context) => MainCategoryScreen(
            //                           catid.toString(),
            //                           name.toString(),
            //                         ),
            //                       ),
            //                     );
            //                   },
            //                   child: layoutShape == "rectangle_with_border"?Container(
            //                     margin: const EdgeInsets.symmetric(horizontal: 10),
            //                     padding: const EdgeInsets.all(3),
            //                     decoration: BoxDecoration(
            //                       shape:  BoxShape.rectangle,
            //                       border: borderColor != null
            //                           ? Border.all(
            //                         color: borderColor,
            //                         width: 2,
            //                       )
            //                           : null, // hide if null
            //                       borderRadius: BorderRadius.circular(10), // 15 is radius in pixels
            //                     ),
            //                     child: ClipRRect(
            //                       borderRadius: BorderRadius.circular(10), // 👈 radius for image
            //                       child: CachedNetworkImage(
            //                         height: 90,
            //                         width: 90,
            //                         imageUrl: imageUrl,
            //                         fit: BoxFit.cover,
            //                         useOldImageOnUrlChange: true,
            //                         memCacheHeight: 200,
            //                         memCacheWidth: 200,
            //                         placeholder: (context, url) =>
            //                         const Center(child: CircularProgressIndicator()),
            //                         errorWidget: (context, url, error) =>
            //                         const Center(child: Icon(Icons.error)),
            //                       ),
            //                     ),
            //                   ):Container(),
            //                 ),
            //                 Text(
            //                   name,
            //                   style: const TextStyle(
            //                     color: Colors.black,
            //                     fontSize: 15,
            //                     fontWeight: FontWeight.w400,
            //                   ),
            //                 ),
            //               ],
            //             );
            //           },
            //         ),
            //       ),
            //       const SizedBox(height: 10),
            //     ],
            //   ),
            // )
            //     : const SizedBox.shrink(), // 👈 hide container if shape != circle
            //
            //
            // SizedBox(height: 10),
            //
            // // last New Layout @3   End =======================================================
            //
            // //==========================Video Layout ================================================//

          ],
        ),
      ),
      //bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // App Bar
  AppBar _buildAppBar() {
    final bgColor = (appBarColor != null && appBarColor!.isNotEmpty)
        ? getColorFromHex(appBarColor!)
        : Colors.white;
    return AppBar(
      backgroundColor:bgColor,
      elevation: 0,
      leadingWidth: 180, // ⬅️ Enough space for menu + logo
      leading: Row(
        children: [
          const SizedBox(width: 5),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.black, size: 30),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
          Image.asset("assets/Ornatique2.png", width: 120), // ⬅️ Your logo here
        ],
      ),
      // title: Container(
      //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      //   decoration: BoxDecoration(
      //     color: Colors.purple[100],
      //     borderRadius: BorderRadius.circular(12),
      //   ),
      //   child: Row(
      //     mainAxisSize: MainAxisSize.min,
      //     children: [
      //       const Icon(Icons.emoji_events, size: 16, color: Colors.black),
      //       const SizedBox(width: 4),
      //       Text("Crown", style: FontStyles.normal_heading),
      //     ],
      //   ),
      // ),
      actions: [
        IconButton(
          icon: Icon(Icons.play_circle_outline, color: Colors.red,size: 30,),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MediaPage()),
            );
          },
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => NotificationScreen()));
          },
          child: Icon(Icons.notification_add_outlined, color: Color_Constant.black),
        ),
        const SizedBox(width: 15),
        Stack(
          children: [
            GestureDetector(
                onTap: (){
                  Navigator.push(context,
                      MaterialPageRoute(builder:
                          (context) =>
                          CartScreen()
                      )
                  );
                },
                child: Icon(Icons.shopping_cart_outlined, color:Color_Constant.black)),
            // if (cartcatlist.length > 0)
            //   Positioned(
            //     right: 0,
            //     bottom: 6,
            //     child: Container(
            //       padding: EdgeInsets.all(4),
            //       decoration: BoxDecoration(color: Colors.pink, shape: BoxShape.circle),
            //       child: Text(
            //         cartcatlist.length.toString(),
            //         style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            //       ),
            //     ),
            //   ),
          ],
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  // Drawer
  Widget _buildDrawer() {
    return Container(
      width: 250,
      child: Drawer(
        child: Column(
          //padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color:Color_Constant.lightBlue,),
              accountName: Text("John Doe",
                style: FontStyles.subheading,),
              accountEmail: Text("johndoe@example.com",style: FontStyles.offer_heading),
              currentAccountPicture: CircleAvatar(
                backgroundImage: AssetImage("assets/logo.png"),
              ),
            ),
            ListTile(
              leading: Image.asset('assets/home.png',height: 25,).animate().fade(duration: 800.ms).moveY(begin: -50, end: 0),
              title: Text("Home",style: FontStyles.offer_heading,),
              dense: true,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            Divider(height: 0, thickness: 1,indent: 5,endIndent: 10,), // Adjust divider spacing
            ListTile(
              leading: Image.asset('assets/order.png',height: 25,).animate().fade(duration: 800.ms).moveY(begin: -50, end: 0),
              title: Text("Order History",style: FontStyles.offer_heading),
              dense: true,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            Divider(height: 0, thickness: 1,indent: 5,endIndent: 10,), // Adjust divider spacing
            ListTile(
              leading: Image.asset('assets/feedback.png',height: 25,).animate().fade(duration: 800.ms).moveY(begin: -50, end: 0),
              title: Text("Rate App", style: FontStyles.offer_heading),
              dense: true,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            Divider(height: 0, thickness: 1,indent: 5,endIndent: 10,), // Adjust divider spacing
            ListTile(
              leading: Image.asset('assets/privacy-policy.png',height: 25,).animate().fade(duration: 800.ms).moveY(begin: -50, end: 0),
              title: Text("Privacy Policy", style: FontStyles.offer_heading),
              dense: true,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            Divider(height: 0, thickness: 1,indent: 5,endIndent: 10,), // Adjust divider spacing
            ListTile(
              leading: Image.asset('assets/user.png',height: 25,).animate().fade(duration: 800.ms).moveY(begin: -50, end: 0),
              title: Text("Profile",style: FontStyles.offer_heading),
              dense: true,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            Divider(height: 0, thickness: 1,indent: 5,endIndent: 10,), // Adjust divider spacing
            ListTile(
              leading: Image.asset('assets/settings.png',height: 25,).animate().fade(duration: 800.ms).moveY(begin: -50, end: 0),
              title: Text("Settings", style: FontStyles.offer_heading),
              dense: true,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            Divider(height: 0, thickness: 1,indent: 5,endIndent: 10,), // Adjust divider spacing
            ListTile(
              leading: Image.asset('assets/logout.png',height: 25,).animate().fade(duration: 800.ms).moveY(begin: -50, end: 0),
              title: Text("Logout",style: FontStyles.offer_heading),
              dense: true,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            Column(
              children: [
                Divider(height: 0, thickness: 1,indent: 5,endIndent: 10,), // Adjust divider spacing
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 50),
                  child: Column(
                    children: [
                      Text(
                        "By Ornatique App",
                          style: FontStyles.offer_heading
                      ),
                      SizedBox(height: 5),
                      Text(
                        "Version 1.0.0",
                          style: FontStyles.offer_heading
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Offer Banner
  Widget _buildOfferBanner() {
    if (home_offer.isEmpty) {
      return Container(
        padding: EdgeInsets.all(8),
        //color: Color_Constant.lightBlue,
        color: Color(0xFFF3E0EC),
        child: Center(
          child: Text(
            "No Offers Available",
            style: FontStyles.offer_heading,
          ),
        ),
      );
    }

    return Container(
      height: 30,
      //color: Color_Constant.lightBlue,
      //color: Color(0xFFF3E0EC),
      color: getColorFromHex(home_offer[_currentOfferIndex]['color'].toString()),
      child: PageView.builder(
        controller: _offerPageController,
        itemCount: home_offer.length,
        itemBuilder: (context, index) {
          Dynamic_Color = home_offer[_currentOfferIndex]['color'].toString();
          return Center(
            child: Text(
              home_offer[_currentOfferIndex]['name'].toString(),
              key: ValueKey(_currentOfferIndex),
              // style:FontStyles.offer_heading,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            )
          );
        },
        onPageChanged: (index) {
          setState(() {
            _currentOfferIndex = index;
          });
        },
      ),
    );
  }

  // Category List
  // Widget _buildCategoryList() {
  //   return Container(
  //     height: 90,
  //     child: ListView(
  //       scrollDirection: Axis.horizontal,
  //       padding: EdgeInsets.symmetric(horizontal: 10),
  //       children: [
  //         _categoryItem("assets/image_1.png", "Women's Day"),
  //         _categoryItem("assets/image_1.png", "Pendants"),
  //         _categoryItem("assets/image_1.png", "Rings"),
  //         _categoryItem("assets/image_1.png", "Earrings"),
  //         _categoryItem("assets/image_1.png", "Women's Day"),
  //         _categoryItem("assets/image_1.png", "Pendants"),
  //         _categoryItem("assets/image_1.png", "Rings"),
  //         _categoryItem("assets/image_1.png", "Earrings"),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildCategoryList() {
    if (homeZeroList.isEmpty) {
      return SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 10),
        itemCount: homeZeroList.length,
        itemBuilder: (context, index) {
          final category = homeZeroList[index] as Map<String, dynamic>;
          final imageUrl = "$banner_baseUrl/${category['image']}";
          final name = category['name'] ?? '';
          final catid = category['id'] ?? '';

          return _categoryItem(imageUrl, name,catid.toString());
        },
      ),
    );
  }


  Widget _categoryItem(String imagePath, String label,String catid) {
    return Column(
      children: [
        GestureDetector(
          onTap: (){
            Navigator.push(context,
                MaterialPageRoute(builder:
                    (context) =>
                    MainCategoryScreen(catid,label)
                )
            );
          },
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 10),
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              //color: Color(0xFFFFEBEE),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20), // 👈 radius for image
              child: CachedNetworkImage(
                height: 80,
                width: 80,
                imageUrl: imagePath,
                fit: BoxFit.cover,
                useOldImageOnUrlChange: true,
                memCacheHeight: 200,
                memCacheWidth: 200,
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
        Text(label,
           // style: FontStyles.font12_bold
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }


  // Banner Carousel
  Widget _buildBannerCarousel() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.27, // 28% of screen height
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.horizontal,
        itemCount: bannerlist.length,
        itemBuilder: (context, index) {
          final banner = bannerlist[index];
          final product = banner['product'];
          final String? categoryId = product?['id']?.toString();
          final String? subcategoryId = product?['name']?.toString();

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
                        "1"
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
                // Image.network(
                //   banner['imageUrl'],
                //   fit: BoxFit.cover,
                // ),
                CachedNetworkImage(
                  imageUrl: banner['imageUrl'],
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

  // Banner Carousel
  Widget _buildBannerlatestcollectonCarousel() {

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.22, // 28% of screen height
      child: ListView.builder(
        scrollDirection: Axis.horizontal, // Horizontal scroll
        itemCount: storebannerlist.length,
        itemBuilder: (context, index) {
          final banner = storebannerlist[index];
          final product = banner['product'];
          final String? categoryId = product?['id']?.toString();
          final String? subcategoryId = product?['name']?.toString();

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
                        "1",
                      ),
                    ),
                  );
                } else {
                  // Handle case where product data is incomplete
                }
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8), // space between banners
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  width: MediaQuery.of(context).size.width * 0.8, // thodo wide banner
                  imageUrl: banner['imageUrl'],
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: Text(
          title,
          style:FontStyles.estenial_heading,
        ),
      ),
    );
  }


  // // Grid Items
  // Widget _buildGridItems() {
  //   return Padding(
  //     padding: EdgeInsets.symmetric(horizontal: 10),
  //     child: GridView(
  //       shrinkWrap: true,
  //       physics: NeverScrollableScrollPhysics(),
  //       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
  //           childAspectRatio: 1.1, // Adjust aspect ratio for better spacing
  //           crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 1),
  //       children: [
  //         _gridItem("assets/banner.jpg", "Gold with Lab Diamonds"),
  //         _gridItem("assets/banner.jpg", "Silver Jewellery"),
  //         _gridItem("assets/banner.jpg", "Gold with Lab Diamonds"),
  //         _gridItem("assets/banner.jpg", "Silver Jewellery"),
  //       ],
  //     ),
  //   );
  // }

  // Grid Items (Fixed)
  Widget _buildGridItems() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // double getAspectRatio(double height) {
    //   if (height >= 2000) return 1.5;   // Foldables / Tablets (big height)
    //   else if (height >= 900) return 1.28; // Tablets / Very tall phones
    //   else if (height >= 850) return 1.3;  // Large phones
    //   else if (height >= 800) return 1.0;  // Normal phones
    //   else return 0.9;                     // Small phones
    // }

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

    // double getAspectRatio(BuildContext context) {
    //   final width = MediaQuery.of(context).size.width;
    //   final crossAxisSpacing = 20;
    //   final columns = 2;
    //   final itemWidth = (width - (columns + 1) * crossAxisSpacing) / columns;
    //   final itemHeight = 125 + 30; // image + text container height
    //   return itemWidth / itemHeight;
    // }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        // ✅ Sirf 6 item show thase (jo catlist < 6 hoy to jitli hoy tya sudhi)
        itemCount: catlist.length > 6 ? 6 : catlist.length,
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
                callcartlist();
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
                  //color: const Color(0xFFEBDDE3),
                  color: getColorFromHex(color.toString()),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
                child: Text(
                  label,
                  // style: FontStyles.offer_heading,
                  overflow: TextOverflow.ellipsis,
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


  // Bottom Navigation Bar
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      selectedItemColor: Color_Constant.blue,
      unselectedItemColor: Colors.black54,
      showUnselectedLabels: true,
      onTap: _onItemTapped,
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: "Gifts"),
        BottomNavigationBarItem(icon: Icon(Icons.notification_add_outlined), label: "Notification"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      ],
    );
  }

  Future<void> checkAppVersion(BuildContext context) async {
    final info = await PackageInfo.fromPlatform();
    final Dio dio = Dio();
    try {
      final response = await dio.get(
        ApiConstants.baseUrl+ApiConstants.check_version,
        // "https://development.ornatique.co/portal/api/check-version",
        queryParameters: {
          "platform": "android",
          "version": info.version.toString(),
        },
      );

      final data = response.data;

      if (data["status"] == "false" && data["code"] == "FORCE_UPDATE") {
        _showForceUpdateDialog(
          context,
          data["message"],
          data["store_url"],
        );
      }
    } catch (e) {
      debugPrint("Version check error: $e");
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

  Future<void> _checkAndShowPopup() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstTime = prefs.getBool('firstTimePopup') ?? true; // Default is true

    if (isFirstTime) {
      _showAnimatedPopup();
      await prefs.setBool('firstTimePopup', false); // Mark as shown
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
        _startAutoScroll();
      }
    } else {
      print('Banner fetch failed - server error or null response');
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text("Failed to load banners")),
      // );
    }
  }

  Future<void> getstorebanner() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final body = {
      "user_id": prefs.getString("Uid").toString(),
    };
    final response = await ApiHelper().postRequest(ApiConstants.storehome_banner, body);

    print("Store Banner Request: {}");
    print("Store Banner Response: ${response.toString()}");

    if (response != null && response.statusCode == 200) {
      final data = response.data;

      if (data['status'] == "1") {
        final List<dynamic> banners = data['data'];
        final String baseUrl = data['image_url'];

        // Build a list of full image URLs
        setState(() {
          storebannerlist = banners.map((item) {
            return {
              "imageUrl": baseUrl + "/" + item['image'].toString(),
              "product": item['product']
            };
          }).toList();
        });
        _startAutoScroll();
      }
    } else {
      print('Store Banner fetch failed - server error or null response');
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text("Failed to load banners")),
      // );
    }
  }

  Future<void> getwelcomepopup() async {
    final response = await ApiHelper().postRequest(ApiConstants.welcome_popup, {});

    print("Welcome popup Request: {}");
    print("Welcome popup Response: ${response.toString()}");

    if (response != null && response.statusCode == 200) {
      final data = response.data;

      if (data['status'] == "1") {
        final List<dynamic> banners = data['data'];
        final String baseUrl = data['image_url'];

        // Build a list of full image URLs
        setState(() {

         // welcome_image = (baseUrl + "/" + banners[0]['gallery_adv'].toString());
          popuplist = banners
              .map((item) => baseUrl + "/" + item['gallery_adv'].toString())
              .toList();
          _checkAndShowPopup();

        });

      }
    } else {
      print('Banner fetch failed - server error or null response');
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text("Failed to load banners")),
      // );
    }
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
          homeZeroList = catlist.where((item) => item['home'] == "1").toList(); // Filtered list
          banner_baseUrl = data['image_url'];
        });

        print("✅ catlist.length: ${catlist.length}");
        print("✅ homeZeroList.length: ${homeZeroList.length}");

        if (homeZeroList.isNotEmpty) {
          print("🖼️ First image (home=0): $banner_baseUrl/${homeZeroList[0]['image']}");
        } else {
          print("❌ No items with home = 0 found.");
        }
      }
    } else {
      setState(() {
        catlist = [];
        homeZeroList = [];
      });
      print('❌ Category load failed - server error or null response');
    }
  }

  Future<void> topcollectioncategory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final body = {
      "user_id": prefs.getString("Uid").toString(),
    };

    final response = await ApiHelper().postRequest(ApiConstants.topcollectioncat_list, body);
    print("Top collection category Request: $body");
    print("Top collection category Raw Response: ${response.toString()}");

    if (response != null && response.statusCode == 200) {
      final data = response.data; // this is already a Map

      if (data['status'] == "1") {
        print("✅ Top collection Parsed Category Response: $data");

        setState(() {
          topcollection_catlist = data['data']; // Complete list
          //homeZeroList = catlist.where((item) => item['home'] == "1").toList(); // Filtered list
          //collection_baseUrl = data['image_url'];
        });

        print("✅ Top collection catlist.length: ${topcollection_catlist.length}");
        print("✅ Top collection homeZeroList.length: ${homeZeroList.length}");

        // if (homeZeroList.isNotEmpty) {
        //   print("🖼️ First image (home=0): $banner_baseUrl/${homeZeroList[0]['image']}");
        // } else {
        //   print("❌ No items with home = 0 found.");
        // }
      }
    } else {
      setState(() {
        topcollection_catlist = [];
        //homeZeroList = [];
      });
      print('❌ Top collection Category load failed - server error or null response');
    }
  }

  Future<void> subcategory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final body = {
      "user_id": prefs.getString("Uid").toString(),
    };

    try {
      final response = await ApiHelper().postRequest(ApiConstants.cat_list, body);
      print("subcategory Request: $body");
      print("subcategory Raw Response: ${response.toString()}");

      if (response != null && response.statusCode == 200) {
        final data = response.data; // This is already a Map

        if (data['status'] == "1") {
          print("✅ subcategory Response: $data");

          setState(() {
            subcatlist = List.from(data['data'] ?? []); // Ensure it’s a List, or fallback to empty
            subcat_baseUrl = data['image_url'] ?? ''; // Ensure base URL is set
          });

          // Safe check before accessing the first item
          if (subcatlist.isNotEmpty) {
            print("✅ catlist.length: ${subcatlist.length}");
            print("🖼️ First image: $subcat_baseUrl/${subcatlist[0]['image']}");
          }
        } else {
          // Handle the error if data['status'] != "1" or data['data'] is null
          print('❌ Invalid status or no data found');
          // ScaffoldMessenger.of(context).showSnackBar(
          //   const SnackBar(content: Text("No data found")),
          // );
        }
      } else {
        setState(() => subcatlist = []);
        print('❌ Category load failed - server error or null response');
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text("Category Load Failed")),
        // );
      }
    } catch (e) {
      print('❌ Exception: $e');
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text("An error occurred")),
      // );
    }
  }


  // Method to call the API and fetch the offer data
  Future<void> calloffer() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final body = {"user_id": prefs.getString("Uid").toString()};
    final response = await ApiHelper().postRequest(ApiConstants.home_offer, body);

    if (response != null && response.statusCode == 200) {
      final data = response.data;
      if (data['status'] == "1") {
        setState(() {
          home_offer = data['data'];
          print("✅ Offer List: $data");
          print("✅ catlist.length: ${home_offer.length}");
        });
      } else {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text("No Offers Available")),
        // );
      }
    } else {
      setState(() => home_offer = []);
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text("Offer Load Failed")),
      // );
    }
  }

  Future<void> callornatique_essential() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final body = {"user_id": prefs.getString("Uid").toString()};
    final response = await ApiHelper().postRequest(ApiConstants.Ornatique_Essential, body);

    if (response != null && response.statusCode == 200) {
      final data = response.data;
      if (data['status'] == "1") {
        setState(() {
          home_OrnatiueEssential = data['data'];
          print("✅ Offer List: $data");
          print("✅ catlist.length: ${home_OrnatiueEssential.length}");
        });
      } else {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text("No Offers Available")),
        // );
      }
    } else {
      setState(() => home_offer = []);
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text("Offer Load Failed")),
      // );
    }
  }


  Future<void> callcartlist() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final body = {
      "user_id": prefs.getString('Uid').toString(),
    };

    try {
      //LoadingDialog.show(context, message: "Loading...");
      final response = await ApiHelper().postRequest(ApiConstants.cartlist, body);
      //LoadingDialog.hide(context);
      print("cart Request: $body");
      print("cart Response: ${response?.data}");

      if (response != null && response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == "1") {
          setState(() {
            cartcatlist = (data['data'] as List)
                .cast<Map<String, dynamic>>()
                .where((item) => item['quantity'] > 0)
                .map((item) => {
              ...item,
              'count': item['quantity'] ?? 1,
            })
                .toList();
            prefs.setString("cart_count", cartcatlist.length.toString());
            print("cart length: "+cartcatlist.length.toString());
           // banner_baseUrl = data['image_url'];
            setState(() {
              allProducts = List.from(cartcatlist);
            //  filteredProducts = List.from(allProducts);
            });
          });
        } else {
          setState(() => catlist = []);
        }
      } else {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text("Failed to load products")),
        // );
      }
    } catch (e) {
      //LoadingDialog.hide(context);
      print("❌ Product List Error: $e");
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text("Error loading products")),
      // );
    }
  }


  Future<void> callheadind() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('fcm').toString();
    final body = {
      "user_id": prefs.getString("Uid").toString(),
      "fcm_token": token.toString(),
    };
    final response =
    await ApiHelper().postRequest(ApiConstants.home_heading, body);
    print("Heading Request: $body");
    if (response != null && response.statusCode == 200) {
      final data = response.data;
      if (data['status'] == "1") {
        print("Login API URL: ${ApiConstants.baseUrl + ApiConstants.home_heading}");
        setState(() {

          homeHeading = data['data']; // direct object set
          appBarColor = homeHeading!['app_bar_color'].toString();
          appBGColor = homeHeading!['back_ground_color'].toString();
          appBottomColor = homeHeading!['bottom_bar_color'].toString();
          prefs.setString("app_bar_color", appBarColor.toString());
          prefs.setString("back_ground_color", appBGColor.toString());
          print("✅ Heading Data: $homeHeading");
          print("✅ heading_one: ${homeHeading?['heading_one']}");
        });
      } else {

        setState(() => homeHeading = null);
      }
    } else if(response != null && response.statusCode == 426) {
      final data = response.data;
      if (data["status"] == false && data["code"] == "FORCE_UPDATE") {
        _showForceUpdateDialog(
          context,
          data["message"],
          data["store_url"],
        );
      }
      setState(() => homeHeading = null);
    }
  }


  Future<void> callgetlayout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final response = await ApiHelper().getRequest(ApiConstants.layout);

    print("layout Request: {}");
    print("layout Response: ${response.toString()}");

    if (response != null && response.statusCode == 200) {
      final data = response.data;

      if (data['status'] == true) {
        setState(() {
          homelayout = data['data'];
        });

        if (homelayout.isNotEmpty) {
          final layout = homelayout[0]; // first layout
          layoutShape = layout['shape'];        // e.g. "circle"
          final layoutId = layout['id'];
          final bgColorHex = layout['color'];
          layoutImage = layout['image']; // e.g. image URL


          if (bgColorHex != null && bgColorHex.toString().isNotEmpty) {
            try {
              setState(() {
                containerBgColor = Color(
                  int.parse(bgColorHex.replaceFirst('#', '0xff')),
                );

                print("⚠️ Invalid color format: $containerBgColor");
              });
            } catch (e) {
              print("⚠️ Invalid color format: $e");
              setState(() {
                containerBgColor = defaultBgColor;
              });
            }
          } else {
            // null or empty — use default color
            setState(() {
              containerBgColor = defaultBgColor;
            });
          }

          print("✅ layout_id: $layoutId");
          print("✅ bgColorHex: $bgColorHex");

          // call next API after first one is done
          callInsideAppLayout(layoutId.toString());
        }
      } else {
        print("⚠️ API returned false status");
      }
    } else {
      print('❌ Banner fetch failed - server error or null response');
    }
  }


  Future<void> callInsideAppLayout(String layoutId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("Uid") ?? "";

    // Construct full URL with query parameters
    final uri = Uri.parse(ApiConstants.insideapplayout).replace(
      queryParameters: {
        "user_id": userId,
        "layout_id": layoutId,
      },
    );

    print("Inside App layout GET Request: $uri");

    final response = await ApiHelper().getRequest(uri.toString());

    print("Inside App layout GET Response: ${response.toString()}");

    if (response != null && response.statusCode == 200) {
      final data = response.data;

      setState(() {
        homeinside_App_layout = data['data']; // direct object set
      });



      print("✅ homeinside_App_layout: $homeinside_App_layout");
    } else {
      setState(() => homeHeading = null);
      print("❌ GET request failed or server error");
    }
  }





  void _showAnimatedPopup() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Popup",
      transitionDuration: Duration(milliseconds: 600),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: ScaleTransition(
              scale: animation,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.9,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 10),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(popuplist.length, (index) {
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  height: 400,
                                  width: double.infinity,
                                  child: CachedNetworkImage(
                                    imageUrl: popuplist[index],
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

                              if (index == 0)
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: InkWell(
                                    onTap: () => Navigator.pop(context),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: EdgeInsets.all(4),
                                      child: Image.asset(
                                        'assets/close.png',
                                        height: 20,
                                        width: 20,
                                        color: Colors.white,
                                      ).animate().fade(duration: 800.ms).moveY(begin: -30, end: 0),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        );
      },
    );
  }






  void _startAutoScroll() {
    _bannerTimer?.cancel();  // old timer stop
    _bannerTimer = Timer.periodic(Duration(seconds: 3), (Timer timer) {
      if (bannerlist.isEmpty) return;

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
  }




}

Widget _buildCategoryItem(String iconPath, String title) {
  return Column(
    children: [
      CircleAvatar(
        radius: 38,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(iconPath, fit: BoxFit.contain),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14,
          letterSpacing: 1,
        ),
      ),
    ],
  );
}

Widget _buildCollectionCard(String image, String title , String color) {
  return Container(
    width: 140,
    height: 100,
    margin: const EdgeInsets.only(left: 12),
    decoration: BoxDecoration(
      //color: Color(0xFFF3E0EC), // light pink background like screenshot
      color: getColorFromHex(color.toString()),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
          // child: Image.network(
          //   image,
          //   height: 120,
          //   width: double.infinity,
          //   fit: BoxFit.cover,
          // ),
          child: SizedBox(
            height: 120,
            width: double.infinity,
            child:
            CachedNetworkImage(
              imageUrl: image,
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
        const SizedBox(height: 6),
        SizedBox(
          width: 120,
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
  );
}

Color getColorFromHex(String? hexColor) {
  if (hexColor == null || hexColor == "null") {
    return Color(0xFFF3E0EC); // Default color if null
  }
  hexColor = hexColor.toUpperCase().replaceAll("#", "");
  if (hexColor.length == 6) {
    hexColor = "FF$hexColor"; // Adding opacity (FF for full opacity)
  }
  return Color(int.parse(hexColor, radix: 16));
}