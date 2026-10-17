import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/component/empty_error_state_widget.dart';
import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/component/selected_item_widget.dart';
import 'package:booking_system_flutter/generated/assets.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/shop_model.dart';

import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/shop/shimmer/shop_shimmer.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

class FilterShopListComponent extends StatefulWidget {
  const FilterShopListComponent({Key? key}) : super(key: key);

  @override
  State<FilterShopListComponent> createState() => _FilterShopListComponentState();
}

class _FilterShopListComponentState extends State<FilterShopListComponent> {
  Future<List<ShopModel>>? future;

  List<ShopModel> shopList = [];

  int page = 1;
  bool isLastPage = false;

  @override
  void initState() {
    super.initState();
    init(showLoader: false);
  }

  Future<void> init({bool showLoader = true}) async {
    appStore.setLoading(showLoader);
    future = getShopList(
      page,
      shopList: shopList,
      lastPageCallBack: (b) {
        isLastPage = b;
      },
    ).whenComplete(() => appStore.setLoading(false));
    setState(() {});
  }

  void setPageToOne() {
    setState(() {
      page = 1;
    });

    init();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SnapHelperWidget<List<ShopModel>>(
          future: future,
          initialData: cachedShopList,
          loadingWidget: ShopShimmer(),
          errorBuilder: (error) {
            return NoDataWidget(
              title: error,
              imageWidget: ErrorStateWidget(),
              retryText: language.reload,
              onRetry: () {
                init();
              },
            );
          },
          onSuccess: (list) {
            if (shopList.isEmpty && !appStore.isLoading)
              return NoDataWidget(
                title: language.lblNoShopsFound,
                imageWidget: EmptyStateWidget(),
              ).center();
            return AnimatedListView(
              slideConfiguration: sliderConfigurationGlobal,
              itemCount: list.length,
              listAnimationType: ListAnimationType.FadeIn,
              fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
              padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
              onSwipeRefresh: () async {
                setState(() {
                  page = 1;
                });
                init();

                return await 2.seconds.delay;
              },
              onNextPage: () {
                if (!isLastPage) {
                  setState(() {
                    page++;
                  });
                  init();
                }
              },
              itemBuilder: (context, index) {
                ShopModel data = list[index];

                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: boxDecorationWithRoundedCorners(
                    borderRadius: radius(),
                    backgroundColor: context.cardColor,
                    border: appStore.isDarkMode ? Border.all(color: context.dividerColor) : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: data.shopFirstImage.isNotEmpty
                              ? CachedImageWidget(
                                  url: data.shopFirstImage,
                                  fit: BoxFit.cover,
                                  width: 45,
                                  height: 45,
                                  usePlaceholderIfUrlEmpty: true,
                                )
                              : Container(
                                  padding: EdgeInsets.all(12),
                                  child: Image.asset(
                                    Assets.iconsIcDefaultShop,
                                    height: 16,
                                    width: 16,
                                    color: primaryColor,
                                  ),
                                ),
                        ),
                      ),
                      16.width,
                      Text(data.name.validate(), style: boldTextStyle()).expand(),
                      4.width,
                      SelectedItemWidget(isSelected: filterStore.shopIds.contains(data.id)),
                    ],
                  ),
                ).onTap(
                  () {
                    if (data.isSelected.validate()) {
                      data.isSelected = false;
                    } else {
                      data.isSelected = true;
                    }

                    filterStore.shopIds = [];

                    shopList.forEach((element) {
                      if (element.isSelected.validate()) {
                        filterStore.addToShopList(serId: element.id.validate());
                      }
                    });

                    setState(() {});
                  },
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  splashColor: Colors.transparent,
                );
              },
            );
          },
        ),
        Observer(builder: (_) => LoaderWidget().visible(appStore.isLoading && page != 1)),
      ],
    );
  }
}
