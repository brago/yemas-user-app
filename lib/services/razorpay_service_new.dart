import 'dart:convert' show base64Encode, utf8;

import 'package:booking_system_flutter/network/network_utils.dart' show getRemoteDataFromUrl;
import 'package:nb_utils/nb_utils.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../main.dart';
import '../model/payment_gateway_response.dart';
import '../utils/colors.dart';
import '../utils/common.dart';
import '../utils/configs.dart';

class RazorPayServiceNew {
  late PaymentSetting paymentSetting;
  late Razorpay razorPay;
  num totalAmount = 0;
  late Function(Map<String, dynamic>) onComplete;

  RazorPayServiceNew({
    required PaymentSetting paymentSetting,
    required num totalAmount,
    required Function(Map<String, dynamic>) onComplete,
  }) {
    razorPay = Razorpay();
    razorPay.on(Razorpay.EVENT_PAYMENT_SUCCESS, handlePaymentSuccess);
    razorPay.on(Razorpay.EVENT_PAYMENT_ERROR, handlePaymentError);
    razorPay.on(Razorpay.EVENT_EXTERNAL_WALLET, handleExternalWallet);
    this.paymentSetting = paymentSetting;
    this.totalAmount = totalAmount;
    this.onComplete = onComplete;
  }

  Future handlePaymentSuccess(PaymentSuccessResponse response) async {
    appStore.setLoading(false);
    onComplete.call({
      'orderId': response.orderId,
      'paymentId': response.paymentId,
      'signature': response.signature,
    });
  }

  void handlePaymentError(PaymentFailureResponse response) {
    appStore.setLoading(false);
    toast(language.yourPaymentFailedPleaseTryAgain, print: true);
  }

  void handleExternalWallet(ExternalWalletResponse response) {
    appStore.setLoading(false);
    toast("${language.externalWallet} " + response.walletName!);
  }

  Future<void> razorPayCheckout() async {
    appStore.setLoading(true);
    try {
      String orderId = '';
      final data = await createRazorPayOrder(amount: totalAmount);

      if (data != null && data is Map<String, dynamic> && data.containsKey('id') && data['id'] is String && data['id'].isNotEmpty) {
        orderId = data['id'];
      }
      if (orderId.isEmpty) {
        throw 'Order id is empty or not found';
      }
      String razorKey = paymentSetting.isTest == 1 ? paymentSetting.testValue!.razorKey! : paymentSetting.liveValue!.razorKey!;
      var options = {
        'key': razorKey,
        'amount': (totalAmount * 100).toInt(),
        'name': APP_NAME,
        'theme.color': primaryColor.toHex(),
        'payment_capture': 1,
        'order_id': orderId,
        'description': APP_NAME,
        'image': 'https://razorpay.com/assets/razorpay-glyph.svg',
        'currency': await isIqonicProduct ? RAZORPAY_CURRENCY_CODE : '${appConfigurationStore.currencyCode}',
        'prefill': {'contact': appStore.userContactNumber, 'email': appStore.userEmail},
        'external': {
          'wallets': ['paytm']
        },
      };

      razorPay.open(options);
    } catch (e) {
      appStore.setLoading(false);
      log(e.toString());
    }
  }

  Map<String, String> buildHeaderForRazorpay(String razorPaySecretKey, String razorPayPublicKey) {
    return {
      'Authorization': 'Basic ${base64Encode(utf8.encode('$razorPayPublicKey:$razorPaySecretKey'))}',
      'content-type': 'application/json',
    };
  }

  String generateReceipt() {
    return "Receipt-${DateTime.now().millisecondsSinceEpoch}";
  }

  Future<dynamic> createRazorPayOrder({
    required num amount,
  }) async {
    try {
      final secretKey = paymentSetting.isTest == 1 ? paymentSetting.testValue!.razorSecret! : paymentSetting.liveValue!.razorSecret!;
      final publicKey = paymentSetting.isTest == 1 ? paymentSetting.testValue!.razorKey! : paymentSetting.liveValue!.razorKey!;
      final currency = await isIqonicProduct ? RAZORPAY_CURRENCY_CODE : '${appConfigurationStore.currencyCode}';
      final response = await getRemoteDataFromUrl(
        url: 'https://api.razorpay.com/v1/orders',
        request: {
          "amount": (amount * 100).round(),
          "currency": currency,
          "receipt": generateReceipt(),
          "payment_capture": 1,
        },
        header: buildHeaderForRazorpay(secretKey, publicKey),
      );

      if (response != null) {
        return response;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
