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
  int _selectedIndex = 0; // Tracks which tab is active

  // --- VARIABLES FOR CHANNELS ---
  String panelChannel = "deemonrider";
  String chatChannel1 = "deemonrider";
  String chatChannel2 = "twitchdev"; // Just an example for a second chat

  // We need three separate controllers for three separate tabs
  late final WebViewController _panelController;
  late final WebViewController _chatController1;
  late final WebViewController _chatController2;

  @override
  void initState() {
    super.initState();

    // 1. Setup the Extension Panel
    _panelController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse("https://www.twitch.tv/popout/$panelChannel/extensions/pm0qkv9g4h87t5y6lg329oam8j7ze9/panel"));

    // 2. Setup first Chat tab
    _chatController1 = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse("https://www.twitch.tv/popout/$chatChannel1/chat?popout="));

    // 3. Setup second Chat tab
    _chatController2 = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse("https://www.twitch.tv/popout/$chatChannel2/chat?popout="));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Twitch Multi-Tool")),
      // IndexedStack keeps all tabs "alive" in the background so they don't reload every time you click
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          WebViewWidget(controller: _panelController),
          WebViewWidget(controller: _chatController1),
          WebViewWidget(controller: _chatController2),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.extension), label: 'Panel'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat 1'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'Chat 2'),
        ],
      ),
    );
  }
}