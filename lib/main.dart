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
  String? nickname;
  WebViewController? controller;

  TwitchTab({required this.type, required this.channel, this.nickname, this.controller});

  Map<String, dynamic> toJson() => {'type': type, 'channel': channel, 'nickname': nickname};

  factory TwitchTab.fromJson(Map<String, dynamic> json) {
    return TwitchTab(type: json['type'], channel: json['channel'], nickname: json['nickname']);
  }
}

class TwitchApp extends StatefulWidget {
  const TwitchApp({super.key});
  @override
  State<TwitchApp> createState() => _TwitchAppState();
}

class _TwitchAppState extends State<TwitchApp> with TickerProviderStateMixin {
  List<TwitchTab> myTabs = [];
  late PageController _pageController;
  int _currentPageIndex = 0;
  bool isLeftHanded = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initializeApp();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
          _pageController = PageController();
          _currentPageIndex = 0;
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

  void _addTab(String type, String channel, String? nickname) {
    setState(() {
      myTabs.add(TwitchTab(
        type: type, 
        channel: channel,
        nickname: nickname,
        controller: _createController(_generateUrl(type, channel))
      ));
      _pageController.jumpToPage(myTabs.length - 1);
      _currentPageIndex = myTabs.length - 1;
    });
    _saveTabs();
  }

  void _closeTab(int index) {
    setState(() {
      myTabs.removeAt(index);
      if (myTabs.isNotEmpty) {
        // Adjust current page index if needed
        if (_currentPageIndex >= myTabs.length) {
          _currentPageIndex = myTabs.length - 1;
        }
        // Recreate PageController to sync with new list
        _pageController = PageController(initialPage: _currentPageIndex);
      } else {
        _showAddDialog();
      }
    });
    _saveTabs();
  }

  void _reorderTabs(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final TwitchTab item = myTabs.removeAt(oldIndex);
      myTabs.insert(newIndex, item);
      // If current page was affected, adjust the index
      if (oldIndex == _currentPageIndex) {
        _currentPageIndex = newIndex;
      } else if (oldIndex < _currentPageIndex && newIndex >= _currentPageIndex) {
        _currentPageIndex--;
      } else if (oldIndex > _currentPageIndex && newIndex < _currentPageIndex) {
        _currentPageIndex++;
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
          if (myTabs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white, size: 28),
              onPressed: () => myTabs[_currentPageIndex].controller?.reload(),
            ),
        ],
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: myTabs.isEmpty 
          ? const Center(child: Text("No tabs open.")) 
          : PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) => setState(() { _currentPageIndex = index; }),
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
    if (myTabs.isEmpty) return const SizedBox();
    return ReorderableListView.builder(
      scrollDirection: Axis.horizontal,
      onReorder: _reorderTabs,
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      itemCount: myTabs.length,
      itemBuilder: (context, index) {
        final tab = myTabs[index];
        bool isActive = _currentPageIndex == index;
        
        String displayName = tab.nickname ?? tab.channel;
        if (displayName.toLowerCase() == "deemonrider" && tab.nickname == null) displayName = "DR";
        
        IconData icon = tab.type == "chat" ? Icons.chat_bubble : Icons.extension;
        if (tab.type == "login") {
          icon = Icons.person;
          displayName = "Login";
        }

        return ReorderableDragStartListener(
          key: ValueKey(index),
          index: index,
          child: GestureDetector(
            onTap: () {
              _pageController.jumpToPage(index);
              setState(() { _currentPageIndex = index; });
            },
            child: Container(
              height: 42,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
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
            ),
          ),
        );
      },
    );
  }

  void _showAddDialog() {
    TextEditingController channelController = TextEditingController();
    TextEditingController nicknameController = TextEditingController();
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
              const SizedBox(height: 10),
              TextField(
                controller: nicknameController,
                decoration: const InputDecoration(hintText: "Nickname (Optional custom tab label)"),
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                icon: const Icon(Icons.extension),
                label: const Text("Add Extension Panel"),
                onPressed: () {
                  String name = channelController.text.trim().isEmpty ? "deemonrider" : channelController.text.trim();
                  String? nickname = nicknameController.text.trim().isEmpty ? null : nicknameController.text.trim();
                  _addTab("panel", name, nickname);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.chat),
                label: const Text("Add Chat"),
                onPressed: () {
                  String name = channelController.text.trim().isEmpty ? "deemonrider" : channelController.text.trim();
                  String? nickname = nicknameController.text.trim().isEmpty ? null : nicknameController.text.trim();
                  _addTab("chat", name, nickname);
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              TextButton(
                onPressed: () {
                  _addTab("login", "", null);
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