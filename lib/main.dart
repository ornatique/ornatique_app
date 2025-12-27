// import 'package:flutter/material.dart';
// import 'package:ornatique/Login/Splash_Screen.dart';
//
// void main() {
//
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         primaryColor: Colors.white, // Set primary color to white
//         scaffoldBackgroundColor: Colors.white, // Ensure Scaffold uses white background
//         appBarTheme: AppBarTheme(
//           backgroundColor: Colors.white, // Keep AppBar background white
//           elevation: 0, // Remove shadow
//           iconTheme: IconThemeData(color: Colors.black), // Set icons to black for contrast
//         ),
//         bottomNavigationBarTheme: BottomNavigationBarThemeData(
//           backgroundColor: Colors.white, // Keep Bottom Navigation white
//           elevation: 0, // Remove shadow
//         ),
//       ),
//       home: SplashScreen(),
//     );
//   }
// }
//
// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});
//
//   // This widget is the home page of your application. It is stateful, meaning
//   // that it has a State object (defined below) that contains fields that affect
//   // how it looks.
//
//   // This class is the configuration for the state. It holds the values (in this
//   // case the title) provided by the parent (in this case the App widget) and
//   // used by the build method of the State. Fields in a Widget subclass are
//   // always marked "final".
//
//   final String title;
//
//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }
//
// class _MyHomePageState extends State<MyHomePage> {
//   int _counter = 0;
//
//   void _incrementCounter() {
//     setState(() {
//       // This call to setState tells the Flutter framework that something has
//       // changed in this State, which causes it to rerun the build method below
//       // so that the display can reflect the updated values. If we changed
//       // _counter without calling setState(), then the build method would not be
//       // called again, and so nothing would appear to happen.
//       _counter++;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // This method is rerun every time setState is called, for instance as done
//     // by the _incrementCounter method above.
//     //
//     // The Flutter framework has been optimized to make rerunning build methods
//     // fast, so that you can just rebuild anything that needs updating rather
//     // than having to individually change instances of widgets.
//     return Scaffold(
//       appBar: AppBar(
//         // TRY THIS: Try changing the color here to a specific color (to
//         // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
//         // change color while the other colors stay the same.
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//         // Here we take the value from the MyHomePage object that was created by
//         // the App.build method, and use it to set our appbar title.
//         title: Text(widget.title),
//       ),
//       body: Center(
//         // Center is a layout widget. It takes a single child and positions it
//         // in the middle of the parent.
//         child: Column(
//           // Column is also a layout widget. It takes a list of children and
//           // arranges them vertically. By default, it sizes itself to fit its
//           // children horizontally, and tries to be as tall as its parent.
//           //
//           // Column has various properties to control how it sizes itself and
//           // how it positions its children. Here we use mainAxisAlignment to
//           // center the children vertically; the main axis here is the vertical
//           // axis because Columns are vertical (the cross axis would be
//           // horizontal).
//           //
//           // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
//           // action in the IDE, or press "p" in the console), to see the
//           // wireframe for each widget.
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             const Text('You have pushed the button this many times:'),
//             Text(
//               '$_counter',
//               style: Theme.of(context).textTheme.headlineMedium,
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _incrementCounter,
//         tooltip: 'Increment',
//         child: const Icon(Icons.add),
//       ), // This trailing comma makes auto-formatting nicer for build methods.
//     );
//   }
// }



import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Login/Splash_Screen.dart';
import 'Screens/JewelleryScreen.dart';
import 'Screens/NotificationDatabase.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'Screens/ProductDetailScreen.dart';

const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    // description
    importance: Importance.high,
    playSound: true);
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp();
//   NotificationDatabase.instance.addNotification(
//     message.notification?.title ?? "No Title",
//     message.notification?.body ?? "No Message",
//   );
//   print('A bg message just showed up :  ${message.messageId}');
// }
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    importance: Importance.high,
    playSound: true,
  );

  // Create channel
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  final String title = message.notification?.title ?? "No Title";
  final String body = message.notification?.body ?? "No Message";

  String? imageUrl = 'https://images.unsplash.com/photo-1606115915090-be18fea23ec7?q=80&w=1965&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D';

  BigPictureStyleInformation? bigPicture;

  print("📩 BG Notification Data:");
  print("Title: $title");
  print("Body: $body");

  if (imageUrl != null && imageUrl.isNotEmpty) {
    try {
      final String bigPicturePath = await downloadAndSaveFile(imageUrl, 'bg_bigImage.jpg');
      bigPicture = BigPictureStyleInformation(
        FilePathAndroidBitmap(bigPicturePath),
        contentTitle: title,
        summaryText: body,
      );
    } catch (e) {
      print("Error downloading image in BG: $e");
    }
  }

  await flutterLocalNotificationsPlugin.show(
    title.hashCode,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        styleInformation: bigPicture,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        attachments: imageUrl != null
            ? [DarwinNotificationAttachment(await downloadAndSaveFile(imageUrl, 'ios_img.jpg'))]
            : [],
      ),
    ),
  );
}

