import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../Api_Constant/ApiConstants.dart';
import '../Api_Constant/api_helper.dart';
import '../ConstantColors/Color_Constant.dart';
import '../Constant_font/FontStyles.dart';

class MediaPage extends StatefulWidget {
  const MediaPage({super.key});

  @override
  State<MediaPage> createState() => _MediaPageState();
}

class _MediaPageState extends State<MediaPage> {
  List<MediaItem> mediaItems = [];
  bool isLoading = true;
  Color? appBarColor;
  Future<void> _loadAppBarColor() async {
    appBarColor = await AppColorHelper.getAppBarColor();
    setState(() {});
  }
  @override
  void initState() {
    super.initState();
    _loadAppBarColor();
    fetchMedia();
  }

  Future<void> fetchMedia() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final body = {
      "user_id": prefs.getString("Uid").toString(),
    };

    final response = await ApiHelper().postRequest(ApiConstants.media_list, body);
    print("category Request: $body");
    print("category Raw Response: ${response!.data}");

    if (response != null && response.statusCode == 200) {
      // Agar response.data string hoy to decode karo, na hoy to direct use karo
      final jsonData = response.data is String
          ? json.decode(response.data)
          : response.data;

      final imageBase = jsonData["image_url"] ?? "";
      final videoBase = jsonData["video_url"] ?? "";

      List<MediaItem> imageList = [];
      List<MediaItem> videoList = [];

      for (var item in jsonData["data"] ?? []) {
        // Image
        if (item["image"] != null && item["image"].toString().isNotEmpty) {
          imageList.add(MediaItem(
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
        if (item["media_file"] != null && item["media_file"].toString().isNotEmpty) {
          videoList.add(MediaItem(
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

      // Merge in alternating order
      List<MediaItem> mergedList = [];
      int maxLength = imageList.length > videoList.length
          ? imageList.length
          : videoList.length;

      for (int i = 0; i < maxLength; i++) {
        if (i < imageList.length) mergedList.add(imageList[i]);
        if (i < videoList.length) mergedList.add(videoList[i]);
      }

      setState(() {
        mediaItems = mergedList;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }







  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Explore", style: FontStyles.appbar_heading),
        elevation: 0,
        backgroundColor: appBarColor ?? Colors.white,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(4.0),
        child: MasonryGridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          itemCount: mediaItems.length,
          itemBuilder: (context, index) {
            final media = mediaItems[index];
            return GestureDetector(
              onTap: () {
                final currentMedia = mediaItems[index];

                // 🔹 Related list filter (category wise)
                final relatedList = mediaItems.where((m) =>
                m.categoryId == currentMedia.categoryId
                ).toList();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FullScreenPostPage(mediaItems: relatedList)),
                );
              },
              child: Hero(
                tag: media.url,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: media.isVideo
                      ? SizedBox(
                    //height: 200,
                    child: FittedBox(
                      fit: BoxFit.fill,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width / 2,
                        child: VideoPlayerWidget(videoUrl: media.url),
                      ),
                    ),
                  )
                      : CachedNetworkImage(
                    imageUrl: media.url,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(height: 150, color: Colors.grey[800]),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class MediaItem {
  final String url;
  final bool isVideo;
  final String name;
  final String description;
  final String id;
  final String categoryId;
  final String subcategoryId;
  bool isLiked;

  MediaItem({
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

class FullScreenPostPage extends StatefulWidget {
  final List<MediaItem> mediaItems;

  const FullScreenPostPage({super.key, required this.mediaItems});

  @override
  State<FullScreenPostPage> createState() => _FullScreenPostPageState();
}

class _FullScreenPostPageState extends State<FullScreenPostPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Posts",
          style: TextStyle(color: Colors.black),
        ),
        elevation: 0,
      ),
      body: ListView.builder(
        itemCount: widget.mediaItems.length,
        itemBuilder: (context, index) {
          final media = widget.mediaItems[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey[200],
                        child: ClipOval(
                          child: Image.asset(
                            "assets/logo.jpg",
                            fit: BoxFit.cover,
                            width: 40,
                            height: 40,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Ornatique Silver",
                          style: GoogleFonts.playfairDisplay(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const Icon(Icons.more_vert),
                    ],
                  ),
                ),

                // Media
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Hero(
                    tag: media.url,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
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
                                          left: 50,
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
                                                    aspectRatio: 16 / 9,
                                                    child: VideoPlayerWidget(videoUrl: media.url),
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
                            child: CachedNetworkImage(
                                                    imageUrl: media.url,
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                    height: 400,
                                                    placeholder: (context, url) =>
                                                    const Center(child: CircularProgressIndicator()),
                                                    errorWidget: (context, url, error) =>
                                                    const Center(child: Icon(Icons.error)),
                                                  ),
                          ),
                    ),
                  ),
                ),

                // Like / Comment / Share Row
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        media.isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 25,
                        color: media.isLiked ? Colors.red : Colors.black,
                      ),
                      onPressed: () {
                        toggleLike(media.id, index);
                      },
                    ),
                    const SizedBox(width: 0),
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
                      child: const Icon(Icons.chat_bubble_outline, size: 25),
                    ),
                    // const SizedBox(width: 10),
                    // const Icon(Icons.send_outlined, size: 25),
                  ],
                ),



// Likes text like Instagram
                if (media.isLiked) // Only show if liked
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: "Liked by ",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          TextSpan(
                            text: media.name, // Replace with username
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const TextSpan(
                            text: " and others",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),


                // Description like Instagram
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "${media.name} ", // Username
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                        TextSpan(
                          text: media.description, // Post caption
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                            height: 1.4, // Spacing like Instagram
                          ),
                        ),
                      ],
                    ),
                    maxLines: 3, // Optional: limit lines
                    overflow: TextOverflow.ellipsis, // Show "..."
                  ),
                ),
                const SizedBox(height: 0),

                // // Time
                // const Padding(
                //   padding: EdgeInsets.symmetric(horizontal: 12),
                //   child: Text(
                //     "2 hours ago",
                //     style: TextStyle(fontSize: 12),
                //   ),
                // ),
              ],
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
            widget.mediaItems[index].isLiked =
            !widget.mediaItems[index].isLiked;
          });
        }
        print("Like toggle: ${jsonData["message"]}");
      }
    } catch (e) {
      print("Like toggle error: $e");
    }
  }
}








