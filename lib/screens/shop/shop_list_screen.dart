import 'dart:async';
import 'package:booking_system_flutter/component/base_scaffold_widget.dart';
import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/component/empty_error_state_widget.dart';
import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/shop_model.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/filter/filter_screen.dart';
import 'package:booking_system_flutter/screens/shop/component/shop_component.dart';
import 'package:booking_system_flutter/screens/shop/shimmer/shop_shimmer.dart';
import 'package:booking_system_flutter/screens/shop/shop_detail_screen.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

class ShopListScreen extends StatefulWidget {
  final ShopModel? selectedShop;
  final int providerId;
  final int serviceId;
  final String providerName;
  final String serviceName;
  final bool isForBooking;
  final bool? isShopChange;

  const ShopListScreen({
    Key? key,
    this.selectedShop,
    this.providerId = 0,
    this.serviceName = '',
    this.providerName = '',
    this.serviceId = 0,
    this.isForBooking = false,
    this.isShopChange = true,
  }) : super(key: key);

  @override
  State<ShopListScreen> createState() => _ShopListScreenState();
}

class _ShopListScreenState extends State<ShopListScreen> {
  FocusNode searchFocusNode = FocusNode();
  TextEditingController searchCont = TextEditingController();

  List<ShopModel> shops = [];
  ShopModel selectedShop = ShopModel();
  Future<List<ShopModel>>? future;

  int page = 1;

  bool isLastPage = false;

  bool isForSelection = false;

  @override
  void initState() {
    super.initState();

    init(showLoader: false);
  }

  Future<void> init({bool showLoader = true}) async {
    setState(() {
      isForSelection = widget.selectedShop != null || widget.isForBooking;
      if (widget.selectedShop != null) {
        selectedShop = widget.selectedShop!;
      }
    });
    await getShops(showLoader: showLoader);
  }

  Future<void> getShops({bool showLoader = true}) async {
    appStore.setLoading(showLoader);
    future = getShopList(
      page,
      search: searchCont.text.validate(),
      perPage: 10,
      shopList: shops,
      providerIds: widget.providerId > 0 ? widget.providerId.toString() : filterStore.providerId.join(","),
      serviceIds: widget.serviceId > 0 ? widget.serviceId.toString() : filterStore.serviceId.join(","),
      lastPageCallBack: (b) {
        isLastPage = b;
      },
    ).whenComplete(
      () => appStore.setLoading(false),
    );
    setState(() {});
  }

  Future<void> setPageToOne() async {
    setState(() {
      page = 1;
    });
    await getShops();
  }

  Future<void> onNextPage() async {
    if (!isLastPage) {
      setState(() {
        page++;
      });
      await getShops();
    }
  }

  String get setSearchString {
    return "What you are looking for?";
  }

  @override
  void dispose() {
    searchCont.dispose();
    super.dispose();
  }

  Widget buildBodyWidget() {
    return Stack(
      children: [
        Column(
          children: [
            Row(
              children: [
                AppTextField(
                  textFieldType: TextFieldType.OTHER,
                  focus: searchFocusNode,
                  controller: searchCont,
                  suffix: CloseButton(
                    onPressed: () {
                      searchCont.clear();
                      setPageToOne();
                    },
                  ).visible(searchCont.text.isNotEmpty),
                  onFieldSubmitted: (s) {
                    setPageToOne();
                  },
                  decoration: inputDecoration(context).copyWith(
                    hintText: "Search Here...",

                    ///todo:
                    prefixIcon: ic_search.iconImage(size: 10).paddingAll(14),
                    hintStyle: secondaryTextStyle(),
                  ),
                ).expand(),
                16.width,
                if (widget.isShopChange == true)
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: boxDecorationDefault(color: context.primaryColor),
                    child: CachedImageWidget(
                      url: ic_filter,
                      height: 26,
                      width: 26,
                      color: Colors.white,
                    ),
                  ).onTap(() {
                    hideKeyboard(context);

                    FilterScreen(
                      isFromShop: true,
                      isFromProvider: true,
                    ).launch(context).then((value) {
                      if (value != null) {
                        setPageToOne();
                      }
                    });
                  }, borderRadius: radius())
              ],
            ).paddingAll(16),
            SnapHelperWidget<List<ShopModel>>(
              future: future,
              errorBuilder: (error) {
                return Center(
                  child: NoDataWidget(
                    title: error,
                    imageWidget: ErrorStateWidget(),
                    retryText: language.reload,
                    onRetry: () {
                      setPageToOne();
                    },
                  ),
                );
              },
              loadingWidget: ShopShimmer(),
              onSuccess: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: NoDataWidget(
                      title: language.lblNoShopsFound,
                      imageWidget: EmptyStateWidget(),
                    ).paddingOnly(bottom: 100),
                  );
                }

                return AnimatedListView(
                  listAnimationType: ListAnimationType.FadeIn,
                  fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
                  padding: EdgeInsets.only(left: 16, right: 16, bottom: 120),
                  physics: AlwaysScrollableScrollPhysics(),
                  itemCount: 1,
                  onSwipeRefresh: () async {
                    setPageToOne();
                    return await 2.seconds.delay;
                  },
                  onNextPage: onNextPage,
                  itemBuilder: (context, index) {
                    if (shops.isNotEmpty)
                      return AnimatedWrap(
                        spacing: 16.0,
                        runSpacing: 16.0,
                        scaleConfiguration: ScaleConfiguration(duration: 400.milliseconds, delay: 50.milliseconds),
                        listAnimationType: ListAnimationType.FadeIn,
                        fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
                        alignment: WrapAlignment.start,
                        itemCount: shops.length,
                        itemBuilder: (context, index) {
                          final shop = shops[index];

                          return ShopComponent(
                            shop: shop,
                            imageSize: 56,
                            isSelected: selectedShop.id == shop.id,
                            showServices: !isForSelection,
                            onTap: () {
                              if (isForSelection) {
                                setState(() {
                                  selectedShop = shop;
                                });
                              } else {
                                ShopDetailScreen(shopId: shop.id).launch(context);
                              }
                            },
                          );
                        },
                      );
                    return Offstage();
                  },
                );
              },
            ).expand(),
          ],
        ),
        if (isForSelection)
          Positioned(
            bottom: widget.isForBooking ? 0 : 16,
            left: 16,
            right: 16,
            child: AppButton(
              margin: EdgeInsets.only(bottom: 12),
              width: context.width() - context.navigationBarHeight,
              text: language.lblSelectShop,
              color: context.primaryColor,
              textColor: Colors.white,
              onTap: () {
                if (selectedShop.id > 0) finish(context, selectedShop);
              },
            ),
          ),
        Observer(builder: (context) => LoaderWidget().visible(appStore.isLoading))
      ],
    );
  }

  String getScreenTitle() {
    if (widget.selectedShop != null) return language.lblSelectShop;
    if (widget.providerName.isNotEmpty) return language.lblProvidersShops(widget.providerName);
    if (widget.serviceName.isNotEmpty) return language.lblShopsOffer(widget.serviceName);
    return language.lblAllShop;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isForBooking) return buildBodyWidget();
    return AppScaffold(
      appBarTitle: getScreenTitle(),
      child: buildBodyWidget(),
    );
  }
}
