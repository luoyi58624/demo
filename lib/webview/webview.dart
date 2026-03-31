import 'package:el_dart/el_dart.dart';
import 'package:el_flutter/el_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

part 'webview_widget.dart';

part 'webview_page.dart';

/// 无动画页面路由
class NoAnimationPage<T> extends PageRouteBuilder<T> {
  NoAnimationPage({
    required Widget child,
    super.settings,
    super.maintainState,
    super.fullscreenDialog,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) => child,
         // 关键：动画时长 0
         transitionDuration: Duration.zero,
         reverseTransitionDuration: Duration.zero,
         // 关闭所有过渡动画
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           return child;
         },
       );
}
