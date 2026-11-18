import 'package:booking_system_flutter/component/back_widget.dart';
import 'package:booking_system_flutter/component/base_scaffold_body.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/screens/auth/sign_up_screen.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:country_picker/country_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../network/rest_apis.dart';
import '../../utils/configs.dart';
import '../../utils/constant.dart';
import '../dashboard/dashboard_screen.dart';

/// Log in or sign up with a code received by SMS.
/// Existing customers go straight to the app; new ones are only asked their name.
class OTPLoginScreen extends StatefulWidget {
  /// Number already typed on the sign-in screen: the code is sent right away.
  final String? phoneNumber;
  final Country? country;

  const OTPLoginScreen({Key? key, this.phoneNumber, this.country}) : super(key: key);

  @override
  State<OTPLoginScreen> createState() => _OTPLoginScreenState();
}

class _OTPLoginScreenState extends State<OTPLoginScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController numberController = TextEditingController();
  final FocusNode _mobileNumberFocus = FocusNode();

  Country selectedCountry = defaultCountry();

  String otpCode = '';
  String verificationId = '';
  int? resendToken;

  bool isCodeSent = false;
  bool isVerifying = false;

  String get fullNumber => "+${selectedCountry.phoneCode} ${numberController.text.trim()}";

  @override
  void initState() {
    super.initState();
    if (widget.country != null) selectedCountry = widget.country!;
    if (widget.phoneNumber.validate().isNotEmpty) {
      numberController.text = widget.phoneNumber!.trim();
      afterBuildCreated(() => sendOTP());
    } else {
      afterBuildCreated(() => appStore.setLoading(false));
    }
  }

  //region Methods
  Future<void> changeCountry() async {
    showCountryPicker(
      context: context,
      countryListTheme: CountryListThemeData(
        textStyle: secondaryTextStyle(color: textSecondaryColorGlobal),
        searchTextStyle: primaryTextStyle(),
        inputDecoration: InputDecoration(
          labelText: language.search,
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderSide: BorderSide(color: const Color(0xFF8C98A8).withValues(alpha: 0.2))),
        ),
      ),
      showPhoneCode: true,
      onSelect: (Country country) {
        selectedCountry = country;
        setState(() {});
      },
    );
  }

  Future<void> sendOTP() async {
    if (numberController.text.trim().length < 8) {
      toast('Entrez un numéro de téléphone valide');
      return;
    }
    hideKeyboard(context);
    appStore.setLoading(true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: "+${selectedCountry.phoneCode}${numberController.text.trim()}",
        forceResendingToken: resendToken,
        // Android sometimes reads the SMS by itself: go on without typing the code.
        verificationCompleted: (PhoneAuthCredential credential) async {
          if (!isVerifying) await signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          appStore.setLoading(false);
          if (e.code == 'invalid-phone-number') {
            toast("Ce numéro n'est pas valide. Vérifiez-le.");
          } else if (e.code == 'too-many-requests') {
            toast('Trop de tentatives. Réessayez dans quelques minutes.');
          } else {
            toast(e.message ?? e.code, print: true);
          }
        },
        codeSent: (String id, int? token) {
          appStore.setLoading(false);
          verificationId = id;
          resendToken = token;
          isCodeSent = id.isNotEmpty;
          setState(() {});
        },
        codeAutoRetrievalTimeout: (String id) {
          verificationId = id;
        },
      );
    } on Exception catch (e) {
      appStore.setLoading(false);
      toast(e.toString(), print: true);
    }
  }

  Future<void> submitOtp() async {
    if (otpCode.validate().length < OTP_TEXT_FIELD_LENGTH) {
      toast('Entrez les $OTP_TEXT_FIELD_LENGTH chiffres du code');
      return;
    }
    hideKeyboard(context);
    await signInWithCredential(PhoneAuthProvider.credential(verificationId: verificationId, smsCode: otpCode));
  }

  /// The phone number is proved: log in, or ask the name of a new customer.
  Future<void> signInWithCredential(PhoneAuthCredential credential) async {
    isVerifying = true;
    appStore.setLoading(true);

    try {
      final UserCredential credentials = await FirebaseAuth.instance.signInWithCredential(credential);
      final String uid = credentials.user!.uid.validate();
      // Proof of the phone number for the server.
      final String firebaseToken = (await credentials.user!.getIdToken()).validate();

      final loginResponse = await loginUser({
        'username': numberController.text.trim(),
        'login_type': LOGIN_TYPE_OTP,
        'uid': uid,
        'firebase_token': firebaseToken,
      }, isSocialLogin: true);

      if (loginResponse.isUserExist.validate(value: true)) {
        await saveUserData(loginResponse.userData!);
        await appStore.setLoginType(LOGIN_TYPE_OTP);
        appStore.setLoading(false);
        DashboardScreen().launch(context, isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
      } else {
        appStore.setLoading(false);
        SignUpScreen(
          isOTPLogin: true,
          phoneNumber: numberController.text.trim(),
          countryCode: selectedCountry.countryCode,
          uid: uid,
          firebaseToken: firebaseToken,
        ).launch(context, isNewTask: false);
      }
    } on FirebaseAuthException catch (e) {
      appStore.setLoading(false);
      if (e.code == 'invalid-verification-code') {
        toast("Ce code n'est pas le bon. Vérifiez le SMS et réessayez.");
      } else if (e.code == 'session-expired') {
        toast('Le code a expiré. Touchez « Renvoyer le code ».');
      } else {
        toast(e.message ?? e.code, print: true);
      }
    } catch (e) {
      appStore.setLoading(false);
      toast(e.toString(), print: true);
    } finally {
      isVerifying = false;
    }
  }
  // endregion

  Widget _codeWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        16.height,
        Text('Entrez le code reçu par SMS au', style: secondaryTextStyle(size: 14), textAlign: TextAlign.center),
        4.height,
        Text(fullNumber, style: boldTextStyle(size: 16)),
        32.height,
        OTPTextField(
          pinLength: OTP_TEXT_FIELD_LENGTH,
          textStyle: primaryTextStyle(),
          decoration: inputDecoration(context).copyWith(counter: const Offstage()),
          onChanged: (s) => otpCode = s,
          onCompleted: (pin) {
            otpCode = pin;
            submitOtp();
          },
        ).fit(),
        30.height,
        AppButton(onTap: submitOtp, text: 'Valider', color: primaryColor, textColor: Colors.white, width: context.width()),
        16.height,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () {
                isCodeSent = false;
                otpCode = '';
                setState(() {});
              },
              child: Text('Modifier le numéro', style: secondaryTextStyle(color: primaryColor)),
            ),
            TextButton(
              onPressed: sendOTP,
              child: Text('Renvoyer le code', style: secondaryTextStyle(color: primaryColor)),
            ),
          ],
        ),
      ],
    ).paddingAll(16);
  }

  Widget _numberWidget() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nous allons vous envoyer un code par SMS.', style: secondaryTextStyle(size: 14)),
        16.height,
        Form(
          key: formKey,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: 48.0,
                decoration: BoxDecoration(color: context.cardColor, borderRadius: BorderRadius.circular(12.0)),
                child: Row(
                  children: [
                    Text("+${selectedCountry.phoneCode}", style: primaryTextStyle(size: 12)),
                    Icon(Icons.arrow_drop_down, color: primaryColor),
                  ],
                ).paddingOnly(left: 8),
              ).onTap(() => changeCountry()),
              10.width,
              AppTextField(
                controller: numberController,
                focus: _mobileNumberFocus,
                textFieldType: TextFieldType.PHONE,
                decoration: inputDecoration(context).copyWith(hintText: 'Ex. : ${selectedCountry.example}', hintStyle: secondaryTextStyle()),
                autoFocus: true,
                onFieldSubmitted: (s) => sendOTP(),
              ).expand(),
            ],
          ),
        ),
        30.height,
        AppButton(onTap: sendOTP, text: 'Recevoir un code par SMS', color: primaryColor, textColor: Colors.white, width: context.width()),
      ],
    );
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => hideKeyboard(context),
      child: Scaffold(
        appBar: AppBar(
          title: Text(isCodeSent ? 'Code reçu par SMS' : 'Votre numéro de téléphone', style: boldTextStyle(size: APP_BAR_TEXT_SIZE)),
          elevation: 0,
          backgroundColor: context.scaffoldBackgroundColor,
          leading: Navigator.of(context).canPop() ? BackWidget(iconColor: context.iconColor) : null,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(statusBarIconBrightness: appStore.isDarkMode ? Brightness.light : Brightness.dark, statusBarColor: context.scaffoldBackgroundColor),
        ),
        body: Body(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: isCodeSent ? _codeWidget() : _numberWidget(),
          ),
        ),
      ),
    );
  }
}
