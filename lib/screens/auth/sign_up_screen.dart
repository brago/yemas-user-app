import 'dart:math';

import 'package:booking_system_flutter/component/back_widget.dart';
import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/dashboard/dashboard_screen.dart';
import 'package:booking_system_flutter/services/deep_link_service.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/configs.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

/// Account creation, kept as short as possible:
/// - after an SMS code ([isOTPLogin]): only the name is asked;
/// - with an e-mail: name, e-mail, phone and password.
/// The customer is logged in right after, with no second sign-in.
class SignUpScreen extends StatefulWidget {
  final String? phoneNumber;
  final String? countryCode;
  final bool isOTPLogin;
  final String? uid;

  /// Firebase ID token proving the phone number (SMS sign-up).
  final String? firebaseToken;

  SignUpScreen({Key? key, this.phoneNumber, this.isOTPLogin = false, this.countryCode, this.uid, this.firebaseToken}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  Country selectedCountry = defaultCountry();

  final TextEditingController nameCont = TextEditingController();
  final TextEditingController emailCont = TextEditingController();
  final TextEditingController mobileCont = TextEditingController();
  final TextEditingController passwordCont = TextEditingController();
  final TextEditingController referralCodeCont = TextEditingController();

  final FocusNode nameFocus = FocusNode();
  final FocusNode emailFocus = FocusNode();
  final FocusNode mobileFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();
  final FocusNode referralCodeFocus = FocusNode();

  bool showReferral = false;
  bool isFirstTimeValidation = true;

  bool? isReferralValid;
  String? referralValidationMessage;

  @override
  void initState() {
    super.initState();
    referralCodeCont.addListener(() {
      if (isReferralValid != null || referralValidationMessage != null) {
        setState(() {
          isReferralValid = null;
          referralValidationMessage = null;
        });
      }
    });
    init();
  }

  void init() async {
    if (widget.phoneNumber != null) {
      selectedCountry = Country.parse(widget.countryCode.validate(value: selectedCountry.countryCode));
      mobileCont.text = widget.phoneNumber.validate();
    }

    // Referral code received through an invitation link.
    final pendingCode = DeepLinkService().getPendingReferralCode();
    if (pendingCode != null && pendingCode.isNotEmpty) {
      referralCodeCont.text = pendingCode;
      showReferral = true;
      await _validateReferralCodeIfNeeded();
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  //region Logic
  String buildMobileNumber() {
    if (mobileCont.text.isEmpty) return '';
    return '+${mobileCont.text.trim().formatPhoneNumber(selectedCountry.phoneCode)}';
  }

  /// "Awa Konan Marie" → first name "Awa", last name "Konan Marie".
  (String, String) splitName() {
    final parts = nameCont.text.trim().split(RegExp(r'\s+'));
    return (parts.first, parts.length > 1 ? parts.sublist(1).join(' ') : '');
  }

  /// Usernames are not asked any more: built from the e-mail, plus a few digits.
  String usernameFromEmail(String email) {
    final base = email.split('@').first.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return '${base.isEmpty ? 'client' : base}${Random().nextInt(9000) + 1000}';
  }

  Future<void> register() async {
    hideKeyboard(context);
    if (appStore.isLoading) return;

    if (!formKey.currentState!.validate()) {
      isFirstTimeValidation = false;
      setState(() {});
      return;
    }
    if (!await _validateReferralCodeIfNeeded()) return;

    final (firstName, lastName) = splitName();
    final Map<String, dynamic> request = {
      'first_name': firstName,
      'last_name': lastName,
      'user_type': USER_TYPE_USER,
      'contact_number': buildMobileNumber(),
      if (referralCodeCont.text.trim().isNotEmpty) 'referral_code': referralCodeCont.text.trim(),
    };

    if (widget.isOTPLogin) {
      // The server checks the phone number with the Firebase token, and creates
      // the account with no e-mail or password to remember.
      request.addAll({
        'username': widget.phoneNumber.validate().trim(),
        'login_type': LOGIN_TYPE_OTP,
        'uid': widget.uid.validate(),
        'firebase_token': widget.firebaseToken.validate(),
      });
    } else {
      request.addAll({
        'username': usernameFromEmail(emailCont.text.trim()),
        'email': emailCont.text.trim(),
        'password': passwordCont.text.trim(),
      });
    }

    appStore.setLoading(true);
    try {
      final registerResponse = await createUser(request);

      if (widget.isOTPLogin && registerResponse.userData?.apiToken.validate().isNotEmpty == true) {
        await saveUserData(registerResponse.userData!);
        await appStore.setLoginType(LOGIN_TYPE_OTP);
      } else {
        // E-mail sign-up: log in straight away with the new password.
        final loginResponse = await loginUser({'email': emailCont.text.trim(), 'password': passwordCont.text.trim()});
        await saveUserData(loginResponse.userData!);
        await appStore.setLoginType(LOGIN_TYPE_USER);
        authService.verifyFirebaseUser();
      }

      appStore.setLoading(false);
      toast('Bienvenue ${firstName.validate()} !');
      DashboardScreen().launch(context, isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
    } catch (e) {
      appStore.setLoading(false);
      toast(e.toString());
    }
  }

  Future<bool> _validateReferralCodeIfNeeded() async {
    final code = referralCodeCont.text.trim();
    if (code.isEmpty) {
      setState(() {
        isReferralValid = null;
        referralValidationMessage = null;
      });
      return true;
    }

    try {
      appStore.setLoading(true);
      final response = await checkReferralCode(code);
      final bool isValid = response.status == true;
      setState(() {
        isReferralValid = isValid;
        referralValidationMessage = isValid ? 'Code valide' : "Ce code n'existe pas";
      });
      if (!isValid) {
        referralCodeFocus.requestFocus();
        toast(referralValidationMessage);
      }
      return isValid;
    } catch (e) {
      log(e.toString());
      setState(() {
        isReferralValid = false;
        referralValidationMessage = e.toString();
      });
      toast(e.toString());
      return false;
    } finally {
      appStore.setLoading(false);
    }
  }

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
  //endregion

  //region Widgets
  Widget _buildTopWidget() {
    return Column(
      children: [
        (context.height() * 0.10).toInt().height,
        Container(
          height: 72,
          width: 72,
          padding: const EdgeInsets.all(16),
          child: ic_profile2.iconImage(color: Colors.white),
          decoration: boxDecorationDefault(shape: BoxShape.circle, color: primaryColor),
        ),
        16.height,
        Text(widget.isOTPLogin ? 'Comment vous appelez-vous ?' : 'Créer mon compte', style: boldTextStyle(size: 22), textAlign: TextAlign.center).center(),
        8.height,
        Text(
          widget.isOTPLogin ? 'Votre numéro est vérifié. Il ne reste que votre nom.' : 'Quelques informations, et c\'est parti.',
          style: secondaryTextStyle(size: 14),
          textAlign: TextAlign.center,
        ).center().paddingSymmetric(horizontal: 32),
      ],
    );
  }

  Widget _phoneField() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 48.0,
          decoration: BoxDecoration(color: context.cardColor, borderRadius: BorderRadius.circular(12.0)),
          child: Row(
            children: [
              Text("+${selectedCountry.phoneCode}", style: primaryTextStyle(size: 12)),
              Icon(Icons.arrow_drop_down, color: textSecondaryColorGlobal),
            ],
          ).paddingOnly(left: 8),
        ).onTap(() => changeCountry()),
        10.width,
        AppTextField(
          textFieldType: TextFieldType.PHONE,
          controller: mobileCont,
          focus: mobileFocus,
          nextFocus: passwordFocus,
          errorThisFieldRequired: 'Indiquez votre numéro',
          decoration: inputDecoration(context, labelText: 'Votre numéro de téléphone').copyWith(
            hintText: 'Ex. : ${selectedCountry.example}',
            hintStyle: secondaryTextStyle(),
          ),
          maxLength: 15,
        ).expand(),
      ],
    );
  }

