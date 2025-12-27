import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ornatique/Screens/ProductDetailScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Api_Constant/ApiConstants.dart';
import '../Api_Constant/api_helper.dart';
import '../ConstantColors/Color_Constant.dart';
import '../Constant_font/FontStyles.dart';
import '../LoadingDialog/LoadingDialog.dart';
import '../OrderConfirmationDialog.dart';
import '../VideolistScreen.dart';
import 'CartScreen.dart';
import 'MainCategoryScreen.dart';
import 'MediaPage.dart';

class JewelleryScreen extends StatefulWidget {
  String? cat_id, subcat_id,subcat_name;
  JewelleryScreen(this.cat_id, this.subcat_id,this.subcat_name, {super.key});

  @override
  _JewelleryScreenState createState() => _JewelleryScreenState();
}

class _JewelleryScreenState extends State<JewelleryScreen> {
  int cartCount = 0;
  Map<int, int> cartItems = {};
  Set<int> wishlistProductIds = {};
  List<dynamic> catlist = [];
  String? banner_baseUrl;
  List<int> _counts = [];
  Timer? _debounce;
  List<TextEditingController> _controllers = [];
  // void addToCart(int productId) {
  //   setState(() {
  //     cartItems[productId] = (cartItems[productId] ?? 0) + 1;
  //     cartCount++;
  //   });
  //   addToCartApi(productId, cartCount);
  // }


  Color? appBarColor;

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

  Future<void> _increment(int productId,int index) async {
    setState(() {
      catlist[index]['count'] = (catlist[index]['count'] ?? 0) + 1;
      _counts[index]++;
      _controllers[index].text = _counts[index].toString();
    });
    await addToCartApi(productId,  _counts[index]);
    await saveProductQtyToPrefs(productId, _counts[index]); // ✅ Save to SharedPreferences
  }

  Future<void> _decrement(int productId, int index) async {
    if ((catlist[index]['count'] ?? 0) > 0) {
      setState(() {
        catlist[index]['count'] = (catlist[index]['count'] ?? 0) - 1;
        _counts[index]--;
        _controllers[index].text = _counts[index].toString();
      });
      await addToCartApi(productId,  _counts[index]);
      await saveProductQtyToPrefs(productId, _counts[index]); // ✅ Save to SharedPreferences
    }
  }

  // Calculate total weight dynamically
  double getTotalWeight() {
    double totalWeight = 0.0;

    for (var product in catlist) {
      if (product == null || product == null) continue;
      final gross = double.tryParse(product['gross_weight'].toString()) ?? 0.0;
      final less = double.tryParse(product['less_weight'].toString()) ?? 0.0;
      final count = product['count'] ?? 0;

      double netWeight = (gross - less) * count;
      totalWeight += netWeight;
    }

    return totalWeight;
  }

  Future<void> addToCartApi(int productId, int quantity) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final body = {
      "user_id": prefs.getString('Uid').toString(),
      "product_id": productId.toString(),
      "quantity": quantity.toString(),
    };

