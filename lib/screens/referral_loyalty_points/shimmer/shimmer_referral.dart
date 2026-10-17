import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../component/shimmer_widget.dart';

class ReferralLoyaltyShimmer extends StatelessWidget {
  const ReferralLoyaltyShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// ---- Available Loyalty Points Card ----
        Container(
          height: 80,
          decoration: boxDecorationWithRoundedCorners(
            borderRadius: radius(16),
            backgroundColor: context.cardColor,
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShimmerWidget(height: 14, width: 140),
                  12.height,
                  ShimmerWidget(height: 18, width: 60),
                ],
              ).expand(),
              16.width,
              ShimmerWidget(
                height: 48,
                width: 48,
                child: Container(
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                ),
              ),
            ],
          ).paddingAll(16),
        ).paddingSymmetric(horizontal: 16),

        24.height,

        /// ---- History Title + View All ----
        Row(
          children: [
            ShimmerWidget(height: 16, width: 90),
            const Spacer(),
            ShimmerWidget(height: 12, width: 60),
          ],
        ).paddingSymmetric(horizontal: 16),

        12.height,

        /// ---- History List ----
        ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 6,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (_, __) => 10.height,
          itemBuilder: (_, index) {
            return Container(
              height: 70,
              decoration: boxDecorationWithRoundedCorners(
                borderRadius: radius(16),
                backgroundColor: context.cardColor,
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  /// Left: Title + date
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ShimmerWidget(height: 14, width: 160),
                      8.height,
                      ShimmerWidget(height: 12, width: 110),
                    ],
                  ).expand(),

                  12.width,

                  ShimmerWidget(height: 18, width: 40),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
