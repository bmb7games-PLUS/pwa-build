import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  InAppWebViewController? _webViewController;

  Future<bool> _onWillPop() async {
    if (_webViewController != null) {
      if (await _webViewController!.canGoBack()) {
        _webViewController!.goBack();
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri(dotenv.env['HOST_URL']!),
            ),
            onWebViewCreated: (controller) {
              _webViewController = controller;
            },
          ),
        ),
      ),
    );
  }
}
