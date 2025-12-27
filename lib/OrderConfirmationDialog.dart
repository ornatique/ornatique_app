import 'package:flutter/material.dart';
import 'package:ornatique/OrderScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'Api_Constant/ApiConstants.dart';
import 'Api_Constant/api_helper.dart';
import 'LoadingDialog/LoadingDialog.dart';

class OrderConfirmationDialog {
  static Future<bool?> show(BuildContext context,
      {String title = "Your Estimate Confirmed!",
        String message = "Your Estimate has been Recived successfully."}) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut),
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 10,
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: _AnimatedContent(
                title: title,
                message: message,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedContent extends StatefulWidget {
  final String title;
  final String message;

  const _AnimatedContent({required this.title, required this.message});

  @override
  State<_AnimatedContent> createState() => _AnimatedContentState();
}

class _AnimatedContentState extends State<_AnimatedContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _rotationAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addOrder() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      //LoadingDialog.show(context, message: "Placing Order...");
      final body = {
        "user_id": prefs.getString('Uid').toString(),
      };
      final response = await ApiHelper().postRequest(ApiConstants.add_order, body);
     // LoadingDialog.hide(context);

      print("Add order Request: $body");
      print("Add order Response: ${response?.data}");

      if (response != null && response.statusCode == 200) {
        final result = response.data;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['status'] == "1"
                ? "Order added successfully!"
                : "Failed to add order."),
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => OrderScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Something went wrong!")),
        );
      }
    } catch (e) {
      LoadingDialog.hide(context);
      print("❌ Add Order API Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error placing order.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RotationTransition(
          turns: _rotationAnimation,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Icon(Icons.check_circle, color: Colors.blue[400], size: 90),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          widget.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
        const SizedBox(height: 25),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
              ),
              onPressed: () async {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => OrderScreen()),
                );
              },
              child: const Text(
                "OK",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            const SizedBox(width: 25),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[400],
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(14),
              ),
              onPressed: () {
                // WhatsApp action here (replace with actual logic)
                print("WhatsApp button pressed");
                _openWhatsApp();
              },
              child: Image.asset("assets/whatsapp.png",height: 25,),
            ),
          ],
        )

      ],
    );
  }

  Future<void> _openWhatsApp() async {
    final String phoneNumber = "919925823290"; // ✅ No + sign
    final String message = Uri.encodeComponent("Hello! I want to inquire about your products.");
    final Uri whatsappUrl = Uri.parse("https://wa.me/$phoneNumber?text=$message");

    // DEBUG PRINT actual URL
    debugPrint("Trying to launch: $whatsappUrl");

    final canLaunch = await canLaunchUrl(whatsappUrl);
    debugPrint("Can launch: $canLaunch");

    if (canLaunch) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      // fallback or error
      debugPrint("Could not launch WhatsApp");
      //_showErrorDialog();
    }
  }
}