Future<String> downloadAndSaveFile(String url, String fileName) async {
  final Directory directory = await getApplicationDocumentsDirectory();
  final String filePath = '${directory.path}/$fileName';
  final http.Response response = await http.get(Uri.parse(url));
  final File file = File(filePath);
  await file.writeAsBytes(response.bodyBytes);
  return filePath;
}
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Disable screenshot and screen recording
  await ScreenProtector.preventScreenshotOn();
  await ScreenProtector.protectDataLeakageOn(); // for extra safety

  try {
    await Firebase.initializeApp();
    print("✅ Firebase initialized");
  } catch (e) {
    print("❌ Firebase init error: $e");
  }

  try {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    print("✅ Background handler registered");
  } catch (e) {
    print("❌ Background handler error: $e");
  }

  try {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    print("✅ Notification channel created");
  } catch (e) {
    print("❌ Notification channel error: $e");
  }

  try {
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    print("✅ Foreground notification options set");
  } catch (e) {
    print("❌ Foreground notification setup error: $e");
  }

  requestNotificationPermission(); // 👈 Add this


  runApp(MyApp());
}

Future<void> requestNotificationPermission() async {
  if (Platform.isAndroid) {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if (androidInfo.version.sdkInt >= 33) {
      var status = await Permission.notification.status;
      if (!status.isGranted) {
        status = await Permission.notification.request();
        if (status.isGranted) {
          print("✅ Android: Notification permission granted");
        } else {
          print("❌ Android: Notification permission denied");
        }
      } else {
        print("🔔 Android: Notification permission already granted");
      }
    } else {
      print("📱 Android < 13: Notification permission not required");
    }
  } else if (Platform.isIOS) {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("✅ iOS: Notification permission granted");
    } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print("❌ iOS: Notification permission denied");
    } else if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      print("❓ iOS: Permission not determined");
    }
  }
}


void triggerLocalNetworkAccess() async {
  try {
    final socket = await Socket.connect('127.0.0.1', 12345).timeout(Duration(seconds: 1));
    socket.destroy();
  } catch (_) {}
}

