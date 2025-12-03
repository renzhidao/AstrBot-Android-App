import 'package:get/get.dart';
import '../pages/terminal/terminal_page.dart';
import '../pages/webview/webview_page.dart';
import '../pages/settings/settings_page.dart';
import '../pages/home/home_page.dart';

class AppRoutes {
  static const String home = '/';
  static const String terminal = '/terminal';
  static const String webview = '/webview';
  static const String settings = '/settings';

  static final routes = [
    GetPage(
      name: home,
      page: () => const HomePage(),
    ),
    GetPage(
      name: terminal,
      page: () => const TerminalPage(),
    ),
    GetPage(
      name: webview,
      page: () => const WebViewPage(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: settings,
      page: () => const SettingsPage(),
      transition: Transition.fadeIn,
    ),
  ];
}
