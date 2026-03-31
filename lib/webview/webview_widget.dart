part of 'webview.dart';

/// Webview组件，当你需要将webview嵌套在
class WebviewWidget extends StatefulWidget {
  const WebviewWidget({
    super.key,
    this.url,
    this.html,
    this.windowId,
    this.showScrollbar = true,
    this.disabledCache = false,
    this.enableGestureRecognizers = false,
    this.gestureRecognizers,
    this.enableNavIntercept = false,
    this.onCreated,
    this.onMounted,
    this.onProgressChanged,
    this.onTitleChanged,
    this.onCreateWindow,
  }) : assert(
         (url != null && html == null && windowId == null) ||
             (html != null && url == null && windowId == null) ||
             (windowId != null && url == null && html == null),
         '注意，webview参数url、html、windowId必须三选一',
       );

  /// 加载的网页地址，如果是http开头则走网络请求，否则将加载assets目录下静态html文件
  final String? url;

  /// 加载html字符串
  final String? html;

  /// 使用windowId创建webview，用于onCreateWindow事件
  final int? windowId;

  /// 是否显示滚动条，默认true
  final bool showScrollbar;

  /// 是否禁止webview缓存
  final bool disabledCache;

  /// 是否开启手势识别器，默认false；如果你将webview嵌套在一个滚动容器中，
  /// 同时webview也是一个可滚动页面，那么你应该将其设置为true，否则webview无法滚动
  final bool enableGestureRecognizers;

  /// 自定义webview页面允许的手势，默认使用所有手势。
  ///
  /// Factory(() => EagerGestureRecognizer()), // 所有手势
  ///
  /// Factory(() => HorizontalDragGestureRecognizer()), // 水平滑动手势
  ///
  /// Factory(() => VerticalDragGestureRecognizer()), // 垂直滑动手势
  ///
  /// Factory(() => ScaleGestureRecognizer()), // 缩放手势
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;

  /// 是否开启Webview页面的导航拦截，注意：IOS下无效，因为WillPopScope将导致IOS无法侧边返回
  final bool enableNavIntercept;

  /// 网页加载进度
  final void Function(InAppWebViewController controller, int progress)? onProgressChanged;

  /// webview创建完成，你可以在这里添加JavaScript处理程序，供前端调用
  final void Function(InAppWebViewController controller)? onCreated;

  /// webview页面加载完成，你可以在这里执行JavaScript中的方法
  final void Function(InAppWebViewController controller, Uri? url)? onMounted;

  /// 跳转地址url变化
  final void Function(InAppWebViewController controller, String? title)? onTitleChanged;

  /// webview触发新窗口事件
  final Future<bool?> Function(
    InAppWebViewController controller,
    CreateWindowAction createWindowAction,
  )?
  onCreateWindow;

  @override
  State<WebviewWidget> createState() => _WebviewWidgetState();
}

class _WebviewWidgetState extends State<WebviewWidget> with WidgetsBindingObserver {
  InAppWebViewController? webViewController;
  bool _isHttp = false;

  // webview的默认设置
  Map<String, dynamic> get _defaultWebviewSetting => {
    // 支持IOS上左右滑动的导航手势
    'allowsBackForwardNavigationGestures': true,
    // 支持打开多窗口
    'javaScriptCanOpenWindowsAutomatically': true,
    'supportMultipleWindows': true,
    // 透明背景，解决黑暗模式下webview的背景色和flutter背景色不一致问题
    'transparentBackground': true,
    // flutter webview最新渲染方式，虽然它可以提升webview的性能，但在部分手机上会出现flutter页面过渡动画帧不同步的bug
    'useHybridComposition': true,
    // 禁止IOS平台网页过度滚动，即滚动弹跳动画
    'disallowOverScroll': true,
    // 禁止Android网页过度滚动，安卓12之前会有渐变波纹，安卓12之后网页会出现拉伸弹跳动画，个人觉得很别扭
    'overScrollMode': 2,
  };

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    if (widget.url != null) _isHttp = widget.url!.startsWith('http');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant WebviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    Map<String, dynamic> webviewSetting = {
      'forceDark': Theme.of(context).brightness == Brightness.light ? 2 : 0,
      'verticalScrollBarEnabled': widget.showScrollbar,
      'clearCache': widget.disabledCache,
    };
    webviewSetting.addAll(_defaultWebviewSetting);
    webViewController?.setSettings(settings: InAppWebViewSettings.fromMap(webviewSetting)!);
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    Map<String, dynamic> webviewSetting = {
      'forceDark': Theme.of(context).brightness == Brightness.light ? 2 : 0,
      'verticalScrollBarEnabled': widget.showScrollbar,
      'clearCache': widget.disabledCache,
    };
    webviewSetting.addAll(_defaultWebviewSetting);
    webViewController?.setSettings(settings: InAppWebViewSettings.fromMap(webviewSetting)!);
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> webviewSetting = {
      // 是否为黑暗模式，注意：目前flutter中的webview加载的网页似乎无法监听系统主题，
      // 即css使用dark: media模式是没有效果的，我们必须在flutter中做处理，
      // 通过 didChangePlatformBrightness 监听系统主题变化，
      // 设置forceDark属性来强制webview以黑暗模式展示。
      'forceDark': ElBrightness.isDark(context) ? 2 : 0,
      // 是否显示滚动条
      'verticalScrollBarEnabled': widget.showScrollbar,
      'clearCache': widget.disabledCache,
    };
    webviewSetting.addAll(_defaultWebviewSetting);
    return WillPopScope(
      onWillPop: ElPlatform.isIOS
          ? null
          : widget.enableNavIntercept
          ? () async {
              try {
                var flag = await webViewController?.canGoBack();
                if (flag == true) {
                  webViewController!.goBack();
                  return false;
                } else {
                  return true;
                }
              } catch (e) {
                return true;
              }
            }
          : null,
      child: InAppWebView(
        initialUrlRequest: widget.url == null
            ? null
            : _isHttp
            ? URLRequest(url: WebUri(widget.url!))
            : null,
        initialFile: widget.url == null
            ? null
            : _isHttp
            ? null
            : widget.url,
        initialData: widget.html == null ? null : InAppWebViewInitialData(data: widget.html!),
        windowId: widget.windowId,
        initialSettings: InAppWebViewSettings.fromMap(webviewSetting),
        gestureRecognizers: widget.enableGestureRecognizers
            ? widget.gestureRecognizers ??
                  {
                    Factory(() => EagerGestureRecognizer()),
                    // Factory(() => VerticalDragGestureRecognizer()),
                  }
            : null,
        onWebViewCreated: (controller) async {
          webViewController = controller;
          if (widget.onCreated != null) widget.onCreated!(controller);
        },
        // onLoadStart: (controller, url) {
        //   LoggerUtil.i('load start');
        // },
        // onUpdateVisitedHistory: (controller, url, isReload) {
        //   LoggerUtil.i('load update');
        // },
        onLoadStop: (controller, url) async {
          if (widget.onMounted != null) widget.onMounted!(controller, url);
          // webViewController?.getContentHeight().then((value) {
          //   LoggerUtil.i(value);
          // });
        },
        onProgressChanged: (controller, progress) {
          if (widget.onProgressChanged != null) widget.onProgressChanged!(controller, progress);
        },
        onReceivedError: (controller, request, error) async {},
        onTitleChanged: widget.onTitleChanged,
        onCreateWindow: widget.onCreateWindow,
      ),
    );
  }
}
