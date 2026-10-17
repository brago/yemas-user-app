import 'package:booking_system_flutter/component/base_scaffold_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/category_model.dart';
import 'package:booking_system_flutter/model/user_data_model.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/booking_filter/components/filter_service_list_component.dart';
import 'package:booking_system_flutter/screens/filter/component/filter_category_component.dart';
import 'package:booking_system_flutter/screens/filter/component/filter_price_component.dart';
import 'package:booking_system_flutter/screens/filter/component/filter_provider_component.dart';
import 'package:booking_system_flutter/screens/filter/component/filter_rating_component.dart';
import 'package:booking_system_flutter/screens/filter/component/filter_zone_component.dart';
import 'package:booking_system_flutter/model/zone_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../utils/constant.dart';

class FilterScreen extends StatefulWidget {
  final bool isFromProvider;
  final bool isFromCategory;
  final bool isFromShop;

  FilterScreen({
    this.isFromProvider = true,
    this.isFromCategory = false,
    this.isFromShop = false,
  });

  @override
  _FilterScreenState createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  int isSelected = 0;

  List<CategoryData> catList = [];
  List<UserData> providerList = [];
  List<ZoneModel> zoneList = [];

  num? minPrice;
  num? maxPrice;
  int? selectedZoneId;

  @override
  void initState() {
    super.initState();
    appStore.setLoading(true);
    afterBuildCreated(() => init());
  }

  void init() async {
    Future.wait([
      if (widget.isFromProvider) getProviders(),
      if (!widget.isFromCategory) getCategories(),
    ]);

    // Initialize selected zone from filter store
    selectedZoneId = filterStore.zoneId;

    appStore.setLoading(false);
    getZoneList(services: zoneList);
  }

  Future<void> getProviders() async {
    appStore.setLoading(true);
    await getProvider(type: FILTER_PROVIDER).then((value) {
      minPrice = value.min;
      maxPrice = value.max;

      providerList = value.providerList.validate();
      for (var element in providerList) {
        if (filterStore.providerId.contains(element.id)) {
          element.isSelected = true;
        }
      }
      setState(() {});
    }).catchError((e) {
      toast(e.toString());
    }).whenComplete(() => appStore.setLoading(false));
  }

