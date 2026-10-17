import 'package:booking_system_flutter/component/base_scaffold_body.dart';
import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/component/price_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/package_data_model.dart';
import 'package:booking_system_flutter/model/service_detail_response.dart';
import 'package:booking_system_flutter/model/shop_model.dart';
import 'package:booking_system_flutter/screens/booking/component/confirm_booking_dialog.dart';
import 'package:booking_system_flutter/screens/map/map_screen.dart';
import 'package:booking_system_flutter/screens/service/service_detail_screen.dart';
import 'package:booking_system_flutter/screens/shop/shop_list_screen.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../component/wallet_balance_component.dart';
import '../../../model/booking_amount_model.dart';
import '../../../utils/booking_calculations_logic.dart' show finalCalculations, calculateTotalTaxAmount;
import '../../app_theme.dart';
import '../../component/back_widget.dart';
import '../../component/chat_gpt_loder.dart';
import '../../generated/assets.dart';
import '../../network/rest_apis.dart';
import '../../services/location_service.dart';
import '../../utils/permissions.dart';
import '../service/addons/service_addons_component.dart';
import 'component/applied_tax_list_bottom_sheet.dart';
import 'component/booking_slots.dart';
import 'component/coupon_list_screen.dart';

class BookServiceScreen extends StatefulWidget {
  final ServiceDetailResponse data;
  final BookingPackage? selectedPackage;
  final ShopModel? selectedShop;
  final int? serviceId;

  BookServiceScreen({
    required this.data,
    this.selectedPackage,
    this.selectedShop,
    this.serviceId,
  });

  @override
  _BookServiceScreenState createState() => _BookServiceScreenState();
}

class _BookServiceScreenState extends State<BookServiceScreen> {
  CouponData? appliedCouponData;
  bool isPointsApplied = false;
  num pointsDiscountAmount = 0;
  int? enteredPoints;
  int? lastAppliedPoints;
  BookingAmountModel bookingAmountModel = BookingAmountModel();
  num advancePaymentAmount = 0;

  int itemCount = 1;
  ShopModel? selectedShop;
  bool isEarnPointsLoading = false;
  int? calculatedEarnPoints;

  TextEditingController addressCont = TextEditingController();
  TextEditingController descriptionCont = TextEditingController();
  TextEditingController pointsCont = TextEditingController();

  TextEditingController dateTimeCont = TextEditingController();
  DateTime currentDateTime = DateTime.now();
  DateTime? selectedDate;
  DateTime? finalDate;
  DateTime? packageExpiryDate;
  TimeOfDay? pickedTime;

  RedeemPoints? get activeRedeemPoints => widget.selectedPackage?.redeemPoints ?? widget.data.redeemPoints;

  int? get activeEarnPoints {
    if (widget.selectedPackage != null) {
      return calculatedEarnPoints;
    }
    return calculatedEarnPoints;
  }

  @override
  void initState() {
    super.initState();
    init();
    enteredPoints = null;
    pointsCont.text = '';

    pointsCont.addListener(() {
      if (isPointsApplied && lastAppliedPoints != null) {
        final currentText = pointsCont.text.trim();
        final appliedText = lastAppliedPoints.toString();

        if (currentText != appliedText) {
          isPointsApplied = false;
          pointsDiscountAmount = 0;
          lastAppliedPoints = null;
          setPrice();
        }
      }
      final parsed = int.tryParse(pointsCont.text.trim());
      if (parsed != enteredPoints) {
        setState(() => enteredPoints = parsed);
      }
    });
    if (widget.selectedPackage != null && widget.selectedPackage!.endDate.validate().isNotEmpty) {
      packageExpiryDate = DateTime.parse(widget.selectedPackage!.endDate.validate());
    }
  }

  void init() async {
    setPrice();
    if (widget.selectedShop != null) {
      selectedShop = widget.selectedShop;
    }
    try {
      if (widget.data.serviceDetail != null) {
        if (widget.data.serviceDetail!.dateTimeVal != null) {
          if (widget.data.serviceDetail!.isSlotAvailable.validate()) {
            dateTimeCont.text = formatBookingDate(widget.data.serviceDetail!.dateTimeVal.validate(), format: DATE_FORMAT_1);
            selectedDate = DateTime.parse(widget.data.serviceDetail!.dateTimeVal.validate());
            pickedTime = TimeOfDay.fromDateTime(selectedDate!);
          }
          addressCont.text = widget.data.serviceDetail!.address.validate();
        }
      }
    } catch (e) {}
    setState(() {});
    fetchEarnPointsForCurrentSelection();
  }

  Future<void> fetchEarnPointsForCurrentSelection() async {
    final serviceId = widget.serviceId ?? widget.data.serviceDetail?.id;
    if (serviceId == null) return;

    final subTotal = bookingAmountModel.finalSubTotal;

    setState(() {
      isEarnPointsLoading = true;
    });

    try {
      final points = await getServiceEarnPoints(
          serviceId: widget.selectedPackage != null ? widget.selectedPackage?.id ?? 0 : serviceId, subTotal: subTotal, type: widget.selectedPackage != null ? "package_service" : "service");
      setState(() {
        calculatedEarnPoints = points;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        calculatedEarnPoints = null;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        isEarnPointsLoading = false;
      });
    }
  }

  void _handleSetLocationClick() {
    Permissions.cameraFilesAndLocationPermissionsGranted().then((value) async {
      await setValue(PERMISSION_STATUS, value);

      if (value) {
        String? res = await MapScreen(latitude: getDoubleAsync(LATITUDE), latLong: getDoubleAsync(LONGITUDE)).launch(context);

        addressCont.text = res.validate();
        setState(() {});
      }
    });
  }

