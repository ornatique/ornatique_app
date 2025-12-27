import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ornatique/ConstantColors/Color_Constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Api_Constant/ApiConstants.dart';
import '../Api_Constant/api_helper.dart';
import '../Constant_font/FontStyles.dart';
import '../GlobalDrawer.dart';
import '../LoadingDialog/LoadingDialog.dart';
import '../OrderConfirmationDialog.dart';
import 'CartScreen.dart';

class ScanScreen extends StatefulWidget {
  @override
  _ScanScreenState createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  List<String> scannedItems = [];
  List catlist = [];
  String? banner_baseUrl;
  bool isLoading = true; // For loading spinner before API data arrives
  int cartCount = 0;
  Color? appBarColor;
  final TextEditingController _controller = TextEditingController();
  void _onBarcodeDetected(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final String? value = barcode.rawValue;
      if (value != null && !scannedItems.contains(value)) {
        setState(() {
          scannedItems.add(value);
          print("Item Scan"+ scannedItems.toString());
        });
       // category(value);
        getqrsave(value).whenComplete(() {
          print("QR Save action complete");
        });
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text("Scanned: $value"),
        //     backgroundColor: Colors.green,
        //     duration: Duration(seconds: 2),
        //   ),
        // );
      }
    }
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

  Future<void> _increment(int productId, int index) async {
    setState(() {
      catlist[index]['count'] += 1;
      _updateTotalWeight();
    });
    await addToCartApi(productId, catlist[index]['count']);

  }

  Future<void> _decrement(int productId, int index) async {
    if (catlist[index]['count'] > 0) {
      setState(() {
        catlist[index]['count'] -= 1;
        _updateTotalWeight();
      });
      await addToCartApi(productId, catlist[index]['count']);

    }
  }

  // New method to update total weight
  void _updateTotalWeight() {
    setState(() {
      getTotalWeight(); // This will re-calculate and trigger UI update
    });
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
  // // Calculate total weight dynamically
  // double getTotalWeight() {
  //   double totalWeight = 0.0;
  //
  //   for (var product in catlist) {
  //     if (product == null) continue;
  //
  //     final gross = double.tryParse(product['gross_weight']?.toString() ?? '0') ?? 0.0;
  //     final less = double.tryParse(product['less_weight']?.toString() ?? '0') ?? 0.0;
  //     final count = product['count'] ?? 0; // Corrected line
  //
  //     double netWeight = (gross - less) * count;
  //     totalWeight += netWeight;
  //   }
  //
  //   return totalWeight;
  // }

  // Calculate total net weight dynamically
  double getTotalWeight() {
    double totalWeight = 0.0;

    for (var product in catlist) {
      if (product == null || product['product'] == null) continue;

      final gross = double.tryParse(product['product']['gross_weight']?.toString() ?? '0') ?? 0.0;
      final less = double.tryParse(product['product']['less_weight']?.toString() ?? '0') ?? 0.0;
      final count = product['count'] ?? 1; // Use default count of 1

      double netWeight = (gross - less) * count; // Calculate Net Weight
      totalWeight += netWeight; // Add Net Weight to Total
    }
    return totalWeight;
  }




  Future<void> category(String product_id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final body = {
      "user_id": prefs.getString("Uid").toString(),
      "product_id": product_id,
    };

    final response = await ApiHelper().postRequest(ApiConstants.Scan_qr, body);
    print("category Request: $body");
    print("category Raw Response: ${response.toString()}");
    if (response != null && response.statusCode == 200) {
      final data = response.data;
      if (data['status'] == "1") {
        setState(() {
          // catlist = data['data'].map((item) {
          //   item['count'] = int.tryParse(item['product']['quantity']?.toString() ?? '0') ?? 0;
          //   return item;
          // }).toList();
          catlist = data['data'].map((item) {
            // Set count to 1 by default if it does not exist
            item['count'] = item['count'] ?? 1;
            return item;
          }).toList();
          banner_baseUrl = data['image_url'];
        });
      }
    } else {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text("Category Load Failed")),
      // );
    }
  }