class MyApp extends StatefulWidget {
  //MyApp({Key key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  //String uid = null;
  String? token;
  String uid = "";
  String? deviceId;
  Future<void> fetchDeviceId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Theme.of(context).platform == TargetPlatform.android) {
      var androidInfo = await deviceInfo.androidInfo;
      setState(() {
        deviceId = androidInfo.id; // Unique Android ID
        prefs.setString("Device_id", deviceId.toString());
        print("Android Device ID : "+deviceId.toString());
      });
    } else if (Theme.of(context).platform == TargetPlatform.iOS) {
      var iosInfo = await deviceInfo.iosInfo;
      setState(() {
        deviceId = iosInfo.identifierForVendor; // Unique iOS ID
        prefs.setString("Device_id", deviceId.toString());
        print("Ios Device ID : "+deviceId.toString());
      });
    }
  }

  Future<String> downloadAndSaveFile(String url, String fileName) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$fileName';
    final http.Response response = await http.get(Uri.parse(url));
    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }



  // void _handleNotificationClick(Map<String, dynamic> data) {
  //   final categoryId = data['category_id']?.toString();
  //   final subcategoryId = data['subcategory_id']?.toString();
  //   final productId = data['product_id']?.toString();
  //   final subcategoryName = data['subcategory_name']?.toString() ?? "";
  //
  //   Future.microtask(() {
  //     final ctx = navigatorKey.currentContext;
  //     if (ctx == null) return;
  //
  //     if (productId != null && productId.isNotEmpty) {
  //       Navigator.push(
  //         ctx,
  //         MaterialPageRoute(builder: (_) => ProductDetailScreen(productId,subcategoryName,"1")),
  //       );
  //     } else if (categoryId != null && subcategoryId != null) {
  //       Navigator.push(
  //         ctx,
  //         MaterialPageRoute(
  //           builder: (_) =>
  //               JewelleryScreen(categoryId, subcategoryId, subcategoryName),
  //         ),
  //       );
  //     }
  //   });
  // }

  @override
  void initState() {
    //getUserid();
    super.initState();
    fetchDeviceId();

    // HANDLE COLD START (app terminated -> opened by tapping notification)
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print("📦 getInitialMessage triggered (cold start)");
        final data = message.data;
        final productId = data['product_id']?.toString();
        final subcategoryName = data['subcategory_name']?.toString() ?? "";

        // wait till first frame so navigatorKey / MaterialApp is ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // navigatorKey.currentState?.pushReplacement(
          //   MaterialPageRoute(builder: (context) => SplashScreen()),
          // );
          if (productId != null && productId.isNotEmpty) {
            navigatorKey.currentState?.pushReplacement(
              MaterialPageRoute(
                builder: (context) => ProductDetailScreen(productId, subcategoryName, "1"),
              ),
            );
          } else {
            // Optional: handle category/subcategory navigation if product_id not present
            final categoryId = data['category_id']?.toString();
            final subcategoryId = data['subcategory_id']?.toString();
            if (categoryId != null && subcategoryId != null) {
              navigatorKey.currentState?.pushReplacement(
                MaterialPageRoute(
                  builder: (context) => JewelleryScreen(categoryId, subcategoryId, subcategoryName),
                ),
              );
            }
          }
        });
      }
    });
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('A new onMessage event was published!');
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null) {
        print('📲 Notification Received!');
        print('Title: ${message.notification?.title}');
        print('Body: ${message.notification?.body}');
        print('Data: ${message.data}');
        String? imageUrl = message.data['image']; // must be sent from server
        print(imageUrl);
        //String? imageUrl = 'https://images.unsplash.com/photo-1606115915090-be18fea23ec7?q=80&w=1965&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D';

        BigPictureStyleInformation? bigPicture;

        if (imageUrl != null && imageUrl.isNotEmpty) {
          try {
            final String bigPicturePath = await downloadAndSaveFile(imageUrl, 'bigImage.jpg');
            bigPicture = BigPictureStyleInformation(
              FilePathAndroidBitmap(bigPicturePath),
              contentTitle: notification.title,
              summaryText: notification.body,
            );
          } catch (e) {
            print("❌ Error downloading image: $e");
          }
        }
        flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                color: Colors.blue,
                playSound: true,
                icon: '@mipmap/ic_launcher',
                largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
                styleInformation: bigPicture,
              ),
              iOS: DarwinNotificationDetails(
                attachments: imageUrl != null
                    ? [DarwinNotificationAttachment(await downloadAndSaveFile(imageUrl, 'ios_img.jpg'))]
                    : [],
              ),
            ));
      }

      NotificationDatabase.instance.addNotification(
        message.notification?.title ?? "No Title",
        message.notification?.body ?? "No Message",
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');

      // Add notification to local DB
      NotificationDatabase.instance.addNotification(
        message.notification?.title ?? "No Title",
        message.notification?.body ?? "No Message",
      );

      // Handle navigation
      final data = message.data;
      final categoryId = data['category_id']?.toString();
      final subcategoryId = data['subcategory_id']?.toString();
      final productId = data['product_id']?.toString();
      final subcategoryName = data['subcategory_name']?.toString() ?? "";

      Future.microtask(() {
        final ctx = navigatorKey.currentContext;
        if (ctx == null) {
          print("⚠️ navigatorKey.currentContext is null (MaterialApp not ready yet)");
          return;
        }

        if (productId != null && productId.isNotEmpty) {
          Navigator.push(
            ctx,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(productId,subcategoryName,"1"),
            ),
          );
        } else if (categoryId != null && subcategoryId != null) {
          Navigator.push(
            ctx,
            MaterialPageRoute(
              builder: (context) => JewelleryScreen(
                categoryId,
                subcategoryId,
                subcategoryName,
              ),
            ),
          );
        } else {
          print('⚠️ Missing category_id or subcategory_id in notification data');
        }
      });
    });


    getToken();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // ✅ important for navigation without context
      title: 'Ornatique',
      theme: ThemeData(
        primaryColor: Colors.white, // Set primary color to white
        scaffoldBackgroundColor: Colors.white, // Ensure Scaffold uses white background
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white, // Keep AppBar background white
          elevation: 0, // Remove shadow
          iconTheme: IconThemeData(color: Colors.black), // Set icons to black for contrast
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white, // Keep Bottom Navigation white
          elevation: 0, // Remove shadow
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }

  getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    token = await FirebaseMessaging.instance.getToken();
    prefs.setString("fcm", token.toString());
    print("FCM : "+token.toString());
    print("Fire base token is : "+token!);
  }
}

// class MyApp extends StatelessWidget {
//   const MyApp({Key key}) : super(key: key);
//
//
//
//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Quiz Zone',
//       theme: ThemeData(
//           primarySwatch: Colors.blue, scaffoldBackgroundColor: Colors.white),
//       debugShowCheckedModeBanner: false,
//       home: const SplashScreen(),
//     );
//   }
// }


