import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const MaterialApp(home: TwitchApp()));
}

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
    // We start with no tabs now, which triggers the auto-popup logic
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkTabsAndShowDialog());
  }

  void _checkTabsAndShowDialog() {
    if (myTabs.isEmpty) {
      _showAddDialog();
    }
  }

  void _addTab(String title, String url) {
    setState(() {
      final newController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse(url));
      
      myTabs.add(TwitchTab(title: title, controller: newController));
      _tabController = TabController(length: myTabs.length, vsync: this);
      _tabController!.animateTo(myTabs.length - 1);
    });
  }

  void _closeTab(int index) {
    setState(() {
      myTabs.removeAt(index);
      if (myTabs.isNotEmpty) {
        _tabController = TabController(length: myTabs.length, vsync: this);
      } else {
        _tabController = null;
        _checkTabsAndShowDialog(); // Show dialog if last tab closed
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Twitch Multi-Tool"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box),
            onPressed: () => _showAddDialog(),
          ),
          if (myTabs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => myTabs[_tabController!.index].controller.reload(),
            ),
        ],
      ),
      body: myTabs.isEmpty 
        ? const Center(child: Text("No tabs open. Tap + to add one.")) 
        : TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(), // FIX: Disables swipe to switch tabs
            children: myTabs.map((tab) => WebViewWidget(controller: tab.controller)).toList(),
          ),
      bottomNavigationBar: myTabs.isEmpty ? null : Material(
        color: Theme.of(context).primaryColor,
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          tabs: myTabs.asMap().entries.map((entry) {
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(entry.value.title, style: const TextStyle(color: Colors.white)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _closeTab(entry.key),
                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showAddDialog() {
    TextEditingController channelController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: myTabs.isNotEmpty, // Cannot tap outside to close if 0 tabs
      builder: (context) {
        return StatefulBuilder( // Allows the dialog buttons to update as you type
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Add New Tab"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: channelController,
                    decoration: const InputDecoration(hintText: "Channel Name (Defaults to deemonrider)"),
                    onChanged: (val) => setDialogState(() {}), // Refresh buttons as you type
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Whitespace stripping logic
                      String name = channelController.text.trim();
                      if (name.isEmpty) name = "deemonrider";
                      _addTab("Panel: $name", "https://www.twitch.tv/popout/$name/extensions/pm0qkv9g4h87t5y6lg329oam8j7ze9/panel");
                      Navigator.pop(context);
                    }, 
                    child: const Text("Add Extension Panel")
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    // Greyed out logic: null onPressed = disabled button
                    onPressed: channelController.text.trim().isEmpty ? null : () {
                      String name = channelController.text.trim();
                      _addTab("Chat: $name", "https://www.twitch.tv/popout/$name/chat?popout=");
                      Navigator.pop(context);
                    }, 
                    child: const Text("Add Chat")
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      _addTab("Login", "https://www.twitch.tv/login");
                      Navigator.pop(context);
                    },
                    child: const Text("Add Login Tab")
                  )
                ],
              ),
            );
          }
        );
      },
    );
  }
}