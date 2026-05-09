import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
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
  bool isLeftHanded = false;

  @override
  void initState() {
    super.initState();
    _loadHandedness();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkTabsAndShowDialog());
  }

  Future<void> _loadHandedness() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isLeftHanded = prefs.getBool('isLeftHanded') ?? false;
    });
  }

  // UPDATED: This now accepts the dialog's local "setDialogState" 
  // so it can force the switch to flip visually in sync with the buttons.
  Future<void> _toggleHandedness(bool value, StateSetter setDialogState) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLeftHanded', value);
    
    // Update the main app (buttons move)
    setState(() {
      isLeftHanded = value;
    });
    
    // Update the dialog (switch flips)
    setDialogState(() {}); 
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
    List<Widget> actionButtons = [
      IconButton(
        icon: const Icon(Icons.add_box, color: Colors.white),
        onPressed: () => _showAddDialog(),
      ),
      if (myTabs.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () => myTabs[_tabController!.index].controller.reload(),
        ),
    ];

    return Scaffold(
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
        height: 85, 
        color: const Color(0xFF9146FF),
        child: Row(
          children: isLeftHanded 
            ? [...actionButtons, Expanded(child: _buildTabBar())] 
            : [Expanded(child: _buildTabBar()), ...actionButtons],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    if (myTabs.isEmpty) return const SizedBox();
    return TabBar(
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
    );
  }

  void _showAddDialog() {
    TextEditingController channelController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: myTabs.isNotEmpty,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Settings & New Tab"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text("Left Handed Mode"),
                    value: isLeftHanded,
                    onChanged: (bool value) {
                      // We now pass the 'setDialogState' directly into our toggle logic
                      _toggleHandedness(value, setDialogState);
                    },
                  ),
                  const Divider(),
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
          }
        );
      },
    );
  }
}