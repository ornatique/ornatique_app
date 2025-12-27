import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ornatique/ConstantColors/Color_Constant.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Api_Constant/ApiConstants.dart';
import '../Api_Constant/api_helper.dart';
import '../Constant_font/FontStyles.dart';
import '../GlobalDrawer.dart';
import '../LoadingDialog/LoadingDialog.dart';
import 'CartScreen.dart';
import 'ProductDetailScreen.dart';
import 'StaticImageScanScreen.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // List<Map<String, dynamic>> allProducts = [
  //   {'id': 'PS.154', 'size': 29, 'weight': 9.400, 'count': null},
  //   {'id': 'PS.153', 'size': 34, 'weight': 9.800, 'count': null},
  //   {'id': 'PS.152', 'size': 33, 'weight': 9.800, 'count': null},
  //   {'id': 'PS.151', 'size': 32, 'weight': 8.200, 'count': null},
  //   {'id': 'PS.150', 'size': 30, 'weight': 8.500, 'count': null},
  //   {'id': 'PS.154', 'size': 29, 'weight': 9.400, 'count': null},
  //   {'id': 'PS.153', 'size': 34, 'weight': 9.800, 'count': null},
  //   {'id': 'PS.152', 'size': 33, 'weight': 9.800, 'count': null},
  //   {'id': 'PS.151', 'size': 32, 'weight': 8.200, 'count': null},
  //   {'id': 'PS.150', 'size': 30, 'weight': 8.500, 'count': null},
  // ];

  List<Map<String, dynamic>> filteredProducts = [];
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> allProducts = [];
  String? banner_baseUrl;
  int cartCount = 0;
  List<int> _counts = [];
  Timer? _debounce;
  List<TextEditingController> _controllers = [];
  FocusNode _focusNode = FocusNode();
  late TextEditingController _controller;
  Color? appBarColor;
  Color? appBGColor;
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
  void initState() {
    super.initState();
    //filteredProducts = List.from(allProducts); // Initially show all products
    _loadAppBarColor();
    searchController.addListener(_filterProducts);

    //addToCart(0);
    callproductlist();
  }

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

  // Calculate total weight dynamically
  double getTotalWeight() {
    double totalWeight = 0.0;

    for (var product in allProducts) {
      if (product == null || product == null) continue;
      final gross = double.tryParse(product['gross_weight'].toString()) ?? 0.0;
      final less = double.tryParse(product['less_weight'].toString()) ?? 0.0;
      final count = product['count'] ?? 0;

      double netWeight = (gross - less) * count;
      totalWeight += netWeight;
    }

    return totalWeight;
  }

  Future<void> callproductlist() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final body = {
      "user_id": prefs.getString('Uid').toString(),
    };

    try {
      //LoadingDialog.show(context, message: "Loading...");
      final response = await ApiHelper().postRequest(ApiConstants.product, body);
      print("product Request: $body");
      print("product Response: ${response?.data}");

      if (response != null && response.statusCode == 200) {
        //LoadingDialog.hide(context);
        final data = response.data;

        if (data['status'] == "1") {
          List<dynamic> rawList = data['data'];
          banner_baseUrl = data['image_url'];

          // Map and add count to each item
          allProducts = rawList.map<Map<String, dynamic>>((item) {
            return {
              'id': item['id'] ?? '',
              'size': item['size'] ?? '',
              'name': item['name'] ?? '',
              'weight': item['weight'] ?? '',
              'gross_weight': item['gross_weight'] ?? '',
              'less_weight': item['less_weight'] ?? '',
              'hole_size': item['hole_size'] ?? '',
              'count': 0,
              'gallery': jsonDecode(item['gallery'] ?? '[]') ?? [], // Decode gallery images (from string to list)
            };
          }).toList();
          _counts.clear();
          _controllers.clear();
          for (var product in allProducts) {
            _counts.add(product['count'] ?? 1);
            _controllers.add(TextEditingController(text: (product['count'] ?? 1).toString()));
          }
          setState(() {
            filteredProducts = List.from(allProducts);
          });
        } else {
          setState(() {
            allProducts = [];
            filteredProducts = [];
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

  void _filterProducts() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredProducts = allProducts.where((product) {
        final productName = (product["name"] ?? '').toString().toLowerCase();
        final productId = (product["id"] ?? '').toString().toLowerCase();
        final productSize = (product["size"] ?? '').toString().toLowerCase();
        final productNetWeight = (product["weight"] ?? '').toString().toLowerCase();
        return productName.contains(query) || productId.contains(query) || productSize.contains(query) || productNetWeight.contains(query);
      }).toList();
    });
  }


  void _increment(int index,int id) {
    setState(() {
      filteredProducts[index]['count'] = (filteredProducts[index]['count'] ?? 0) + 1;
      _counts[index]++;
      _controllers[index].text = _counts[index].toString();
      //addToCartApi(id,filteredProducts[index]['count']);
      addToCartApi(id, _counts[index]);
    });
  }

  void _decrement(int index,int id) {
    if (filteredProducts[index]['count'] != null && filteredProducts[index]['count']! > 0) {
      setState(() {
        filteredProducts[index]['count'] = filteredProducts[index]['count']! - 1;
        _counts[index]--;
        _controllers[index].text = _counts[index].toString();
        addToCartApi(id, _counts[index]);
      });
    }
  }



  Future<void> addToCartApi(int productId, int quantity) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final body = {
      "user_id": prefs.getString('Uid').toString(),
      "product_id": productId.toString(),
      "quantity": quantity.toString(),
    };

    try {
      //LoadingDialog.show(context, message: "Updating Cart...");
      final response = await ApiHelper().postRequest(ApiConstants.add_cart, body);
      //LoadingDialog.hide(context);
      print("cart add  Request: $body");
      print("cart add Response: ${response?.data}");
      if (response != null && response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == "1") {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(content: Text("Cart updated successfully!")),
          // );
        } else {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(content: Text("Failed to update cart.")),
          // );
        }
      } else {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text("Server error while updating cart.")),
        // );
      }
    } catch (e) {
      LoadingDialog.hide(context);
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text("Error: $e")),
      // );
    }
  }

  Future<void> _loadAppBarColor() async {
    appBarColor = await AppColorHelper.getAppBarColor();
    appBGColor = await AppColorHelper.getBackgroundColor();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Product', style: FontStyles.appbar_heading),
        centerTitle: true,
        backgroundColor: appBarColor ?? Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          Stack(
            children: [
              GestureDetector(
                  onTap: () async {
                    final result = await  Navigator.push(context,
                        MaterialPageRoute(builder:
                            (context) =>
                            CartScreen()
                        )
                    );
                    if (result == 'updated') {
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      setState(() {
                        // તારી refresh logic અહીં લાવ (example: fetchProductList())
                        cartCount = int.parse(prefs.getString("cart_count").toString());
                      });
                    }
                  },
                  child: Icon(Icons.shopping_cart_outlined, color:Color_Constant.black)),
              // if (cartCount > 0)
              //   Positioned(
              //     right: 0,
              //     bottom: 6,
              //     child: Container(
              //       padding: EdgeInsets.all(4),
              //       decoration: BoxDecoration(color: Colors.pink, shape: BoxShape.circle),
              //       child: Text(
              //         "$cartCount",
              //         style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              //       ),
              //     ),
              //   ),

            ],
          ),
          // GestureDetector(
          //   onTap: (){
          //     // Navigator.push(
          //     //   context,
          //     //   MaterialPageRoute(builder: (context) => DirectScanScreen()),
          //     // );
          //   },
          //     child: Icon(Icons.scanner, color:Color_Constant.red,size: 30,))
        ],
      ),
      drawer: GlobalDrawer(), // Add the drawer here
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Search Box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search Product by Name...',
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
              height: MediaQuery.of(context).size.height/1.3,
              child: filteredProducts.isEmpty
                  ? Center(
                child: Text(
                  'Product Not Found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              )
                  : ListView.builder(
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  final List<dynamic> gallery = product['gallery'];
                  // final imageName = gallery[imgIndex];
                  // final imageNameeUrl = '$banner_baseUrl/$imageName';
                  final grossWeight = double.tryParse(product['gross_weight'].toString()) ?? 0;
                  final lessWeight = double.tryParse(product['less_weight'].toString()) ?? 0;
                  final netWeight = grossWeight - lessWeight;
                  print(gallery.toString());
                  return Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Color_Constant.greyshade300, width: 1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    margin: EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: (){
                              Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailScreen(product["id"].toString(),product["name"].toString(),_counts[index].toString())));
                            },
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width:100,height: 100,
                                  child: AutoScrollImageSlider(
                                    gallery: gallery,
                                    bannerBaseUrl: banner_baseUrl ?? "",
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      //Text("ID : "+ product['id'].toString(), style: FontStyles.font12_bold),
                                      Text("Name : "+ product['name'].toString(), style: FontStyles.font12_bold),
                                      SizedBox(height: 0),
                                      // Text(
                                      //   'Size: ${product['size']} mm\nWeight: ${product['gross_weight']} gms\nHole size: 0 mm',
                                      //   style: FontStyles.font12_bold,
                                      // ),

                                      Text(
                                        '${product['size'] != null && product['size'].toString().isNotEmpty ? 'Size: ${product['size']} mm\n' : ''}'
                                            'G.Wt: ${product['gross_weight'].toString()} gms\n'
                                            '${product['less_weight'] != null && product['less_weight'].toString().isNotEmpty ? 'L.Wt: ${product['less_weight']} gms\n' : ''}'
                                            'N.Wt: ${netWeight} gms\n'
                                            '${product['hole_size'] != null && product['hole_size'].toString().isNotEmpty ? 'Hole size: ${product['hole_size']} mm ' : ''}',
                                        style: FontStyles.font12_bold,
                                      )
                                    ],
                                  ),
                                ),
                                SizedBox(width: 10),

                              ],
                            ),
                          ),
                          // Row(
                          //   mainAxisAlignment: MainAxisAlignment.end,
                          //   //mainAxisSize: MainAxisSize.min,
                          //   children: [
                          //     GestureDetector(
                          //       onTap: () => _decrement(index,product["id"]),
                          //       child: Container(
                          //         decoration: BoxDecoration(
                          //           shape: BoxShape.circle,
                          //           color: Color_Constant.red,
                          //         ),
                          //         padding: const EdgeInsets.all(5),
                          //         child: const Icon(Icons.remove, color: Colors.white, size: 20),
                          //       ),
                          //     ),
                          //     SizedBox(width: 10),
                          //     AnimatedContainer(
                          //       duration: const Duration(milliseconds: 300),
                          //       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          //       decoration: BoxDecoration(
                          //         color: Color_Constant.Blue300,
                          //         borderRadius: BorderRadius.circular(5),
                          //       ),
                          //       child: Text(
                          //         product['count'] == null ? '0' : '${product['count']}',
                          //         style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
                          //       ),
                          //     ),
                          //     SizedBox(width: 10),
                          //     GestureDetector(
                          //       onTap: () => _increment(index,product["id"]),
                          //       child: Container(
                          //         decoration: BoxDecoration(
                          //           shape: BoxShape.circle,
                          //           color: Color_Constant.green,
                          //         ),
                          //         padding: const EdgeInsets.all(5),
                          //         child: const Icon(Icons.add, color: Colors.white, size: 20),
                          //       ),
                          //     ),
                          //   ],
                          // ),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Card(
                                  elevation: 2, // Shadow effect for the card
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(2), // Rounded corners for the card
                                  ),
                                  child: Container(
                                    height: 35,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: Colors.grey, // Border color
                                        width: 0, // Border width
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        GestureDetector(
                                          onTap: () => _decrement(index,product["id"]),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.rectangle,
                                              //color: Colors.grey.shade200, // Slight background color for button
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(2),
                                                bottomLeft: Radius.circular(2),
                                              ),
                                            ),
                                            padding: const EdgeInsets.only(left: 5,right: 5),
                                            child: const Icon(Icons.remove, color: Colors.black, size: 25),
                                          ),
                                        ),
                                        // AnimatedContainer(
                                        //   duration: const Duration(milliseconds: 300),
                                        //   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                        //   decoration: BoxDecoration(
                                        //     border: Border(
                                        //       right: BorderSide(color: Colors.grey, width: 1),
                                        //       left: BorderSide(color: Colors.grey, width: 1),
                                        //     ),
                                        //   ),
                                        //   child: Text(
                                        //     '${product['count'] ?? 0}',
                                        //     style: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold),
                                        //   ),
                                        // ),
                                        Container(
                                          width: 40,
                                          decoration: BoxDecoration(
                                            border: Border(
                                              right: BorderSide(color: Colors.grey, width: 1),
                                              left: BorderSide(color: Colors.grey, width: 1),
                                            ),
                                          ),
                                          child: TextField(
                                            //focusNode: _focusNode,
                                            controller: _controllers[index],
                                            keyboardType: TextInputType.number,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              isDense: true,
                                              contentPadding: EdgeInsets.symmetric(vertical: 0),
                                            ),
                                            onTap: () {
                                              if (_controllers[index].text == "0") {
                                                _controllers[index].clear();
                                              }
                                            },
                                            onChanged: (value) {
                                              if (_debounce?.isActive ?? false) _debounce!.cancel();
                                              _debounce = Timer(const Duration(milliseconds: 500), () {
                                                int? newVal = int.tryParse(value);
                                                if (newVal != null && newVal > 0) {
                                                  setState(() {
                                                   // product['count'] = newVal;
                                                    _counts[index] = newVal;
                                                    addToCartApi(product["id"], newVal);
                                                    _focusNode.requestFocus();
                                                  });
                                                }
                                              });

                                            },
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => _increment(index,product["id"]),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.rectangle,
                                              //color: Colors.grey.shade200, // Slight background color for button
                                              borderRadius: BorderRadius.only(
                                                topRight: Radius.circular(2),
                                                bottomRight: Radius.circular(2),
                                              ),
                                            ),
                                            padding: const EdgeInsets.only(left: 5,right: 5),
                                            child: const Icon(Icons.add, color: Colors.black, size: 25),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // bottomNavigationBar: Container(
      //   padding: EdgeInsets.only(
      //     left: 16,
      //     right: 16,
      //     bottom: MediaQuery.of(context).padding.bottom + 12,
      //     top: 12,
      //   ),
      //   decoration: BoxDecoration(
      //     color: Colors.white,
      //     borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      //     boxShadow: [
      //       BoxShadow(
      //         color: Colors.black12,
      //         blurRadius: 10,
      //         offset: Offset(0, -4),
      //       )
      //     ],
      //   ),
      //   child: Row(
      //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //     children: [
      //       Row(
      //         children: [
      //           Icon(Icons.scale, color: Colors.grey[700]),
      //           SizedBox(width: 8),
      //           Text(
      //             "Total: ${getTotalWeight().toStringAsFixed(2)} gms",
      //             style: FontStyles.font16_bold.copyWith(color: Colors.black87),
      //           ),
      //         ],
      //       ),
      //       ElevatedButton.icon(
      //         icon: Icon(Icons.shopping_cart_outlined, color: Colors.white),
      //         label: Text("Add to Cart", style: FontStyles.button.copyWith(color: Colors.white)),
      //         style: ElevatedButton.styleFrom(
      //           backgroundColor: Colors.blueAccent,
      //           padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      //           shape: RoundedRectangleBorder(
      //             borderRadius: BorderRadius.circular(12),
      //           ),
      //           elevation: 3,
      //         ),
      //         onPressed: () {
      //           Navigator.push(
      //             context,
      //             MaterialPageRoute(builder: (context) => CartScreen()),
      //           );
      //         },
      //       ),
      //     ],
      //   ),
      // ),
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
              child:
              // Image.network(
              //   imgUrl,
              //   fit: BoxFit.cover,
              //   width: double.infinity,
              // ),
              CachedNetworkImage(
                imageUrl: imgUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => Center(
                  child: Icon(Icons.error),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
