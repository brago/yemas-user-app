import 'package:booking_system_flutter/component/back_widget.dart';
import 'package:booking_system_flutter/component/shimmer_widget.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';


class ServiceDetailShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Service Detail Header
          SizedBox(
            height: 475,
            width: context.width(),
            child: Stack(
              children: [
                SizedBox(height: 400, width: context.width(), child: ShimmerWidget()),
                Positioned(
                  top: context.statusBarHeight + 8,
                  left: 16,
                  child: Container(
                    child: BackWidget(iconColor: context.iconColor),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: context.cardColor.withValues(alpha: 0.7)),
                  ),
                ),
              ],
            ),
          ),
          ShimmerWidget(height: 18, width: context.width() * 0.6),
          10.height,
          Row(
            children: [
              ShimmerWidget(height: 14, width: 80),
              12.width,
              ShimmerWidget(height: 14, width: 60),
            ],
          ),
          10.height,
          ShimmerWidget(height: 16, width: 100),
          24.height,
          Container(
            width: context.width(),
            padding: const EdgeInsets.all(16),
            decoration: boxDecorationWithRoundedCorners(
              backgroundColor: context.cardColor,
              borderRadius: radius(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerWidget(height: 14, width: 120),
                12.height,
                Row(
                  children: [
                    ShimmerWidget(height: 28, width: 100).cornerRadiusWithClipRRect(20),
                    12.width,
                    ShimmerWidget(height: 28, width: 120).cornerRadiusWithClipRRect(20),
                  ],
                ),
              ],
            ),
          ),
          24.height,
          Container(
            width: context.width(),
            padding: const EdgeInsets.all(16),
            decoration: boxDecorationWithRoundedCorners(
              backgroundColor: context.cardColor,
              borderRadius: radius(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerWidget(height: 50, width: 50).cornerRadiusWithClipRRect(25),
                12.width,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerWidget(height: 14, width: 100), // Name
                    8.height,
                    Row(
                      children: [
                        ShimmerWidget(height: 12, width: 12).cornerRadiusWithClipRRect(6),
                        4.width,
                        ShimmerWidget(height: 12, width: 40),
                        6.width,
                        ShimmerWidget(height: 16, width: 16).cornerRadiusWithClipRRect(8),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          24.height,
          ShimmerWidget(height: 14, width: 100),
          12.height,
          ...List.generate(2, (index) {
            return Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: boxDecorationWithRoundedCorners(
                backgroundColor: context.cardColor,
                borderRadius: radius(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerWidget(height: 14, width: context.width() * 0.5),
                  6.height,
                  ShimmerWidget(height: 12, width: context.width() * 0.7),
                  4.height,
                  ShimmerWidget(height: 12, width: context.width() * 0.65),
                ],
              ),
            );
          }),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: ShimmerWidget(
              height: 48,
              width: context.width(),
            ).cornerRadiusWithClipRRect(12),
          ),
        ],
      ),
    );
  }
}