  void _handleCurrentLocationClick() {
    Permissions.cameraFilesAndLocationPermissionsGranted().then((value) async {
      await setValue(PERMISSION_STATUS, value);

      if (value) {
        appStore.setLoading(true);

        await getUserLocation().then((value) {
          addressCont.text = value;
          widget.data.serviceDetail!.address = value.toString();
          setState(() {});
        }).catchError((e) {
          log(e);
          // toast(e.toString());
        });

        appStore.setLoading(false);
      }
    }).catchError((e) {
      //
    }).whenComplete(() => appStore.setLoading(false));
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  void setPrice() {
    bookingAmountModel = finalCalculations(
      servicePrice: widget.data.serviceDetail!.price.validate(),
      appliedCouponData: appliedCouponData,
      serviceAddons: serviceAddonStore.selectedServiceAddon,
      discount: widget.data.serviceDetail!.discount.validate(),
      taxes: widget.data.taxes,
      quantity: itemCount,
      selectedPackage: widget.selectedPackage,
    );
    if (isPointsApplied && pointsDiscountAmount > 0) {
      bookingAmountModel.finalSubTotal = (bookingAmountModel.finalSubTotal - pointsDiscountAmount).toStringAsFixed(appConfigurationStore.priceDecimalPoint).toDouble();
      bookingAmountModel.finalTotalTax = calculateTotalTaxAmount(widget.data.taxes, bookingAmountModel.finalSubTotal);
      bookingAmountModel.finalGrandTotalAmount = (bookingAmountModel.finalSubTotal + bookingAmountModel.finalTotalTax).toStringAsFixed(appConfigurationStore.priceDecimalPoint).toDouble();
    } else {
      pointsDiscountAmount = 0;
    }
    if (bookingAmountModel.finalSubTotal.isNegative) {
      appliedCouponData = null;
      isPointsApplied = false;
      pointsDiscountAmount = 0;
      setPrice();
      toast(language.youCannotApplyThisCoupon);
    } else {
      advancePaymentAmount =
          bookingAmountModel.finalGrandTotalAmount * (widget.data.serviceDetail!.advancePaymentPercentage.validate() / 100).toStringAsFixed(appConfigurationStore.priceDecimalPoint).toDouble();
    }
    setState(() {});
  }

  void applyCoupon({bool isApplied = false}) async {
    hideKeyboard(context);
    if (widget.data.serviceDetail != null && widget.data.serviceDetail!.id != null) {
      var value = await CouponsScreen(
              serviceId: widget.data.serviceDetail!.id!.toInt(), servicePrice: bookingAmountModel.finalTotalServicePrice, appliedCouponData: appliedCouponData, price: bookingAmountModel.finalSubTotal)
          .launch(context);
      if (value != null) {
        if (value is bool && !value) {
          appliedCouponData = null;
        } else if (value is CouponData) {
          appliedCouponData = value;
        } else {
          appliedCouponData = null;
        }
        setPrice();
        fetchEarnPointsForCurrentSelection();
      }
    }
  }

  void selectDateAndTime(BuildContext context) async {
    if (packageExpiryDate != null && currentDateTime.isAfter(packageExpiryDate!)) {
      return toast(language.packageIsExpired);
    }

    await showDatePicker(
      context: context,
      initialDate: selectedDate ?? currentDateTime,
      firstDate: currentDateTime,
      lastDate: packageExpiryDate ?? currentDateTime.add(30.days),
      locale: Locale(appStore.selectedLanguageCode),
      cancelText: language.lblCancel,
      confirmText: language.lblOk,
      helpText: language.lblSelectDate,
      builder: (_, child) {
        return Theme(
          data: appStore.isDarkMode ? ThemeData.dark() : AppTheme.lightTheme(),
          child: child!,
        );
      },
    ).then((date) async {
      TimeOfDay initialTime = pickedTime ?? (selectedShop != null ? TimeOfDay.fromDateTime(currentDateTime.add(1.hours)) : TimeOfDay.now());
      if (date != null) {
        await showTimePicker(
          context: context,
          initialTime: initialTime,
          cancelText: language.lblCancel,
          confirmText: language.lblOk,
          builder: (_, child) {
            return Theme(
              data: appStore.isDarkMode ? ThemeData.dark() : AppTheme.lightTheme(),
              child: child!,
            );
          },
        ).then((time) {
          if (time != null) {
            finalDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);

            DateTime now = DateTime.now().subtract(1.minutes);
            if (date.isToday && finalDate!.millisecondsSinceEpoch < now.millisecondsSinceEpoch) {
              return toast(language.selectedOtherBookingTime);
            }

            selectedDate = date;
            pickedTime = time;
            widget.data.serviceDetail!.dateTimeVal = finalDate.toString();
            dateTimeCont.text = "${formatBookingDate(selectedDate.toString(), format: DATE_FORMAT_3)} ${pickedTime!.format(context).toString()}";
          }
          setState(() {});
        }).catchError((e) {
          toast(e.toString());
        });
      }
    });
  }