  Widget _referralWidget() {
    if (!showReferral) {
      return TextButton(
        onPressed: () {
          showReferral = true;
          setState(() {});
          referralCodeFocus.requestFocus();
        },
        child: Text("Quelqu'un vous a invité ? Entrez son code", style: secondaryTextStyle(color: primaryColor)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        8.height,
        AppTextField(
          textFieldType: TextFieldType.NAME,
          controller: referralCodeCont,
          focus: referralCodeFocus,
          isValidationRequired: false,
          decoration: inputDecoration(context, labelText: "Code d'invitation (facultatif)"),
        ),
        if (referralValidationMessage.validate().isNotEmpty)
          Text(referralValidationMessage!, style: primaryTextStyle(color: isReferralValid == true ? Colors.green : Colors.red, size: 12)).paddingTop(4),
      ],
    );
  }

  /// Instead of a checkbox: continuing means accepting, with links to read them.
  Widget _consentWidget() {
    return RichTextWidget(
      textAlign: TextAlign.center,
      list: [
        TextSpan(text: 'En continuant, vous acceptez les ', style: secondaryTextStyle(size: 12)),
        TextSpan(
          text: 'conditions',
          style: boldTextStyle(color: primaryColor, size: 12),
          recognizer: TapGestureRecognizer()..onTap = () => checkIfLink(context, appConfigurationStore.termConditions, title: language.termsCondition),
        ),
        TextSpan(text: ' et la ', style: secondaryTextStyle(size: 12)),
        TextSpan(
          text: 'politique de confidentialité',
          style: boldTextStyle(color: primaryColor, size: 12),
          recognizer: TapGestureRecognizer()..onTap = () => checkIfLink(context, appConfigurationStore.privacyPolicy, title: language.privacyPolicy),
        ),
        TextSpan(text: '.', style: secondaryTextStyle(size: 12)),
      ],
    ).paddingSymmetric(vertical: 12, horizontal: 8);
  }

  Widget _buildFormWidget() {
    return Column(
      children: [
        32.height,
        AppTextField(
          textFieldType: TextFieldType.NAME,
          controller: nameCont,
          focus: nameFocus,
          nextFocus: widget.isOTPLogin ? null : emailFocus,
          autoFocus: widget.isOTPLogin,
          errorThisFieldRequired: 'Indiquez votre nom',
          decoration: inputDecoration(context, labelText: 'Votre nom et prénom'),
          suffix: ic_profile2.iconImage(size: 10).paddingAll(14),
          onFieldSubmitted: widget.isOTPLogin ? (_) => register() : null,
        ),
        if (!widget.isOTPLogin) ...[
          16.height,
          AppTextField(
            textFieldType: TextFieldType.EMAIL_ENHANCED,
            controller: emailCont,
            focus: emailFocus,
            nextFocus: mobileFocus,
            errorThisFieldRequired: 'Indiquez votre e-mail',
            decoration: inputDecoration(context, labelText: 'Votre e-mail'),
            suffix: ic_message.iconImage(size: 10).paddingAll(14),
          ),
          16.height,
          _phoneField(),
          8.height,
          AppTextField(
            textFieldType: TextFieldType.PASSWORD,
            controller: passwordCont,
            focus: passwordFocus,
            obscureText: true,
            suffixPasswordVisibleWidget: ic_show.iconImage(size: 10).paddingAll(14),
            suffixPasswordInvisibleWidget: ic_hide.iconImage(size: 10).paddingAll(14),
            decoration: inputDecoration(context, labelText: 'Choisissez un mot de passe (8 caractères minimum)'),
            isValidationRequired: true,
            validator: (val) {
              if (val == null || val.isEmpty) return 'Choisissez un mot de passe';
              if (val.length < 8) return 'Au moins 8 caractères';
              return null;
            },
            onFieldSubmitted: (_) => register(),
          ),
        ],
        8.height,
        _referralWidget(),
        _consentWidget(),
        AppButton(
          text: widget.isOTPLogin ? "C'est parti" : 'Créer mon compte',
          color: primaryColor,
          textColor: Colors.white,
          width: context.width() - context.navigationBarHeight,
          onTap: register,
        ),
      ],
    );
  }

  Widget _buildFooterWidget() {
    if (widget.isOTPLogin) return 30.height;
    return Column(
      children: [
        16.height,
        RichTextWidget(
          list: [
            TextSpan(text: "${language.alreadyHaveAccountTxt} ", style: secondaryTextStyle()),
            TextSpan(
              text: language.signIn,
              style: boldTextStyle(color: primaryColor, size: 14),
              recognizer: TapGestureRecognizer()..onTap = () => finish(context),
            ),
          ],
        ),
        30.height,
      ],
    );
  }
  //endregion

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => hideKeyboard(context),
      child: SafeArea(
        top: false,
        child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: transparentColor,
            leading: Container(
              margin: const EdgeInsets.only(left: 6),
              decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, shape: BoxShape.circle),
              child: BackWidget(iconColor: context.iconColor),
            ),
            scrolledUnderElevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle(statusBarIconBrightness: appStore.isDarkMode ? Brightness.light : Brightness.dark, statusBarColor: context.scaffoldBackgroundColor),
          ),
          body: Stack(
            alignment: AlignmentDirectional.center,
            children: [
              Form(
                key: formKey,
                autovalidateMode: isFirstTimeValidation ? AutovalidateMode.disabled : AutovalidateMode.onUserInteraction,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildTopWidget(),
                      _buildFormWidget(),
                      8.height,
                      _buildFooterWidget(),
                    ],
                  ),
                ),
              ),
              Observer(builder: (_) => LoaderWidget().center().visible(appStore.isLoading)),
            ],
          ),
        ),
      ),
    );
  }
}
