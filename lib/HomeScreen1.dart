import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Api_Constant/ApiConstants.dart';
import 'Api_Constant/api_helper.dart';
import 'Screens/MainCategoryScreen.dart';

class HomeScreen1 extends StatefulWidget {
  const HomeScreen1({super.key});

  @override
  State<HomeScreen1> createState() => _HomeScreen1State();
}

class _HomeScreen1State extends State<HomeScreen1> {
  List<dynamic> homelayout = [];
  List<dynamic> homeinside_App_layout = [];

  Widget? topLayoutWidget;
  Widget? bottomLayoutWidget;

  Color defaultBgColor = Colors.white;

  @override
  void initState() {
    super.initState();
    callGetLayout();
  }

  // 🔹 First API: layouts
  Future<void> callGetLayout() async {
    final response = await ApiHelper().getRequest(ApiConstants.layout);
    print("Layout Response: ${response.toString()}");

    if (response != null && response.statusCode == 200) {
      final data = response.data;

      if (data['status'] == true) {
        homelayout = data['data'];

        for (int i = 0; i < homelayout.length; i++) {
          final layout = homelayout[i];
          final shape = layout['shape'] ?? 'rectangle';
          final layoutId = layout['id']?.toString() ?? '';
          Color containerBgColor = defaultBgColor;
          Color? borderColor;

          final colorHex = layout['color'] ?? '';
          final borderHex = layout['border'];

          try {
            if (colorHex.isNotEmpty) {
              containerBgColor =
                  Color(int.parse(colorHex.replaceFirst('#', '0xff')));
            }
            if (borderHex != null && borderHex.isNotEmpty) {
              borderColor =
                  Color(int.parse(borderHex.replaceFirst('#', '0xff')));
            }
          } catch (e) {
            containerBgColor = defaultBgColor;
            borderColor = null;
          }

          // 🔹 Fetch inside layout for horizontal list
          await callGetHomeInsideLayout(layoutId);

          // 🔹 Build widget
          final layoutWidget = buildLayoutWidget(layout,
              containerBgColor: containerBgColor, borderColor: borderColor);

          // 🔹 Assign top/bottom widget by index or shape
          if (i == 0 || shape == 'circle') {
            topLayoutWidget = layoutWidget;
          } else {
            bottomLayoutWidget = layoutWidget;
          }
        }

        setState(() {});
      }
    }
  }

  // 🔹 Second API: inside layout for horizontal list
  Future<void> callGetHomeInsideLayout(String layoutId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("Uid") ?? "";

    final uri = Uri.parse(ApiConstants.insideapplayout).replace(
      queryParameters: {
        "user_id": userId,
        "layout_id": layoutId,
      },
    );

    print("Inside App layout GET Request: $uri");

    final response = await ApiHelper().getRequest(uri.toString());

    print("Inside App layout GET Response: ${response.toString()}");

    if (response != null && response.statusCode == 200) {
      final data = response.data;

      setState(() {
        homeinside_App_layout = data['data'] ?? [];
      });

      print("✅ homeinside_App_layout: $homeinside_App_layout");
    } else {
      print("❌ GET request failed or server error");
    }
  }

  // 🔹 Layout builder
  Widget buildLayoutWidget(Map<String, dynamic> layout,
      {Color? containerBgColor, Color? borderColor}) {
    final shape = layout['shape'] ?? 'rectangle';
    final layoutImage = layout['image'] ?? '';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: containerBgColor ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Background image
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: layoutImage.isNotEmpty
                    ? Image.network(
                  layoutImage,
                  width: double.infinity,
                  height: 500,
                  fit: BoxFit.fill,
                  errorBuilder: (context, error, stackTrace) =>
                      Image.asset(
                        'assets/layout_2.png',
                        width: double.infinity,
                        height: 500,
                        fit: BoxFit.fill,
                      ),
                )
                    : Image.asset(
                  'assets/layout_2.png',
                  width: double.infinity,
                  height: 500,
                  fit: BoxFit.fill,
                ),
              ),
              // Overlay text + button
              Positioned(
                top: 50,
                left: 25,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Men’s",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8C6A3E),
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Collection",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 25,
                right: 10,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8C6A3E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 12),
                  ),
                  child: const Text(
                    "Explore",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Horizontal list for circle layout
          if (shape == 'circle' && homeinside_App_layout.isNotEmpty)
            buildCircleList(borderColor),

          // Horizontal list for rectangle layout
          if ((shape == 'rectangle' || shape == 'rectangle_with_border') &&
              homeinside_App_layout.isNotEmpty)
            buildRectangleList(borderColor),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget buildCircleList(Color? borderColor) {
    return Container(
      height: 125,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: homeinside_App_layout.length,
        itemBuilder: (context, index) {
          final category = homeinside_App_layout[index];
          final imageUrl = category['category']['image'] ?? '';
          final name = (category['category'] != null && category['category']['name'] != null)
              ? category['category']['name']
              : (category['subcategory'] != null && category['subcategory']['name'] != null)
              ? category['subcategory']['name']
              : '';
          final catid = category['id'] ?? '';

          return Column(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MainCategoryScreen(catid.toString(), name),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: borderColor != null
                        ? Border.all(color: borderColor, width: 2)
                        : null,
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      height: 90,
                      width: 90,
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Text(name.toString()),
            ],
          );
        },
      ),
    );
  }

  Widget buildRectangleList(Color? borderColor) {
    return Container(
      height: 125,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: homeinside_App_layout.length,
        itemBuilder: (context, index) {
          final category = homeinside_App_layout[index];
          final imageUrl = category['category']['image'] ?? '';
          final name = category['subcategory'] != null
              ? category['subcategory']['name']
              : category['category']['name'] ?? '';
          final catid = category['id'] ?? '';

          return Column(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MainCategoryScreen(catid.toString(), name),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(10),
                    border: borderColor != null
                        ? Border.all(color: borderColor, width: 2)
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      height: 90,
                      width: 90,
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Text(name),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (topLayoutWidget != null) topLayoutWidget!,
            const SizedBox(height: 100),
            if (bottomLayoutWidget != null) bottomLayoutWidget!,
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
