part of 'webview.dart';

// webview的默认设置
const Map<String, dynamic> _defaultWebviewSetting = {
  // 支持IOS上左右滑动的导航手势
  'allowsBackForwardNavigationGestures': true,
  // 支持打开多窗口
  'javaScriptCanOpenWindowsAutomatically': true,
  'supportMultipleWindows': true,
  // 透明背景，解决黑暗模式下webview的背景色和flutter背景色不一致问题
  'transparentBackground': true,
  // flutter混合合成(HC)，就目前而言，该选项的webview的性能最高(VD、HC、TLHC)，但在路由过渡过程中会出现闪烁bug
  'useHybridComposition': true,
  // 禁止IOS平台网页过度滚动，即滚动弹跳动画
  'disallowOverScroll': true,
  // 禁止Android网页过度滚动，安卓12之前会有渐变波纹，安卓12之后网页会出现拉伸弹跳动画
  'overScrollMode': 2,
};

class _WebviewPageController {
  InAppWebViewController? webViewController;

  final loadProgress = Obs(0.0);
  final webviewTitle = Obs('');

  /// 当前访问的历史记录，由canGoBackOrForward方法提供，注意：返回上一页依旧会获取用户完整的历史记录，当用户进入新的页面后才会覆盖之前旧的历史
  final history = Obs<List<WebHistoryItem>>([]);

  /// 将要可以退出，主要根据此变量取消路由拦截
  final willCanBack = Obs(false);

  /// 如果历史记录只有一条数据、或者[willCanBack]可以退出，根据这两个条件动态取消路由拦截
  bool get canBack => history.value.length <= 1 || willCanBack.value;

  void setHistory() {
    webViewController!.getCopyBackForwardList().then((e) {
      if (e?.list != null) {
        history.value = e!.list!;
        webViewController!.canGoBackOrForward(steps: -1).then((value) {
          willCanBack.value = !value;
        });
      }
    });
  }

  void dispose() {
    webViewController?.dispose();
    loadProgress.dispose();
    webviewTitle.dispose();
    history.dispose();
    willCanBack.dispose();
  }
}

/// 如果你将webview页面当做一个独立的App页面，你可以使用此组件，否则你应当使用[WebviewWidget]
class WebviewPage extends StatefulWidget {
  const WebviewPage({
    super.key,
    this.title,
    this.url,
    this.html,
    this.windowId,
    this.clearCache = false,
    this.showAppbar = true,
    this.toolbarHeight,
    this.enableProgressIndicator = false,
    this.focusLandscape = false,
    this.enableNavIntercept = false,
    this.onCreated,
    this.onMounted,
  });

  /// 指定页面标题
  final String? title;

  /// 加载的网页地址，如果是http开头则走网络请求，否则将加载assets目录
  final String? url;

  /// 加载html字符串
  final String? html;

  /// 使用windowId创建webview，一般用于onCreateWindow事件
  final int? windowId;

  /// 是否清除webview缓存
  final bool clearCache;

  /// 是否显示应用头部导航
  final bool showAppbar;

  /// appbar工具栏高度，如果你想隐藏appbar同时保留状态栏，那么你可以将此选项设置为0
  final double? toolbarHeight;

  /// 是否开启网页加载进度
  final bool enableProgressIndicator;

  /// 是否强制横屏展示Webview
  final bool focusLandscape;

  /// 是否开启Webview页面的导航拦截，注意：IOS下无效，因为WillPopScope将导致IOS无法返回
  final bool enableNavIntercept;

  /// webview创建完成，你可以在这里添加JavaScript处理程序，供前端调用
  final void Function(InAppWebViewController controller)? onCreated;

  /// webview加载完成，你可以在这里执行JavaScript中的方法
  final void Function(InAppWebViewController controller, Uri? url)? onMounted;

  @override
  State<WebviewPage> createState() => WebviewPageState();
}

class WebviewPageState extends State<WebviewPage> with WidgetsBindingObserver {
  late _WebviewPageController _controller;
  late String id;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    id = El.uuidStr;

