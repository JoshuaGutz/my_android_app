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
  String type; 
  String channel;
  WebViewController controller;
  TwitchTab({required this.title, required this.type, required this.channel, required this.controller});
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
    setState(() { isLeftHanded = prefs.getBool('isLeftHanded') ?? false; });
  }

  Future<void> _toggleHandedness(bool value, StateSetter setDialogState) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLeftHanded', value);
    setState(() { isLeftHanded = value; });
    setDialogState(() {}); 
  }

  void _checkTabsAndShowDialog() {
    if (myTabs.isEmpty) _showAddDialog();
  }

  WebViewController _createController(String url) {
    return WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
          onNavigationRequest: (request) => NavigationDecision.navigate,
      ))
      ..loadRequest(Uri.parse(url));
  }

  void _addTab(String title, String type, String channel, String url) {
    setState(() {
      myTabs.add(TwitchTab(title: title, type: type, channel: channel, controller: _createController(url)));
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
    Widget actionButtons = Container(
      color: Colors.black38, // Darker for better delineation
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.add_box, color: Colors.white, size: 30), onPressed: _showAddDialog),
          if (myTabs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white, size: 30),
              onPressed: () => myTabs[_tabController!.index].controller.reload(),
            ),
        ],
      ),
    );

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
        height: 70, // Slightly more compact
        color: const Color(0xFF9146FF),
        child: Row(
          children: isLeftHanded 
            ? [actionButtons, const VerticalDivider(width: 1, color: Colors.white30), Expanded(child: _buildTabBar())] 
            : [Expanded(child: _buildTabBar()), const VerticalDivider(width: 1, color: Colors.white30), actionButtons],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    if (myTabs.isEmpty) return const SizedBox();
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      indicatorColor: Colors.transparent, 
      padding: const EdgeInsets.symmetric(vertical: 8),
      labelPadding: const EdgeInsets.symmetric(horizontal: 2), // Even tighter spacing
      tabs: myTabs.asMap().entries.map((entry) {
        String displayName = entry.value.channel;
        if (displayName.toLowerCase() == "deemonrider") displayName = "DR";
        
        IconData icon = entry.value.type == "chat" ? Icons.chat_bubble : Icons.extension;
        if (entry.value.type == "login") {
          icon = Icons.person;
          displayName = "Login";
        }

        return Container(
          height: 42, // Consistent height
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(45),
            borderRadius: BorderRadius.circular(6), 
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: Colors.white), // Beefy icon
              const SizedBox(width: 4),
              Text(displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _closeTab(entry.key),
                child: Container(
                  padding: const EdgeInsets.all(1),
                  decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                ),
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
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Center(child: Text("Settings & New Tab")),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Switch(value: isLeftHanded, onChanged: (val) => _toggleHandedness(val, setDialogState)),
                  const Text("Left Handed Mode"),
                ],
              ),
              const Divider(),
              TextField(
                controller: channelController,
                decoration: const InputDecoration(hintText: "Channel (Defaults to deemonrider)"),
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                icon: const Icon(Icons.extension),
                label: const Text("Add Extension Panel"),
                onPressed: () {
                  String name = channelController.text.trim().isEmpty ? "deemonrider" : channelController.text.trim();
                  _addTab("Panel", "panel", name, "https://www.twitch.tv/popout/$name/extensions/pm0qkv9g4h87t5y6lg329oam8j7ze9/panel");
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.chat),
                label: const Text("Add Chat"),
                onPressed: () {
                  String name = channelController.text.trim().isEmpty ? "deemonrider" : channelController.text.trim();
                  _addTab("Chat", "chat", name, "https://www.twitch.tv/popout/$name/chat?popout=");
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              TextButton(
                onPressed: () {
                  _addTab("Login", "login", "", "https://www.twitch.tv/login");
                  Navigator.pop(context);
                },
                child: const Text("Login to Twitch"),
              )
            ],
          ),
        ),
      ),
    );
  }
}