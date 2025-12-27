import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../ConstantColors/Color_Constant.dart';
import '../Constant_font/FontStyles.dart';
import 'NotificationDatabase.dart';


class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> notifications = [];
  @override
  void initState() {
    super.initState();
    _loadAppBarColor();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final data = await NotificationDatabase.instance.getNotifications();
    setState(() {
      notifications = data;
    });
  }

  Future<void> _deleteNotification(int id) async {
    await NotificationDatabase.instance.deleteNotification(id);
    _loadNotifications();
  }

  String _timeAgo(dynamic timestamp) {
    DateTime dateTime;

    if (timestamp is int) {
      // If timestamp is stored as an integer (milliseconds since epoch)
      dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else if (timestamp is String) {
      // If timestamp is stored as a string (ISO 8601 format)
      try {
        dateTime = DateTime.parse(timestamp);
      } catch (e) {
        return "Invalid date";  // Fallback for incorrect format
      }
    } else {
      return "Unknown time";
    }

    Duration diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) {
      return "${diff.inMinutes} min ago";
    } else if (diff.inHours < 24) {
      return "${diff.inHours} hr ago";
    } else {
      return DateFormat('dd MMM, yyyy').format(dateTime);
    }
  }
  Future<void> _clearAllNotifications() async {
    await NotificationDatabase.instance.clearNotifications();
    _loadNotifications();
  }
  Color? appBarColor;
  Future<void> _loadAppBarColor() async {
    appBarColor = await AppColorHelper.getAppBarColor();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notification ', style: FontStyles.appbar_heading),
        centerTitle: true,
        backgroundColor: appBarColor ?? Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: Icon(Icons.clear_all, color: Colors.black),
            onPressed: _clearAllNotifications,
          ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(child: Text('No notifications available'))
          : ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final item = notifications[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blueAccent.withOpacity(0.8),
                child: Icon(Icons.notifications, color: Colors.white),
              ),
              title: Text(
                item['title'],
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(item['message']),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _timeAgo(item['timestamp']),
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  SizedBox(height: 5),
                  // IconButton(
                  //   icon: Icon(Icons.delete, color: Colors.red),
                  //   onPressed: () => _deleteNotification(item['id']),
                  // ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
