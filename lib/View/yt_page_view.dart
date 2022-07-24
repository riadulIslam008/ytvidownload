import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:ytdownloader/Core/app_assets.dart';
import 'package:ytdownloader/View/Video_Stream_Info/stream_info.dart';
import 'package:ytdownloader/View/settings.dart';

class YtPageView extends StatefulWidget {
  const YtPageView({Key? key}) : super(key: key);

  @override
  State<YtPageView> createState() => _YtPageViewState();
}

class _YtPageViewState extends State<YtPageView> {
  final String _intialUrl = "https://www.m.youtube.com/";
  WebViewController? _webController;
  bool showDownloadButton = false;
  bool showCircularProgressIndicator = false;
  StreamSubscription? _intialDataStreamSubcription;
  // bool showLoading = false;

  @override
  void initState() {
  
    receiveIntentWhenAppClosed();
    receiveIntentWhenAppRunning();

    super.initState();
  }

  //Receive text data when app is running
  void receiveIntentWhenAppRunning() {
    _intialDataStreamSubcription =
        ReceiveSharingIntent.getTextStream().listen((String text) {
      if (text.isNotEmpty) {
        setState(() {
          _webController!.loadUrl(text);
        });
      }
    }, onError: (err) => debugPrint("Receive Intent Error"));
  }

  //Receive text data when app Closed and this is not working
  void receiveIntentWhenAppClosed() {
    ReceiveSharingIntent.getInitialText().then((String? text) {
      if (text != null) {
        setState(() {
          _webController!.loadUrl(text);
        });
      }
    });
  }

  void checkCurrentUrl() async {
    final _url = await _webController!.currentUrl();
    if (_url == "https://m.youtube.com/" ||
        _url == "https://m.youtube.com/#searching" ||
        _url!.contains("search_query")) {
      setState(() {
        showDownloadButton = false;
      });
    } else {
      setState(() {
        showDownloadButton = true;
      });
    }
  }

  // void settingsPage() async {
  //   final _url = await _controller!.currentUrl();
  //   if (_url!.startsWith("https://m.youtube.com/feed/library")) {
  //     NavigationDecision.prevent;
  //     Get.to(const Settings());
  //   }
  // }

  @override
  void dispose() {
    _intialDataStreamSubcription!.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: WillPopScope(
        onWillPop: () async {
          if (await _webController!.canGoBack()) {
            _webController!.goBack();
            checkCurrentUrl();
          }
          return false;
        },
        child: Scaffold(
          floatingActionButton: showDownloadButton
              ? FloatingActionButton(
                  onPressed: () async {
                    final _url = await _webController!.currentUrl();
                    Get.dialog(const VideoByteInfo(), arguments: [_url]);
                    // print(_url);
                  },
                  child: showCircularProgressIndicator
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child:
                                CircularProgressIndicator(color: Colors.white),
                          ),
                        )
                      : Lottie.asset(AppAssets.downloadIcon, height: 50),
                )
              : const SizedBox.shrink(),
          body: WebView(
              initialUrl: _intialUrl,
              javascriptMode: JavascriptMode.unrestricted,
              onProgress: (int progress) async {
                if (progress > 70) {
                  checkCurrentUrl(); 
                }
              },
              onWebViewCreated: (controller) {
                _webController = controller;
              },
              navigationDelegate: (NavigationRequest navigationRequest) {
                if (navigationRequest.url
                    .startsWith("https://www.m.youtube.com/feed/library")) {
                 return NavigationDecision.prevent;
                //  Get.to(const Settings());
                }
               // print(navigationRequest.url);
                // settingsPage();
                return NavigationDecision.navigate;
              }),
        ),
      ),
    );
  }
}
