import 'dart:convert';

import 'package:demo/webview/webview.dart';
import 'package:el_dart/el_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
        home: HomePage(),
      ),
    );
  }
}

final counterProvider = StateProvider<int>((ref) => 0);

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final updateValue = ref.watch(counterProvider);

    return MaterialApp(
      home: Scaffold(
        body: _Demo(),
        floatingActionButton: FloatingActionButton(onPressed: () {}, child: Icon(Icons.add)),
      ),
    );
  }
}

class _Demo extends StatelessWidget {
  const _Demo();

  @override
  Widget build(BuildContext context) {
    return WebviewPage(url: 'https://dashboard.paytm.com/login/',enableProgressIndicator: true,);
    // return WebviewPage(url: 'https://www.bing.com/',showAppbar: false);
  }
}
