import 'package:booking_system_flutter/component/base_scaffold_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/service_detail_response.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/booking/component/coupon_card_widget.dart';
import 'package:booking_system_flutter/screens/booking/shimmer/coupon_list_shimmer.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../component/empty_error_state_widget.dart';
import '../../../model/coupon_list_model.dart';

class CouponsScreen extends StatefulWidget {
  final int serviceId;
  final num price;
  final CouponData? appliedCouponData;
  final num? servicePrice;

  const CouponsScreen({required this.serviceId, this.servicePrice, this.appliedCouponData,required this.price});

  @override
  _CouponsScreenState createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  Future<CouponListResponse>? future;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init({Map? req}) async {
    future = getCouponList(serviceId: widget.serviceId,price:widget.price);
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: language.coupons,
      child: SnapHelperWidget<CouponListResponse>(
        future: future,
        loadingWidget: CouponListShimmer(),
        errorBuilder: (error) {
          return NoDataWidget(
            title: error,
            imageWidget: const ErrorStateWidget(),
            retryText: language.reload,
            onRetry: () {
              appStore.setLoading(true);

              init();
              setState(() {});
            },
          ).center();
        },
        onSuccess: (couponsRes) {
          //TODO: handle from backend
          final List<CouponData> validCoupons = couponsRes.validCupon;

          if (validCoupons.isEmpty) {
            return NoDataWidget(
              title: language.lblNoCouponsAvailable,
              subTitle: language.noCouponsAvailableMsg,
              imageWidget: const EmptyStateWidget(),
            ).center();
          }

          return AnimatedListView(
            shrinkWrap: true,
            itemCount: validCoupons.length,
            slideConfiguration: sliderConfigurationGlobal,
            listAnimationType: ListAnimationType.FadeIn,
            fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
            emptyWidget: NoDataWidget(
              title: language.lblNoCouponsAvailable,
              subTitle: language.noCouponsAvailableMsg,
              imageWidget: const EmptyStateWidget(),
            ),
            onSwipeRefresh: () {
              appStore.setLoading(true);
              init();
              setState(() {});
              return 2.seconds.delay;
            },
            itemBuilder: (context, index) {
              final CouponData data = validCoupons[index];

              if (widget.appliedCouponData != null && widget.appliedCouponData!.code == data.code) {
                data.isApplied = widget.appliedCouponData!.isApplied;
              }
              return CouponCardWidget(data: data, servicePrice: widget.servicePrice).paddingOnly(top: 16);
            },
          );
        },
      ).paddingSymmetric(horizontal: 8),
    );
  }
}
