import 'dart:async';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ornatique/Screens/CustomizeEstimateScreen.dart';
import 'package:ornatique/Screens/SearchScreen.dart';
import 'package:ornatique/Screens/WishlistScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Api_Constant/ApiConstants.dart';
import '../Api_Constant/api_helper.dart';
import '../ConstantColors/Color_Constant.dart';
import '../HomeScreen1.dart';
import 'HomeScreen.dart';
import 'NotificationScreen.dart';
import 'ScanAndListScreen.dart';



class DashBoardScreen extends StatefulWidget {
  DashBoardScreen({Key? key}) : super(key: key);

  @override
  State<DashBoardScreen> createState() => _DashBoardScreenState();
}

class _DashBoardScreenState extends State<DashBoardScreen> {
  final pages = [
    HomeScreen(),
    WishlistScreen(),
    SearchScreen(),
    ScanScreen(),
    CustomizeEstimateScreen()
    // const VcardDataListingScreen(),
    // const ReportsScreen(),
  ];
  int selectedIndex = 0;
  var pageIndex = 0;
  var map;
  var mapEntry;
  StreamSubscription? connection;
  bool isoffline = false;

  String adminRight="";
  Color? color;
  String? yy;
  Color? tt;
  Map<String, dynamic>? homeHeading;
  _DashBoardScreenState();
  String? appBarColor;
  String? appBGColor;
  String? appBottomColor;
  @override
  void initState() {

    super.initState();
    callheadind();
  }
  // Future<void> _loadBottomColor() async {
  //   bottomBarColor = await ColorHelper.getBottomBarColor();
  //   setState(() {});
  // }

  Future<void> callheadind() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final body = {"user_id": prefs.getString("Uid").toString()};
    final response =
    await ApiHelper().postRequest(ApiConstants.home_heading, body);

    if (response != null && response.statusCode == 200) {
      final data = response.data;
      if (data['status'] == "1") {
        setState(() {
          homeHeading = data['data']; // direct object set
          // appBarColor = homeHeading!['app_bar_color'].toString();
          // appBGColor = homeHeading!['back_ground_color'].toString();
          appBottomColor = homeHeading!['bottom_bar_color'].toString();
          // prefs.setString("app_bar_color", appBarColor.toString());
          // prefs.setString("app_bottom_color", appBottomColor.toString());
          print("✅ Heading Data: $homeHeading");
          print("✅ heading_one: ${homeHeading?['heading_one']}");
        });
      } else {
        setState(() => homeHeading = null);
      }
    } else {
      setState(() => homeHeading = null);
    }
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