    _controller = _WebviewPageController();
    if (widget.focusLandscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
    if (widget.focusLandscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }

    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showAppbar) {
      return Scaffold(
        appBar: AppBar(
          title: widget.title == null
              ? ObsBuilder(
                  builder: (context) => Tooltip(
                    message: _controller.webviewTitle.value,
                    child: Text(_controller.webviewTitle.value),
                  ),
                )
              : Tooltip(message: widget.title, child: Text(widget.title!)),
          toolbarHeight: widget.toolbarHeight ?? Theme.of(context).appBarTheme.toolbarHeight,
          actions: [
            PopupMenuButton(
              elevation: 2,
              popUpAnimationStyle: AnimationStyle(duration: const Duration(milliseconds: 0)),
              itemBuilder: (BuildContext context) => <PopupMenuEntry>[
                PopupMenuItem(
                  onTap: () {
                    _controller.webViewController?.reload();
                  },
                  child: Text('刷新'),
                ),
                PopupMenuItem(
                  onTap: () async {
                    // 获取当前网页 URL
                    final uri = await _controller.webViewController?.getUrl();
                    if (uri != null) {
                      // 用系统浏览器打开
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Text('在浏览器中打开'),
                ),
                PopupMenuItem(
                  onTap: () async {
                    CookieManager cookieManager = CookieManager.instance();

                    WebUri? currentUrl = await _controller.webViewController?.getUrl();
                    if (currentUrl != null) {
                      final cookies = await cookieManager.getCookies(url: currentUrl);
                      el.log.i(cookies);

                      el.log.i(cookies.map((e)=>e.name).toList());
                      el.log.i(cookies.any((c) => c.name == "SESSION"));
                      el.log.i(cookies.where((c) => c.name == "XSRF-TOKEN").first);
                    }

                    // if (currentUrl != null) {
                    //   // 👇 读取该域名下的所有 Cookie
                    //   List<Cookie> cookies = await _controller.webViewController!.manager.cookieManager.getCookies(url: currentUrl);
                    //
                    //   // 打印查看
                    //   for (var cookie in cookies) {
                    //     print("Cookie 名称: ${cookie.name}");
                    //     print("Cookie 值: ${cookie.value}");
                    //     print("域名: ${cookie.domain}");
                    //   }
                    // }
                  },
                  child: Text('读取cookie'),
                ),
              ],
            ),
          ],
        ),
        body: buildWebview(),
      );
    } else {
      return Scaffold(body: buildWebview());
    }
  }

  Widget buildWebview() {
    bool isHttp = false;
    if (widget.url != null) isHttp = widget.url!.startsWith('http');
    Map<String, dynamic> webviewSetting = {
      // 是否为黑暗模式，注意：目前flutter中的webview加载的网页似乎无法监听系统主题，
      // 即css使用dark: media模式是没有效果的，我们必须在flutter中做处理，
      // 通过 didChangePlatformBrightness 监听系统主题变化，
      // 设置forceDark属性来强制webview以黑暗模式展示。
      'forceDark': ElBrightness.isDark(context) ? 2 : 0,
      'clearCache': widget.clearCache,
    };
    webviewSetting.addAll(_defaultWebviewSetting);
    return Stack(
      children: [
        ObsBuilder(
          builder: (context) {
            return WillPopScope(
              onWillPop: ElPlatform.isIOS
                  ? null
                  : _controller.canBack
                  ? null
                  : () async {
                      await _controller.webViewController!.goBack();
                      _controller.webViewController!.canGoBackOrForward(steps: -1).then((value) {
                        if (mounted) _controller.willCanBack.value = !value;
                      });
                      return false;
                    },
              child: InAppWebView(
                initialUrlRequest: widget.url == null
                    ? null
                    : isHttp
                    ? URLRequest(url: WebUri(widget.url!))
                    : null,
                initialFile: widget.url == null
                    ? null
                    : isHttp
                    ? null
                    : widget.url,
                initialData: widget.html == null
                    ? null
                    : InAppWebViewInitialData(data: widget.html!),
                windowId: widget.windowId,
                initialSettings: InAppWebViewSettings.fromMap(webviewSetting),
                onWebViewCreated: (controller) {
                  _controller.webViewController = controller;
                  if (widget.onCreated != null) widget.onCreated!(controller);
                },
                onLoadStop: (controller, url) async {
                  if (widget.onMounted != null) widget.onMounted!(controller, url);
                  _controller.setHistory();
                },
                onProgressChanged: (controller, progress) {
                  _controller.loadProgress.value = progress / 100;
                },
                onReceivedError: (controller, request, error) async {},
                onTitleChanged: (controller, title) {
                  _controller.webviewTitle.value = title ?? "";
                },
                onCreateWindow: (controller, createWindowAction) async {
                  Navigator.of(context).push(
                    NoAnimationPage(
                      child: WebviewPage(
                        windowId: createWindowAction.windowId,
                        enableNavIntercept: widget.enableNavIntercept,
                        enableProgressIndicator: widget.enableProgressIndicator,
                        onCreated: widget.onCreated,
                      ),
                    ),
                  );
                  return true;
                },
              ),
            );
          },
        ),
        if (widget.enableProgressIndicator)
          ObsBuilder(
            builder: (context) => Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _controller.loadProgress.value < 1.0
                  ? LinearProgressIndicator(
                      value: _controller.loadProgress.value,
                      minHeight: 2,
                      backgroundColor: Colors.transparent,
                    )
                  : const SizedBox(),
            ),
          ),
      ],
    );
  }
}

