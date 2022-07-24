import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ytdownloader/Service/Notification/notifications.dart';
import 'package:ytdownloader/dI/binding.dart';
import 'package:ytdownloader/View/yt_page_view.dart';

void main() async {
  
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationApi.initNotification();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Youtube Downloader',
      initialBinding: Binding(),
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const YtPageView(),
    );
  }
}
