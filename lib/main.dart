import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const MaterialApp(home: TwitchApp()));
}

class TwitchApp extends StatefulWidget {
  const TwitchApp({super.key});

  @override
  State<TwitchApp> createState() => _TwitchAppState();
}

class _TwitchAppState extends State<TwitchApp> {
  late final WebViewController controller;

  // --- HERE IS YOUR VARIABLE ---
  String channelName = "deemonrider"; 

  @override
  void initState() {
    super.initState();
    
    // Construct the URL using your variable
    String finalUrl = "https://www.twitch.tv/popout/$channelName/extensions/pm0qkv9g4h87t5y6lg329oam8j7ze9/panel";

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(finalUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Twitch Panel: $channelName")),
      body: WebViewWidget(controller: controller),
    );
  }
}