import 'package:booking_system_flutter/component/back_widget.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:nb_utils/nb_utils.dart';

class PhonePeWebViewPage extends StatefulWidget {
  final String redirectUrl;
  final String transactionId;
  final Function(Map<String, dynamic>) onComplete;

  const PhonePeWebViewPage({
    super.key,
    required this.redirectUrl,
    required this.transactionId,
    required this.onComplete,
  });

  @override
  State<PhonePeWebViewPage> createState() => _PhonePeWebViewPageState();
}

class _PhonePeWebViewPageState extends State<PhonePeWebViewPage> {
  late final WebViewController _controller;
  bool hasCompleted = false; // prevent double-callbacks

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            log("Navigating to: ${request.url}");

            // Detect backend callback page
            if (request.url.contains("payment/success")) {
              _handleCallbackPage(request.url);
              return NavigationDecision.prevent;
            }
            // Detect backend callback page
            if (request.url.contains("payment/failed")) {
              _handlePaymentFailed();
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            log("WebView Error: ${error.description}");
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.redirectUrl));
  }

  dispose() {
    _controller.clearCache();
    super.dispose();
  }

  Future<void> _handleCallbackPage(String url) async {
    if (hasCompleted) return;
    hasCompleted = true;

    try {
      final data = Uri.parse(url);
      final txnId = data.queryParameters['transaction_id'];
      if (txnId == null || txnId.isEmpty) {
        _handlePaymentFailed();
        return;
      }
      widget.onComplete({
        "transactionId": txnId,
        "merchantId": 'N/A',
        "status": 'payment_success',
      });
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } catch (e) {
      _handlePaymentFailed();
    }
  }

  void _handlePaymentFailed() {
    widget.onComplete({
      "status": 'payment_error',
    });
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: appBarWidget(
          "PhonePe Payment",
          showBack: true,
          elevation: 1,
          color: primaryColor,
          backWidget: BackWidget(
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}