  @override
  void dispose() {
    connection?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Future<bool> _onWillPop() async {
      if (pageIndex == 0) {
        // final bool res = await showDialog(
        //     context: context,
        //     builder: (BuildContext context) => CustomDialog(
        //         "Are you sure you want to exit?",
        //         "Thanks for using this app",
        //         "Exit",
        //         "Cancel",
        //         "",
        //         "",
        //         context,
        //         onClick1,
        //         onCancel1));
        // // Navigator.pop(context);

        return false;
      } else {
        setState(() {
          pageIndex = 0;
        });
        return false;
      }
    }

    return WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          /* appBar: userName == '' && profileImage == '' && pageIndex==1
                ? CustomAppBar(userName, profileImage, onClick)
                : null,*/
            body: isoffline == false
                ? pages[pageIndex]
                : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Image(
                  //   height: 300, width: MediaQuery.of(context).size.width,
                  //   image: const AssetImage("images/no_internet_connection.png"),
                  // )

                ],
              ),
            ),


          bottomNavigationBar: _buildBottomNavigationBar(),
        ));
  }

  Container buildBottomBar(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        //color:Color(int.parse(GetStorage().read("mycolor").replaceAll('#', '0xff'))),
        color: Colors.blue[20],

        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(0), topRight: Radius.circular(0)),
      ),
      child: Column(
        children: [
          // new Divider(
          //   color: Colors.black,
          // ),
          Padding(
            padding: const EdgeInsets.only(top:2.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                    enableFeedback: false,
                    onPressed: () {
                      setState(() {
                        pageIndex = 0;
                      });
                    },
                    icon: pageIndex == 0
                        ? const Icon(Icons.home,
                      size: 20,
                      color:  Colors.blue,
                    )
                        : const Icon(Icons.home,
                      size: 20,
                      color: Colors.black,
                    )),

                IconButton(
                    enableFeedback: false,
                    onPressed: () {
                      setState(() {
                        pageIndex = 1;
                      });
                    },
                    icon: pageIndex == 1
                        ? const Icon(Icons.favorite,
                      size: 20,
                      color:  Colors.blue,
                    )
                        : const Icon(Icons.favorite,
                      size: 20,
                      color: Colors.black,
                    )),
                IconButton(
                    enableFeedback: false,
                    onPressed: () {
                      setState(() {
                        pageIndex = 2;
                      });
                    },
                    icon: pageIndex == 2
                        ? const Icon(Icons.person,
                      size: 20,
                      color: Colors.blue,
                    )
                        : const Icon(Icons.person,
                      size: 20,
                      color: Colors.black,
                    )),


              ],
            ),
          ),
        ],
      ),
    );
  }

  onClick1(String p1, String p2) {
    SystemNavigator.pop();
  }

  onCancel1() {}

  // setPreferenceValue() async {
  //   PreferenceManager preferenceManager = PreferenceManager.instance;
  //   setState(() {
  //     preferenceManager.getStringValue("ClientUrl").then((value) => setState(() {
  //       clientUrl = value;
  //     }));
  //     preferenceManager.getStringValue("customer_id").then((value) => setState(() {
  //       customerId = value;
  //     }));
  //     preferenceManager.getStringValue("user_id").then((value) => setState(() {
  //       userId = value;
  //     }));
  //     preferenceManager.getStringValue("userName").then((value) => setState(() {
  //       userName = value;
  //     }));
  //     preferenceManager.getStringValue("profileImage").then((value) => setState(() {
  //       profileImage = value;
  //     }));
  //   });
  // }



  onClick(String title) {
    log('AppBar Click::==> $title');
    if (title == 'Profile') {
      // Navigator.push(
      //     context,
      //     MaterialPageRoute(
      //         builder: (BuildContext context) => const ProfileScreen()))
      //     .then((value) {
      //   if (!mounted) return;
      //   setState(() {
      //     //setPreferenceValue();
      //   });
      // });
    } else if (title == 'Notification') {
      // Navigator.push(
      //     context,
      //     MaterialPageRoute(
      //         builder: (BuildContext context) =>
      //         const NotificationScreen())).then((value) {
      //   if (!mounted) return;
      //   setState(() {
      //     setPreferenceValue();
      //   });
      // });
    }
  }

  // Bottom Navigation Bar
  Widget _buildBottomNavigationBar() {

    return BottomNavigationBar(
      currentIndex: pageIndex,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.black54,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed, // 👈 Force karo
      backgroundColor:  (appBottomColor != null && appBottomColor!.isNotEmpty)
        ? getColorFromHex(appBottomColor!)
        : Colors.white,
      elevation: 0,
      onTap: _onItemTapped,
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Product"),
        BottomNavigationBarItem(
            icon: Icon(Icons.favorite), label: "Wishlist"),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
        BottomNavigationBarItem(icon: Icon(Icons.qr_code), label: "Scan"),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Customized"),
      ],
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      if(index==0){
       pageIndex=0;
      }else if(index==1){
        pageIndex = 1;
      }else if(index==2){
        pageIndex = 2;
      }else if(index==3){
        pageIndex = 3;
      }else{
        pageIndex = index;
      }
    });
  }
}
