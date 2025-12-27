import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'Api_Constant/ApiConstants.dart';
import 'Api_Constant/api_helper.dart';
import 'Constant_font/FontStyles.dart';


class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  String? htmlContent;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPrivacyPolicy();
  }

  Future<void> fetchPrivacyPolicy() async {
    final response = await ApiHelper().postRequest(ApiConstants.privacy_policy, {});
    if (response != null && response.statusCode == 200) {
      setState(() {
        htmlContent = response.data['data']['privacy'];
        isLoading = false;
      });
    } else {
      setState(() {
        htmlContent = "<p>Failed to load privacy policy.</p>";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Privacy Policy ', style: FontStyles.appbar_heading),
        centerTitle: true,
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        // actions: [
        //   IconButton(
        //     icon: Icon(Icons.clear_all, color: Colors.black),
        //     onPressed: _clearAllNotifications,
        //   ),
        // ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Html(data: htmlContent),
      ),
    );
  }
}