/// IOS导航栏webview
class CupertinoWebviewPage extends StatefulWidget {
  const CupertinoWebviewPage({
    super.key,
    this.title,
    this.url,
    this.html,
    this.previousPageTitle = '返回',
    this.showAppbar = true,
    this.enableProgressIndicator = false,
    this.enableFullScreen = false,
    this.headerBackground,
    this.headerColor,
    this.focusLandscape = false,
    this.enableNavIntercept = false,
    this.onCreated,
    this.onMounted,
  });

  /// 指定页面标题
  final String? title;

  /// 加载的网页地址，如果是http开头则走网络请求，否则将加载assets目录
  final String? url;

  /// 加载html字符串
  final String? html;

  /// 返回文字
  final String previousPageTitle;

  /// 是否显示应用头部导航，若为false，则导航头和状态栏都消失
  final bool showAppbar;

  /// 是否开启网页加载进度
  final bool enableProgressIndicator;

  /// 是否开启全屏
  final bool enableFullScreen;

  /// 头部背景颜色，默认从 Theme.of 中获取
  final Color? headerBackground;

  /// 头部内容颜色，默认根据背景色自动匹配白色和黑色
  final Color? headerColor;

  /// 是否强制横屏展示Webview
  final bool focusLandscape;

  /// 是否开启Webview页面的导航拦截，注意：IOS下无效，因为WillPopScope将导致IOS无法返回
  final bool enableNavIntercept;

  /// webview创建完成，你可以在这里添加JavaScript处理程序，供前端调用
  final void Function(InAppWebViewController controller)? onCreated;

  /// webview加载完成，你可以在这里执行JavaScript中的方法
  final void Function(InAppWebViewController controller, Uri? url)? onMounted;

  @override
  State<CupertinoWebviewPage> createState() => _CupertinoWebviewPageState();
}

class _CupertinoWebviewPageState extends State<CupertinoWebviewPage> {
  InAppWebViewController? webViewController;
  String? webviewTitle; // 网页标题
  double progress = 0;

  @override
  void initState() {
    super.initState();
    // 强制横屏
    if (widget.focusLandscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }

    if (widget.enableFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.bottom]);
    }
  }

  @override
  void dispose() {
    super.dispose();
    if (widget.focusLandscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }

    if (widget.enableFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    }
  }

  @override
  Widget build(BuildContext context) {
    Color headerBackground =
        widget.headerBackground ??
        Theme.of(context).appBarTheme.backgroundColor ??
        Theme.of(context).primaryColor;
    Color headerColor =
        widget.headerColor ?? (headerBackground.isDark ? Colors.white : Colors.grey.shade800);
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.title ?? webviewTitle ?? '', style: TextStyle(color: headerColor)),
        previousPageTitle: widget.previousPageTitle,
        backgroundColor: headerBackground,
      ),
      child: SafeArea(child: buildWebview()),
    );
  }

  Widget buildWebview() {
    return Stack(
      children: [
        WebviewWidget(
          url: widget.url,
          html: widget.html,
          enableNavIntercept: widget.enableNavIntercept,
          showScrollbar: false,
          onCreated: widget.onCreated,
          onMounted: widget.onMounted,
          onProgressChanged: (controller, progress) {
            setState(() {
              this.progress = progress / 100;
            });
          },
          onTitleChanged: (controller, title) {
            setState(() {
              webviewTitle = title;
            });
          },
        ),
        if (widget.enableProgressIndicator)
          progress < 1.0
              ? LinearProgressIndicator(
                  value: progress,
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                )
              : const SizedBox(),
      ],
    );
  }
}
