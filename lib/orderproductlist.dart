import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ornatique/ConstantColors/Color_Constant.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Api_Constant/ApiConstants.dart';
import '../Api_Constant/api_helper.dart';
import '../Constant_font/FontStyles.dart';
import '../LoadingDialog/LoadingDialog.dart';
import '../OrderConfirmationDialog.dart';
import 'Screens/ProductDetailScreen.dart';

class orderproductlist extends StatefulWidget {
  String order_id;
  orderproductlist(this.order_id,{super.key});
  @override
  _orderproductlistState createState() => _orderproductlistState();
}

class _orderproductlistState extends State<orderproductlist> {
  // List<Map<String, dynamic>> allProducts = [
  //   {'id': 'PS.154', 'size': 29, 'weight': 9.400, 'count': 0},
  //   {'id': 'PS.153', 'size': 34, 'weight': 9.800, 'count': 0},
  //   {'id': 'PS.152', 'size': 33, 'weight': 9.800, 'count': 0},
  //   {'id': 'PS.151', 'size': 32, 'weight': 8.200, 'count': 0},
  // ];

  List<Map<String, dynamic>> filteredProducts = [];
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> allProducts = [];
  List catlist = [];
  String? banner_baseUrl;
  Color? appBarColor;
  Future<void> _loadAppBarColor() async {
    appBarColor = await AppColorHelper.getAppBarColor();
    setState(() {});
  }
  @override
  void initState() {
    super.initState();

    //filteredProducts = List.from(allProducts); // Initially show all products
    searchController.addListener(_filterProducts);
    _loadAppBarColor();
    callproductlist();
  }

