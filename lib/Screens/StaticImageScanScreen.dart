// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:google_ml_kit/google_ml_kit.dart';
// import 'package:image_picker/image_picker.dart';
//
// class DirectScanScreen extends StatefulWidget {
//   const DirectScanScreen({super.key});
//
//   @override
//   State<DirectScanScreen> createState() => _DirectScanScreenState();
// }
//
// class _DirectScanScreenState extends State<DirectScanScreen> {
//   File? scannedImage;
//   bool scanning = false;
//
//   final List<Map<String, String>> products = [
//     {
//       "name": "Gold Ring ANG68",
//       "image":
//       "https://ornatique.co/portal/public/assets/images/product/ANG68-(W.T-26.730).jpg",
//       "tag": "ring",
//     },
//     {
//       "name": "Gold Ring ANG89",
//       "image":
//       "https://ornatique.co/portal/public/assets/images/product/ANG68-(W.T-26.730).jpg",
//       "tag": "ring",
//     },
//     {
//       "name": "Gold Chain",
//       "image":
//       "https://ornatique.co/portal/public/assets/images/product/sample-chain.jpg",
//       "tag": "chain",
//     },
//   ];
//
//   List<Map<String, String>> result = [];
//
//   @override
//   void initState() {
//     super.initState();
//     Future.delayed(Duration.zero, openCameraAndScan);
//   }
//
//
//
//   Future<void> openCameraAndScan() async {
//     final picker = ImagePicker();
//
//     final XFile? image =
//     await picker.pickImage(source: ImageSource.camera);
//
//     if (image == null) return;
//
//     setState(() {
//       scanning = true;
//       scannedImage = File(image.path);
//     });
//
//     final inputImage = InputImage.fromFile(File(image.path));
//
//     final imageLabeler = ImageLabeler(options: ImageLabelerOptions());
//
//     final List<ImageLabel> labels = await imageLabeler.processImage(inputImage);
//
//     imageLabeler.close();
//
//     // 🔹 Convert labels to lowercase for matching
//     List<String> detectedTags =
//     labels.map((e) => e.label.toLowerCase()).toList();
//
//     print("Detected Tags: $detectedTags");
//
//     // 🔹 Filter products by detected tags
//     result = products
//         .where((p) => detectedTags.contains(p['tag']!.toLowerCase()))
//         .toList();
//
//     setState(() {
//       scanning = false;
//     });
//
//     // 🔹 Print result
//     print("Scan Result:");
//     for (var p in result) {
//       print("Name: ${p['name']}, Tag: ${p['tag']}");
//     }
//   }
//
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Scanning")),
//       body: scanning
//           ? const Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             CircularProgressIndicator(),
//             SizedBox(height: 12),
//             Text("Scanning image..."),
//           ],
//         ),
//       )
//           : ListView.builder(
//         itemCount: result.length,
//         itemBuilder: (context, index) {
//           final p = result[index];
//           return ListTile(
//             leading: Image.network(p['image']!, width: 50),
//             title: Text(p['name']!),
//             trailing: const Icon(Icons.check_circle,
//                 color: Colors.green),
//           );
//         },
//       ),
//     );
//   }
// }
