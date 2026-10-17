import 'package:booking_system_flutter/component/base_scaffold_widget.dart';
import 'package:booking_system_flutter/screens/service/shimmer/view_all_service_shimmer.dart';
import 'package:booking_system_flutter/store/filter_store.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../component/cached_image_widget.dart';
import '../../component/empty_error_state_widget.dart';
import '../../main.dart';
import '../../model/category_model.dart';
import '../../model/service_data_model.dart';
import '../../network/rest_apis.dart';
import '../../utils/common.dart';
import '../../utils/constant.dart';
import '../../utils/images.dart';
import '../filter/filter_screen.dart';
import 'component/service_component.dart';

class ViewAllServiceScreen extends StatefulWidget {
  final int? categoryId;
  final String? categoryName;
  final String isFeatured;
  final bool isFromProvider;
  final bool isFromCategory;
  final int? providerId;
  final int? shopId;

  final String screenTitle;

  ViewAllServiceScreen({
    this.categoryId,
    this.categoryName = '',
    this.isFeatured = '',
    this.isFromProvider = true,
    this.isFromCategory = false,
    this.providerId,
    this.shopId,
    this.screenTitle = '',
    Key? key,
  }) : super(key: key);

  @override
  State<ViewAllServiceScreen> createState() => _ViewAllServiceScreenState();
}

class _ViewAllServiceScreenState extends State<ViewAllServiceScreen> {
  Future<List<CategoryData>>? futureCategory;
  List<CategoryData> categoryList = [];

  Future<List<ServiceData>>? futureService;
  List<ServiceData> serviceList = [];

  FocusNode myFocusNode = FocusNode();
  TextEditingController searchCont = TextEditingController();

  int? subCategory;

  int page = 1;
  bool isLastPage = false;

  @override
  void initState() {
    super.initState();
    init();
    filterStore = FilterStore();
  }

  void init() async {
    fetchAllServiceData();
    if (widget.categoryId != null) {
      await fetchCategoryList();
    }
  }

  Future<void> fetchCategoryList() async {
    futureCategory = getSubCategoryListAPI(
      catId: widget.categoryId!,
    );
  }

  void fetchAllServiceData() async {
    futureService = searchServiceAPI(
      page: page,
      list: serviceList,
      isZoneId: filterStore.zoneId.validate(),
      categoryId: widget.categoryId != null ? widget.categoryId.validate().toString() : filterStore.categoryId.join(','),
      subCategory: subCategory != null ? subCategory.validate().toString() : '',
      providerId: widget.providerId != null ? widget.providerId.toString() : filterStore.providerId.join(","),
      isPriceMin: filterStore.isPriceMin,
      isPriceMax: filterStore.isPriceMax,
      ratingId: filterStore.ratingId.join(','),
      search: searchCont.text,
      latitude: appStore.isCurrentLocation ? getDoubleAsync(LATITUDE).toString() : "",
      longitude: appStore.isCurrentLocation ? getDoubleAsync(LONGITUDE).toString() : "",
      lastPageCallBack: (p0) {
        isLastPage = p0;
      },
      shopId: widget.shopId != null ? widget.shopId.toString() : '',
      isFeatured: widget.isFeatured,
    );
  }

  String get setSearchString {
    if (!widget.categoryName.isEmptyOrNull) {
      return widget.categoryName!;
    } else if (widget.isFeatured == "1") {
      return language.lblFeatured;
    } else if (widget.screenTitle.isNotEmpty) {
      return widget.screenTitle;
    } else {
      return language.allServices;
    }
  }

