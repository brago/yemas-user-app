import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:booking_system_flutter/component/base_scaffold_widget.dart';
import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/component/custom_image_picker.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/city_list_model.dart';
import 'package:booking_system_flutter/model/country_list_model.dart';
import 'package:booking_system_flutter/model/login_model.dart';
import 'package:booking_system_flutter/model/state_list_model.dart';
import 'package:booking_system_flutter/network/network_utils.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/model_keys.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_picker/country_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobx/mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../utils/configs.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  EditProfileScreenState createState() => EditProfileScreenState();
}

class EditProfileScreenState extends State<EditProfileScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  File? imageFile;
  XFile? pickedFile;

  List<CountryListResponse> countryList = [];
  List<StateListResponse> stateList = [];
  List<CityListResponse> cityList = [];

  CountryListResponse? selectedCountry;
  StateListResponse? selectedState;
  CityListResponse? selectedCity;

  TextEditingController fNameCont = TextEditingController();
  TextEditingController lNameCont = TextEditingController();
  TextEditingController emailCont = TextEditingController();
  TextEditingController userNameCont = TextEditingController();
  TextEditingController mobileCont = TextEditingController();
  TextEditingController addressCont = TextEditingController();

  FocusNode fNameFocus = FocusNode();
  FocusNode lNameFocus = FocusNode();
  FocusNode emailFocus = FocusNode();
  FocusNode userNameFocus = FocusNode();
  FocusNode mobileFocus = FocusNode();

  ValueNotifier valueNotifier = ValueNotifier(true);

  int countryId = 0;
  int stateId = 0;
  int cityId = 0;

  Country selectedCountryCode = defaultCountry();

  bool isEmailVerified = getBoolAsync(IS_EMAIL_VERIFIED);

  bool showRefresh = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    afterBuildCreated(() {
      appStore.setLoading(true);
    });

    countryId = getIntAsync(COUNTRY_ID);
    stateId = getIntAsync(STATE_ID);
    cityId = getIntAsync(CITY_ID);

    fNameCont.text = appStore.userFirstName;
    lNameCont.text = appStore.userLastName;
    emailCont.text = appStore.userEmail;
    userNameCont.text = appStore.userName;
    mobileCont.text = appStore.userContactNumber.split("-").last;
    countryId = appStore.countryId;
    stateId = appStore.stateId;
    cityId = appStore.cityId;
    addressCont.text = appStore.address;

    userDetailAPI();

    if (getIntAsync(COUNTRY_ID) != 0) {
      await getCountry();

      setState(() {});
    } else {
      await getCountry();
    }
  }

  //region Logic
  String buildMobileNumber() {
    if (mobileCont.text.isEmpty) {
      return '';
    } else {
      return '${mobileCont.text.trim().formatPhoneNumber(selectedCountryCode.phoneCode)}';
    }
  }

  Future<void> userDetailAPI() async {
    await getUserDetail(appStore.userId).then((value) {
      isEmailVerified = value.emailVerified.validate().getBoolInt();
      setValue(IS_EMAIL_VERIFIED, isEmailVerified);
      mobileCont.text = value.contactNumber.validate().formatPhoneNumber(selectedCountryCode.phoneCode);
      String raw = value.contactNumber.validate().trim();
      if (raw.startsWith('+')) {
        RegExp re = RegExp(r'^\+(\d{1,3})\s*(.*)$');
        Match? m = re.firstMatch(raw);
        if (m != null) {
          String callingCode = m.group(1) ?? '';
          String local = (m.group(2) ?? '').replaceAll(RegExp(r'[^\d]'), '');

          selectedCountryCode = Country(
            countryCode: appStore.userContactNumber.split("-").last,
            phoneCode: callingCode,
            e164Sc: 0,
            geographic: true,
            level: 1,
            name: '',
            example: '',
            displayName: '',
            displayNameNoCountryCode: '',
            e164Key: '',
            fullExampleWithPlusSign: '',
          );
          mobileCont.text = local.isNotEmpty ? local : raw.replaceAll(RegExp(r'[^\d]'), '');
          valueNotifier.value = !valueNotifier.value;
        } else {
          // Fallback to digits only as local
          mobileCont.text = raw.replaceAll(RegExp(r'[^\d]'), '');
        }
      } else {
        // No + prefix, keep default picker and just clean the number
        mobileCont.text = raw.replaceAll(RegExp(r'[^\d]'), '');
      }
      setState(() {});
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString());
    });
  }

  Future<void> getCountry() async {
    await getCountryList().then((value) async {
      countryList.clear();
      countryList.addAll(value);

      if (value.any((element) => element.id == getIntAsync(COUNTRY_ID))) {
        selectedCountry = value.firstWhere((element) => element.id == getIntAsync(COUNTRY_ID));
      }

      setState(() {});
      await getStates(getIntAsync(COUNTRY_ID));
    }).catchError((e) {
      toast('$e', print: true);
    });
    appStore.setLoading(false);
  }

  Future<void> getStates(int countryId) async {
    appStore.setLoading(true);
    await getStateList({UserKeys.countryId: countryId}).then((value) async {
      stateList.clear();
      stateList.addAll(value);

      if (value.any((element) => element.id == getIntAsync(STATE_ID))) {
        selectedState = value.firstWhere((element) => element.id == getIntAsync(STATE_ID));
      }

      setState(() {});
      if (getIntAsync(STATE_ID) != 0) {
        await getCity(getIntAsync(STATE_ID));
      }
    }).catchError((e) {
      toast('$e', print: true);
    });
    appStore.setLoading(false);
  }

  Future<void> getCity(int stateId) async {
    appStore.setLoading(true);

    await getCityList({UserKeys.stateId: stateId}).then((value) async {
      cityList.clear();
      cityList.addAll(value);

      if (value.any((element) => element.id == getIntAsync(CITY_ID))) {
        selectedCity = value.firstWhere((element) => element.id == getIntAsync(CITY_ID));
      }

      setState(() {});
    }).catchError((e) {
      toast('$e', print: true);
    });
    appStore.setLoading(false);
  }

  Future<void> update() async {
    hideKeyboard(context);

    MultipartRequest multiPartRequest = await getMultiPartRequest('update-profile');
    multiPartRequest.fields[UserKeys.id] = appStore.userId.toString();
    multiPartRequest.fields[UserKeys.firstName] = fNameCont.text;
    multiPartRequest.fields[UserKeys.lastName] = lNameCont.text;
    multiPartRequest.fields[UserKeys.userName] = userNameCont.text;
    // multiPartRequest.fields[UserKeys.userType] = appStore.loginType;
    multiPartRequest.fields[UserKeys.contactNumber] = buildMobileNumber();
    multiPartRequest.fields[UserKeys.email] = emailCont.text;
    multiPartRequest.fields[UserKeys.countryId] = countryId.toString();
    multiPartRequest.fields[UserKeys.stateId] = stateId.toString();
    multiPartRequest.fields[UserKeys.cityId] = cityId.toString();
    multiPartRequest.fields[CommonKeys.address] = addressCont.text;
    multiPartRequest.fields[UserKeys.displayName] = '${fNameCont.text.validate() + " " + lNameCont.text.validate()}';
    if (imageFile != null) {
      multiPartRequest.files.add(await MultipartFile.fromPath(UserKeys.profileImage, imageFile!.path));
    }

    multiPartRequest.headers.addAll(buildHeaderTokens());
    appStore.setLoading(true);

    sendMultiPartRequest(
      multiPartRequest,
      onSuccess: (data) async {
        appStore.setLoading(false);
        if (data != null) {
          if ((data as String).isJson()) {
            LoginResponse res = LoginResponse.fromJson(jsonDecode(data));

            if (FirebaseAuth.instance.currentUser != null) {
              userService.updateDocument({
                'profile_image': res.userData!.profileImage.validate(),
                'updated_at': Timestamp.now().toDate().toString(),
              }, FirebaseAuth.instance.currentUser!.uid);
            }

            saveUserData(res.userData!);
            finish(context);
            toast(res.message.validate().capitalizeFirstLetter());
          }
        }
      },
      onError: (error) {
        toast(error.toString(), print: true);
        appStore.setLoading(false);
      },
    ).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString(), print: true);
    });
  }

  void _getFromGallery() async {
    pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      maxHeight: 1800,
    );
    if (pickedFile != null) {
      imageFile = File(pickedFile!.path);
      setState(() {});
    }
  }

  _getFromCamera() async {
    pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 1800,
      maxHeight: 1800,
    );
    if (pickedFile != null) {
      imageFile = File(pickedFile!.path);
      setState(() {});
    }
  }

  Future<void> verifyEmail() async {
    appStore.setLoading(true);

    await verifyUserEmail(emailCont.text).then((value) async {
      isEmailVerified = value.isEmailVerified.validate().getBoolInt();

      toast(value.message);

      await setValue(IS_EMAIL_VERIFIED, isEmailVerified);
      setState(() {});
      appStore.setLoading(false);
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString());
    });
  }

  void _showImgPickDialog(BuildContext context) {
    showInDialog(
      context,
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      title: Text(language.chooseAction, style: boldTextStyle()),
      builder: (p0) {
        return const FilePickerDialog(isSelected: (false));
      },
    ).then((file) async {
      if (file != null) {
        if (file == GalleryFileTypes.CAMERA) {
          _getFromCamera();
        } else if (file == GalleryFileTypes.GALLERY) {
          _getFromGallery();
        }
      }
    });
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
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: const Color(0xFF8C98A8).withValues(alpha: 0.2),
            ),
          ),
        ),
      ),

      showPhoneCode: true, // optional. Shows phone code before the country name.
      onSelect: (Country country) {
        selectedCountryCode = country;
        setState(() {});
      },
    );
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showLoader: true,
      isLoading: Observable(appStore.isLoading),
      appBarTitle: language.editProfile,
      child: RefreshIndicator(
        onRefresh: () async {
          return await userDetailAPI();
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Form(
              key: formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    children: [
                      Container(
                        decoration: boxDecorationDefault(
                          border: Border.all(color: context.scaffoldBackgroundColor, width: 4),
                          shape: BoxShape.circle,
                        ),
                        child: imageFile != null
                            ? Image.file(
                                imageFile!,
                                width: 85,
                                height: 85,
                                fit: BoxFit.cover,
                              ).cornerRadiusWithClipRRect(40)
                            : Observer(
                                builder: (_) => CachedImageWidget(
                                  url: appStore.userProfileImage,
                                  height: 85,
                                  width: 85,
                                  fit: BoxFit.cover,
                                  radius: 43,
                                ),
                              ),
                      ),
                      Positioned(
                        bottom: 4,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: boxDecorationWithRoundedCorners(
                            boxShape: BoxShape.circle,
                            backgroundColor: primaryColor,
                            border: Border.all(color: Colors.white),
                          ),
                          child: const Icon(AntDesign.camera, color: Colors.white, size: 12),
                        ).onTap(() async {
                          _showImgPickDialog(context);
                        }),
                      ).visible(!isLoginTypeGoogle && !isLoginTypeApple)
                    ],
                  ),
                  16.height,
                  AppTextField(
                    textFieldType: TextFieldType.NAME,
                    controller: fNameCont,
                    focus: fNameFocus,
                    errorThisFieldRequired: language.requiredText,
                    nextFocus: lNameFocus,
                    enabled: !isLoginTypeApple,
                    decoration: inputDecoration(context, labelText: language.hintFirstNameTxt),
                    suffix: ic_profile2.iconImage(size: 10).paddingAll(14),
                  ),
                  16.height,
                  AppTextField(
                    textFieldType: TextFieldType.NAME,
                    controller: lNameCont,
                    focus: lNameFocus,
                    errorThisFieldRequired: language.requiredText,
                    nextFocus: userNameFocus,
                    enabled: !isLoginTypeApple,
                    decoration: inputDecoration(context, labelText: language.hintLastNameTxt),
                    suffix: ic_profile2.iconImage(size: 10).paddingAll(14),
                  ),
                  16.height,
                  AppTextField(
                    textFieldType: TextFieldType.NAME,
                    controller: userNameCont,
                    focus: userNameFocus,
                    enabled: false,
                    errorThisFieldRequired: language.requiredText,
                    nextFocus: emailFocus,
                    decoration: inputDecoration(context, labelText: language.hintUserNameTxt),
                    suffix: ic_profile2.iconImage(size: 10).paddingAll(14),
                  ),
                  16.height,
                  AppTextField(
                    textFieldType: TextFieldType.EMAIL_ENHANCED,
                    controller: emailCont,
                    focus: emailFocus,
                    nextFocus: mobileFocus,
                    errorThisFieldRequired: language.requiredText,
                    decoration: inputDecoration(context, labelText: language.hintEmailTxt),
                    suffix: ic_message.iconImage(size: 10).paddingAll(14),
                    autoFillHints: [AutofillHints.email],
                    onFieldSubmitted: (email) async {
                      if (emailCont.text.isNotEmpty) await verifyEmail();
                    },
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Wrap(
                      spacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          isEmailVerified ? language.verified : language.verifyEmail,
                          style: isEmailVerified ? secondaryTextStyle(color: Colors.green) : secondaryTextStyle(),
                        ),
                        if (!isEmailVerified && !showRefresh)
                          ic_pending.iconImage(color: Colors.amber, size: 14)
                        else
                          Icon(
                            isEmailVerified ? Icons.check_circle : Icons.refresh,
                            color: isEmailVerified ? Colors.green : Colors.grey,
                            size: 16,
                          )
                      ],
                    ).paddingSymmetric(horizontal: 6, vertical: 2).onTap(
                      () {
                        verifyEmail();
                      },
                      borderRadius: radius(),
                    ),
                  ).paddingSymmetric(vertical: 4),
                  10.height,
                  // AppTextField(
                  //   textFieldType: isAndroid ? TextFieldType.PHONE : TextFieldType.NAME,
                  //   controller: mobileCont,
                  //   focus: mobileFocus,
                  //   maxLength: 15,
                  //   buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) {
                  //     return Offstage();
                  //   },
                  //   enabled: !isLoginTypeOTP,
                  //   errorThisFieldRequired: language.requiredText,
                  //   decoration: inputDecoration(context, labelText: language.hintContactNumberTxt),
                  //   suffix: ic_calling.iconImage(size: 10).paddingAll(14),
                  //   validator: (mobileCont) {
                  //     if (mobileCont!.isEmpty) return language.phnRequiredText;
                  //     if (isIOS && !RegExp(r"^([0-9]{1,5})-([0-9]{1,10})$").hasMatch(mobileCont)) {
                  //       return language.inputMustBeNumberOrDigit;
                  //     }
                  //     if (!mobileCont.trim().contains('-')) return '"-" ${language.requiredAfterCountryCode}';
                  //     return null;
                  //   },
                  // ),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Country code ...
                      Container(
                        height: 48.0,
                        margin: EdgeInsets.only(bottom: context.height() * 0.032),
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Center(
                          child: ValueListenableBuilder(
                            valueListenable: valueNotifier,
                            builder: (context, value, child) => Row(
                              children: [
                                Text(
                                  "+${selectedCountryCode.phoneCode}",
                                  style: primaryTextStyle(size: 12),
                                ),
                                const Icon(Icons.arrow_drop_down)
                              ],
                            ).paddingOnly(left: 8),
                          ),
                        ),
                      ).onTap(() => changeCountry()),
                      10.width,
                      // Mobile number text field...
                      Expanded(
                        child: AppTextField(
                          textFieldType: isAndroid ? TextFieldType.PHONE : TextFieldType.NAME,
                          controller: mobileCont,
                          focus: mobileFocus,
                          enabled: !isLoginTypeOTP,
                          isValidationRequired: false,
                          errorThisFieldRequired: language.requiredText,
                          decoration: inputDecoration(context, hintText: '${language.hintContactNumberTxt}').copyWith(
                            // hintText: '${selectedCountry.example}',
                            hintStyle: secondaryTextStyle(),
                          ),
                          maxLength: 15,
                          suffix: ic_calling.iconImage(size: 10).paddingAll(14),
                        ),
                      ),
                    ],
                  ),
                  16.height,
                  Row(
                    children: [
                      DropdownButtonFormField<CountryListResponse>(
                        decoration: inputDecoration(context, labelText: language.selectCountry),
                        isExpanded: true,
                        initialValue: selectedCountry,
                        dropdownColor: context.cardColor,
                        items: countryList.map((CountryListResponse e) {
                          return DropdownMenuItem<CountryListResponse>(
                            value: e,
                            child: Text(
                              e.name!,
                              style: primaryTextStyle(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (CountryListResponse? value) async {
                          hideKeyboard(context);
                          countryId = value!.id!;
                          selectedCountry = value;
                          selectedState = null;
                          selectedCity = null;
                          getStates(value.id!);

                          setState(() {});
                        },
                      ).expand(),
                      8.width.visible(stateList.isNotEmpty),
                      if (stateList.isNotEmpty)
                        DropdownButtonFormField<StateListResponse>(
                          decoration: inputDecoration(context, labelText: language.selectState),
                          isExpanded: true,
                          dropdownColor: context.cardColor,
                          initialValue: selectedState,
                          items: stateList.map((StateListResponse e) {
                            return DropdownMenuItem<StateListResponse>(
                              value: e,
                              child: Text(
                                e.name!,
                                style: primaryTextStyle(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (StateListResponse? value) async {
                            hideKeyboard(context);
                            selectedCity = null;
                            selectedState = value;
                            stateId = value!.id!;
                            await getCity(value.id!);
                            setState(() {});
                          },
                        ).expand(),
                    ],
                  ),
                  16.height,
                  if (cityList.isNotEmpty)
                    DropdownButtonFormField<CityListResponse>(
                      decoration: inputDecoration(context, labelText: language.selectCity),
                      isExpanded: true,
                      initialValue: selectedCity,
                      dropdownColor: context.cardColor,
                      items: cityList.map((CityListResponse e) {
                        return DropdownMenuItem<CityListResponse>(
                          value: e,
                          child: Text(e.name!, style: primaryTextStyle(), maxLines: 1, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (CityListResponse? value) async {
                        hideKeyboard(context);
                        selectedCity = value;
                        cityId = value!.id!;
                        setState(() {});
                      },
                    ),
                  16.height,
                  AppTextField(
                    controller: addressCont,
                    textFieldType: TextFieldType.MULTILINE,
                    maxLines: 5,
                    decoration: inputDecoration(context, labelText: language.hintAddress),
                    suffix: ic_location.iconImage(size: 10).paddingAll(14),
                    isValidationRequired: false,
                  ),
                  40.height,
                  AppButton(
                    text: language.save,
                    color: primaryColor,
                    textColor: white,
                    width: context.width() - context.navigationBarHeight,
                    onTap: () {
                      ifNotTester(() {
                        update();
                      });
                    },
                  ),
                  24.height,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}