import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../../controllers/terminal_controller.dart';

class WebViewPage extends StatefulWidget {
  // 添加参数来指定要显示的webview类型
  final bool showNapCat;
  // 添加参数来决定是否刷新页面
  final bool refreshOnLoad;
  
  const WebViewPage({Key? key, this.showNapCat = false, this.refreshOnLoad = false}) : super(key: key);

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController _currentController;
  
  final HomeController homeController = Get.find<HomeController>();
  
  // 标记 WebView 是否初始化
  // Flag for WebView initialization
  bool _webViewInitialized = false;

  @override
  void initState() {
    super.initState();
    _initSystemUI();
    // 根据参数初始化相应的WebView控制器
    if (widget.showNapCat) {
      _initNapCatController();
    } else {
      _initAstrBotController();
    }
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

  void _initAstrBotController() {
    _currentController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            _injectClipboardScript(_currentController);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('AstrBot WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse('http://127.0.0.1:6185'));

    if (_currentController.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      final androidController = _currentController.platform as AndroidWebViewController;
      androidController
          .setMediaPlaybackRequiresUserGesture(false);
      // 设置混合内容模式以提高兼容性（Android 9+ 需要）
      androidController.setMixedContentMode(MixedContentMode.compatibilityMode);
      // 允许访问本地文件和内容
      androidController.setAllowFileAccess(true);
      androidController.setAllowContentAccess(true);
    }

    _currentController.addJavaScriptChannel(
      'Android',
      onMessageReceived: (JavaScriptMessage message) {
        if (message.message == 'getClipboardData') {
          _getClipboardData(_currentController);
        }
      },
    );
    
    // 如果需要刷新页面，则重新加载
    if (widget.refreshOnLoad) {
      _currentController.reload();
    }
    
    setState(() {
      _webViewInitialized = true;
    });
  }

  void _initNapCatController() {
    _currentController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (WebResourceError error) {
            debugPrint('NapCat WebView error: ${error.description}');
          },
        ),
      );

    // 监听 Token 变化
    ever(homeController.napCatWebUiToken, (String token) {
      if (token.isNotEmpty) {
        final url = 'http://127.0.0.1:6099/webui?token=$token';
        _currentController.loadRequest(Uri.parse(url));
      }
    });

    // 初始加载
    if (homeController.napCatWebUiToken.isNotEmpty) {
      final url = 'http://127.0.0.1:6099/webui?token=${homeController.napCatWebUiToken.value}';
      _currentController.loadRequest(Uri.parse(url));
    } else {
      _currentController.loadRequest(Uri.parse('http://127.0.0.1:6099/webui'));
    }

    if (_currentController.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      final androidController = _currentController.platform as AndroidWebViewController;
      androidController
          .setMediaPlaybackRequiresUserGesture(false);
      // 设置混合内容模式以提高兼容性（Android 9+ 需要）
      androidController.setMixedContentMode(MixedContentMode.compatibilityMode);
      // 允许访问本地文件和内容
      androidController.setAllowFileAccess(true);
      androidController.setAllowContentAccess(true);
    }
    
    setState(() {
      _webViewInitialized = true;
    });
  }

  void _injectClipboardScript(WebViewController controller) {
    const String jsCode = '''
      const originalReadText = navigator.clipboard.readText;
      navigator.clipboard.readText = function () {
        console.log('Intercepted clipboard read');
        return new Promise((resolve) => {
          Android.postMessage('getClipboardData');
          setTimeout(() => {
            originalReadText.call(navigator.clipboard).then(text => {
              resolve(text);
            }).catch(() => resolve(''));
          }, 100);
        });
      };
    ''';
    controller.runJavaScript(jsCode);
  }

  Future<void> _getClipboardData(WebViewController controller) async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clipboardData?.text ?? '';
    controller.runJavaScript('window.clipboardText = "$text";');
  }

  @override
  Widget build(BuildContext context) {
    if (!_webViewInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: true,
        child: WebViewWidget(controller: _currentController),
      ),
    );
  }
}