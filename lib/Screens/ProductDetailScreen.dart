import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_viewer_pro/image_viewer_pro.dart';
import 'package:ornatique/ConstantColors/Color_Constant.dart';
import 'package:ornatique/Constant_font/FontStyles.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Api_Constant/ApiConstants.dart';
import '../Api_Constant/api_helper.dart';
import '../LoadingDialog/LoadingDialog.dart';
import 'CartScreen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String product_id, name,qty;
  const ProductDetailScreen(this.product_id, this.name,this.qty, {super.key});

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int cartCount = 0;
  int currentIndex = 0;
  final PageController _pageController = PageController();
  Timer? _bannerTimer;
  Timer? _offerTimer;
  int _currentOfferIndex = 0;
  int _count = 0;
  Map<int, bool> favoriteItems = {};
  String? name, weight, less_weight, size, hole_size, gross_weight, net_weight,other_charge;
  double grossWeight = 0.851; // Default static value
  List<dynamic> images = []; // 🔥 initially empty list
  List home_offer = [];
  Map<String, dynamic> product = {};
  Color? appBarColor;
  bool isLoading = true; // For loading spinner before API data arrives
  late TextEditingController _controller;
  bool isWishlisted = false;
  @override
  void initState() {
    super.initState();
    _loadAppBarColor();
    calloffer();
    callproductdetails();
    _controller = TextEditingController(text: _count.toString());
    // _bannerTimer = Timer.periodic(Duration(seconds: 5), (Timer timer) {
    //   if (images.isNotEmpty) {
    //     if (currentIndex < images.length - 1) {
    //       currentIndex++;
    //     } else {
    //       currentIndex = 0;
    //     }
    //     _pageController.animateToPage(
    //       currentIndex,
    //       duration: const Duration(milliseconds: 100),
    //       curve: Curves.easeInOut,
    //     );
    //   }
    // });

    _pageController.addListener(() {
      if (mounted) {
        setState(() {
          currentIndex = _pageController.page!.round();
        });
      }
    });
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

  Future<void> _loadAppBarColor() async {
    appBarColor = await AppColorHelper.getAppBarColor();
    setState(() {});
  }

  Future<void> callproductdetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final body = {
      "user_id": prefs.getString('Uid').toString(),
      "product_id": widget.product_id.toString(),
    };

    try {
      // LoadingDialog.show(context, message: "Loading...");
      final response = await ApiHelper().postRequest(
        ApiConstants.product_details,
        body,
      );
      print("product Request: $body");
      print("product Response: ${response?.data}");
      if (response != null && response.statusCode == 200) {
        //  LoadingDialog.hide(context);
        final data = response.data;
        if (data['status'] == "1") {
          setState(() {
            product = data['data'];
            String baseUrl = data['image_url'];
            name = product['name'].toString();
            size = product['size'].toString();
            hole_size = product['hole_size'].toString();
            weight = product['weight'].toString();
            gross_weight = product['gross_weight'].toString();
            less_weight = product['less_weight'].toString();
            other_charge = product['charge'].toString();

            _controller.text=widget.qty.toString();
            _count = int.parse(widget.qty.toString());
            double gross = double.tryParse(gross_weight.toString()) ?? 0.0;
            double less = double.tryParse(less_weight.toString()) ?? 0.0;
            net_weight = (gross - less).toStringAsFixed(3); // example: 5.000

            if (product['gallery'] != null) {
              if (product['gallery'] is String) {
                images = List<String>.from(jsonDecode(product['gallery']));
              } else {
                images = List<String>.from(product['gallery']);
              }

              // Map filenames to full URLs
              images = images.map((img) => '$baseUrl/$img').toList();
              print(images);
            }
            isLoading = false;
          });
        } else {
          //_showError("Product data not found");
        }
      } else {
        // _showError("Failed to load product details");
      }
    } catch (e) {
      LoadingDialog.hide(context);
      print("❌ Error loading product details: $e");
      //_showError("Error loading product");
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> calloffer() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final body = {"user_id": prefs.getString("Uid").toString()};

    try {
      final response = await ApiHelper().postRequest(
        ApiConstants.home_offer,
        body,
      );
      if (response != null && response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == "1") {
          setState(() {
            home_offer = data['data'];
          });
        }
      }
    } catch (e) {
      print("Offer load failed: $e");
    }

    _offerTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (home_offer.isNotEmpty) {
        setState(() {
          _currentOfferIndex = (_currentOfferIndex + 1) % home_offer.length;
        });
      }
    });
  }

  void _increment() {
    setState(() {
      _count++;
      _controller.text = _count.toString();
      addToCartApi(int.parse(widget.product_id), _count);
    });
  }

  void _decrement() {
    if (_count > 0) {
      setState(() {
        _count--;
        _controller.text = _count.toString();
        addToCartApi(int.parse(widget.product_id), _count);
      });
    }
  }

  void onImageSelected(int index) {
    _pageController.jumpToPage(index);
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _offerTimer?.cancel();
    _pageController.dispose();
    super.dispose();
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
      final response = await ApiHelper().postRequest(
        ApiConstants.add_cart,
        body,
      );
      print("cart add  Request: $body");
      print("cart add Response: ${response?.data}");
      if (response != null && response.statusCode == 200) {
        // await Future.delayed(Duration(seconds: 2));
        //  LoadingDialog.hide(context);
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

  @override
  Widget build(BuildContext context) {
    double totalWeight = ((double.tryParse(net_weight ?? "0") ?? 0.0)) * _count;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, {
          "id": widget.product_id.toString(),
          "qty": _count,
        });
        return false; // Prevent default pop
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          backgroundColor: appBarColor ?? Colors.white,
          title: Text(name.toString()=="null"?widget.name:name.toString(), style: FontStyles.appbar_heading),
          //iconTheme: const IconThemeData(color: Colors.black),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            // onPressed: () => Navigator.pop(context, "text"),
            onPressed: () {
              Navigator.pop(context, {
                "id": widget.product_id.toString(), // Pass correct ID
                "qty": _count, // Pass updated quantity
              });
            }

          ),
          actions: [
            Stack(
              children: [
                GestureDetector(
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CartScreen()),
                      ),
                  child: const Padding(
                    padding: EdgeInsets.only(right: 16.0),
                    child: Icon(
                      Icons.shopping_cart_outlined,
                      color: Colors.black,
                    ),
                  ),
                ),
                // if (cartCount > 0)
                //   Positioned(
                //     right: 10,
                //     top: 10,
                //     child: CircleAvatar(
                //       backgroundColor: Color_Constant.pink,
                //       radius: 10,
                //       child: Text(
                //         '$cartCount',
                //         style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                //       ),
                //     ),
                //   ),
              ],
            ),
          ],
        ),
        body:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Offer Banner
                        Container(
                          height: 35,
                          color: getColorFromHex(home_offer[_currentOfferIndex]['color'].toString()),
                          child: Center(
                            child:
                                home_offer.isNotEmpty
                                    ? Text(
                                      home_offer[_currentOfferIndex]['name'] ??
                                          '',
                                      style: FontStyles.offer_heading.copyWith(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                    : const Text(
                                      "No offers",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                          ),
                        ),

                        //Product Image
                        Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Color_Constant.greyshade50,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.shade300,
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                height: 380,
                                child:
                                images.isNotEmpty
                                    ? PageView.builder(
                                  controller: _pageController,
                                  itemCount: images.length,
                                  itemBuilder: (context, index) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: ImageViewerPro(
                                        images: images,
                                        initialIndex: index,
                                        showIndicator: false,
                                        showCloseButton: false,
                                        backgroundColor: Colors.black,
                                        indicatorAlignment: Alignment.bottomCenter,
                                        activateIndicatorDotColor: Colors.white,
                                        indicatorColor: Colors.transparent,
                                        indicatorDotHeight: 8.0,
                                        indicatorDotWidth: 8.0,
                                        indicatorSpacing: 16.0,
                                        indicatorPadding: EdgeInsets.only(bottom: 30),
                                        closeButtonSize: 0.0,
                                        closeButtonColor: Colors.white,
                                        closeButtonBackgroundColor: Colors.transparent,
                                        closeButtonAlignment: Alignment.topRight,
                                        closeButtonPadding: EdgeInsets.only(top: 50, right: 20),
                                        enablePageFling: false,
                                        enableImageRotation: false,
                                        heroTagPrefix: "fullscreen_image_",
                                        networkHeaders: {"Authorization": "Bearer token"},
                                        enableSwipeToDismiss: false,
                                        transitionDuration: Duration(milliseconds: 100),
                                        transitionCurve: Curves.easeInOut,
                                        allowImplicitScrolling: false,
                                        imagePadding: EdgeInsets.all(0),
                                        indicatorEffect: IndicatorEffect.wormEffect,
                                        imageFit: BoxFit.cover,
                                        // customCloseButton: IconButton(
                                        //   icon: Icon(Icons.cancel, color: Colors.red, size: 40),
                                        //   onPressed: () {
                                        //     Navigator.pop(context);
                                        //   },
                                        // ),
                                      ),
                                    );
                                  },
                                )
                                    : const Center(child: Text("No Images")),
                              ),
                            ),
                            Positioned(
                              right: 10,
                              top: 10,
                              child: IconButton(
                                icon: GestureDetector(
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
                                onPressed: () {
                                  // toggleFavorite(productId);
                                },
                              ),
                            ),
                          ],

                        ),




                        // Dots
                        if (images.isNotEmpty)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children:
                                images.asMap().entries.map((entry) {
                                  return GestureDetector(
                                    onTap: () => onImageSelected(entry.key),
                                    child: Container(
                                      width: 10.0,
                                      height: 10.0,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 5.0,
                                      ),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color:
                                            currentIndex == entry.key
                                                ? Color_Constant.black
                                                : Color_Constant.greyshade300,
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),

                        // Thumbnails
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: SizedBox(
                            height: 80,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: images.length,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: () => onImageSelected(index),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 6.0,
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color:
                                            currentIndex == index
                                                ? Color_Constant.pink
                                                : Color_Constant.black,
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child:
                                      // Image.network(
                                      //   "https://ornatique.co/portal/public/assets/images/product/${images[index]}",
                                      //   width: 80,
                                      //   height: 80,
                                      //   fit: BoxFit.cover,
                                      // ),
                                      CachedNetworkImage(
                                        width: 80,
                                        height: 80,
                                        imageUrl:images[index],
                                            //"https://ornatique.co/portal/public/assets/images/product/${images[index]}",
                                        fit: BoxFit.cover,
                                        placeholder:
                                            (context, url) => Center(
                                              child: CircularProgressIndicator(),
                                            ),
                                        errorWidget:
                                            (context, url, error) =>
                                                Center(child: Icon(Icons.error)),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        // Product Details
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 4,
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.grey.shade100,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "G.Wt : ${gross_weight ?? '-'} gms",
                                      style: FontStyles.offer_heading.copyWith(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (less_weight.toString() != "null" &&
                                        less_weight.toString() != "0")
                                    Text(
                                      "L.Wt : ${less_weight.toString() == 'null' ? '0.00' : less_weight} gms",
                                      style: FontStyles.offer_heading.copyWith(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (less_weight.toString() != "null" &&
                                        less_weight.toString() != "0")
                                    Text(
                                      "N.Wt : ${net_weight ?? '-'} gms",
                                      style: FontStyles.offer_heading.copyWith(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (hole_size.toString() != "null" &&
                                        hole_size.toString() != "0")
                                      Text(
                                        "Hole Size : ${hole_size ?? '-'} mm",
                                        style: FontStyles.offer_heading.copyWith(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    if (size.toString() != "null" &&
                                        size.toString() != "0")
                                      Text(
                                        "Size : ${size ?? '-'} mm",
                                        style: FontStyles.offer_heading.copyWith(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    if (other_charge.toString() != "null" &&
                                        other_charge.toString() != "0")
                                      Text(
                                        "OC : ${other_charge ?? '-'} INR",
                                        style: FontStyles.offer_heading.copyWith(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),

                                // Row(
                                //   mainAxisAlignment: MainAxisAlignment.start,
                                //   children: [
                                //     // Text("Qty:", style: FontStyles.offer_heading),
                                //     // const SizedBox(width: 16),
                                //     GestureDetector(
                                //       onTap: _decrement,
                                //       child: Container(
                                //         decoration: BoxDecoration(
                                //           color: Color_Constant.red,
                                //           borderRadius: BorderRadius.circular(8),
                                //         ),
                                //         padding: const EdgeInsets.all(8),
                                //         child: const Icon(Icons.remove, color: Colors.white, size: 20),
                                //       ),
                                //     ),
                                //     const SizedBox(width: 10),
                                //     Container(
                                //       padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                //       decoration: BoxDecoration(
                                //         color: Color_Constant.Blue300,
                                //         borderRadius: BorderRadius.circular(8),
                                //       ),
                                //       child: Text(
                                //         '$_count',
                                //         style: const TextStyle(
                                //           fontSize: 16,
                                //           color: Colors.white,
                                //           fontWeight: FontWeight.bold,
                                //           letterSpacing: 1.2,
                                //         ),
                                //       ),
                                //     ),
                                //     const SizedBox(width: 10),
                                //     GestureDetector(
                                //       onTap: _increment,
                                //       child: Container(
                                //         decoration: BoxDecoration(
                                //           color: Color_Constant.green,
                                //           borderRadius: BorderRadius.circular(8),
                                //         ),
                                //         padding: const EdgeInsets.all(8),
                                //         child: const Icon(Icons.add, color: Colors.white, size: 20),
                                //       ),
                                //     ),
                                //   ],
                                // ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10.0,
                                    vertical: 0,
                                  ),
                                  child: Card(
                                    elevation: 2, // Shadow effect for the card
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        2,
                                      ), // Rounded corners for the card
                                    ),
                                    child: Container(
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: Colors.grey, // Border color
                                          width: 0, // Border width
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          GestureDetector(
                                            onTap: _decrement,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.rectangle,
                                                //color: Colors.grey.shade200, // Slight background color for button
                                                borderRadius: BorderRadius.only(
                                                  topLeft: Radius.circular(2),
                                                  bottomLeft: Radius.circular(2),
                                                ),
                                              ),
                                              padding: const EdgeInsets.only(
                                                right: 10,
                                                left: 10,
                                              ),
                                              child: const Icon(
                                                Icons.remove,
                                                color: Colors.black,
                                                size: 25,
                                              ),
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
                                          //   '$_count',
                                          //     style: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold),
                                          //   ),
                                          // ),
                                          Container(
                                            width: 50,
                                            // Make this container width fixed so textfield is consistent
                                            decoration: BoxDecoration(
                                              border: Border(
                                                right: BorderSide(
                                                  color: Colors.grey,
                                                  width: 1,
                                                ),
                                                left: BorderSide(
                                                  color: Colors.grey,
                                                  width: 1,
                                                ),
                                              ),
                                            ),
                                            child: TextField(
                                              controller: _controller,
                                              keyboardType: TextInputType.number,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              onTap: () {
                                                if (_controller.text == "0") {
                                                  _controller.clear();
                                                }
                                              },
                                              decoration: const InputDecoration(
                                                border: InputBorder.none,
                                                isDense: true,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      vertical: 0,
                                                    ),
                                              ),
                                              onChanged: _onTextChanged,
                                              inputFormatters: [
                                                // Allow only digits (optional, requires import of flutter/services.dart)
                                                // FilteringTextInputFormatter.digitsOnly,
                                              ],
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: _increment,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.rectangle,
                                                //color: Colors.grey.shade200, // Slight background color for button
                                                borderRadius: BorderRadius.only(
                                                  topRight: Radius.circular(2),
                                                  bottomRight: Radius.circular(2),
                                                ),
                                              ),
                                              padding: const EdgeInsets.only(
                                                left: 10,
                                                right: 10,
                                              ),
                                              child: const Icon(
                                                Icons.add,
                                                color: Colors.black,
                                                size: 25,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 5),

                        // // Quantity Row
                        // Padding(
                        //   padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        //   child: Container(
                        //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        //     decoration: BoxDecoration(
                        //       color: Colors.grey.shade100,
                        //       borderRadius: BorderRadius.circular(10),
                        //       boxShadow: [
                        //         // BoxShadow(
                        //         //   color: Colors.grey.withOpacity(0.2),
                        //         //   spreadRadius: 2,
                        //         //   blurRadius: 6,
                        //         //   offset: const Offset(0, 2),
                        //         // ),
                        //       ],
                        //     ),
                        //     child: Row(
                        //       mainAxisAlignment: MainAxisAlignment.start,
                        //       children: [
                        //         Text("Qty:", style: FontStyles.offer_heading),
                        //         const SizedBox(width: 16),
                        //         GestureDetector(
                        //           onTap: _decrement,
                        //           child: Container(
                        //             decoration: BoxDecoration(
                        //               color: Color_Constant.red,
                        //               borderRadius: BorderRadius.circular(8),
                        //             ),
                        //             padding: const EdgeInsets.all(8),
                        //             child: const Icon(Icons.remove, color: Colors.white, size: 20),
                        //           ),
                        //         ),
                        //         const SizedBox(width: 20),
                        //         Container(
                        //           padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        //           decoration: BoxDecoration(
                        //             color: Color_Constant.Blue300,
                        //             borderRadius: BorderRadius.circular(8),
                        //           ),
                        //           child: Text(
                        //             '$_count',
                        //             style: const TextStyle(
                        //               fontSize: 16,
                        //               color: Colors.white,
                        //               fontWeight: FontWeight.bold,
                        //               letterSpacing: 1.2,
                        //             ),
                        //           ),
                        //         ),
                        //         const SizedBox(width: 20),
                        //         GestureDetector(
                        //           onTap: _increment,
                        //           child: Container(
                        //             decoration: BoxDecoration(
                        //               color: Color_Constant.green,
                        //               borderRadius: BorderRadius.circular(8),
                        //             ),
                        //             padding: const EdgeInsets.all(8),
                        //             child: const Icon(Icons.add, color: Colors.white, size: 20),
                        //           ),
                        //         ),
                        //       ],
                        //     ),
                        //   ),
                        // ),
                        // const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),

        // Bottom Bar
        bottomNavigationBar:
            isLoading
                ? const SizedBox.shrink()
                : Container(
                  height: 110,
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: MediaQuery.of(context).padding.bottom,
                    top: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 5,
                        offset: Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total Weight: ${totalWeight.toStringAsFixed(3)} gms",
                        style: FontStyles.font16_bold,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (_count > 0) {
                            setState(() {
                              cartCount += _count;
                            });
                            Fluttertoast.showToast(msg: "Added to cart");
                          } else {
                            Fluttertoast.showToast(msg: "Please select quantity");
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color_Constant.blue,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('Add to Cart', style: FontStyles.button),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  void _onTextChanged(String value) {
    if (value.isEmpty) {
      // If empty, don't update _count yet. Just allow user to type.
      return;
    }
    int? newCount = int.tryParse(value);
    if (newCount != null && newCount > 0) {
      setState(() {
        _count = newCount;
      });
    } else {
      // Invalid input: reset the textfield to last valid value (_count)
      _controller.text = _count.toString();
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
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
      print("Add Wishlist Request: $body");
      print("Add Wishlist Response: ${response?.data}");
      if (response != null && response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == "1") {
          setState(() {
            isWishlisted = true;
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
      print("Remove Wishlist Request: $body");
      print("Remove Wishlist Response: ${response?.data}");
      if (response != null && response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == "1") {
          setState(() {
            isWishlisted = false;
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
}
