import 'package:booking_system_flutter/component/base_scaffold_widget.dart';
import 'package:booking_system_flutter/component/view_all_label_component.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/model/user_data_model.dart';
import 'package:booking_system_flutter/screens/service/view_all_service_screen.dart';
import 'package:booking_system_flutter/screens/shop/component/shop_image_slider.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/model/shop_model.dart';
import 'shimmer/shop_detail_shimmer.dart';
import 'package:booking_system_flutter/component/empty_error_state_widget.dart';
import 'package:booking_system_flutter/screens/service/component/service_component.dart';
import 'package:booking_system_flutter/screens/booking/component/booking_detail_provider_widget.dart';
import 'package:booking_system_flutter/screens/booking/provider_info_screen.dart';

class ShopDetailScreen extends StatefulWidget {
  final int shopId;

  const ShopDetailScreen({
    Key? key,
    required this.shopId,
  }) : super(key: key);

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  Future<ShopDetailResponse>? future;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    future = getShopDetail(widget.shopId);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: language.lblShopDetails,
      child: SnapHelperWidget<ShopDetailResponse>(
        future: future,
        loadingWidget: ShopDetailsShimmer(),
        errorBuilder: (error) {
          return NoDataWidget(
            title: error,
            imageWidget: ErrorStateWidget(),
            retryText: language.reload,
            onRetry: () {
              init();
            },
          ).center();
        },
        onSuccess: (shopResponse) {
          final ShopModel? shop = shopResponse.shopDetail;
          if (shop == null) {
            return NoDataWidget(
              title: language.noDataAvailable,
              imageWidget: EmptyStateWidget(),
              retryText: language.reload,
              onRetry: () {
                init();
              },
            ).center();
          }

          return AnimatedScrollView(
            padding: EdgeInsets.only(bottom: 60, left: 16, top: 16, right: 16),
            onSwipeRefresh: () async {
              return await init();
            },
            children: [
              /// Shop Image Slider
              Container(
                height: 180,
                width: context.width(),
                decoration: boxDecorationWithRoundedCorners(
                  borderRadius: radius(16),
                  backgroundColor: context.cardColor,
                ),
                child: ShopImageSlider(imageList: shop.shopImage),
              ),

              /// Shop Contact Details
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  8.height,
                  Text(shop.name, style: boldTextStyle(size: 18)),
                  8.height,
                  if ((shop.email.validate().isNotEmpty) || (shop.contactNumber.validate().isNotEmpty)) ...[
                    if (shop.email.validate().isNotEmpty) ...[
                      TextIcon(
                        spacing: 10,
                        onTap: () {
                          launchMail("${shop.email.validate()}");
                        },
                        prefix: Image.asset(ic_message, width: 16, height: 16, color: appStore.isDarkMode ? Colors.white : context.primaryColor),
                        text: shop.email.validate(),
                        textStyle: secondaryTextStyle(size: 14),
                        expandedText: true,
                      ),
                      6.height,
                    ],
                    if (shop.contactNumber.validate().isNotEmpty) ...[
                      TextIcon(
                        spacing: 10,
                        onTap: () {
                          launchCall("${shop.contactNumber.validate()}");
                        },
                        prefix: Image.asset(ic_calling, width: 16, height: 16, color: appStore.isDarkMode ? Colors.white : context.primaryColor),
                        text: shop.contactNumber.validate(),
                        textStyle: secondaryTextStyle(size: 14),
                        expandedText: true,
                      ),
                      6.height,
                    ]
                  ],
                  if (shop.latitude != 0 && shop.longitude != 0) ...[
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            ic_location,
                            width: 18,
                            height: 18,
                            color: appStore.isDarkMode ? Colors.white : context.primaryColor,
                          ),
                          10.width,
                          Marquee(
                            child: Text("${shop.address}, ${shop.cityName}, ${shop.stateName}, ${shop.countryName}", style: secondaryTextStyle(size: 14)),
                          ).flexible(),
                        ],
                      ),
                    ),
                    6.height,
                  ],
                  if (shop.shopStartTime.isNotEmpty &&  shop.shopEndTime.isNotEmpty) ...[
                    TextIcon(
                      spacing: 10,
                      onTap: () {
                        if (shop.latitude != 0 && shop.longitude != 0) {
                          launchMapFromLatLng(latitude: shop.latitude, longitude: shop.longitude);
                        } else {
                          launchMap(shop.address);
                        }
                      },
                      prefix: Image.asset(ic_clock, width: 16, height: 16, color: appStore.isDarkMode ? Colors.white : context.primaryColor),
                      text: "${shop.shopStartTime} - ${shop.shopEndTime}",
                      textStyle: secondaryTextStyle(size: 14),
                      expandedText: true,
                    ),
                    6.height,
                  ]
                ],
              ),
              16.height,
              providerWidget(
                data: UserData(
                  displayName: shopResponse.shopDetail!.providerName,
                  profileImage: shopResponse.shopDetail!.providerImage,
                  id: shopResponse.shopDetail!.providerId,
                  providersServiceRating: shopResponse.shopDetail!.providerServiceRating,
                ),
              ),

              /// Services List
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  16.height,
                  ViewAllLabel(
                    label: language.services,
                    onTap: () {
                      ViewAllServiceScreen(shopId: shop.id).launch(context);
                    },
                    list: shop.services.validate(),
                    labelSize: LABEL_TEXT_SIZE,
                  ),
                  if (shop.services.validate().isNotEmpty)
                    AnimatedWrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: shop.services.validate().take(4).map((e) {
                        return ServiceComponent(
                          serviceData: ServiceData(
                            id: e.id,
                            name: e.name,
                            price: e.price,
                            discount: 0,
                            providerName: shop.providerName,
                            providerId: shop.providerId,
                            providerImage: shop.providerImage,
                            attachments: e.attachments,
                            categoryName: e.categoryName,
                            totalRating: e.totalRating,
                            visitType: VISIT_OPTION_ON_SHOP,
                          ),
                          width: context.width() / 2 - 24,
                        );
                      }).toList(),
                    )
                  else
                    NoDataWidget(
                      title: language.lblNoServicesFound,
                      imageWidget: EmptyStateWidget(),
                    ),
                ],
              )
            ],
          );
        },
      ),
    );
  }

  Widget providerWidget({required UserData data}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(language.lblAboutProvider, style: boldTextStyle(size: LABEL_TEXT_SIZE)),
            TextButton(
              onPressed: () {
                ProviderInfoScreen(providerId: data.id).launch(context);
              },
              child: Text(language.viewDetail, style: secondaryTextStyle()),
            )
          ],
        ),
        BookingDetailProviderWidget(providerData: data).onTap(() async {
          await ProviderInfoScreen(providerId: data.id).launch(context);
          setStatusBarColor(Colors.transparent);
        }),
      ],
    );
  }
}
