import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
// import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MaterialApp(home: TwitchApp()));
}

// This helper class keeps track of each tab's name and its own controller
class TwitchTab {
  String title;
  WebViewController controller;
  TwitchTab({required this.title, required this.controller});
}

class TwitchApp extends StatefulWidget {
  const TwitchApp({super.key});
  @override
  State<TwitchApp> createState() => _TwitchAppState();
}

class _TwitchAppState extends State<TwitchApp> with TickerProviderStateMixin {
  List<TwitchTab> myTabs = [];
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    // Start with the Login tab by default
    _addTab("Login", "https://www.twitch.tv/login");
  }

  // Logic to add a new tab
  void _addTab(String title, String url) {
    setState(() {
      final newController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse(url));
      
      myTabs.add(TwitchTab(title: title, controller: newController));
      
      // Update the TabController to handle the new number of tabs
      _tabController = TabController(length: myTabs.length, vsync: this);
      _tabController!.animateTo(myTabs.length - 1); // Jump to the new tab
    });
  }

  // Logic to close a tab
  void _closeTab(int index) {
    if (myTabs.length <= 1) return; // Don't close the last remaining tab
    setState(() {
      myTabs.removeAt(index);
      _tabController = TabController(length: myTabs.length, vsync: this);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Twitch Multi-Tool"),
        leading: IconButton(
          icon: const Icon(Icons.add_box),
          onPressed: () => _showAddDialog(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => myTabs[_tabController!.index].controller.reload(),
          ),
        ],
        bottom: myTabs.isEmpty ? null : TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: myTabs.asMap().entries.map((entry) {
            int idx = entry.key;
            return Tab(
              child: Row(
                children: [
                  Text(entry.value.title),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _closeTab(idx),
                    child: const Icon(Icons.close, size: 16),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: myTabs.isEmpty 
        ? const Center(child: Text("Tap + to add a tab")) 
        : TabBarView(
            controller: _tabController,
            children: myTabs.map((tab) => WebViewWidget(controller: tab.controller)).toList(),
          ),
    );
  }

  void _showAddDialog() {
    TextEditingController channelController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Tab"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: channelController, decoration: const InputDecoration(hintText: "Channel Name")),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                _addTab("Panel: ${channelController.text}", "https://www.twitch.tv/popout/${channelController.text}/extensions/pm0qkv9g4h87t5y6lg329oam8j7ze9/panel");
                Navigator.pop(context);
              }, 
              child: const Text("Add Extension Panel")
            ),
            ElevatedButton(
              onPressed: () {
                _addTab("Chat: ${channelController.text}", "https://www.twitch.tv/popout/${channelController.text}/chat?popout=");
                Navigator.pop(context);
              }, 
              child: const Text("Add Chat")
            ),
          ],
        ),
      ),
    );
  }
}