    try {
      // LoadingDialog.show(context, message: "Loading...");
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

  Future<void> addwishlist(int productId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final body = {
      "user_id": prefs.getString('Uid').toString(),
      "product_id": productId.toString(),
      "is_key": "1",
    };

    try {
      //LoadingDialog.show(context, message: "Loading...");
      final response = await ApiHelper().postRequest(ApiConstants.addwishlist, body);
     // LoadingDialog.hide(context);

      if (response != null && response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == "1") {
          setState(() {
            wishlistProductIds.add(productId);
          });
          // Fluttertoast.showToast(
          //   msg: data['message'].toString(),
          //   toastLength: Toast.LENGTH_SHORT,
          //   gravity: ToastGravity.BOTTOM,
          //   backgroundColor: Colors.black87,
          //   textColor: Colors.white,
          //   fontSize: 16.0,
          // );
        }
      } else {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text("Failed to add to Wishlist")),
        // );
      }
    } catch (e) {
      LoadingDialog.hide(context);
      print("❌ Add Wishlist Error: $e");
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text("Add Wishlist Error")),
      // );
    }
  }

  Future<void> removewishlist(int productId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final body = {
      "user_id": prefs.getString('Uid').toString(),
      "product_id": productId.toString(),
      "is_key": "0",
    };

    try {
     // LoadingDialog.show(context, message: "Loading...");
      final response = await ApiHelper().postRequest(ApiConstants.removewishlist, body);
     // LoadingDialog.hide(context);

      if (response != null && response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == "1") {
          setState(() {
            wishlistProductIds.remove(productId);
          });
          // Fluttertoast.showToast(
          //   msg: data['message'].toString(),
          //   toastLength: Toast.LENGTH_SHORT,
          //   gravity: ToastGravity.BOTTOM,
          //   backgroundColor: Colors.black87,
          //   textColor: Colors.white,
          //   fontSize: 16.0,
          // );
        }
      } else {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text("Failed to remove from Wishlist")),
        // );
      }
    } catch (e) {
      LoadingDialog.hide(context);
      print("❌ Remove Wishlist Error: $e");
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text("Remove Wishlist Error")),
      // );
    }
  }

  Future<void> callproductlist() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final body = {
      "user_id": prefs.getString('Uid').toString(),
      "category_id": widget.cat_id.toString(),
      "subcategory_id": widget.subcat_id.toString(),
    };

    try {
     // LoadingDialog.show(context, message: "Loading...");
      final response = await ApiHelper().postRequest(ApiConstants.product, body);
      print("product Request: $body");
      print("product Response: ${response?.data}");

      if (response != null && response.statusCode == 200) {
        // await Future.delayed(Duration(seconds: 1));
        // LoadingDialog.hide(context);
        final data = response.data;
        if (data['status'] == "1") {
          setState(() {
            catlist = data['data'];
            banner_baseUrl = data['image_url'];
            wishlistProductIds.clear();
            _counts.clear();
            _controllers.clear();
            for (var product in catlist) {
              _counts.add(product['count'] ?? 0);
              _controllers.add(TextEditingController(text: (product['count'] ?? 0).toString()));
            }
            for (var product in catlist) {
              if (product['is_key'] == "1") {
                wishlistProductIds.add(product['id']);
              }
            }

            /// 🔥 SORT LOGIC (IMPORTANT)
            /// order_confirm = 0 → TOP
            /// order_confirm = 1 → BOTTOM
            catlist.sort((a, b) {
              final int aConfirm = int.tryParse(a['order_confirm']?.toString() ?? '0') ?? 0;
              final int bConfirm = int.tryParse(b['order_confirm']?.toString() ?? '0') ?? 0;
              return aConfirm.compareTo(bConfirm); // ASCENDING
            });

          });
          await loadSavedQtyToUI();
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

  Future<void> saveProductQtyToPrefs(int productId, int quantity) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, String> savedQtyMap = {};
    if (prefs.containsKey('product_qty_map')) {
      savedQtyMap = Map<String, String>.from(json.decode(prefs.getString('product_qty_map')!));
    }
    savedQtyMap[productId.toString()] = quantity.toString();
    await prefs.setString('product_qty_map', json.encode(savedQtyMap));
  }

  @override
  void initState() {
    super.initState();
    _loadAppBarColor();
    addToCart(0);
    callproductlist();
  }

  Future<void> _loadAppBarColor() async {
    appBarColor = await AppColorHelper.getAppBarColor();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      resizeToAvoidBottomInset: true,  // Allow UI resize when keyboard opens
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildGridView()),
          // _buildBottomBar(),
        ],
      ),
      // Bottom Navigation Bar with Total Weight and Submit Button
      bottomNavigationBar: Container(
        height: 110,
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom,
          top: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: Offset(0, -3),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Total Weight: ${getTotalWeight().toStringAsFixed(3)} gms",style: FontStyles.font16_bold),
            //Text("Total Weight:", style: FontStyles.font16_bold),
            // Text("${getTotalWeight().toStringAsFixed(3)} gms", style: FontStyles.font16_bold),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[300],
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                //_addOrder();
                Navigator.push(context,
                    MaterialPageRoute(builder:
                        (context) =>
                        CartScreen()
                    )
                );
              },
              child: Text("Add to Cart", style: FontStyles.button),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: appBarColor ?? Colors.white,
      elevation: 0,
      centerTitle: true,
      title: Text(widget.subcat_name.toString(), style: FontStyles.appbar_heading),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context, 'updated'),
        ),
      actions: [
        Icon(Icons.favorite_border, color: Colors.transparent),
        SizedBox(width: 10),
        /// 👇 Play Video Button
        IconButton(
          icon: Icon(Icons.play_circle_outline, color: Colors.red,size: 30,),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoListScreen(widget.cat_id.toString(),widget.subcat_id.toString()),
              ),
            );
          },
        ),
        Stack(
          children: [

            GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CartScreen()),
                );

                if (result == 'updated') {
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  setState(() {
                    // તારી refresh logic અહીં લાવ (example: fetchProductList())
                   cartCount = int.parse(prefs.getString("cart_count").toString());
                  });
                }
              },
              child: Icon(Icons.shopping_cart_outlined, color: Colors.black),
            ),
            // if (cartCount > 0)
            //   Positioned(
            //     right: 0,
            //     bottom: 6,
            //     child: Container(
            //       padding: EdgeInsets.all(4),
            //       decoration: BoxDecoration(color: Color_Constant.pink, shape: BoxShape.circle),
            //       child: Text(
            //         "$cartCount",
            //         style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            //       ),
            //     ),
            //   ),
          ],
        ),
        SizedBox(width: 10),
      ],
    );
  }

  Widget _buildGridView() {
    if (catlist.isEmpty) {
      return Center(
        child: Text(
          "No Data Found",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      );
    }
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    double getAspectRatio(double height) {
      if (height > 800) return 0.75;
      else if (height <= 800) return 0.65;
      else return 0.45;
    }
    return Padding(
      padding: EdgeInsets.all(10),
      child: GridView.builder(
        itemCount: catlist.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 5,
          mainAxisSpacing: 10,
          childAspectRatio: getAspectRatio(screenHeight),
        ),
        itemBuilder: (context, index) {
          final category = catlist[index] as Map<String, dynamic>;
          final imageUrl = "$banner_baseUrl/${category['image']}";
          return _buildProductCard(category, imageUrl,index);
        },
      ),
    );
  }



  Widget _buildProductCard(Map<String, dynamic> product, String imageUrl,int index) {
    int quantity = cartItems[product["id"]] ?? 0;
    bool isWishlisted = wishlistProductIds.contains(product["id"]);
    List<dynamic> gallery = [];
    try {
      gallery = product['gallery'] is String
          ? List<String>.from(jsonDecode(product['gallery']))
          : product['gallery'];
    } catch (e) {
      gallery = [];
    }

   // print(gallery.length);

    final grossWeight = double.tryParse(product['gross_weight'].toString()) ?? 0;
    final lessWeight = double.tryParse(product['less_weight'].toString()) ?? 0;
    final netWeight = grossWeight - lessWeight;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Color_Constant.greyshade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              // GestureDetector(
              //   onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailScreen(product["id"].toString(),product["name"].toString()))),
              //   child: ClipRRect(
              //     borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
              //     child: Image.network(imageUrl, height: 140, fit: BoxFit.cover, width: double.infinity),
              //   ),
              // ),

              GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailScreen(product["id"].toString(),product["name"].toString(),_counts[index].toString())));

                  print("Returned result: $result"); // ✅ Check this first

                  if (result is Map<String, dynamic>) {
                    String updatedId = result['id'].toString();
                    int updatedQty = int.tryParse(result['qty'].toString()) ?? 0;

                    print("updatedId: $updatedId, updatedQty: $updatedQty"); // ✅ Debug

                    int i = catlist.indexWhere((item) => item['id'].toString() == updatedId);
                    if (i != -1) {
                      setState(() {
                        catlist[i]['count'] = updatedQty;
                        _counts[i] = updatedQty;
                        _controllers[i].text = updatedQty.toString();
                        print("✅ Updated qty in setState: $updatedQty");
                      });
                    } else {
                      print("❌ ID not found in catlist: $updatedId");
                    }
                  } else {
                    print("❌ result was null or not a valid map");
                  }
                },
                child: AutoScrollImageSlider(
                  gallery: gallery,
                  bannerBaseUrl: banner_baseUrl ?? "",
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  //width: 140,
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: product["label_product"] == null || product["label_product"].toString() == "null"
                        ? null
                        : getColorFromHex(product["color"]),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(product["label_product"].toString()=="null"?"":product["label_product"].toString(), style: FontStyles.font8_white_color),
                ),
              ),
              if (product["order_confirm"] == "1")
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red, // ordered color
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      "ORDERED",
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 4,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    isWishlisted
                        ? removewishlist(product["id"])
                        : addwishlist(product["id"]);
                  },
                  child: Icon(
                    isWishlisted ? Icons.favorite : Icons.favorite_border,
                    color: isWishlisted ? Colors.red : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 5),
          // Padding(
          //   padding: EdgeInsets.symmetric(horizontal: 4),
          //   child: Row(
          //     children: [
          //       Icon(Icons.star, color: Color_Constant.accent, size: 16),
          //       Text("${4.9}", style: FontStyles.font12_bold),
          //     ],
          //   ),
          // ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              product["name"].toString(),
              style: FontStyles.offer_heading,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          // Padding(
          //   padding: EdgeInsets.symmetric(horizontal: 4),
          //   child: Text(
          //     "G.Wt : ${product['gross_weight'].toString() + " gms"}",
          //     style: FontStyles.font12_bold,
          //     maxLines: 2,
          //     overflow: TextOverflow.ellipsis,
          //     textAlign: TextAlign.center,
          //   ),
          // ),
          // Padding(
          //   padding: EdgeInsets.symmetric(horizontal: 4),
          //   child: Text(
          //     "L.Wt : ${product['less_weight'].toString() + " gms"}",
          //     style: FontStyles.font12_bold,
          //     maxLines: 2,
          //     overflow: TextOverflow.ellipsis,
          //     textAlign: TextAlign.center,
          //   ),
          // ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              "Wt : ${netWeight.toString() + " gms"}",
              style: FontStyles.font12_bold,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          // Padding(
          //   padding: EdgeInsets.symmetric(horizontal: 4),
          //   child: Text(
          //     product['hole_size'].toString()=="null"?"":"Hole Size : ${product['hole_size'].toString()+  " mm"}",
          //     style: FontStyles.font12_bold,
          //     maxLines: 2,
          //     overflow: TextOverflow.ellipsis,
          //     textAlign: TextAlign.center,
          //   ),
          // ),
          //Spacer(),

          // Padding(
          //   padding: EdgeInsets.all(5),
          //   child: Align(
          //     alignment: Alignment.center,
          //     child: ElevatedButton(
          //       style: ElevatedButton.styleFrom(
          //         backgroundColor: Color_Constant.blueAccent,
          //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          //       ),
          //       onPressed: () => addToCart(product["id"]),
          //       child: Text(
          //         quantity > 0 ? "Added ($quantity)" : "Add To Cart",
          //         style: FontStyles.button,
          //       ),
          //     ),
          //   ),
          // ),
          // Padding(
          //   padding: const EdgeInsets.all(10.0),
          //   child: Row(
          //     //mainAxisSize: MainAxisSize.min,
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: [
          //       GestureDetector(
          //         onTap: () => _decrement(product["id"],index),
          //         child: Container(
          //           decoration: BoxDecoration(
          //             shape: BoxShape.circle,
          //             color: Color_Constant.red,
          //           ),
          //           padding: const EdgeInsets.all(5),
          //           child: const Icon(Icons.remove, color: Colors.white, size: 20),
          //         ),
          //       ),
          //       SizedBox(width: 20),
          //       AnimatedContainer(
          //         duration: const Duration(milliseconds: 300),
          //         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          //         decoration: BoxDecoration(
          //           color: Color_Constant.Blue300,
          //           borderRadius: BorderRadius.circular(5),
          //         ),
          //         child: Text(
          //           '${product['count'] ?? 0}',
          //           style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
          //         ),
          //
          //       ),
          //       SizedBox(width: 20),
          //       GestureDetector(
          //         onTap: () => _increment(product["id"],index),
          //         child: Container(
          //           decoration: BoxDecoration(
          //             shape: BoxShape.circle,
          //             color: Color_Constant.green,
          //           ),
          //           padding: const EdgeInsets.all(5),
          //           child: const Icon(Icons.add, color: Colors.white, size: 20),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),

          Padding(
            padding: const EdgeInsets.all(10),
            child: Card(
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
                      onTap: () => _decrement(product["id"],index),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          //color: Colors.grey.shade200, // Slight background color for button
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(2),
                            bottomLeft: Radius.circular(2),
                          ),
                        ),
                        padding: const EdgeInsets.only(right: 10),
                        child: const Icon(Icons.remove, color: Colors.black, size: 25),
                      ),
                    ),
                    // AnimatedContainer(
                    //   duration: const Duration(milliseconds: 300),
                    //   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
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
                      width: 50,
                      // Make this container width fixed so textfield is consistent
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Colors.grey, width: 1),
                          left: BorderSide(color: Colors.grey, width: 1),
                        ),
                      ),
                      child: TextField(
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
                                saveProductQtyToPrefs(product["id"], newVal); // ✅ Save to SharedPreferences
                               // _focusNode.requestFocus();
                              });
                            }
                          });

                        },
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _increment(product["id"],index),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          //color: Colors.grey.shade200, // Slight background color for button
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(2),
                            bottomRight: Radius.circular(2),
                          ),
                        ),
                        padding: const EdgeInsets.only(left: 10),
                        child: const Icon(Icons.add, color: Colors.black, size: 25),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Color_Constant.greyshade300))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildBottomButton(Icons.filter_list, "Filter"),
          _buildBottomButton(Icons.sort, "Sort By"),
        ],
      ),
    );
  }

  Widget _buildBottomButton(IconData icon, String label) {
    return Expanded(
      child: TextButton.icon(
        onPressed: () {},
        icon: Icon(icon, color: Color_Constant.black),
        label: Text(label, style: TextStyle(fontSize: 16)),
      ),
    );
  }

  // Function to get Color from hex string
  Color getColorFromHex(String? hexColor) {
    if (hexColor == null || hexColor == "null") {
      return Color_Constant.amber700; // Default color if null
    }
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor"; // Adding opacity (FF for full opacity)
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  Future<void> _addOrder() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      LoadingDialog.show(context, message: "Loading...");
      final body = {
        "user_id": prefs.getString('Uid').toString(),
      };
      final response = await ApiHelper().postRequest(ApiConstants.add_order, body);
      LoadingDialog.hide(context);

      print("Add order Request: $body");
      print("Add order Response: ${response?.data}");

      if (response != null && response.statusCode == 200) {
        final result = response.data;
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text(result['status'] == "1"
        //         ? "Order added successfully!"
        //         : "Failed to add order."),
        //   ),
        // );

        final result1 = await OrderConfirmationDialog.show(context);

        if (result1 == true) {
          setState(() {
            print(result.toString());
            callproductlist();  // Cart refresh
          });

        }

      } else {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text("Something went wrong!")),
        // );
      }
    } catch (e) {
      LoadingDialog.hide(context);
      print("❌ Add Order API Error: $e");
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text("Error placing order.")),
      // );
    }
  }

  Future<void> loadSavedQtyToUI() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('product_qty_map')) return;

    Map<String, String> savedQtyMap = Map<String, String>.from(json.decode(prefs.getString('product_qty_map')!));

    for (int i = 0; i < catlist.length; i++) {
      String productId = catlist[i]['id'].toString();
      if (savedQtyMap.containsKey(productId)) {
        int savedQty = int.tryParse(savedQtyMap[productId]!) ?? 0;
        _counts[i] = savedQty;
        _controllers[i].text = savedQty.toString();
        catlist[i]['count'] = savedQty;
      }
    }

    setState(() {}); // Refresh UI
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
      height: 150,
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
                width: double.infinity,
                imageUrl:imgUrl,
                //height: 150,
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
