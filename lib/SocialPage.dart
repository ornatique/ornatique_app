import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'Api_Constant/ApiConstants.dart';
import 'Api_Constant/api_helper.dart';
import 'ConstantColors/Color_Constant.dart';
import 'Constant_font/FontStyles.dart';

class SocialPage extends StatefulWidget {
  const SocialPage({Key? key}) : super(key: key);

  @override
  State<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage> {
  List<Map<String, dynamic>> apps = [];

  // Define icon and color for each platform
  final Map<String, Map<String, dynamic>> socialMeta = {
    'facebook': {
      'icon': FontAwesomeIcons.facebookF,
      'color': Colors.blue,
    },
    'twitter': {
      'icon': FontAwesomeIcons.twitter,
      'color': Colors.lightBlue,
    },
    'instagram': {
      'icon': FontAwesomeIcons.instagram,
      'color': Colors.purple,
    },
    'linkedin': {
      'icon': FontAwesomeIcons.linkedin,
      'color': Colors.blueAccent,
    },
    'whatsapp': {
      'icon': FontAwesomeIcons.whatsapp,
      'color': Colors.green,
    },
    'youtube': {
      'icon': FontAwesomeIcons.youtube,
      'color': Colors.red,
    },
  };
  Color? appBarColor;
  Future<void> _loadAppBarColor() async {
    appBarColor = await AppColorHelper.getAppBarColor();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _loadAppBarColor();
    fetchSocialLinks();
  }

  Future<void> fetchSocialLinks() async {
    final response = await ApiHelper().postRequest(ApiConstants.social, {});

    if (response != null && response.statusCode == 200) {
      final data = response.data;
      final socialData = data['data'][0];

      apps.clear();
      socialData.forEach((key, value) {
        // Skip twitter and linkedin
        if ((key == 'twitter' || key == 'linkedin')) return;

        if (socialMeta.containsKey(key) && value != null && value.toString().isNotEmpty) {
          apps.add({
            'name': key[0].toUpperCase() + key.substring(1),
            'icon': socialMeta[key]!['icon'],
            'color': socialMeta[key]!['color'],
            'url': value,
          });
        }
      });

      setState(() {});
    }
  }


  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Connect With Us!",style: FontStyles.appbar_heading),
        backgroundColor: appBarColor ?? Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: apps.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          itemCount: apps.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 0.8,
          ),
          itemBuilder: (context, index) {
            final app = apps[index];
            return InkWell(
              onTap: () => _launchURL(app['url']),
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: app['color'],
                    child: FaIcon(
                      app['icon'],
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    app['name'],
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
