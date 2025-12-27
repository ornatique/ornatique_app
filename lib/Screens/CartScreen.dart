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
import 'ProductDetailScreen.dart';

class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // List<Map<String, dynamic>> allProducts = [
  //   {'id': 'PS.154', 'size': 29, 'weight': 9.400, 'count': 0},
  //   {'id': 'PS.153', 'size': 34, 'weight': 9.800, 'count': 0},
  //   {'id': 'PS.152', 'size': 33, 'weight': 9.800, 'count': 0},
  //   {'id': 'PS.151', 'size': 32, 'weight': 8.200, 'count': 0},
  // ];
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> filteredProducts = [];
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> allProducts = [];
  List<int> _counts = [];
  List<TextEditingController> _controllers = [];
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
    _loadAppBarColor();
    callcartlist();
    //filteredProducts = List.from(allProducts); // Initially show all products
    searchController.addListener(_filterProducts);
  }

  void _filterProducts() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredProducts = allProducts.where((product) {
       // final productName = (product['product']?['id'] ?? '').toString().toLowerCase();
        final productName = (product['product']?["name"] ?? '').toString().toLowerCase();
        final productId = (product['product']?["id"] ?? '').toString().toLowerCase();
        final productSize = (product['product']?["size"] ?? '').toString().toLowerCase();
        return productName.contains(query) || productId.contains(query) || productSize.contains(query);
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


  // Calculate total weight dynamically
  double getTotalWeight() {
    double totalWeight = 0.0;

    for (var product in catlist) {
      if (product == null || product['product'] == null) continue;
      final gross = double.tryParse(product['product']['gross_weight'].toString()) ?? 0.0;
      final less = double.tryParse(product['product']['less_weight'].toString()) ?? 0.0;
      final count = product['count'] ?? 0;

      double netWeight = (gross - less) * count;
      totalWeight += netWeight;
    }

    return totalWeight;
  }

  Future<void> _addOrder(String remarks) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      LoadingDialog.show(context, message: "Loading...");
      final body = {
        "user_id": prefs.getString('Uid').toString(),
        "remarks": remarks.toString(),
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
            callcartlist();  // Cart refresh
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

  Future<void> callcartlist() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final body = {
      "user_id": prefs.getString('Uid').toString(),
    };

    try {
      LoadingDialog.show(context, message: "Loading...");
      final response = await ApiHelper().postRequest(ApiConstants.cartlist, body);
      LoadingDialog.hide(context);
      print("cart Request: $body");
      print("cart Response: ${response?.data}");

      if (response != null && response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == "1") {
          setState(() {
            catlist = (data['data'] as List)
                .cast<Map<String, dynamic>>()
                .where((item) => item['quantity'] > 0)
                .map((item) => {
              ...item,
              'count': item['quantity'] ?? 1,
            })
                .toList();
            _counts.clear();
            _controllers.clear();
            for (var product in catlist) {
              _counts.add(product['count'] ?? 1);
              _controllers.add(TextEditingController(text: (product['count'] ?? 1).toString()));
            }
            banner_baseUrl = data['image_url'];
            prefs.setString("cart_count", catlist.length.toString());
            setState(() {
              allProducts = List.from(catlist);
              filteredProducts = List.from(allProducts);
            });
          });
        } else {
          setState(() => catlist = []);
        }
      } else {
        setState(() => catlist = []);
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text("Failed to load products")),
        // );
      }
    } catch (e) {
      LoadingDialog.hide(context);
      print("❌ Product List Error: $e");
      //ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text("Error loading products")),
      // );
    }
  }

  Future<void> _increment(int index) async {
    setState(() {
      catlist[index]['count'] = (catlist[index]['count'] ?? 0) + 1;
      _counts[index]++;
      _controllers[index].text = _counts[index].toString();
    });
    //await addToCartApi(catlist[index]['product_id'], catlist[index]['count']);
    await addToCartApi(catlist[index]['product_id'], _counts[index]);
  }

  Future<void> addToCartApi(int productId, int quantity) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final body = {
      "user_id": prefs.getString('Uid').toString(),
      "product_id": productId.toString(),
      "quantity": quantity.toString(),
    };

    try {
      //LoadingDialog.show(context, message: "Loading...");
      final response = await ApiHelper().postRequest(ApiConstants.add_cart, body);
     // LoadingDialog.hide(context);
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

  void _decrement(int index) async {
    int currentCount = _counts[index];
    _counts[index]--;
    _controllers[index].text = _counts[index].toString();
    await addToCartApi(catlist[index]['product_id'], _counts[index]);
    if (currentCount <= 1) {
      bool? confirm = await showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierLabel: '',
        transitionDuration: Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete_forever, color: Colors.red, size: 50),
                    SizedBox(height: 15),
                    Text(
                      "Remove Item?",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Do you want to remove this item from the cart?",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context, false),
                          child: Text("Cancel", style: TextStyle(fontWeight: FontWeight.bold),),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: Text("Remove", style: TextStyle(fontWeight: FontWeight.bold),),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.elasticOut,
            ),
            child: child,
          );
        },
      );



      if (confirm == true) {
        await deleteCartItem(catlist[index]['product_id'].toString())
            .whenComplete(() async {
          await callcartlist(); // Call your second API here
        });
        // setState(() {
        //   catlist.removeAt(index);
        // });
      }

    } else {
      setState(() {
        catlist[index]['count'] = currentCount - 1;
      });
    }
  }

  Future<void> deleteCartItem(String cartItemId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      LoadingDialog.show(context, message: "Deleting...");
      final body = {
        "user_id": prefs.getString('Uid').toString(),
        "product_id": cartItemId
      };
      final response = await ApiHelper().postRequest(ApiConstants.delete_cart, body);
      LoadingDialog.hide(context);
      print("Remove cart Request: $body");
      print("Remove cart Response: ${response?.data}");
      if (response != null && response.statusCode == 200) {
        final result = response.data;
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text(result['status'] == "1"
        //         ? "Item removed successfully!"
        //         : "Failed to remove item."),
        //   ),
        // );
      } else {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text("Something went wrong!")),
        // );
      }
    } catch (e) {
      LoadingDialog.hide(context);
      print("❌ Delete API Error: $e");
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text("Error deleting item.")),
      // );
    }
  }



  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Add Cart ', style: FontStyles.appbar_heading),
        centerTitle: true,
        backgroundColor: appBarColor ?? Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context, 'updated'),
        ),
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
                  hintText: 'Search Product by Name...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Color_Constant.lightBlue50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            // Product List
            Container(
              height: MediaQuery.of(context).size.height / 1.5,
              child: filteredProducts.isEmpty
                  ? Center(
                child: Text(
                  'Product Not Found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              )
                  :ListView.builder(
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = filteredProducts[index]; // Use filteredProducts instead of catlist
                  final imageUrl = "$banner_baseUrl/${product['image']}";
                  List<dynamic> gallery = [];
                  try {
                    gallery = product['product']['gallery'] is String
                        ? List<String>.from(jsonDecode(product['product']['gallery']))
                        : product['product']['gallery'];
                  } catch (e) {
                    gallery = [];
                  }
                  final grossWeight = double.tryParse(product['product']['gross_weight'].toString()) ?? 0;
                  final lessWeight = double.tryParse(product['product']['less_weight'].toString()) ?? 0;
                  final netWeight = grossWeight - lessWeight;
                  return Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Color_Constant.greyshade300, width: 1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            //crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: (){
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailScreen(product['product']["id"].toString(),product['product']["name"].toString(),product['quantity'].toString())));
                                },
                                child: Container(
                                  width:100,height: 100,
                                  child: AutoScrollImageSlider(
                                    gallery: gallery,
                                    bannerBaseUrl: banner_baseUrl ?? "",
                                  ),
                                ),
                              ),
                              //Image.network("$banner_baseUrl/${catlist[index]['product']['image']}", height: 60, fit: BoxFit.cover, width: 80),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(product['product']['name'].toString(), style: FontStyles.font12_bold),
                                    SizedBox(height: 0),
                                    Text(
                                          'Gross Weight: ${grossWeight.toStringAsFixed(2)} gms\n'
                                          'Less Weight: ${lessWeight.toStringAsFixed(2)} gms\n'
                                          'Net Weight: ${netWeight.toStringAsFixed(2)} gms\n'
                                              '${product['product']['size'] != null ? 'Size: ${product['product']['size']} mm' : ''}\n'
                                          '${product['product']['hole_size'] != null ? 'Hole Size: ${product['product']['hole_size']} mm' : ''}',
                                      style: FontStyles.font12_bold,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 5),

                            ],
                          ),
                          // Row(
                          //   //mainAxisSize: MainAxisSize.min,
                          //   mainAxisAlignment: MainAxisAlignment.end,
                          //   children: [
                          //     GestureDetector(
                          //       onTap: () => _decrement(index),
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
                          //         '${product['count']}',
                          //         style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
                          //       ),
                          //
                          //     ),
                          //     SizedBox(width: 10),
                          //     GestureDetector(
                          //       onTap: () => _increment(index),
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
                            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0),
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
                                          onTap: () => _decrement(index),
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
                                              int? newVal = int.tryParse(value);
                                              if (newVal != null && newVal > 0) {
                                                setState(() {
                                                  product['count'] = int.tryParse(value) ?? 1;
                                                  _counts[index] = newVal;
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => _increment(index),
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
      // Bottom Navigation Bar with Total Weight and Submit Button
      bottomNavigationBar: Container(
        height: 120,
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
            Text("Total Weight: ${getTotalWeight().toStringAsFixed(2)} gms",style: FontStyles.font16_bold),
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
                await showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) {
                    return Dialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                      backgroundColor: Colors.white,
                      //backgroundColor: const Color(0xFFF4F3FE), // Soft pastel background
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.mode_comment_outlined,
                              color: Color(0xFF6C63FF), // Elegant Indigo
                              size: 50,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '📝 Enter Remarks',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333366),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _controller,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: 'Write your notes here...',
                                filled: true,
                                fillColor: Colors.white,
                                hintStyle: TextStyle(color: Colors.grey.shade500),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF6C63FF)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                  const BorderSide(color: Color(0xFF6C63FF), width: 2),
                                ),
                              ),
                              style: const TextStyle(color: Color(0xFF333366)),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.black87,
                                      side: const BorderSide(color: Color(0xFF9999CC)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                    child: Text("Cancel",style: FontStyles.font16_bold),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      _addOrder(_controller.text.trim());
                                      Navigator.of(context).pop();
                                    },
                                    icon: const Icon(Icons.send_rounded, size: 18,color: Colors.white,),
                                    label: Text("Submit",style: FontStyles.button),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:Colors.blue,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              child: Text("Submit", style: FontStyles.button),
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