class CommentBottomSheet extends StatefulWidget {
  final String postId;
  const CommentBottomSheet({super.key, required this.postId});

  @override
  State<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<CommentBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  final Dio _dio = Dio();

  List comments = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    getComments(widget.postId);
  }

  Future<void> getComments(String postId) async {
    final dio = Dio();

    try {
      final response = await dio.post(
        "https://ornatique.co/portal/api/media/comments",
        data: {
          "media_id": postId,
        },
        // options: Options(
        //   headers: {
        //     "Accept": "application/json",
        //     "Content-Type": "application/json",
        //   },
        // ),
      );

      if (response.statusCode == 200 && response.data["status"] == "1") {
        setState(() {
          comments = response.data["comments"] ?? [];
          //isLoading = false;
        });
      } else {
        setState(() {
          comments = [];
          //isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching comments: $e");
    }
  }

  Future<void> _sendComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("Uid") ?? "";

    try {
      final res = await _dio.post(
        "https://ornatique.co/portal/api/media/add-comment",
        data: {
          "user_id": userId,
          "media_id": widget.postId,
          "comment": text,
        },
      );

      if (res.statusCode == 200 && res.data["status"] == "1") {
        _controller.clear();
        await getComments(widget.postId); // Refresh after adding comment
      }
    } catch (e) {
      debugPrint("Add comment error: $e");
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom, // Keyboard height adjust
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Container(
                  height: 4,
                  width: 40,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  "Comments",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 10),

                // Comment List
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final c = comments[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CircleAvatar(
                              backgroundImage: NetworkImage(
                                "https://source.unsplash.com/random/40",
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      style: const TextStyle(color: Colors.black),
                                      children: [
                                        TextSpan(
                                          text: "Test ",
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        TextSpan(text: c['comment']),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "2h ago",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Comment Input
                SafeArea(
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundImage:
                        NetworkImage("https://source.unsplash.com/random/40"),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: "Add a comment...",
                            filled: true,
                            fillColor: Colors.grey[200],
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: _isSending
                            ? const CircularProgressIndicator(strokeWidth: 2)
                            : const Icon(Icons.send, color: Colors.blue),
                        onPressed: _isSending ? null : _sendComment,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}



class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool isPopup;
  const VideoPlayerWidget({
    Key? key,
    required this.videoUrl,
    this.isPopup = false, // default false
  }) : super(key: key);

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isVisible = false;
  bool _isLoading = true;
  bool _isMuted = true; // 🔇 by default muted

  @override
  void initState() {
    super.initState();
    _preloadVideo();
  }

  Future<void> _preloadVideo() async {
    try {
      File file = await DefaultCacheManager().getSingleFile(widget.videoUrl);

      _controller = VideoPlayerController.file(file)
        ..setLooping(true)
        ..setVolume(0); // 🔇 start muted

      await _controller!.initialize();
      setState(() => _isLoading = false);

      if (_isVisible) _controller!.play();
    } catch (e) {
      print("Video preload error: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    final isNowVisible = info.visibleFraction > 0.6;
    setState(() => _isVisible = isNowVisible);

    if (_controller != null && _controller!.value.isInitialized) {
      isNowVisible ? _controller!.play() : _controller!.pause();
    }
  }

  void _toggleMute() {
    if (_controller == null) return;
    setState(() {
      _isMuted = !_isMuted;
      _controller!.setVolume(_isMuted ? 0 : 1); // 🔊 toggle volume
    });
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.videoUrl),
      onVisibilityChanged: _onVisibilityChanged,
      child: _isLoading
          ? Container(
        height: 200,
        color: Colors.black12,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      )
          : _controller != null && _controller!.value.isInitialized
          ? Stack(
        alignment: Alignment.bottomCenter,
        children: [
          AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: VideoPlayer(_controller!),
          ),

          // 🔊 Mute/Unmute Button like Instagram
          // 🔹 Mute Button
          Positioned(
            top: 10,
            right: widget.isPopup  ? 30 : 10, // ✅ Popup hoy to 20, normal hoy to 10
            child: GestureDetector(
              onTap: _toggleMute,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isMuted ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),

// 🔹 Video Progress (popup hoy to hide)
          if (!widget.isPopup) // ✅ popup hoy to progress indicator remove
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(
                _controller!,
                allowScrubbing: false,
                colors: VideoProgressColors(
                  playedColor: Colors.red,
                  backgroundColor: Colors.grey,
                ),
              ),
            ),

        ],
      )
          : const SizedBox(),
    );
  }
}

