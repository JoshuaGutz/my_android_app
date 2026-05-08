import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false, // Hides the "Debug" banner
    home: TwitchApp(),
  ));
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkTabsAndShowDialog());
  }

  void _checkTabsAndShowDialog() {
    if (myTabs.isEmpty) {
      _showAddDialog();
    }
  }

  WebViewController _createController(String url) {
    return WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  void _addTab(String title, String url) {
    setState(() {
      myTabs.add(TwitchTab(title: title, controller: _createController(url)));
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
        _checkTabsAndShowDialog();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // SafeArea prevents content from going under the status bar/clock
      body: SafeArea(
        child: myTabs.isEmpty 
          ? const Center(child: Text("No tabs open.")) 
          : TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: myTabs.map((tab) => WebViewWidget(controller: tab.controller)).toList(),
            ),
      ),
      bottomNavigationBar: Container(
        height: 90, // Slightly taller to accommodate buttons + tabs
        color: const Color(0xFF9146FF), // Twitch Purple
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top part of the bar: Global Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_box, color: Colors.white),
                    onPressed: () => _showAddDialog(),
                  ),
                  const Text("Twitch Multi-Tool", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  if (myTabs.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: () => myTabs[_tabController!.index].controller.reload(),
                    ),
                ],
              ),
            ),
            // Bottom part: The Scrollable Tabs
            if (myTabs.isNotEmpty)
              Expanded(
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
                            child: const Icon(Icons.close, size: 16, color: Colors.white54),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog() {
    TextEditingController channelController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: myTabs.isNotEmpty,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add New Tab"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: channelController,
                decoration: const InputDecoration(hintText: "Channel (Defaults to deemonrider)"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  String name = channelController.text.trim();
                  if (name.isEmpty) name = "deemonrider";
                  _addTab("Panel: $name", "https://www.twitch.tv/popout/$name/extensions/pm0qkv9g4h87t5y6lg329oam8j7ze9/panel");
                  Navigator.pop(context);
                }, 
                child: const Text("Add Extension Panel")
              ),
              ElevatedButton(
                onPressed: () {
                  String name = channelController.text.trim();
                  if (name.isEmpty) name = "deemonrider";
                  _addTab("Chat: $name", "https://www.twitch.tv/popout/$name/chat?popout=");
                  Navigator.pop(context);
                }, 
                child: const Text("Add Chat")
              ),
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
      },
    );
  }
}