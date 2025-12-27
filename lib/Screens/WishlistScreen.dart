import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ornatique/Screens/ProductDetailScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Api_Constant/ApiConstants.dart';
import '../Api_Constant/api_helper.dart';
import '../ConstantColors/Color_Constant.dart';
import '../Constant_font/FontStyles.dart';
import '../GlobalDrawer.dart';
import '../LoadingDialog/LoadingDialog.dart';
import 'CartScreen.dart';

class WishlistScreen extends StatefulWidget {
  @override
  _WishlistScreenState createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  int cartCount = 0;
  int favoriteCount = 0;
  List<int> _counts = [];
  List<TextEditingController> _controllers = [];
  Map<int, int> cartItems = {};
  Map<int, bool> favoriteItems = {};
  List<dynamic> catlist = [];
  String? banner_baseUrl;
  bool _isLoading = true; // New loading flag
  Set<int> wishlistProductIds = {};
  late TextEditingController _controller;
  FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  Color? appBarColor;
  Color? appBGColor;
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

  Future<void> _increment(int index) async {
    setState(() {
      catlist[index]['count'] = (catlist[index]['count'] ?? 0) + 1;
      _counts[index]++;
      _controllers[index].text = _counts[index].toString();
    });
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
      print("Remove wishlist Request: $body");
      print("Remove wishlist Response: ${response?.data}");
      if (response != null && response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == "1") {
          setState(() {
            wishlistProductIds.remove(productId);
          });
          Fluttertoast.showToast(
            msg: data['message'].toString(),
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.black87,
            textColor: Colors.white,
            fontSize: 16.0,
          );
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

  void _decrement(int index) async {
    int currentCount = _counts[index];

    if (currentCount > 0) {
      setState(() {
        _counts[index] = currentCount - 1;
        _controllers[index].text = _counts[index].toString();

        // Update catlist quantity if that is source of truth
        catlist[index]['count'] = _counts[index];
      });

      await addToCartApi(catlist[index]['product_id'], _counts[index]);
    }
  }




  Future<void> deleteCartItem(String cartItemId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
     // LoadingDialog.show(context, message: "Deleting...");
      final body = {
        "user_id": prefs.getString('Uid').toString(),
        "product_id": cartItemId
      };
      final response = await ApiHelper().postRequest(ApiConstants.delete_cart, body);
      //LoadingDialog.hide(context);
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

  Future<void> signUp() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final body = {"user_id": prefs.getString('Uid').toString()};
    try {
      //LoadingDialog.show(context, message: "Loading...");
      final response = await ApiHelper().postRequest(ApiConstants.wishlist, body);
      //LoadingDialog.hide(context);
      print("Wishlist Request: $body");
      print("Wishlist Response: ${response?.data}");
      if (response != null && response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == "1" && data['data'].isNotEmpty) {
          setState(() {
            catlist = data['data'];
            favoriteCount = catlist.length;
            banner_baseUrl = data['image_url'];
            favoriteItems.clear();
            for (var item in catlist) {
              int id = int.parse(item['product']['id'].toString());
              favoriteItems[id] = true;
            }
            _counts.clear();
            _controllers.clear();
            for (var product in catlist) {
              _counts.add(product['count'] ?? 0);
              _controllers.add(TextEditingController(text: (product['count'] ?? 0).toString()));
            }
            _isLoading = false;
          });
        } else {
          setState(() {
            catlist = [];
            favoriteCount = 0;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      LoadingDialog.hide(context);
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    //_controller = TextEditingController(text: _count.toString());
    _loadAppBarColor();
    addToCart(0);
    signUp();
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
      appBar: _buildAppBar(),
      drawer: GlobalDrawer(),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : catlist.isEmpty
            ? Center(
          child: Text(
            "No Data Found",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        )
            : _buildGridView(),
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

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: appBarColor ?? Colors.white,
      elevation: 0,
      centerTitle: true,
      title: Text("WishListed Product", style: FontStyles.appbar_heading),
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.menu, color: Colors.black),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      actions: [
        Stack(
          children: [
            Icon(Icons.favorite_border, color: Colors.black),
            if (favoriteCount > 0)
              Positioned(
                right: 0,
                bottom: 6,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.pink, shape: BoxShape.circle),
                  child: Text(
                    "$favoriteCount",
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(width: 10),
        Stack(
          children: [
            GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(context,
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
        SizedBox(width: 10),
      ],
    );
  }

  Widget _buildGridView() {
    return Padding(
      padding: EdgeInsets.all(10),
      child: ScrollConfiguration(
        behavior: ScrollBehavior().copyWith(overscroll: false),
        child: GridView.builder(
          itemCount: catlist.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 5,
            mainAxisSpacing: 10,
            childAspectRatio: 0.58,
          ),
          itemBuilder: (context, index) {
            return _buildProductCard(catlist[index],index);
          },
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> item ,int index) {
    int productId = int.parse(item['product']['id'].toString());
    int quantity = cartItems[productId] ?? 0;
    bool isFavorited = favoriteItems[productId] ?? false;

    final product = catlist[index];
    List<dynamic> gallery = [];
    try {
      gallery = item['product']['gallery'] is String
          ? List<String>.from(jsonDecode(item['product']['gallery']))
          : item['product']['gallery'];
    } catch (e) {
      gallery = [];
    }
    final grossWeight = double.tryParse(item['product']['gross_weight'].toString()) ?? 0;
    final lessWeight = double.tryParse(item['product']['less_weight'].toString()) ?? 0;
    final netWeight = grossWeight - lessWeight;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: (){
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailScreen(item['product']["id"].toString(),item['product']["name"].toString(),_counts[index].toString())));
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
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber[700],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "PURE GOLD & LAB DIAMOND",
                    style: FontStyles.font8_white_color,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                child: IconButton(
                  icon: GestureDetector(
                    onTap: () {
                      if (isFavorited) {
                        removewishlist(item['product']["id"]).then((_) async {
                          await signUp(); // Call your second API here
                        });
                      } else {
                        removewishlist(product["id"]);
                      }
                    },
                    child: Icon(
                      isFavorited ? Icons.favorite : Icons.favorite_border,
                      color: isFavorited ? Colors.pink : Colors.pink,
                    ),
                  ),
                  onPressed: () {
                    // toggleFavorite(productId);
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 5),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              item['product']["name"].toString(),
              style: FontStyles.offer_heading,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          // Padding(
          //   padding: EdgeInsets.symmetric(horizontal: 4),
          //   child: Text(
          //     "Size : ${item['product']['size']}",
          //     style: FontStyles.font10_bold,
          //     maxLines: 2,
          //     overflow: TextOverflow.ellipsis,
          //     textAlign: TextAlign.center,
          //   ),
          // ),
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
              item['product']['less_weight'] == null || item['product']['less_weight'] == "0"
                  ? ""
                  : "L.Wt : ${item['product']['less_weight'].toString()} gms",
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
          // Padding(
          //   padding: EdgeInsets.symmetric(horizontal: 4),
          //   child: Text(
          //     "Weight : ${item['product']['weight']}",
          //     style: FontStyles.font10_bold,
          //     maxLines: 2,
          //     overflow: TextOverflow.ellipsis,
          //     textAlign: TextAlign.center,
          //   ),
          // ),
          //Spacer(),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceAround,
          //   children: [
          //     Padding(
          //       padding: EdgeInsets.all(2),
          //       child: ElevatedButton(
          //         style: ElevatedButton.styleFrom(
          //           backgroundColor: Colors.blueAccent,
          //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          //         ),
          //         onPressed: () => addToCart(productId),
          //         child: Text(
          //           quantity > 0 ? "Added ($quantity)" : "Add To Cart",
          //           style: FontStyles.button,
          //         ),
          //       ),
          //     ),
          //   ],
          // ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0),
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
                                product['count'] = newVal;
                                _counts[index] = newVal;
                                addToCartApi(catlist[index]['product_id'], newVal);
                              });
                            }
                          });
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