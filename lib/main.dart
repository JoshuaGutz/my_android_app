import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: TwitchApp(),
  ));
}

class TwitchTab {
  String type; 
  String channel;
  WebViewController? controller;

  TwitchTab({required this.type, required this.channel, this.controller});

  Map<String, dynamic> toJson() => {'type': type, 'channel': channel};

  factory TwitchTab.fromJson(Map<String, dynamic> json) {
    return TwitchTab(type: json['type'], channel: json['channel']);
  }
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
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() { isLeftHanded = prefs.getBool('isLeftHanded') ?? false; });

    String? savedTabsJson = prefs.getString('saved_tabs');
    if (savedTabsJson != null) {
      Iterable decoded = jsonDecode(savedTabsJson);
      List<TwitchTab> loadedTabs = decoded.map((model) => TwitchTab.fromJson(model)).toList();
      
      for (var tab in loadedTabs) {
        tab.controller = _createController(_generateUrl(tab.type, tab.channel));
      }

      if (loadedTabs.isNotEmpty) {
        setState(() {
          myTabs = loadedTabs;
          _tabController = TabController(length: myTabs.length, vsync: this);
          _tabController!.addListener(() => setState(() {})); 
        });
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (myTabs.isEmpty) _showAddDialog();
    });
  }

  String _generateUrl(String type, String channel) {
    if (type == "login") return "https://www.twitch.tv/login";
    if (type == "chat") return "https://www.twitch.tv/popout/$channel/chat?popout=";
    return "https://www.twitch.tv/popout/$channel/extensions/pm0qkv9g4h87t5y6lg329oam8j7ze9/panel";
  }

  Future<void> _saveTabs() async {
    final prefs = await SharedPreferences.getInstance();
    String encodedData = jsonEncode(myTabs.map((t) => t.toJson()).toList());
    await prefs.setString('saved_tabs', encodedData);
  }

  Future<void> _toggleHandedness(bool value, StateSetter setDialogState) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLeftHanded', value);
    setState(() { isLeftHanded = value; });
    setDialogState(() {}); 
  }

  WebViewController _createController(String url) {
    return WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(url));
  }

  void _addTab(String type, String channel) {
    setState(() {
      myTabs.add(TwitchTab(
        type: type, 
        channel: channel, 
        controller: _createController(_generateUrl(type, channel))
      ));
      _tabController = TabController(length: myTabs.length, vsync: this);
      _tabController!.addListener(() => setState(() {}));
      _tabController!.animateTo(myTabs.length - 1);
    });
    _saveTabs();
  }

  void _closeTab(int index) {
    setState(() {
      myTabs.removeAt(index);
      if (myTabs.isNotEmpty) {
        _tabController = TabController(length: myTabs.length, vsync: this);
        _tabController!.addListener(() => setState(() {}));
      } else {
        _tabController = null;
        _showAddDialog();
      }
    });
    _saveTabs();
  }

  @override
  Widget build(BuildContext context) {
    Widget actionButtons = Container(
      color: Colors.black45, // Slightly darker block for buttons
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.add_box, color: Colors.white, size: 28), onPressed: _showAddDialog),
          if (myTabs.isNotEmpty && _tabController != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white, size: 28),
              onPressed: () => myTabs[_tabController!.index].controller?.reload(),
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
              children: myTabs.map((tab) => WebViewWidget(controller: tab.controller!)).toList(),
            ),
      ),
      bottomNavigationBar: Container(
        height: 70,
        color: const Color(0xFF9146FF),
        child: Row(
          children: isLeftHanded 
            ? [actionButtons, const VerticalDivider(width: 1, color: Colors.white24), Expanded(child: _buildTabBar())] 
            : [Expanded(child: _buildTabBar()), const VerticalDivider(width: 1, color: Colors.white24), actionButtons],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    if (myTabs.isEmpty || _tabController == null) return const SizedBox();
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.center, // Keeps selected tab centered in the available area
      indicatorColor: Colors.transparent, 
      dividerColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 10),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      tabs: myTabs.asMap().entries.map((entry) {
        int index = entry.key;
        bool isActive = _tabController!.index == index;
        
        String displayName = entry.value.channel;
        if (displayName.toLowerCase() == "deemonrider") displayName = "DR";
        
        IconData icon = entry.value.type == "chat" ? Icons.chat_bubble : Icons.extension;
        if (entry.value.type == "login") {
          icon = Icons.person;
          displayName = "Login";
        }

        return Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            // "Pressed in" look: Darker purple and slightly shadow-inset effect
            color: isActive ? const Color(0xFF5B2B9F) : Colors.white.withAlpha(40),
            borderRadius: BorderRadius.circular(8), 
            border: Border.all(
              color: isActive ? Colors.black26 : Colors.white24, 
              width: 1.5
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: isActive ? Colors.white70 : Colors.white),
              const SizedBox(width: 6),
              Text(displayName, style: TextStyle(
                color: isActive ? Colors.white : Colors.white70, 
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal, 
                fontSize: 12
              )),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _closeTab(index),
                child: Container(
                  padding: const EdgeInsets.all(1),
                  decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 12, color: Colors.white70),
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
                  _addTab("panel", name);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.chat),
                label: const Text("Add Chat"),
                onPressed: () {
                  String name = channelController.text.trim().isEmpty ? "deemonrider" : channelController.text.trim();
                  _addTab("chat", name);
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              TextButton(
                onPressed: () {
                  _addTab("login", "");
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