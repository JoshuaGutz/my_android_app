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
  int _selectedIndex = 0; 

  // Variables for your channels
  String channelName = "deemonrider"; 

  late final WebViewController _loginController;
  late final WebViewController _panelController;
  late final WebViewController _chatController;

  @override
  void initState() {
    super.initState();

    // 1. LOGIN HELPER - Use this first to sign in
    _loginController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse("https://www.twitch.tv/login"));

    // 2. EXTENSION PANEL
    _panelController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse("https://www.twitch.tv/popout/$channelName/extensions/pm0qkv9g4h87t5y6lg329oam8j7ze9/panel"));

    // 3. CHAT
    _chatController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse("https://www.twitch.tv/popout/$channelName/chat?popout="));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Twitch Tool: $channelName")),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          WebViewWidget(controller: _loginController),
          WebViewWidget(controller: _panelController),
          WebViewWidget(controller: _chatController),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Needed for 3+ items
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() { _selectedIndex = index; });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.login), label: 'Login'),
          BottomNavigationBarItem(icon: Icon(Icons.extension), label: 'Panel'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
        ],
      ),
    );
  }
}