  Future<void> getCategories() async {
    await getCategoryList(CATEGORY_LIST_ALL).then((value) {
      catList = value.categoryList.validate();
      for (var element in catList) {
        if (filterStore.categoryId.contains(element.id)) {
          element.isSelected = true;
        }
      }
      setState(() {});
    }).catchError((e) {
      toast(e.toString());
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  Widget buildItem({required String name, required bool isSelected}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
      width: context.width(),
      decoration: boxDecorationDefault(
        color: isSelected ? context.cardColor : context.scaffoldBackgroundColor,
        borderRadius: radius(0),
      ),
      child: Text(name, style: boldTextStyle(size: 12)),
    );
  }

  void clearFilter() {
    filterStore.clearFilters();
    selectedZoneId = null; // Clear the local state as well
    finish(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: AppScaffold(
        appBarTitle: language.lblFilterBy,
        scaffoldBackgroundColor: context.cardColor,
        child: Column(
          children: [
            Row(
              children: [
                /// LEFT FILTER MENU
                Container(
                  decoration: boxDecorationDefault(
                    color: context.scaffoldBackgroundColor,
                    borderRadius: radius(0),
                  ),
                  child: Column(
                    children: [
                      if (widget.isFromProvider)
                        buildItem(
                          isSelected: isSelected == 0,
                          name: language.textProvider,
                        ).onTap(() {
                          if (!appStore.isLoading) {
                            isSelected = 0;
                            setState(() {});
                          }
                        }),
                      if (widget.isFromShop)
                        buildItem(
                          isSelected: isSelected == (widget.isFromProvider ? 1 : 0),
                          name: language.lblServices,
                        ).onTap(() {
                          if (!appStore.isLoading) {
                            isSelected = widget.isFromProvider ? 1 : 0;
                            setState(() {});
                          }
                        }),
                      if (!widget.isFromShop) ...[
                        if (!widget.isFromCategory)
                          buildItem(
                            isSelected: isSelected == (widget.isFromProvider ? (widget.isFromShop ? 2 : 1) : (widget.isFromShop ? 1 : 0)),
                            name: language.lblCategory,
                          ).onTap(() {
                            if (!appStore.isLoading) {
                              isSelected = widget.isFromProvider ? (widget.isFromShop ? 2 : 1) : (widget.isFromShop ? 1 : 0);
                              setState(() {});
                            }
                          }),
                        buildItem(
                          isSelected: isSelected ==
                              (widget.isFromProvider
                                  ? (widget.isFromShop ? (widget.isFromCategory ? 2 : 3) : (widget.isFromCategory ? 1 : 2))
                                  : (widget.isFromShop ? (widget.isFromCategory ? 1 : 2) : (widget.isFromCategory ? 0 : 1))),
                          name: language.lblPrice,
                        ).onTap(() {
                          if (!appStore.isLoading) {
                            isSelected = widget.isFromProvider
                                ? (widget.isFromShop ? (widget.isFromCategory ? 2 : 3) : (widget.isFromCategory ? 1 : 2))
                                : (widget.isFromShop ? (widget.isFromCategory ? 1 : 2) : (widget.isFromCategory ? 0 : 1));
                            setState(() {});
                          }
                        }),
                        buildItem(
                          isSelected: isSelected ==
                              (widget.isFromProvider
                                  ? (widget.isFromShop ? (widget.isFromCategory ? 3 : 4) : (widget.isFromCategory ? 2 : 3))
                                  : (widget.isFromShop ? (widget.isFromCategory ? 2 : 3) : (widget.isFromCategory ? 1 : 2))),
                          name: language.lblRating,
                        ).onTap(() {
                          if (!appStore.isLoading) {
                            isSelected = widget.isFromProvider
                                ? (widget.isFromShop ? (widget.isFromCategory ? 3 : 4) : (widget.isFromCategory ? 2 : 3))
                                : (widget.isFromShop ? (widget.isFromCategory ? 2 : 3) : (widget.isFromCategory ? 1 : 2));
                            setState(() {});
                          }
                        }),
                        buildItem(
                          isSelected: isSelected ==
                              (widget.isFromProvider
                                  ? (widget.isFromShop ? (widget.isFromCategory ? 4 : 5) : (widget.isFromCategory ? 3 : 4))
                                  : (widget.isFromShop ? (widget.isFromCategory ? 3 : 4) : (widget.isFromCategory ? 2 : 3))),
                          name: language.lblZone,
                        ).onTap(() {
                          if (!appStore.isLoading) {
                            isSelected = widget.isFromProvider
                                ? (widget.isFromShop ? (widget.isFromCategory ? 4 : 5) : (widget.isFromCategory ? 3 : 4))
                                : (widget.isFromShop ? (widget.isFromCategory ? 3 : 4) : (widget.isFromCategory ? 2 : 3));
                            setState(() {});
                          }
                        }),
                      ],
                    ],
                  ),
                ).expand(flex: 2),

                /// RIGHT FILTER PANEL
                [
                  if (appStore.isLoading) Offstage(),
                  if (widget.isFromProvider)
                    Observer(
                      builder: (context) => FilterProviderComponent(
                        providerList: providerList,
                        showLoader: appStore.isLoading,
                      ),
                    ),
                  if (widget.isFromShop) FilterServiceListComponent(showLoader: false),
                  if (!widget.isFromCategory) FilterCategoryComponent(catList: catList),
                  FilterPriceComponent(
                    min: minPrice.validate(),
                    max: maxPrice.validate(),
                  ),
                  FilterRatingComponent(),
                  FilterServiceZoneComponent(
                    providerList: zoneList,
                    initialSelectedZoneId: selectedZoneId,
                    onZoneSelected: (id) {
                      setState(() {
                        selectedZoneId = id;
                      });
                    },
                  ),
                ][isSelected]
                    .flexible(flex: 5),
              ],
            ).expand(),

            /// BOTTOM BUTTONS
            Observer(
              builder: (_) => Container(
                decoration: boxDecorationDefault(color: context.scaffoldBackgroundColor),
                width: context.width(),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (filterStore.providerId.validate().isNotEmpty ||
                        filterStore.categoryId.validate().isNotEmpty ||
                        (filterStore.isPriceMin.validate().isNotEmpty && filterStore.isPriceMax.validate().isNotEmpty) ||
                        filterStore.ratingId.validate().isNotEmpty ||
                        filterStore.zoneId != null)
                      AppButton(
                        text: language.lblClearFilter,
                        textColor: context.primaryColor,
                        shapeBorder: RoundedRectangleBorder(
                          side: BorderSide(color: context.primaryColor),
                          borderRadius: radius(),
                        ),
                        onTap: () {
                          clearFilter();
                        },
                      ).expand(),
                    16.width,
                    AppButton(
                      text: language.lblApply,
                      textColor: Colors.white,
                      color: context.primaryColor,
                      onTap: () {
                        filterStore.categoryId = [];
                        catList.forEach((element) {
                          if (element.isSelected) {
                            filterStore.addToCategoryIdList(prodId: element.id.validate());
                          }
                        });

                        filterStore.providerId = [];
                        providerList.forEach((element) {
                          if (element.isSelected) {
                            filterStore.addToProviderList(prodId: element.id.validate());
                          }
                        });
                        if (selectedZoneId != null) {
                          filterStore.zoneId = selectedZoneId;
                        } else {
                          filterStore.zoneId = null;
                        }
                        finish(context, true);
                      },
                    ).expand(),
                  ],
                ),
              ).visible(!appStore.isLoading),
            ),
          ],
        ),
      ),
    );
  }
}
