import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import 'Api_Constant/ApiConstants.dart';
import 'Api_Constant/api_helper.dart';
import 'Constant_font/FontStyles.dart';
import 'Screens/MediaPage.dart';

class VideoListScreen extends StatefulWidget {
  String cat_id, Subcat_id;
  VideoListScreen(this.cat_id, this.Subcat_id, {super.key});

  @override
  State<VideoListScreen> createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  bool isLoading = true;
  List<filterMediaItem> mediaItems = [];
  final List<VideoPlayerController> _controllers = [];

  @override
  void initState() {
    super.initState();
    fetchMedia();
  }

  Future<void> fetchMedia() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final body = {
      "category_id": widget.cat_id.toString(),
      "subcategory_id": widget.Subcat_id.toString(),
    };

    final response =
    await ApiHelper().postRequest(ApiConstants.filtermedia_list, body);
    print("category Request: $body");
    print("category Raw Response: ${response!.data}");

    if (response != null && response.statusCode == 200) {
      final jsonData =
      response.data is String ? json.decode(response.data) : response.data;

      final imageBase = jsonData["image_url"] ?? "";
      final videoBase = jsonData["video_url"] ?? "";

      List<filterMediaItem> imageList = [];
      List<filterMediaItem> videoList = [];

      for (var item in jsonData["data"] ?? []) {
        if (item["image"] != null && item["image"].toString().isNotEmpty) {
          imageList.add(filterMediaItem(
            url: "$imageBase/${item["image"]}",
            isVideo: false,
            name: item["name"] ?? "",
            description: item["description"] ?? "",
            id: item["id"].toString(),
            categoryId: item["category_id"].toString(),
            subcategoryId: item["subcategory_id"].toString(),
            isLiked: item["is_liked"] == 1,
          ));
        }
        if (item["media_file"] != null &&
            item["media_file"].toString().isNotEmpty) {
          videoList.add(filterMediaItem(
            url: "$videoBase/${item["media_file"]}",
            isVideo: true,
            name: item["name"] ?? "",
            description: item["description"] ?? "",
            id: item["id"].toString(),
            categoryId: item["category_id"].toString(),
            subcategoryId: item["subcategory_id"].toString(),
            isLiked: item["is_liked"] == 1,
          ));
        }
      }

      // merge images & videos
      List<filterMediaItem> mergedList = [];
      int maxLength =
      imageList.length > videoList.length ? imageList.length : videoList.length;

      for (int i = 0; i < maxLength; i++) {
        if (i < imageList.length) mergedList.add(imageList[i]);
        if (i < videoList.length) mergedList.add(videoList[i]);
      }

      setState(() {
        mediaItems = mergedList;
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String formatDuration(Duration position) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(position.inMinutes)}:${twoDigits(position.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Media Story", style: FontStyles.appbar_heading),
        //backgroundColor: Colors.black,
        //foregroundColor: Colors.white,
      ),
      //backgroundColor: Colors.black,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: mediaItems.length,
        itemBuilder: (context, index) {
          final media = mediaItems[index];

          return Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 5.0, vertical: 10),
            child: GestureDetector(

              child: Card(
                color: Colors.grey[900],
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 Image or Video
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12)),
                      child: media.isVideo
                          ? GestureDetector(
                        onTap: () {
                          // 🔹 Single tap -> Popup ma image open
                          showGeneralDialog(
                            context: context,
                            barrierDismissible: true,
                            barrierLabel: "Popup",
                            transitionDuration: const Duration(milliseconds: 600),
                            pageBuilder: (context, animation, secondaryAnimation) {
                              return Center(
                                child: Material(
                                  color: Colors.transparent,
                                  child: ScaleTransition(
                                    scale: animation,
                                    child: Stack(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(20.0),
                                          child: Container(
                                            width: MediaQuery.of(context).size.width, // 🔹 Full width
                                            // decoration: BoxDecoration(
                                            //   color: Colors.white,
                                            //   borderRadius: BorderRadius.circular(15),
                                            // ),
                                            child: SizedBox(
                                              width: double.infinity, // 🔹 Full width instead of 100
                                              height: MediaQuery.of(context).size.height * 0.6, // 🔹 Height control
                                              child: VideoPlayerWidget(videoUrl: media.url, isPopup: true),
                                            ),
                                          ),
                                        ),

                                        // 🔹 Close Button
                                        Positioned(
                                          top: 30,
                                          //right: 70,
                                          left: 60,
                                          child: InkWell(
                                            onTap: () => Navigator.pop(context),
                                            child: Container(
                                              decoration: const BoxDecoration(
                                                color: Colors.black54,
                                                shape: BoxShape.circle,
                                              ),
                                              padding: const EdgeInsets.all(6),
                                              child: Image.asset(
                                                'assets/close.png',
                                                height: 20,
                                                width: 20,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                            transitionBuilder: (context, animation, secondaryAnimation, child) {
                              return FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(scale: animation, child: child),
                              );
                            },
                          );

                        },
                        onDoubleTap: (){
                          if (!media.isLiked) {   // ✅ jo already liked nathi to j toggle karvu
                            toggleLike(media.id, index);
                          }
                        },
                            child: AspectRatio(
                                                    aspectRatio: 16 / 12,
                                                    child: VideoPlayerWidget(videoUrl: media.url,isPopup: true),
                                                  ),
                          )
                          : GestureDetector(
                        onTap: () {
                          // 🔹 Single tap -> Popup ma image open
                          showGeneralDialog(
                            context: context,
                            barrierDismissible: true,
                            barrierLabel: "Popup",
                            transitionDuration: const Duration(milliseconds: 600),
                            pageBuilder: (context, animation, secondaryAnimation) {
                              return Center(
                                child: Material(
                                  color: Colors.transparent,
                                  child: ScaleTransition(
                                    scale: animation,
                                    child: Stack(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(20.0),
                                          child: Container(
                                            width: MediaQuery.of(context).size.width * 0.9,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(15),
                                              boxShadow: [
                                                BoxShadow(color: Colors.black26, blurRadius: 10),
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(10),
                                              child: SizedBox(
                                                height: 400,
                                                width: double.infinity,
                                                child: CachedNetworkImage(
                                                  imageUrl: media.url,
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) =>
                                                  const Center(child: CircularProgressIndicator()),
                                                  errorWidget: (context, url, error) =>
                                                  const Center(child: Icon(Icons.error)),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                        // 🔹 Close Button
                                        Positioned(
                                          top: 30,
                                          right: 30,
                                          child: InkWell(
                                            onTap: () => Navigator.pop(context),
                                            child: Container(
                                              decoration: const BoxDecoration(
                                                color: Colors.black54,
                                                shape: BoxShape.circle,
                                              ),
                                              padding: const EdgeInsets.all(6),
                                              child: Image.asset(
                                                'assets/close.png',
                                                height: 20,
                                                width: 20,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                            transitionBuilder: (context, animation, secondaryAnimation, child) {
                              return FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(scale: animation, child: child),
                              );
                            },
                          );
                        },
                        onDoubleTap: (){
                          if (!media.isLiked) {   // ✅ jo already liked nathi to j toggle karvu
                            toggleLike(media.id, index);
                          }
                        },
                            child: Image.network(
                                                    media.url,
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                    height: 250,
                                                  ),
                          ),
                    ),

                    // 🔹 Name
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        media.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    // 🔹 Description
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        media.description,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                      ),
                    ),

                    // 🔹 Like Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(
                            media.isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color:
                            media.isLiked ? Colors.red : Colors.white,
                          ),
                          onPressed: () {
                            toggleLike(media.id, index);
                          },
                        ),
                        InkWell(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) =>
                                  CommentBottomSheet(postId: media.id),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(Icons.chat_bubble_outline,color: Colors.white, size: 25),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> toggleLike(String mediaId, int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("Uid").toString();

    final dio = Dio();

    try {
      final response = await dio.post(
        "https://ornatique.co/portal/api/media/like-toggle",
        data: {
          "user_id": userId,
          "media_id": mediaId,
        },
      );

      if (response.statusCode == 200) {
        final jsonData = response.data;
        if (jsonData["status"] == "1") {
          setState(() {
            mediaItems[index].isLiked = !mediaItems[index].isLiked;
          });
        }
        print("Like toggle: ${jsonData["message"]}");
      }
    } catch (e) {
      print("Like toggle error: $e");
    }
  }
}

class filterMediaItem {
  final String url;
  final bool isVideo;
  final String name;
  final String description;
  final String id;
  final String categoryId;
  final String subcategoryId;
  bool isLiked;

  filterMediaItem({
    required this.url,
    required this.isVideo,
    required this.name,
    required this.description,
    required this.id,
    required this.categoryId,
    required this.subcategoryId,
    this.isLiked = false,
  });
}
