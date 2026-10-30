import 'dart:convert';
import 'package:booking_system_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nb_utils/nb_utils.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../model/payment_gateway_response.dart';

class JekoPayServices {
  late PaymentSetting paymentSetting;
  num totalAmount;
  late Function(Map<String, dynamic>) onComplete;

  JekoPayServices({
    required this.paymentSetting,
    required this.totalAmount,
    required this.onComplete,
  });

  Future<void> payWithJeko({
    required BuildContext context,
    required int bookingId,
    String paymentMethod = 'wave',
  }) async {
    appStore.setLoading(true);
    try {
      final token = appStore.token;
      final response = await http.post(
        Uri.parse('https://yemas-services.com/api/jeko/initiate'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': totalAmount.toInt(),
          'booking_id': bookingId,
          'payment_method': paymentMethod,
        }),
      );
      final data = jsonDecode(response.body);
      if (data['success'] != true || data['payment_url'] == null) {
        appStore.setLoading(false);
        toast('Erreur de paiement: ${data['error'] ?? 'Lien non généré'}');
        return;
      }
      final paymentUrl = data['payment_url'] as String;
      final reference = data['reference'] as String;
      appStore.setLoading(false);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => JekoWebView(
            paymentUrl: paymentUrl,
            reference: reference,
            successUrl: 'https://yemas-services.com/payment/success',
            errorUrl: 'https://yemas-services.com/payment/error',
            onSuccess: () {
              toast(language.yourPaymentHasBeenMadeSuccessfully);
              onComplete.call({'transaction_id': reference});
            },
            onError: () {
              toast(language.yourPaymentFailedPleaseTryAgain);
            },
          ),
        ),
      );
    } catch (e) {
      appStore.setLoading(false);
      toast('Erreur: $e');
    }
  }
}

class JekoWebView extends StatefulWidget {
  final String paymentUrl;
  final String reference;
  final String successUrl;
  final String errorUrl;
  final VoidCallback onSuccess;
  final VoidCallback onError;

  const JekoWebView({
    Key? key,
    required this.paymentUrl,
    required this.reference,
    required this.successUrl,
    required this.errorUrl,
    required this.onSuccess,
    required this.onError,
  }) : super(key: key);

  @override
  State<JekoWebView> createState() => _JekoWebViewState();
}

class _JekoWebViewState extends State<JekoWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) => setState(() => _isLoading = true),
        onPageFinished: (url) => setState(() => _isLoading = false),
        onNavigationRequest: (request) {
          final url = request.url;
          if (url.startsWith(widget.successUrl)) {
            Navigator.pop(context);
            widget.onSuccess();
            return NavigationDecision.prevent;
          }
          if (url.startsWith(widget.errorUrl)) {
            Navigator.pop(context);
            widget.onError();
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement Jèko'),
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
            ),
        ],
      ),
    );
  }
}
