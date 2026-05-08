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
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkTabsAndShowDialog());
  }

  void _checkTabsAndShowDialog() {
    if (myTabs.isEmpty) {
      _showAddDialog();
    }
  }

  // Helper to create a controller with "Deep Link" protection
  WebViewController _createController(String url) {
    return WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // This prevents the "Open in Twitch App" popup by forcing
            // all navigation to stay inside THIS webview.
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
      appBar: AppBar(
        title: const Text("Twitch Multi-Tool"),
        actions: [
          IconButton(icon: const Icon(Icons.add_box), onPressed: () => _showAddDialog()),
          if (myTabs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => myTabs[_tabController!.index].controller.reload(),
            ),
        ],
      ),
      body: myTabs.isEmpty 
        ? const Center(child: Text("No tabs open.")) 
        : TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: myTabs.map((tab) => WebViewWidget(controller: tab.controller)).toList(),
          ),
      // Sizedbox here makes the bottom bar 50% thicker (height 80 instead of standard ~50)
      bottomNavigationBar: myTabs.isEmpty ? null : Container(
        height: 80, 
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
                  Text(entry.value.title, style: const TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _closeTab(entry.key),
                    child: const Icon(Icons.close, size: 20, color: Colors.white),
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
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  String name = channelController.text.trim();
                  if (name.isEmpty) name = "deemonrider";
                  _addTab("Panel: $name", "https://www.twitch.tv/popout/$name/extensions/pm0qkv9g4h87t5y6lg329oam8j7ze9/panel");
                  Navigator.pop(context);
                }, 
                child: const Text("Add Extension Panel")
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  String name = channelController.text.trim();
                  if (name.isEmpty) name = "deemonrider"; // Default for chat too!
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
      },
    );
  }
}