import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Api_Constant/ApiConstants.dart';
import '../Api_Constant/api_helper.dart';
import '../ConstantColors/Color_Constant.dart';
import '../Constant_font/FontStyles.dart';
import '../LoadingDialog/LoadingDialog.dart';

class CustomOrderListScreen extends StatefulWidget {
  const CustomOrderListScreen({Key? key}) : super(key: key);

  @override
  State<CustomOrderListScreen> createState() => _CustomOrderListScreenState();
}

class _CustomOrderListScreenState extends State<CustomOrderListScreen> {
  List customOrderList = [];
  String? baseUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppBarColor();
    fetchCustomOrders();
  }

  Future<void> fetchCustomOrders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final body = {
      "user_id": prefs.getString("Uid").toString(),
    };

    final response = await ApiHelper().postRequest(ApiConstants.customize_list, body);
    //LoadingDialog.show(context, message: "Loading...");
    print("📦 Request Body: $body");
    print("📩 Raw Response: ${response.toString()}");

    if (response != null && response.statusCode == 200) {
      // await Future.delayed(Duration(seconds: 1)); // Simulate API call
      // LoadingDialog.hide(context);
      final data = response.data;

      if (data['status'] == "1") {
        setState(() {
          customOrderList = data['data'];
          baseUrl = data['image_url'] + "/";
        });
      } else {
        setState(() {
          customOrderList = []; // empty list
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No orders found.")),
        );
      }
    } else {
      LoadingDialog.hide(context);
      setState(() {
        customOrderList = []; // empty list
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load orders.")),
      );
    }
  }

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
  Color? appBarColor;
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
  Future<void> _loadAppBarColor() async {
    appBarColor = await AppColorHelper.getAppBarColor();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Customize Order", style: FontStyles.appbar_heading),
        backgroundColor: appBarColor ?? Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart_outlined,color: Colors.black,),
            onPressed: () {},
          ),
        ],
      ),
      body: customOrderList.isEmpty
          ? const Center(child: Text("No custom orders found."))
          : Container(
            height: MediaQuery.of(context).size.height/1.2,
            child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: customOrderList.length,
                    itemBuilder: (context, index) {
            final order = customOrderList[index];
            final image = order['image'] ?? '';
            final remarks = order['remarks'] ?? '';
            final status = order['status'] ?? 'Pending';
            final createdAt = DateTime.parse(order['created_at']);
            
            return Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5)),
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Image.network(
                        "$baseUrl$image",
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, size: 100),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Remarks: $remarks",
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            // color: status == 'Pending'
                            //     ? Colors.blueAccent.shade100
                            //     : Colors.green.shade100,
                            color: getStatusColor(order['status'] ?? 'Pending'),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            order['status'] ?? 'Pending',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          DateFormat('dd MMM yyyy').format(createdAt),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
                    },
                  ),
          ),
    );
  }
}