  Widget subCategoryWidget() {
    return SnapHelperWidget<List<CategoryData>>(
      future: futureCategory,
      initialData: cachedSubcategoryList.firstWhere((element) => element?.$1 == widget.categoryId.validate(), orElse: () => null)?.$2,
      loadingWidget: const Offstage(),
      onSuccess: (list) {
        if (list.length == 1) return const Offstage();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            16.height,
            Text(language.lblSubcategories, style: boldTextStyle(size: LABEL_TEXT_SIZE)).paddingLeft(16),
            HorizontalList(
              itemCount: list.validate().length,
              padding: const EdgeInsets.only(left: 16, right: 16),
              runSpacing: 8,
              spacing: 12,
              itemBuilder: (_, index) {
                CategoryData data = list[index];

                return Observer(
                  builder: (_) {
                    bool isSelected = filterStore.selectedSubCategoryId == index;

                    return GestureDetector(
                      onTap: () {
                        filterStore.setSelectedSubCategory(catId: index);

                        subCategory = data.id;
                        page = 1;

                        appStore.setLoading(true);
                        fetchAllServiceData();

                        setState(() {});
                      },
                      child: SizedBox(
                        width: context.width() / 4 - 28,
                        child: Column(
                          children: [
                            16.height,
                            Badge(
                              isLabelVisible: isSelected,
                              padding: EdgeInsets.zero,
                              backgroundColor: context.cardColor,
                              offset: const Offset(0, 1),
                              label: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: boxDecorationDefault(color: context.primaryColor),
                                child: const Icon(Icons.done, size: 16, color: Colors.white),
                              ).visible(isSelected),
                              child: index == 0
                                  ? Container(
                                      height: CATEGORY_ICON_SIZE,
                                      width: CATEGORY_ICON_SIZE,
                                      decoration: BoxDecoration(color: context.cardColor, shape: BoxShape.circle, border: Border.all(color: grey)),
                                      alignment: Alignment.center,
                                      child: Text(data.name.validate(), style: boldTextStyle(size: 12)),
                                    )
                                  : index != 0
                                      ? data.categoryImage.validate().endsWith('.svg')
                                          ? Container(
                                              width: CATEGORY_ICON_SIZE,
                                              height: CATEGORY_ICON_SIZE,
                                              //  padding: EdgeInsets.all(8),
                                              decoration: BoxDecoration(color: context.cardColor, shape: BoxShape.circle),
                                              child: SvgPicture.network(
                                                data.categoryImage.validate(),
                                                height: CATEGORY_ICON_SIZE,
                                                width: CATEGORY_ICON_SIZE,
                                                colorFilter: ColorFilter.mode(
                                                  appStore.isDarkMode ? Colors.white : data.color.validate(value: '000').toColor(),
                                                  BlendMode.srcIn,
                                                ),
                                                placeholderBuilder: (context) => const PlaceHolderWidget(height: CATEGORY_ICON_SIZE, width: CATEGORY_ICON_SIZE, color: transparentColor),
                                              ),
                                            )
                                          : Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(color: context.cardColor, shape: BoxShape.circle),
                                              child: CachedImageWidget(
                                                url: data.categoryImage.validate(),
                                                fit: BoxFit.fitWidth,
                                                width: SUBCATEGORY_ICON_SIZE,
                                                height: SUBCATEGORY_ICON_SIZE,
                                                circle: true,
                                              ),
                                            )
                                      : const Offstage(),
                            ),
                            4.height,
                            if (index == 0) Text(language.lblViewAll, style: boldTextStyle(size: 12), textAlign: TextAlign.center, maxLines: 1),
                            if (index != 0) Marquee(child: Text('${data.name.validate()}', style: boldTextStyle(size: 12), textAlign: TextAlign.center, maxLines: 1)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            16.height,
          ],
        );
      },
    );
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    filterStore.clearFilters();
    myFocusNode.dispose();
    filterStore.setSelectedSubCategory(catId: 0);
    super.dispose();
  }

  // Disable refresh and next page if showing shop-specific services
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => hideKeyboard(context),
      child: AppScaffold(
        appBarTitle: setSearchString,
        child: SizedBox(
          height: context.height(),
          width: context.width(),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    AppTextField(
                      textFieldType: TextFieldType.OTHER,
                      focus: myFocusNode,
                      controller: searchCont,
                      suffix: CloseButton(
                        onPressed: () {
                          page = 1;
                          searchCont.clear();
                          filterStore.setSearch('');
                          appStore.setLoading(true);
                          fetchAllServiceData();
                          setState(() {});
                        },
                      ).visible(searchCont.text.isNotEmpty),
                      onFieldSubmitted: (s) {
                        page = 1;

                        filterStore.setSearch(s);
                        appStore.setLoading(true);

                        fetchAllServiceData();
                        setState(() {});
                      },
                      decoration: inputDecoration(context).copyWith(
                        hintText: "${language.lblSearchFor} $setSearchString",
                        prefixIcon: ic_search.iconImage(size: 10).paddingAll(14),
                        hintStyle: secondaryTextStyle(),
                      ),
                    ).expand(),
                    16.width,
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: boxDecorationDefault(color: context.primaryColor),
                      child: const CachedImageWidget(
                        url: ic_filter,
                        height: 26,
                        width: 26,
                        color: Colors.white,
                      ),
                    ).onTap(() {
                      hideKeyboard(context);

                      FilterScreen(
                        isFromProvider: widget.isFromProvider,
                        isFromCategory: widget.isFromCategory,
                        // isFromShop: true,
                      ).launch(context).then((value) {
                        if (value != null) {
                          page = 1;
                          appStore.setLoading(true);

                          fetchAllServiceData();
                          setState(() {});
                        }
                      });
                    }, borderRadius: radius())
                  ],
                ),
              ),
              AnimatedScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                onSwipeRefresh: () {
                  page = 1;
                  appStore.setLoading(true);
                  fetchAllServiceData();
                  setState(() {});
                  return Future.value(false);
                },
                onNextPage: () {
                  if (!isLastPage) {
                    page++;
                    appStore.setLoading(true);
                    fetchAllServiceData();
                    setState(() {});
                  }
                },
                children: [
                  if (widget.categoryId != null) subCategoryWidget(),
                  16.height,
                  SnapHelperWidget(
                    future: futureService,
                    loadingWidget: const ViewAllServiceShimmer(),
                    errorBuilder: (p0) {
                      return NoDataWidget(
                        title: p0,
                        retryText: language.reload,
                        imageWidget: const ErrorStateWidget(),
                        onRetry: () {
                          page = 1;
                          appStore.setLoading(true);

                          fetchAllServiceData();
                          setState(() {});
                        },
                      );
                    },
                    onSuccess: (data) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(language.service, style: boldTextStyle(size: LABEL_TEXT_SIZE)).paddingSymmetric(horizontal: 16),
                          AnimatedListView(
                            itemCount: serviceList.length,
                            listAnimationType: ListAnimationType.FadeIn,
                            fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            emptyWidget: NoDataWidget(
                              title: language.lblNoServicesFound,
                              subTitle: (searchCont.text.isNotEmpty || filterStore.providerId.isNotEmpty || filterStore.categoryId.isNotEmpty) ? language.noDataFoundInFilter : null,
                              imageWidget: const EmptyStateWidget(),
                            ),
                            itemBuilder: (_, index) {
                              return ServiceComponent(
                                serviceData: serviceList[index],
                                isFromViewAllService: true,
                              ).paddingAll(8);
                            },
                          ).paddingAll(8),
                        ],
                      );
                    },
                  ),
                ],
              ).expand(),
            ],
          ),
        ),
      ),
    );
  }
}