  void handleDateTimePick() {
    hideKeyboard(context);
    if (widget.data.serviceDetail!.isSlot == 1) {
      showModalBottomSheet(
        backgroundColor: Colors.transparent,
        context: context,
        isScrollControlled: true,
        isDismissible: true,
        shape: RoundedRectangleBorder(borderRadius: radiusOnly(topLeft: defaultRadius, topRight: defaultRadius)),
        builder: (_) {
          return DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.65,
            maxChildSize: 1,
            builder: (context, scrollController) => BookingSlotsComponent(
              data: widget.data,
              showAppbar: true,
              scrollController: scrollController,
              onApplyClick: () {
                setState(() {});
              },
            ),
          );
        },
      );
    } else {
      selectDateAndTime(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget(
        widget.selectedPackage == null ? language.bookTheService : language.bookPackage,
        textColor: Colors.white,
        color: context.primaryColor,
        backWidget: BackWidget(),
      ),
      body: Body(
        showLoader: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.selectedPackage == null) Text(language.service, style: boldTextStyle(size: LABEL_TEXT_SIZE)),
              if (widget.selectedPackage == null) 8.height,
              if (widget.selectedPackage == null) serviceWidget(context),

              packageWidget(),
              8.height,
              addressAndDescriptionWidget(context),
              16.height,

              Text("${language.hintDescription}", style: boldTextStyle(size: LABEL_TEXT_SIZE)),
              8.height,
              AppTextField(
                textFieldType: TextFieldType.MULTILINE,
                controller: descriptionCont,
                maxLines: 10,
                minLines: 3,
                isValidationRequired: false,
                enableChatGPT: appConfigurationStore.chatGPTStatus,
                promptFieldInputDecorationChatGPT: inputDecoration(context).copyWith(
                  hintText: language.writeHere,
                  fillColor: context.scaffoldBackgroundColor,
                  filled: true,
                  hintStyle: primaryTextStyle(),
                ),
                testWithoutKeyChatGPT: appConfigurationStore.testWithoutKey,
                loaderWidgetForChatGPT: const ChatGPTLoadingWidget(),
                onFieldSubmitted: (s) {
                  widget.data.serviceDetail!.bookingDescription = s;
                },
                onChanged: (s) {
                  widget.data.serviceDetail!.bookingDescription = s;
                },
                decoration: inputDecoration(context).copyWith(
                  fillColor: context.cardColor,
                  filled: true,
                  hintText: language.lblEnterDescription,
                  hintStyle: secondaryTextStyle(),
                ),
              ),

              /// Only active status package display
              if (serviceAddonStore.selectedServiceAddon.validate().isNotEmpty)
                AddonComponent(
                  isFromBookingLastStep: true,
                  serviceAddon: serviceAddonStore.selectedServiceAddon,
                  onSelectionChange: (v) {
                    serviceAddonStore.setSelectedServiceAddon(v);
                    setPrice();
                    fetchEarnPointsForCurrentSelection();
                  },
                ),
              16.height,
              buildBookingSummaryWidget(),
              redeemWigdet().paddingTop(16).visible(activeRedeemPoints != null &&
                  activeRedeemPoints!.maxDiscount.validate() != 0 &&
                  widget.data.userPoints.validate() != 0 &&
                  (widget.selectedPackage != null ? widget.selectedPackage!.price.validate() > 0 : !widget.data.serviceDetail!.isFreeService)),
              8.height,
              buildPartialRedeemRanges(activeRedeemPoints!).visible(activeRedeemPoints != null &&
                  activeRedeemPoints!.maxDiscount.validate() != 0 &&
                  widget.data.userPoints.validate() != 0 &&
                  (widget.selectedPackage != null ? widget.selectedPackage!.price.validate() > 0 : !widget.data.serviceDetail!.isFreeService)),
              16.height,

              priceWidget(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Observer(builder: (context) {
                    return const WalletBalanceComponent().visible(appConfigurationStore.isEnableUserWallet && widget.data.serviceDetail!.isFixedService);
                  }),
                  16.height,
                  Text(language.disclaimer, style: boldTextStyle(size: LABEL_TEXT_SIZE)),
                  Text(language.disclaimerContent, style: secondaryTextStyle()),
                ],
              ).paddingSymmetric(vertical: 16),
              earnPoints().visible(activeEarnPoints != 0).paddingBottom(36),
              Row(
                children: [
                  AppButton(
                    color: context.primaryColor,
                    text: widget.data.serviceDetail!.isAdvancePayment && !widget.data.serviceDetail!.isFreeService && widget.data.serviceDetail!.isFixedService
                        ? language.advancePayment
                        : language.confirm,
                    textColor: Colors.white,
                    onTap: () {
                      if (widget.data.serviceDetail!.isOnSiteService && addressCont.text.isEmpty && widget.data.serviceDetail!.dateTimeVal.validate().isEmpty) {
                        toast(language.pleaseEnterAddressAnd);
                      } else if (widget.data.serviceDetail!.isOnSiteService && addressCont.text.isEmpty) {
                        toast(language.pleaseEnterYourAddress);
                      } else if ((widget.data.serviceDetail!.isSlot != 1 && widget.data.serviceDetail!.dateTimeVal.validate().isEmpty) ||
                          (widget.data.serviceDetail!.isSlot == 1 && (widget.data.serviceDetail!.bookingSlot == null || widget.data.serviceDetail!.bookingSlot.validate().isEmpty))) {
                        toast(language.pleaseSelectBookingDate);
                      } else {
                        widget.data.serviceDetail!.address = addressCont.text;
                        showInDialog(
                          context,
                          barrierDismissible: false,
                          insetPadding: const EdgeInsets.symmetric(horizontal: 10),
                          builder: (p0) {
                            return ConfirmBookingDialog(
                              data: widget.data,
                              bookingPrice: bookingAmountModel.finalGrandTotalAmount,
                              selectedPackage: widget.selectedPackage,
                              qty: itemCount,
                              couponCode: appliedCouponData?.code,
                              shopModel: selectedShop,
                              bookingAmountModel: BookingAmountModel(
                                finalCouponDiscountAmount: bookingAmountModel.finalCouponDiscountAmount,
                                finalDiscountAmount: bookingAmountModel.finalDiscountAmount,
                                finalSubTotal: bookingAmountModel.finalSubTotal,
                                finalTotalServicePrice: bookingAmountModel.finalTotalServicePrice,
                                finalTotalTax: !widget.data.serviceDetail!.isFreeService ? bookingAmountModel.finalTotalTax : 0,
                              ),
                              isPointsApplied: isPointsApplied,
                              redeemedPoints: isPointsApplied ? activeRedeemPoints?.thresholdPoints ?? int.tryParse(pointsCont.text) : null,
                              redeemedDiscount: isPointsApplied ? pointsDiscountAmount : null,
                              earnPoints: activeEarnPoints,
                            );
                          },
                        );
                      }
                    },
                  ).expand(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget addressFieldWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        16.height,
        Text(language.lblYourAddress, style: boldTextStyle(size: LABEL_TEXT_SIZE)),
        8.height,
        AppTextField(
          textFieldType: TextFieldType.MULTILINE,
          controller: addressCont,
          maxLines: 3,
          minLines: 3,
          onFieldSubmitted: (s) {
            widget.data.serviceDetail!.address = s;
          },
          decoration: inputDecoration(
            context,
            prefixIcon: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ic_location.iconImage(size: 22).paddingOnly(top: 0),
              ],
            ),
          ).copyWith(
            fillColor: context.cardColor,
            filled: true,
            hintText: language.lblEnterYourAddress,
            hintStyle: secondaryTextStyle(),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              child: Text(language.lblChooseFromMap, style: boldTextStyle(color: primaryColor, size: 13)),
              onPressed: () {
                _handleSetLocationClick();
              },
            ).flexible(),
            TextButton(
              onPressed: _handleCurrentLocationClick,
              child: Text(language.lblUseCurrentLocation, style: boldTextStyle(color: primaryColor, size: 13), textAlign: TextAlign.right),
            ).flexible(),
          ],
        ),
      ],
    );
  }

  Widget addressAndDescriptionWidget(BuildContext context) {
    return Column(
      children: [
        if (widget.data.isAvailableAtShop && selectedShop != null)
          shopWidget()
        else if (widget.data.serviceDetail!.isOnSiteService)
          addressFieldWidget()
        else if (widget.selectedPackage != null && !widget.selectedPackage!.isAllServiceOnline)
          addressFieldWidget()
        else if ((widget.selectedPackage != null && widget.selectedPackage!.isAllServiceOnline) && widget.data.serviceDetail!.isOnlineService)
          Text(language.noteAddressIsNot, style: secondaryTextStyle()).paddingTop(16),
        16.height.visible(!widget.data.serviceDetail!.isOnSiteService && !widget.data.isAvailableAtShop),
      ],
    );
  }

  Widget serviceWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: boxDecorationDefault(color: context.cardColor),
      width: context.width(),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.data.serviceDetail!.name.validate(), style: boldTextStyle()),
              4.height,
              if ((convertToHourMinute(widget.data.serviceDetail!.duration.validate())).isNotEmpty)
                Text('${language.duration} (${convertToHourMinute(widget.data.serviceDetail!.duration.validate())})', style: secondaryTextStyle()),
              16.height,
              if (widget.data.serviceDetail!.isFixedService)
                Container(
                  height: 40,
                  padding: const EdgeInsets.all(8),
                  decoration: boxDecorationWithRoundedCorners(
                    backgroundColor: context.scaffoldBackgroundColor,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_drop_down_sharp, size: 24).onTap(
                        () {
                          if (itemCount != 1) {
                            itemCount--;
                            setPrice();
                            fetchEarnPointsForCurrentSelection();
                          }
                        },
                      ),
                      16.width,
                      Text(itemCount.toString(), style: primaryTextStyle()),
                      16.width,
                      const Icon(Icons.arrow_drop_up_sharp, size: 24).onTap(
                        () {
                          itemCount++;
                          setPrice();
                          fetchEarnPointsForCurrentSelection();
                        },
                      ),
                    ],
                  ),
                )
            ],
          ).expand(),
          CachedImageWidget(
            url: widget.data.serviceDetail!.attachments.validate().isNotEmpty ? widget.data.serviceDetail!.attachments!.first.validate() : '',
            height: 80,
            width: 80,
            fit: BoxFit.cover,
          ).cornerRadiusWithClipRRect(defaultRadius)
        ],
      ),
    );
  }

  Widget priceWidget() {
    if (!widget.data.serviceDetail!.isFreeService)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.selectedPackage == null) 8.height,
          if (widget.selectedPackage == null)
            Container(
              padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
              decoration: boxDecorationDefault(color: context.cardColor),
              child: Row(
                children: [
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ic_coupon_prefix.iconImage(color: Colors.green, size: 20),
                      Text(language.lblCoupon, style: primaryTextStyle()),
                    ],
                  ).expand(),
                  16.width,
                  TextButton(
                    onPressed: () {
                      if (appliedCouponData != null) {
                        showConfirmDialogCustom(
                          context,
                          dialogType: DialogType.DELETE,
                          title: language.doYouWantTo,
                          positiveText: language.lblDelete,
                          negativeText: language.lblCancel,
                          onAccept: (p0) {
                            appliedCouponData = null;
                            setPrice();
                            setState(() {});
                          },
                        );
                      } else {
                        applyCoupon();
                      }
                    },
                    child: Text(
                      appliedCouponData != null ? language.lblRemoveCoupon : language.applyCoupon,
                      style: primaryTextStyle(color: context.primaryColor),
                    ),
                  )
                ],
              ),
            ),
          24.height,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(language.priceDetail, style: boldTextStyle(size: LABEL_TEXT_SIZE)),
            ],
          ),
          16.height,
          Container(
            padding: const EdgeInsets.all(16),
            width: context.width(),
            decoration: boxDecorationDefault(color: context.cardColor),
            child: Column(
              children: [
                /// Service or Package Price
                Row(
                  children: [
                    Text(language.lblPrice, style: secondaryTextStyle(size: 14)).expand(),
                    16.width,
                    if (widget.selectedPackage != null)
                      PriceWidget(price: bookingAmountModel.finalTotalServicePrice, color: textPrimaryColorGlobal, isBoldText: true)
                    else if (!widget.data.serviceDetail!.isHourlyService)
                      Marquee(
                        child: Row(
                          children: [
                            PriceWidget(price: widget.data.serviceDetail!.price.validate(), size: 12, isBoldText: false, color: textSecondaryColorGlobal),
                            Text(' * $itemCount  = ', style: secondaryTextStyle()),
                            PriceWidget(price: bookingAmountModel.finalTotalServicePrice, color: textPrimaryColorGlobal),
                          ],
                        ),
                      )
                    else
                      PriceWidget(price: bookingAmountModel.finalTotalServicePrice, color: textPrimaryColorGlobal, isBoldText: true)
                  ],
                ),

                /// Fix Discount on Base Price
                if (widget.data.serviceDetail!.discount.validate() != 0 && widget.selectedPackage == null)
                  Column(
                    children: [
                      Divider(height: 26, color: context.dividerColor),
                      Row(
                        children: [
                          Text(language.lblDiscount, style: secondaryTextStyle(size: 14)),
                          Text(
                            " (${widget.data.serviceDetail!.discount.validate()}% ${language.lblOff.toLowerCase()})",
                            style: boldTextStyle(color: Colors.green),
                          ).expand(),
                          16.width,
                          PriceWidget(
                            price: bookingAmountModel.finalDiscountAmount,
                            color: Colors.green,
                            isBoldText: true,
                          ),
                        ],
                      ),
                    ],
                  ),

                /// Coupon Discount on Base Price
                if (widget.selectedPackage == null)
                  Column(
                    children: [
                      if (appliedCouponData != null) Divider(height: 26, color: context.dividerColor),
                      if (appliedCouponData != null)
                        Row(
                          children: [
                            Row(
                              children: [
                                Text(language.lblCoupon, style: secondaryTextStyle(size: 14)),
                                Text(
                                  " (${appliedCouponData!.code})",
                                  style: boldTextStyle(color: primaryColor, size: 14),
                                ).onTap(() {
                                  applyCoupon(isApplied: appliedCouponData!.code.validate().isNotEmpty);
                                }).expand(),
                              ],
                            ).expand(),
                            PriceWidget(
                              price: bookingAmountModel.finalCouponDiscountAmount,
                              color: Colors.green,
                              isBoldText: true,
                            ),
                          ],
                        ),
                    ],
                  ),

                /// Itemized Service Add-ons
                if (serviceAddonStore.selectedServiceAddon.validate().isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(height: 26, color: context.dividerColor),
                      ...serviceAddonStore.selectedServiceAddon
                          .map((a) => Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(a.name.validate(), style: secondaryTextStyle(size: 14)).flexible(fit: FlexFit.loose),
                                  16.width,
                                  PriceWidget(price: a.price.validate(), color: textPrimaryColorGlobal, isBoldText: false, size: 14),
                                ],
                              ))
                          .toList(),
                      8.height,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(language.serviceAddOns, style: boldTextStyle(size: 14)).flexible(fit: FlexFit.loose),
                          16.width,
                          PriceWidget(price: bookingAmountModel.finalServiceAddonAmount, color: textPrimaryColorGlobal),
                        ],
                      ),
                    ],
                  ),

                /// Points Discount
                if (isPointsApplied && pointsDiscountAmount > 0)
                  Column(
                    children: [
                      Divider(height: 26, color: context.dividerColor),
                      Row(
                        children: [
                          Row(
                            children: [
                              Text("Loyalty Points", style: secondaryTextStyle(size: 14)),
                              Text(
                                activeRedeemPoints!.redeemType!.contains("full") ? " (${activeRedeemPoints?.thresholdPoints.validate() ?? 0} pts)" : " (${pointsCont.text} pts)",
                                style: boldTextStyle(color: primaryColor, size: 14),
                              ).expand(),
                            ],
                          ).expand(),
                          PriceWidget(
                            price: pointsDiscountAmount,
                            color: Colors.green,
                            isBoldText: true,
                          ),
                        ],
                      ),
                    ],
                  ),

                /// Show Subtotal, Total Amount and Apply Discount, Coupon if service is Fixed or Hourly
                // if (widget.selectedPackage == null)
                Column(
                  children: [
                    Divider(height: 26, color: context.dividerColor),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(language.lblSubTotal, style: secondaryTextStyle(size: 14)).flexible(fit: FlexFit.loose),
                        16.width,
                        PriceWidget(price: bookingAmountModel.finalSubTotal, color: textPrimaryColorGlobal),
                      ],
                    ),
                  ],
                ),

                /// Tax Amount Applied on Price
                Column(
                  children: [
                    Divider(height: 26, color: context.dividerColor),
                    Row(
                      children: [
                        Row(
                          children: [
                            Text(language.lblTax, style: secondaryTextStyle(size: 14)).expand(),
                            if (widget.data.taxes.validate().isNotEmpty)
                              Icon(Icons.info_outline_rounded, size: 20, color: context.primaryColor).onTap(
                                () {
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (_) {
                                      return AppliedTaxListBottomSheet(taxes: widget.data.taxes.validate(), subTotal: bookingAmountModel.finalSubTotal);
                                    },
                                  );
                                },
                              ),
                          ],
                        ).expand(),
                        16.width,
                        PriceWidget(price: bookingAmountModel.finalTotalTax, color: Colors.red, isBoldText: true),
                      ],
                    ),
                  ],
                ),

                /// Final Amount
                Column(
                  children: [
                    Divider(height: 26, color: context.dividerColor),
                    Row(
                      children: [
                        Text(language.totalAmount, style: secondaryTextStyle(size: 14)).expand(),
                        PriceWidget(
                          price: bookingAmountModel.finalGrandTotalAmount,
                          color: primaryColor,
                        )
                      ],
                    ),
                  ],
                ),

                /// Advance Payable Amount if it is required by Service Provider
                if (widget.data.serviceDetail!.isAdvancePayment && widget.data.serviceDetail!.isFixedService && !widget.data.serviceDetail!.isFreeService)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(height: 26, color: context.dividerColor),
                      Row(
                        children: [
                          Row(
                            children: [
                              Text(language.advancePayAmount, style: secondaryTextStyle(size: 14)),
                              Text(" (${widget.data.serviceDetail!.advancePaymentPercentage.validate().toString()}%)  ", style: boldTextStyle(color: Colors.green)),
                            ],
                          ).expand(),
                          PriceWidget(price: advancePaymentAmount, color: primaryColor),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          )
        ],
      );

    return const Offstage();
  }

  Widget buildDateWidget() {
    if (widget.data.serviceDetail!.isSlotAvailable) {
      return Text(widget.data.serviceDetail!.dateTimeVal.validate(), style: boldTextStyle(size: 12));
    }
    return Text(formatBookingDate(widget.data.serviceDetail!.dateTimeVal.validate(), format: DATE_FORMAT_3), style: boldTextStyle(size: 12));
  }

  Widget buildTimeWidget() {
    if (widget.data.serviceDetail!.bookingSlot == null) {
      return Text(
          formatBookingDate(
            widget.data.serviceDetail!.dateTimeVal.validate(),
            format: HOUR_12_FORMAT,
            isTime: true,
          ),
          style: boldTextStyle(size: 12));
    }
    return Text(
      TimeOfDay(
        hour: widget.data.serviceDetail!.bookingSlot.validate().splitBefore(':').split(":").first.toInt(),
        minute: widget.data.serviceDetail!.bookingSlot.validate().splitBefore(':').split(":").last.toInt(),
      ).format(context),
      style: boldTextStyle(size: 12),
    );
  }

  Widget buildBookingSummaryWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        8.height,
        widget.data.serviceDetail!.dateTimeVal == null
            ? GestureDetector(
                onTap: () async {
                  handleDateTimePick();
                },
                child: DottedBorderWidget(
                  color: context.primaryColor,
                  radius: defaultRadius,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    alignment: Alignment.center,
                    decoration: boxDecorationWithShadow(blurRadius: 0, backgroundColor: context.cardColor, borderRadius: radius()),
                    child: Column(
                      children: [
                        ic_calendar.iconImage(size: 26),
                        8.height,
                        Text(
                          language.chooseDateTime,
                          style: secondaryTextStyle(),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : Container(
                padding: const EdgeInsets.all(16),
                decoration: boxDecorationDefault(color: context.cardColor),
                width: context.width(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text("${language.lblDate}: ", style: secondaryTextStyle()),
                            buildDateWidget(),
                          ],
                        ),
                        8.height,
                        Row(
                          children: [
                            Text("${language.lblTime}: ", style: secondaryTextStyle()),
                            buildTimeWidget(),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: ic_edit_square.iconImage(size: 18),
                      visualDensity: VisualDensity.compact,
                      onPressed: () async {
                        handleDateTimePick();
                      },
                    )
                  ],
                ),
              ),
      ],
    );
  }

  Widget packageWidget() {
    if (widget.selectedPackage != null)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(language.package, style: boldTextStyle(size: LABEL_TEXT_SIZE)),
          16.height,
          Container(
            padding: const EdgeInsets.all(16),
            decoration: boxDecorationDefault(color: context.cardColor),
            width: context.width(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Marquee(child: Text(widget.selectedPackage!.name.validate(), style: boldTextStyle())),
                        4.height,
                        Text("${language.services}: ${widget.selectedPackage!.serviceList.validate().map((e) => e.name).join(", ")}", style: secondaryTextStyle()),
                      ],
                    ).expand(),
                    16.width,
                    CachedImageWidget(
                      url: widget.selectedPackage!.imageAttachments.validate().isNotEmpty ? widget.selectedPackage!.imageAttachments!.first.validate() : '',
                      height: 60,
                      width: 60,
                      fit: BoxFit.cover,
                    ).cornerRadiusWithClipRRect(defaultRadius),
                  ],
                ),
              ],
            ),
          ),
        ],
      );

    return const Offstage();
  }

  Widget _buildFallbackImage() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Image.asset(
        Assets.iconsIcDefaultShop,
        height: 14,
        width: 14,
        color: primaryColor,
      ),
    );
  }

  Widget shopWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between items
          children: [
            Text(language.lblShopDetails, style: boldTextStyle(size: LABEL_TEXT_SIZE)),
            Spacer(),
            TextButton(
              onPressed: () async {
                await showModalBottomSheet(
                  context: context,
                  backgroundColor: context.scaffoldBackgroundColor,
                  barrierColor: appStore.isDarkMode ? Colors.white10 : Colors.black26,
                  showDragHandle: true,
                  constraints: BoxConstraints(maxHeight: context.height() * 0.9),
                  enableDrag: true,
                  isScrollControlled: true,
                  shape: RoundedRectangleBorder(
                    borderRadius: radiusOnly(topRight: 16, topLeft: 16),
                  ),
                  builder: (context) {
                    return ShopListScreen(
                      serviceId: widget.serviceId.validate(),
                      selectedShop: selectedShop,
                      isForBooking: true,
                      isShopChange: false,
                    );
                  },
                ).then(
                  (value) {
                    if (value != null) {
                      selectedShop = value;
                      setState(() {});
                    }
                  },
                );
              },
              child: Text("Change", style: boldTextStyle(size: 14, color: primaryColor)),
            ),
          ],
        ),
        Container(
          padding: EdgeInsets.all(16),
          decoration: boxDecorationDefault(
            color: context.cardColor,
            border: appStore.isDarkMode ? Border.all(color: context.dividerColor) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: selectedShop!.shopFirstImage.isNotEmpty
                          ? CachedImageWidget(
                              url: selectedShop!.shopFirstImage,
                              fit: BoxFit.cover,
                              width: 60,
                              height: 60,
                              usePlaceholderIfUrlEmpty: true,
                            )
                          : _buildFallbackImage(),
                    ),
                  ),
                  16.width,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(selectedShop!.name, style: boldTextStyle()),
                      4.height,
                      TextIcon(
                        spacing: 10,
                        prefix: Image.asset(ic_clock, width: 12, height: 12, color: context.iconColor),
                        text: selectedShop!.shopStartTime.validate().isNotEmpty && selectedShop!.shopEndTime.isNotEmpty ? '${selectedShop!.shopStartTime} - ${selectedShop!.shopEndTime}' : '---',
                        textStyle: secondaryTextStyle(size: 12),
                        expandedText: true,
                        edgeInsets: EdgeInsets.zero,
                      ),
                    ],
                  ).expand(),
                ],
              ),
              8.height,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((selectedShop!.email.validate().isNotEmpty) || (selectedShop!.contactNumber.validate().isNotEmpty)) ...[
                    if (selectedShop!.email.validate().isNotEmpty) ...[
                      4.height,
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${language.email}:',
                            style: boldTextStyle(size: 12, color: appStore.isDarkMode ? textSecondaryColor : textPrimaryColor),
                          ).expand(),
                          8.width,
                          Expanded(
                            flex: 4,
                            child: GestureDetector(
                              onTap: () {
                                launchMail("${selectedShop!.email.validate()}");
                              },
                              child: Text(
                                selectedShop!.email.validate(),
                                style: boldTextStyle(size: 12, color: appStore.isDarkMode ? white : textSecondaryColor, weight: FontWeight.w400),
                              ),
                            ),
                          ),
                        ],
                      ),
                      4.height,
                    ],
                    if (selectedShop!.contactNumber.validate().isNotEmpty) ...[
                      4.height,
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            language.mobile,
                            style: boldTextStyle(size: 12, color: appStore.isDarkMode ? textSecondaryColor : textPrimaryColor),
                          ).expand(),
                          8.width,
                          Expanded(
                            flex: 4,
                            child: GestureDetector(
                              onTap: () {
                                launchCall("${selectedShop!.contactNumber.validate()}");
                              },
                              child: Text(
                                selectedShop!.contactNumber.validate(),
                                style: boldTextStyle(size: 12, color: appStore.isDarkMode ? white : textSecondaryColor, weight: FontWeight.w400),
                              ),
                            ),
                          ),
                        ],
                      ),
                      4.height,
                    ]
                  ],
                  if (selectedShop!.latitude != 0 && selectedShop!.longitude != 0) ...[
                    4.height,
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${language.hintAddress}:',
                          style: boldTextStyle(size: 12, color: appStore.isDarkMode ? textSecondaryColor : textPrimaryColor),
                        ).expand(),
                        8.width,
                        Expanded(
                          flex: 4,
                          child: GestureDetector(
                            onTap: () {
                              if (selectedShop!.latitude != 0 && selectedShop!.longitude != 0) {
                                launchMapFromLatLng(latitude: selectedShop!.latitude, longitude: selectedShop!.longitude);
                              } else {
                                launchMap(selectedShop!.address);
                              }
                            },
                            child: Text(
                              "${selectedShop!.address}, ${selectedShop!.cityName}, ${selectedShop!.stateName}, ${selectedShop!.countryName}",
                              style: boldTextStyle(size: 12, color: appStore.isDarkMode ? white : textSecondaryColor, weight: FontWeight.w400),
                              softWrap: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    4.height,
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget redeemWigdet() {
    final redeemPointsData = activeRedeemPoints!;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(language.lblRedeemPoints, style: boldTextStyle(size: LABEL_TEXT_SIZE)),
            Container(
              padding: EdgeInsets.all(5),
              decoration: boxDecorationWithRoundedCorners(border: Border.all(color: primaryColor), borderRadius: BorderRadius.circular(16)),
              child: Center(
                child: Text(
                  "${widget.data.userPoints.validate()} pts available",
                  style: primaryTextStyle(color: primaryColor),
                ),
              ),
            )
          ],
        ),
        8.height,
        DottedBorderWidget(
          color: context.primaryColor,
          radius: defaultRadius,
          child: Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            decoration: boxDecorationWithShadow(blurRadius: 0, backgroundColor: context.cardColor, borderRadius: radius()),
            child: Row(
              spacing: 8,
              children: [
                ic_redeem.iconImage(size: 26, color: primaryColor),
                if (activeRedeemPoints!.redeemType.validate().contains("full")) pointsInputWidget(redeemPoints: redeemPointsData).expand(),
                if (activeRedeemPoints!.redeemType.validate().contains("partial")) pointsForPartialInputWidget(controller: pointsCont, redeemPoints: redeemPointsData).expand(),
                AppButton(
                    text: isPointsApplied ? language.remove : language.lblApply,
                    textStyle: primaryTextStyle(color: white),
                    color: isPointsApplied ? Colors.red : primaryColor,
                    shapeBorder: RoundedRectangleBorder(borderRadius: radius(8)),
                    onTap: () {
                      if (isPointsApplied) {
                        isPointsApplied = false;
                        pointsDiscountAmount = 0;
                        lastAppliedPoints = null;
                        setPrice();
                        fetchEarnPointsForCurrentSelection();
                        toast("Applied Points removed");
                        return;
                      }

                      final redeemPointsData = activeRedeemPoints!;
                      final int userPointsAvailable = widget.data.userPoints.validate().toInt();
                      final String enteredRaw = pointsCont.text.trim();
                      final int? entered = enteredRaw.isNotEmpty ? int.tryParse(enteredRaw) : null;


                      if (redeemPointsData.redeemType.validate().contains('partial')) {
                        if (enteredRaw.isEmpty || entered == null) {
                          toast("Please enter points to apply");
                          return;
                        }
                      }

                      if (entered != null && entered <= 0) {
                        toast("Please enter a valid points value greater than 0");
                        return;
                      }
                      if (redeemPointsData.redeemType.validate().contains('partial')) {
                        final ranges = (redeemPointsData.ranges ?? []);
                        if (entered == null && ranges.isNotEmpty) {
                          final minAllowed = (ranges..sort((a, b) => (a.pointFrom ?? 0).compareTo(b.pointFrom ?? 0))).first.pointFrom ?? 0;
                          if (userPointsAvailable < minAllowed) {
                            toast("Insufficient points. Minimum required $minAllowed pts");
                            return;
                          }
                        }

                        final result = computePartialRedeem(
                          redeemPoints: redeemPointsData,
                          userPoints: userPointsAvailable,
                          enteredPoints: entered,
                        );

                        if (result['success'] == true) {
                          int appliedPts = (result['appliedPoints'] as int);
                          final discount = (result['discountAmount'] as num).toDouble();

                          if (appliedPts > userPointsAvailable) {
                            toast("Insufficient points. You only have $userPointsAvailable pts");
                            return;
                          }

                          if (appliedPts <= 0 || discount <= 0) {
                            toast("Cannot apply 0 points or zero discount. Please enter a valid points amount.");
                            return;
                          }

                          isPointsApplied = true;
                          lastAppliedPoints = appliedPts;
                          pointsCont.text = appliedPts.toString();
                          pointsDiscountAmount = discount;

                          setPrice();
                          fetchEarnPointsForCurrentSelection();
                          toast("Applied $appliedPts pts for \$${discount.toStringAsFixed(2)} off");
                        } else {
                          toast(result['message'].toString());
                        }
                      } else {
                        final int threshold = redeemPointsData.thresholdPoints.validate().toInt();
                        if (redeemPointsData.thresholdPoints.validate() != 0) {
                          if (userPointsAvailable >= threshold) {
                            final double discount = redeemPointsData.maxDiscount!.toDouble();
                            final num payableAmount = bookingAmountModel.finalTotalServicePrice;
                            if (discount >= payableAmount) {
                              toast("You cannot apply more points than the service amount.");
                              return;
                            }
                            isPointsApplied = true;
                            pointsDiscountAmount = discount;
                            setPrice();
                            fetchEarnPointsForCurrentSelection();
                            toast("Points applied");
                          } else {
                            toast("Insufficient points. You need $threshold points");
                          }
                        }
                      }
                    }).paddingAll(4)
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget pointsInputWidget({required RedeemPoints redeemPoints}) {
    return GestureDetector(
        onTap: () {},
        child: Container(
          decoration: boxDecorationWithRoundedCorners(
            backgroundColor: maxPointColor,
          ),
          height: context.height() * 0.052,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${redeemPoints.thresholdPoints.validate()} pts = ',
                style: secondaryTextStyle(),
              ),
              Text(
                "\$${redeemPoints.maxDiscount.validate().toDouble()} off",
                style: secondaryTextStyle(),
              )
            ],
          ),
        ));
  }

  Widget pointsForPartialInputWidget({
    required TextEditingController controller,
    required RedeemPoints redeemPoints,
  }) {
    return Row(
      children: [
        ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: context.height() * 0.042,
              color: white,
              child: AppTextField(
                textFieldType: TextFieldType.NAME,
                controller: controller,
                textStyle: primaryTextStyle(),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                enabled: true,
                readOnly: false,
                decoration: InputDecoration(
                  hintText: 'Enter Points',
                  hintStyle: secondaryTextStyle(),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  filled: true,
                  fillColor: appStore.isDarkMode ? context.scaffoldBackgroundColor : white,
                ),
                onChanged: (val) {
                  if (isPointsApplied && lastAppliedPoints != null) {
                    final currentText = val.trim();
                    final appliedText = lastAppliedPoints.toString();
                    if (currentText != appliedText) {
                      isPointsApplied = false;
                      pointsDiscountAmount = 0;
                      lastAppliedPoints = null;
                      setPrice();
                    }
                  }
                  final parsed = int.tryParse(val.trim());
                  if (parsed != enteredPoints) {
                    setState(() => enteredPoints = parsed);
                  }
                },
              ),
            )).expand(),
      ],
    );
  }

  Widget earnPoints() {
    if (activeEarnPoints == null || activeEarnPoints == 0) {
      return const Offstage();
    }

    final earnPointsValue = activeEarnPoints!;

    return DottedBorderWidget(
      color: Colors.green,
      radius: defaultRadius,
      child: Container(
        padding: const EdgeInsets.all(14),
        alignment: Alignment.center,
        decoration: boxDecorationWithShadow(blurRadius: 0, backgroundColor: context.cardColor, borderRadius: radius()),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              ic_coins,
              width: 34,
              height: 44,
            ),
            10.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: secondaryTextStyle(size: 12, color: white),
                      children: [
                        TextSpan(text: language.completeThisBookingToEarn, style: primaryTextStyle()),
                        TextSpan(
                          text: '$earnPointsValue loyalty points',
                          style: boldTextStyle(color: context.primaryColor),
                        ),
                      ],
                    ),
                  ),
                  4.height,
                  Text(
                    language.redeemPointsOnNextBooking,
                    style: secondaryTextStyle(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPartialRedeemRanges(RedeemPoints redeemPoints) {
    if (redeemPoints.ranges == null || redeemPoints.ranges!.isEmpty) {
      return SizedBox();
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: redeemPoints.ranges!.map((range) {
        final from = range.pointFrom ?? 0;
        final to = range.pointTo ?? 0;
        final matches = enteredPoints != null && enteredPoints! >= from && enteredPoints! <= to;

        final boxDecoration = BoxDecoration(
          color: matches ? maxPointColor : context.cardColor,
          borderRadius: BorderRadius.circular(8),
        );

        final amountText = range.amount != null ? "\$${(range.amount!.toDouble()).toStringAsFixed(2)}" : "";

        return Container(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 14),
          decoration: boxDecoration,
          child: Text(
            "${from} To ${to} pts = ${amountText} off",
            style: secondaryTextStyle(),
          ),
        );
      }).toList(),
    );
  }

  Map<String, dynamic> computePartialRedeem({
    required RedeemPoints redeemPoints,
    required int userPoints,
    int? enteredPoints,
  }) {
    final ranges = (redeemPoints.ranges ?? []).toList();

    if (ranges.isEmpty) {
      return {'success': false, 'message': 'No ranges defined'};
    }

    // Sort ranges by point_from
    ranges.sort((a, b) => (a.pointFrom ?? 0).compareTo(b.pointFrom ?? 0));

    if (enteredPoints != null) {
      final minAllowed = ranges.first.pointFrom ?? 0;
      if (enteredPoints < minAllowed) {
        return {
          'success': false,
          'message': 'Minimum redeemable points is $minAllowed. Please enter $minAllowed or more.',
        };
      }
      final lastRange = ranges.last;
      final maxAllowed = lastRange.pointTo ?? lastRange.pointFrom ?? 0;

      if (enteredPoints > maxAllowed) {
        return {
          'success': true,
          'appliedPoints': maxAllowed,
          'discountAmount': lastRange.amount ?? 0,
          'message': 'Entered points exceed maximum. Applied max range.',
        };
      }
      for (var range in ranges) {
        final from = range.pointFrom ?? 0;
        final to = range.pointTo ?? from;

        if (enteredPoints >= from && enteredPoints <= to) {
          return {
            'success': true,
            'appliedPoints': enteredPoints,
            'discountAmount': range.amount ?? 0,
            'message': 'Applied $enteredPoints pts for range $from - $to',
          };
        }
      }
      return {'success': false, 'message': 'Entered points do not fall in any valid range.'};
    }
    final affordableRanges = ranges.where((r) => userPoints >= (r.pointFrom ?? 0)).toList();

    if (affordableRanges.isEmpty) {
      final minRequired = ranges.first.pointFrom ?? 0;
      return {
        'success': false,
        'message': 'Insufficient points. Minimum required: $minRequired',
      };
    }

    final bestRange = affordableRanges.last;
    final applyPoints = bestRange.pointFrom ?? 0;

    return {
      'success': true,
      'appliedPoints': applyPoints,
      'discountAmount': bestRange.amount ?? 0,
      'message': 'Auto-applied best range starting at $applyPoints pts',
    };
  }
}
