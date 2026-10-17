// ignore_for_file: body_might_complete_normally_catch_error

 import 'package:booking_system_flutter/model/payment_gateway_response.dart';
 import 'package:booking_system_flutter/services/phone_pe/phone_pe_view_page.dart';
 import 'package:booking_system_flutter/network/network_utils.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';


import '../../../../main.dart';

class PhonePeServices {
  late PaymentSetting paymentSetting;
  int bookingId = 21;
  num totalAmount = 0;
  late Function(Map<String, dynamic>) onComplete;
  bool isTest = false;
  String environmentValue = '';

  String merchantId = "";

  PhonePeServices({
    required PaymentSetting paymentSetting,
    required num totalAmount,
    int bookingId = 0,
    required Function(Map<String, dynamic>) onComplete,
  }) {
    isTest = paymentSetting.isTest == 1;
    environmentValue = isTest ? "UAT" : "PRODUCTION";
    merchantId = "M22MHJ61A01OI"; // Replace with your actual
    this.paymentSetting = paymentSetting;
    this.totalAmount = totalAmount;
    this.onComplete = onComplete;
    this.bookingId = bookingId;
  }

   // ✅ Backend endpoint (relative). Base URL and headers handled by network utils
   final String initiateApi = "phonepe/initiate";
   final String initiateV2Api = "phonepe/initiate-v2";

  String txnId = "";

  Future<void> phonePeCheckout(BuildContext context, {
    bool isV2 = false,
  }) async {
    try {
      appStore.setLoading(true);

      // Call backend to get redirect URL using dynamic HTTP utils
      final response = await buildHttpResponse(
        isV2 ? initiateV2Api : initiateApi,
        method: HttpMethodType.POST,
        request: {
          "amount": double.parse(totalAmount.toStringAsFixed(2)),
          "booking_id": bookingId,
          "transaction_id": txnId,
        },
      );

      final data = await handleResponse(response) as Map<String, dynamic>;

      String redirectUrl = "";
      if(isV2) {
        redirectUrl = data['redirectUrl'];
      } else {
        redirectUrl = data['data']?['instrumentResponse']?['redirectInfo']?['url']?.toString() ?? "";
      }

      if (redirectUrl.isEmpty) {
        throw Exception("Invalid redirect URL in backend response: ${response.body}");
      }

       appStore.setLoading(false);
       await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PhonePeWebViewPage(
            redirectUrl: redirectUrl,
            transactionId: txnId,
            onComplete: onComplete,
          ),
        ),
      );
    } catch (e, stack) {
      appStore.setLoading(false);
      log(" PhonePe WebView Error: $e");
      log(" Stack: $stack");
      toast("PhonePe payment failed: ${e.toString()}");
    }
  }

}



