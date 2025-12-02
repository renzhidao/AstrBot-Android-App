import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../components/bottom_navigation_bar.dart';
import '../webview/webview_page.dart';
import '../settings/settings_page.dart';

import '../../controllers/terminal_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  DateTime? _lastBackPressed;
  // 标志：是否需要刷新AstrBot页面
  bool _shouldRefreshAstrBot = false;

  final HomeController homeController = Get.find<HomeController>();

  @override
  void initState() {
    super.initState();
    _initSystemUI();
  }

  @override
  void dispose() {
    _restoreSystemUI();
    super.dispose();
  }

  void _initSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));
  }

  void _restoreSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));
  }

  Future<void> _handleBackPress() async {
    // 否则执行双击退出逻辑
    final now = DateTime.now();
    final backButtonInterval = _lastBackPressed == null
        ? const Duration(seconds: 3)
        : now.difference(_lastBackPressed!);

    if (backButtonInterval > const Duration(seconds: 2)) {
      _lastBackPressed = now;
      Get.showSnackbar(
        const GetSnackBar(
          message: '再按一次退出',
          duration: Duration(seconds: 2),
          snackPosition: SnackPosition.BOTTOM,
          margin: EdgeInsets.all(10),
          borderRadius: 10,
          backgroundColor: Colors.black87,
          messageText: Text('再按一次退出', style: TextStyle(color: Colors.white)),
        ),
      );
    } else {
      _lastBackPressed = null;
      if (mounted) {
        SystemNavigator.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 检查 NapCat WebUI 是否启用
    final bool napCatEnabled = homeController.napCatWebUiEnabled.get() ?? false;
    
    // 动态构建页面列表，与导航项匹配
    final List<Widget> pages = [
      // 1. AstrBot WebView 页面
      WebViewPage(
        showNapCat: false,
        refreshOnLoad: _shouldRefreshAstrBot,
      ),
      // 2. NapCat WebView 页面（仅在启用时添加）
      if (napCatEnabled) const WebViewPage(showNapCat: true),
      // 3. 设置页面
      const SettingsPage(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBackPress();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            top: true,
            child: pages[_currentIndex],
          ),
          bottomNavigationBar: CustomBottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              // 检查是否从设置页返回并切换到AstrBot页面
              if (_currentIndex == 2 && index == 0) {
                _shouldRefreshAstrBot = true;
              } else {
                _shouldRefreshAstrBot = false;
              }
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ),
      ),
    );
  }
}