  Future<void> getqrsave(String product_id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final body = {
      "user_id": prefs.getString("Uid").toString(),
      "product_id": product_id,
      "is_save": "1",
    };

    final response = await ApiHelper().postRequest(ApiConstants.save_qr, body);
    print("Save Qr Request: $body");
    print("Save Qr Raw Response: ${response.toString()}");
    if (response != null && response.statusCode == 200) {
      final data = response.data;
      if (data['status'] == "1") {
        setState(() {

          category(data['data']['product']['id'].toString());
          // catlist = data['data'].map((item) {
          //   item['count'] = int.tryParse(item['product']['quantity']?.toString() ?? '0') ?? 0;
          //   return item;
          // }).toList();
          // if (data['data'] is List) {
          //   catlist = List<Map<String, dynamic>>.from(data['data']);
          // } else if (data['data'] is Map) {
          //   catlist = [data['data']]; // Convert Map to List
          // } else {
          //   catlist = [];
          // }
          // catlist = data['data'].map((item) {
          //   // Set count to 1 by default if it does not exist
          //   item['count'] = item['count'] ?? 1;
          //   return item;
          // }).toList();
         // banner_baseUrl = data['image_url'];
        });
      }
    } else {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text("Category Load Failed")),
      // );
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadAppBarColor();
    addToCart(0);
  }
  Future<void> _loadAppBarColor() async {
    appBarColor = await AppColorHelper.getAppBarColor();
    setState(() {});
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("QR/Barcode Scanner", style: FontStyles.appbar_heading),
        backgroundColor: appBarColor ?? Colors.white,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
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
        ],
      ),
      drawer: GlobalDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 6, spreadRadius: 2),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      MobileScanner(
                        controller: MobileScannerController(
                          facing: CameraFacing.back,
                          detectionSpeed: DetectionSpeed.normal,
                          detectionTimeoutMs: 250, // speed of detection
                          torchEnabled: false,
                          formats: [BarcodeFormat.qrCode, BarcodeFormat.code128], // add required formats
                        ),
                        onDetect: _onBarcodeDetected,
                      ),
                      Positioned(
                        top: 10,
                        child: Text(
                          "Scan QR/Barcode",
                          style: GoogleFonts.roboto(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 8, spreadRadius: 2),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Scanned Items", style: FontStyles.font16_bold),
                  const Divider(),
                  Expanded(
                    child: catlist.isEmpty
                        ? Center(
                      child: Text("No items scanned yet", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16)),
                    )
                        : ListView.builder(
                      itemCount: catlist.length,
                      itemBuilder: (context, index) {
                        final item = catlist[index];
                        final List galleryImages = item['product']['gallery'] != null && item['product']['gallery'].toString().isNotEmpty
                            ? List<String>.from(jsonDecode(item['product']['gallery']))
                            : [];
                        //final String productId = item['id'] ?? 'No id';
                        final String title = item['product']['name'] ?? 'No Name';
                        final String weight = item['product']['weight'] ?? '';
                        //final String quantity = item['product']['quantity'] ?? '';
                        final String size = item['product']['size'].toString();
                        final String imageUrlBase = banner_baseUrl ?? '';
                        final grossWeight = double.tryParse(item['product']['gross_weight'].toString()) ?? 0;
                        final lessWeight = double.tryParse(item['product']['less_weight'].toString()) ?? 0;
                        final netWeight = grossWeight - lessWeight;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          elevation: 4,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title, style: FontStyles.font16_bold),
                                SizedBox(height: 8),
                                SizedBox(
                                  height: 50,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: galleryImages.length,
                                    separatorBuilder: (_, __) => SizedBox(width: 10),
                                    itemBuilder: (context, imgIndex) {
                                      final imageUrl = '$imageUrlBase/${galleryImages[imgIndex]}';
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          imageUrl,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Text("Size: $size mm", style: FontStyles.font12_bold),
                                        // Text("Weight: $weight gm", style: FontStyles.font12_bold),
                                        Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 4),
                                          child: Text(
                                            "G.Wt : ${item['product']['gross_weight'].toString() + " gms"}",
                                            style: FontStyles.font12_bold,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 4),
                                          child:
                                          // Text(
                                          //   "L.Wt : ${(item['product']['less_weight'] ?? '').toString().isEmpty ? '-' : item['product']['less_weight'].toString() + " gms"}",
                                          //   style: FontStyles.font12_bold,
                                          //   maxLines: 2,
                                          //   overflow: TextOverflow.ellipsis,
                                          //   textAlign: TextAlign.center,
                                          // ),
                                          item['product']['less_weight'] == null
                                              ? SizedBox.shrink()
                                              : Text(
                                            "L.Wt : ${item['product']['less_weight']} gms",
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 4),
                                          child: Text(
                                            "N.Wt : ${netWeight.toString() + " gms"}",
                                            style: FontStyles.font12_bold,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 4),
                                          child: Text(
                                            item['product']['hole_size'] == null || item['product']['hole_size'] == "0"
                                                ? ""
                                                : "Hole Size : ${item['product']['hole_size'].toString()} mm",
                                            style: FontStyles.font12_bold,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Padding(
                                    //   padding: const EdgeInsets.all(10.0),
                                    //   child: Row(
                                    //     //mainAxisSize: MainAxisSize.min,
                                    //     mainAxisAlignment: MainAxisAlignment.center,
                                    //     children: [
                                    //       GestureDetector(
                                    //         onTap: () => _decrement( item['id'],index),
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
                                    //           '${catlist[index]['count'] ?? 0}',
                                    //           style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
                                    //         ),
                                    //
                                    //       ),
                                    //       SizedBox(width: 20),
                                    //       GestureDetector(
                                    //         onTap: () => _increment( item['id'],index),
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
                                                onTap: () => _decrement(item['product']["id"],index),
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
                                              AnimatedContainer(
                                                duration: const Duration(milliseconds: 300),
                                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
                                                decoration: BoxDecoration(
                                                  border: Border(
                                                    right: BorderSide(color: Colors.grey, width: 1),
                                                    left: BorderSide(color: Colors.grey, width: 1),
                                                  ),
                                                ),
                                                child: Text(
                                                  '${catlist[index]['count'] ?? 1}',
                                                  style: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () => _increment(item['product']["id"],index),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.rectangle,
                                                    //color: Colors.grey.shade200, // Slight background color for button
                                                    borderRadius: BorderRadius.only(
                                                      topRight: Radius.circular(2),
                                                      bottomRight: Radius.circular(2),
                                                    ),
                                                  ),
                                                  padding: const EdgeInsets.only(right: 5,left: 5),
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
                                //Text("Qty: $quantity", style: FontStyles.font12_bold),
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
          ),
        ],
      ),
      // Bottom Bar
      bottomNavigationBar: Container(
        height: 70,
        padding: EdgeInsets.all(12),
        color: Colors.grey[200],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Total Approx. Weight:", style: FontStyles.font16_bold),
                Text("${getTotalWeight().toStringAsFixed(3)} gms", style: FontStyles.font16_bold),
              ],
            ),
            // ElevatedButton(
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: Colors.blue[300],
            //     padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(10),
            //     ),
            //   ),
            //   onPressed: () async {
            //     Navigator.push(context,
            //         MaterialPageRoute(builder:
            //             (context) =>
            //             CartScreen()
            //         )
            //     );
            //   },
            //   child: Text("Submit", style: FontStyles.button),
            // ),
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
            //callcartlist();  // Cart refresh
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
}
