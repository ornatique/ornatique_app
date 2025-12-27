import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ornatique/BeadSizerScreen.dart';
import 'package:ornatique/Screens/CustomizeEstimateScreen.dart';
import 'package:ornatique/Screens/EditProfile.dart';
import 'package:ornatique/SocialPage.dart';
import 'package:ornatique/TermsScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'Api_Constant/ApiConstants.dart';
import 'Api_Constant/api_helper.dart';
import 'ConstantColors/Color_Constant.dart';
import 'Constant_font/FontStyles.dart';
import 'Login/login_screen.dart';
import 'OrderScreen.dart';
import 'PrivacyPolicyPage.dart';
import 'Screens/CustomOrderListScreen.dart';
import 'Screens/MediaPage.dart';

class GlobalDrawer extends StatefulWidget {
  const GlobalDrawer({Key? key}) : super(key: key);

  @override
  State<GlobalDrawer> createState() => _GlobalDrawerState();
}

class _GlobalDrawerState extends State<GlobalDrawer> {
  String? name ;
  String? email ;
  String? uid;
  var pageIndex = 0;
  String capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getuserdata();
  }
  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 250,
      backgroundColor: Color_Constant.background,
      child: Column(
        children: [
          Column(
            children: [
              Container(
                padding: EdgeInsets.only(top: 80,left: 10,bottom: 20),
                decoration: BoxDecoration(
                  color: Color_Constant.background,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: AssetImage("assets/user.png"),
                    ),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name != null && name!.isNotEmpty ? capitalize(name!) : "John Doe",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        SizedBox(height: 4),
                        SizedBox(
                          width: 160,
                          child: Text(
                            email ?? "johndoe@example.com",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30,),
              Divider(height: 0, thickness: 0.2, indent: 0, endIndent: 0,color: Colors.black,),
              _buildDrawerItem('assets/sale.png', "Your Estimate", OrderScreen(),color: Colors.black),
              // Padding(
              //   padding: const EdgeInsets.only(top:0.0),
              //   child:ListTile(
              //     leading: Image.asset("assets/home.png", height: 25)
              //         .animate()
              //         .fade(duration: 800.ms)
              //         .moveY(begin: -50, end: 0),
              //     title: Text("Home", style: FontStyles.offer_heading),
              //     dense: true,
              //     onTap: () {
              //       Navigator.pop(context);
              //     },
              //   )
              // ),

              _buildDivider(),
              Padding(
                  padding: const EdgeInsets.only(top:0.0),
                  child:ListTile(
                    leading: Image.asset("assets/settings.png",color:Colors.black, height: 25)
                        .animate()
                        .fade(duration: 800.ms)
                        .moveY(begin: -50, end: 0),
                    title: Text("Customized Estimate", style: FontStyles.offer_heading),
                    dense: true,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CustomOrderListScreen()),
                      );
                     // Navigator.of(context);
                    },
                  )
              ),
             // _buildDrawerItem('assets/settings.png', "Customized Estimate", null),
              _buildDivider(),
              Padding(
                  padding: const EdgeInsets.only(top:0.0),
                  child:ListTile(
                    leading: Image.asset("assets/telephone-book.png",color:Colors.black ,height: 25)
                        .animate()
                        .fade(duration: 800.ms)
                        .moveY(begin: -50, end: 0),
                    title: Text("Contact Us", style: FontStyles.offer_heading),
                    dense: true,
                    onTap: () {
                      Navigator.pop(context);
                      final phone = "tel:+91 9925823290"; // replace with actual number
                      launchUrl(Uri.parse(phone));
                    },
                  )
              ),
              //_buildDrawerItem('assets/telephone-book.png', "Contact Us", null),
              _buildDivider(),
              Padding(
                  padding: const EdgeInsets.only(top:0.0),
                  child:ListTile(
                    leading: Image.asset("assets/social-media.png",color:Colors.black, height: 25)
                        .animate()
                        .fade(duration: 800.ms)
                        .moveY(begin: -50, end: 0),
                    title: Text("Social", style: FontStyles.offer_heading),
                    dense: true,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SocialPage()),
                      );
                    },
                  )
              ),
              _buildDivider(),
              Padding(
                  padding: const EdgeInsets.only(top:0.0),
                  child:ListTile(
                    leading: Image.asset("assets/social-media.png",color:Colors.black, height: 25)
                        .animate()
                        .fade(duration: 800.ms)
                        .moveY(begin: -50, end: 0),
                    title: Text("Media Page", style: FontStyles.offer_heading),
                    dense: true,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MediaPage()),
                      );
                    },
                  )
              ),
              _buildDivider(),
              // _buildDrawerItem('assets/privacy-policy.png', "Privacy Policy", PrivacyPolicyPage()),
              // _buildDivider(),
              // _buildDrawerItem('assets/privacy-policy.png', "Terms & Condition", TermsScreen()),
              // _buildDivider(),
              uid != "null"
                  ? _buildDrawerItem('assets/user.png', "Profile", EditProfile())
                  : SizedBox.shrink(),
              _buildDivider(),
              Padding(
                  padding: const EdgeInsets.only(top:0.0),
                  child:ListTile(
                    leading: Image.asset("assets/marriage.png",color:Colors.black, height: 25)
                        .animate()
                        .fade(duration: 800.ms)
                        .moveY(begin: -50, end: 0),
                    title: Text("GB Bead Sizer", style: FontStyles.offer_heading),
                    dense: true,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => BeadSizerScreen()),
                      );
                    },
                  )
              ),
              _buildDivider(),
              // _buildDrawerItem('assets/settings.png', "Settings", null),
              // _buildDivider(),
              Padding(
                  padding: const EdgeInsets.only(top:0.0),
                  child:ListTile(
                    leading: Image.asset("assets/logout.png", color:Colors.black,height: 25)
                        .animate()
                        .fade(duration: 800.ms)
                        .moveY(begin: -50, end: 0),
                    title: Text("Logout", style: FontStyles.offer_heading),
                    dense: true,
                    onTap: () {
                      //Navigator.pop(context);
                      _showLogoutDialog(); // Use safe context
                    },
                  )
              ),
              _buildDivider(),

            ],
          ),
          _buildFooter(),
        ],
      ),
    );


  }

  void showFooterBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        height: 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("App Version: 1.0.0", style: TextStyle(fontSize: 16)),
            Text("Contact Support: support@ornatique.com", style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }


  Widget _buildDrawerItem(String iconPath, String title, Widget? page,{Color? color}) {
    return ListTile(
      leading: Image.asset(iconPath,color: color ?? Colors.black, height: 25)
          .animate()
          .fade(duration: 800.ms)
          .moveY(begin: -50, end: 0),
      title: Text(title, style: FontStyles.offer_heading),
      dense: true,
      onTap: () {
        Navigator.pop(context);
         if (page != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        }
      },
    );
  }

  void _showLogoutDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Logout",
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.logout, size: 50, color: Colors.redAccent),
                  SizedBox(height: 16),
                  Text(
                    "Logout",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Are you sure you want to logout?",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // CLOSE
                        },
                        child: Text("Cancel", style: TextStyle(fontSize: 16)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // CLOSE

                          _logoutUser(); // CALL LOGOUT
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text("Logout", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }




  Future<void> _logoutUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final body = {
      "user_id": prefs.getString("Uid").toString()=="null"?"20":prefs.getString("Uid").toString(),  // Ensure this user ID is dynamically fetched from shared prefs
    };

    print("Logout Request: $body");

    try {
      final response = await ApiHelper().postRequest(ApiConstants.logout, body);
      print("Logout Response: ${response?.data}");

      if (response != null && response.statusCode == 200) {
        final status = response.data['status'];
        print("API status field: $status");

        if (status == "1") {
          // Clear SharedPreferences
          //await prefs.clear();
          prefs.remove("Uid").toString();
          print("SharedPreferences Cleared ✅");

          if (!mounted) return;  // Check if widget is still mounted

          // // Ensure the drawer is closed before navigating
          // Navigator.of(context).pop();  // Close the drawer
          //
          // // Delay to ensure that the drawer is fully closed
          // await Future.delayed(Duration(milliseconds: 300));

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );


          print('Logout success: ${response.data['message']}');
        } else {
          print('Logout failed: ${response.data['message']}');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Logout failed: ${response.data['message']}")),
          );
        }
      } else {
        print('Logout failed: Invalid status code');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Logout failed: Network Error")),
        );
      }
    } catch (e, stackTrace) {
      print("Logout Exception: $e");
      print("Stacktrace: $stackTrace");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Something went wrong!")),
      );
    }
  }

  Widget _buildDivider() {
    return Divider(height: 0, thickness: 0.2, indent: 5, endIndent: 10,color: Colors.black,);
  }

  Widget _buildFooter() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Text("By Ornatique Silver", style: FontStyles.offer_heading),
          SizedBox(height: 5),
          Text("Version 1.0.0", style: FontStyles.offer_heading),
        ],
      ),
    );
  }

  Future<void> getuserdata() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.getString('Uid').toString()??"";
      name = prefs.getString('name').toString()??"";
      email = prefs.getString('email').toString()??"";
      print(prefs.getString('Uid').toString());
      print(prefs.getString('name').toString());
      print(prefs.getString('email').toString());
    });
  }
}
