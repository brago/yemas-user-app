import 'dart:convert';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/utils/configs.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:flutterwave_standard/flutterwave.dart';
import 'package:http/http.dart' as http;
import 'package:nb_utils/nb_utils.dart';
import 'package:uuid/uuid.dart';
import '../model/payment_gateway_response.dart';

class FlutterWaveServiceNew {
  final Customer customer = Customer(
    name: appStore.userName,
    phoneNumber: appStore.userContactNumber,
    email: appStore.userEmail,
  );

  void checkout({
    required PaymentSetting paymentSetting,
    required num totalAmount,
    required Function(Map) onComplete,
  }) async {
    try {
      appStore.setLoading(true);

      final String transactionId = const Uuid().v1();
      String flutterWavePublicKey = '';
      String flutterWaveSecretKey = '';

      if (paymentSetting.isTest == 1) {
        flutterWavePublicKey = paymentSetting.testValue!.flutterwavePublic.validate();
        flutterWaveSecretKey = paymentSetting.testValue!.flutterwaveSecret.validate();
      } else {
        flutterWavePublicKey = paymentSetting.liveValue!.flutterwavePublic.validate();
        flutterWaveSecretKey = paymentSetting.liveValue!.flutterwaveSecret.validate();
      }

      final Flutterwave flutterWave = Flutterwave(
        context: getContext,
        publicKey: flutterWavePublicKey,
        currency: appConfigurationStore.currencyCode.validate(value: "NGN"),
        redirectUrl: "$BASE_URL/payment-verification",
        txRef: transactionId,
        amount: totalAmount.toStringAsFixed(appConfigurationStore.priceDecimalPoint),
        customer: customer,
        paymentOptions: "card, banktransfer, ussd, mpesa", // Add options supported for your account
        customization: Customization(title: language.payWithFlutterWave, logo: appLogo),
        isTestMode: paymentSetting.isTest == 1,
      );

      final ChargeResponse response = await flutterWave.charge();

      log("Flutterwave Charge Response: ${response.toJson()}");

      if (response.status == "success" && response.transactionId.validate().isNotEmpty) {
        bool verified = await verifyFlutterwavePayment(
          transactionId: response.transactionId!,
          secretKey: flutterWaveSecretKey,
        );

        appStore.setLoading(false);

        if (verified) {
          onComplete.call({
            'transaction_id': response.transactionId!,
          });
        } else {
          toast(language.transactionFailed);
        }
      } else {
        appStore.setLoading(false);
        toast(language.lblTransactionCancelled);
      }
    } catch (e) {
      appStore.setLoading(false);
      log("FlutterWave Checkout Error: $e");
      toast("Payment failed: ${e.toString()}");
    }
  }

  Future<bool> verifyFlutterwavePayment({
    required String transactionId,
    required String secretKey,
  }) async {
    final url = 'https://api.flutterwave.com/v3/transactions/$transactionId/verify';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/json',
        },
      );

      final json = jsonDecode(response.body);
      log("Flutterwave Verification Response: $json");

      if (response.statusCode == 200 && json['status'] == 'success') {
        return true;
      } else {
        log("Verification failed: ${json['message']}");
        return false;
      }
    } catch (e) {
      log("Error verifying payment: $e");
      return false;
    }
  }
}