  void _filterProducts() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredProducts = allProducts.where((product) {
        final productName = (product['name'] ?? '').toString().toLowerCase();
        return productName.contains(query);
      }).toList();
    });
  }

  // void _increment(int index) {
  //   setState(() {
  //     filteredProducts[index]['quantity'] = (filteredProducts[index]['quantity'] ?? 0) + 1;
  //   });
  // }
  //
  // void _decrement(int index) {
  //   if (filteredProducts[index]['quantity'] != null && filteredProducts[index]['quantity']! > 0) {
  //     setState(() {
  //       filteredProducts[index]['quantity'] = filteredProducts[index]['quantity']! - 1;
  //     });
  //   }
  // }
  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Color(0xFFFFD700); // Bright Gold for Pending
      case 'approval':
        return Color(0xFF28A745); // Green for Approval
      case 'finishing':
        return Color(0xFF17A2B8); // Cyan for Finishing
      case 'making':
        return Color(0xFFFFC107); // Amber for Making
      case 'done':
        return Color(0xFF6C757D); // Cool Grey for Done
      default:
        return Colors.grey;
    }
  }

  Future<void> callproductlist() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final body = {
      "user_id": prefs.getString('Uid').toString(),
      "order_id": widget.order_id.toString(),
    };

    try {
     // LoadingDialog.show(context, message: "Loading...");
      final response = await ApiHelper().postRequest(ApiConstants.order_details, body);
      print("Order Request: $body");
      print("Order Response: ${response?.data}");

      if (response != null && response.statusCode == 200) {
        // await Future.delayed(Duration(seconds: 1));
        // LoadingDialog.hide(context);
        final data = response.data;
        if (data['status'] == "1") {
          setState(() {
            catlist = data['data'];
            banner_baseUrl = data['image_url'];
            setState(() {
              allProducts = catlist.map<Map<String, dynamic>>((item) {
                return {
                  'name': item['product']['name'] ?? '',
                  'size': item['product']['size'] ?? '',
                  'weight': item['product']['weight'] ?? '',
                  'gross_weight': item['product']['gross_weight'] ?? '',
                  'less_weight': item['product']['less_weight'] ?? '',
                  'hole_size': item['product']['hole_size'] ?? '',
                  'gallery': jsonDecode(item['product']['gallery'] ?? '[]') ?? [],
                  'status': item['status'] ?? 'Pending',
                'quantity': item['quantity'] ?? '',
                };
              }).toList();
              setState(() {
                filteredProducts = List.from(allProducts);
              });
            });
          });
        } else {
          setState(() {
            catlist = []; // empty list
          });
        }
      } else {
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

  String? Dynamic_Color;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('View Order ', style: FontStyles.appbar_heading),
        centerTitle: true,
        backgroundColor: appBarColor ?? Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart_outlined,color: Colors.black,),
            onPressed: () {},
          ),
        ],
      ),
      //drawer: _buildDrawer(),
      body:catlist.isEmpty
          ? Center(
        child: Text(
          "No Data Found",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ): SingleChildScrollView(
        child: Column(
          children: [
            // Search Box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search Product by ID...',
                  prefixIcon: Icon(Icons.search, color: Colors.black),
                  filled: true,
                  fillColor: getColorFromHex(Dynamic_Color.toString()),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Product List
            Container(
              height: MediaQuery.of(context).size.height / 1.35,
              child:filteredProducts.isEmpty
                  ? Center(
                child: Text(
                  'Product Not Found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              )
                  : ListView.builder(
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final category = catlist[index] as Map<String, dynamic>;
                  final imageUrl = "$banner_baseUrl/${category['image']}";
                  final product = filteredProducts[index];
                  List<dynamic> gallery = [];
                  try {
                    gallery = category['product']['gallery'] is String
                        ? List<String>.from(jsonDecode(category['product']['gallery']))
                        : category['product']['gallery'];
                  } catch (e) {
                    gallery = [];
                  }
                  final grossWeight = double.tryParse(product['gross_weight'].toString()) ?? 0;
                  final lessWeight = double.tryParse(product['less_weight'].toString()) ?? 0;
                  final netWeight = grossWeight - lessWeight;
                  return Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Color_Constant.greyshade300, width: 1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 10,left: 10,bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: (){
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailScreen(category['product']["id"].toString(),category['product']["name"].toString(),product['quantity'].toString())));
                                },
                                child: SizedBox(
                                  width: 100,
                                  height: 100,
                                  child: AutoScrollImageSlider(
                                    gallery: gallery,
                                    bannerBaseUrl: banner_baseUrl ?? "",
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(product['name'].toString(), style: FontStyles.font12_bold),
                                    Text(
                                      'Gross Weight: ${grossWeight.toStringAsFixed(2)} gms\n'
                                          'Less Weight: ${lessWeight.toStringAsFixed(2)} gms\n'
                                          'Net Weight: ${netWeight.toStringAsFixed(2)} gms\n'
                                          'Qty: ${product['quantity'].toString()}\n'
                                          '${product['hole_size'] != null && product['hole_size'].toString().isNotEmpty
                                          ? 'Hole Size: ${product['hole_size']} mm'
                                          : ''}',
                                      style: FontStyles.font12_bold,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        /// 🎯 Top-Right Status Badge
                        // Positioned(
                        //   right: 0,
                        //   top: 0,
                        //   child: Container(
                        //     padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        //     decoration: BoxDecoration(
                        //       color:getStatusColor(product['status'] ?? 'Pending'),
                        //       borderRadius: BorderRadius.only(
                        //         topRight: Radius.circular(5),
                        //         bottomLeft: Radius.circular(10),
                        //       ),
                        //     ),
                        //     child: Text(
                        //       product['status'] ?? 'Pending',
                        //       style: TextStyle(
                        //         color: Colors.white,
                        //         fontSize: 10,
                        //         fontWeight: FontWeight.bold,
                        //         letterSpacing: 0.5,
                        //       ),
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  );

                },
              ),
            ),
          ],
        ),
      ),
      // Bottom Navigation Bar with Total Weight and Submit Button
    );
  }


}


class AutoScrollImageSlider extends StatefulWidget {
  final List<dynamic> gallery;
  final String bannerBaseUrl;

  const AutoScrollImageSlider({
    Key? key,
    required this.gallery,
    required this.bannerBaseUrl,
  }) : super(key: key);

  @override
  _AutoScrollImageSliderState createState() => _AutoScrollImageSliderState();
}

class _AutoScrollImageSliderState extends State<AutoScrollImageSlider> {
  late PageController _controller;
  int _currentPage = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: 0);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(Duration(seconds: 3), (Timer timer) {
      if (widget.gallery.isEmpty) return;
      if (_controller.hasClients) {
        _currentPage++;
        if (_currentPage >= widget.gallery.length) {
          _currentPage = 0;
        }
        _controller.animateToPage(
          _currentPage,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.gallery.isEmpty) {
      return Container(height: 140);
    }

    return SizedBox(
      height: 140,
      child: PageView.builder(
        controller: _controller,
        itemCount: widget.gallery.length,
        itemBuilder: (context, index) {
          final imgUrl = "${widget.bannerBaseUrl}/${Uri.encodeComponent(widget.gallery[index])}";
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                imgUrl,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          );
        },
      ),
    );
  }
}
