import 'package:booking_system_flutter/component/shimmer_widget.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class ShopShimmer extends StatelessWidget {
  const ShopShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(16),
      itemCount: 8, // same as placeholder count you want
      separatorBuilder: (_, __) => 16.height,
      itemBuilder: (context, index) {
        return Container(
          decoration: boxDecorationWithRoundedCorners(
            borderRadius: radius(),
            backgroundColor: context.cardColor,
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: shop image + details
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shop image
                  ShimmerWidget(
                    child: Container(
                      height: 56,
                      width: 56,
                      decoration: boxDecorationWithRoundedCorners(
                        borderRadius: radius(28),
                        backgroundColor: context.cardColor,
                      ),
                    ),
                  ),
                  12.width,
                  // Name + Address + Time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerWidget(height: 18, width: 140), // shop name
                        8.height,
                        Row(
                          children: [
                            ShimmerWidget(height: 18, width: 18), // location icon
                            4.width,
                            Expanded(
                              child: ShimmerWidget(height: 14, width: double.infinity),
                            ),
                          ],
                        ),
                        4.height,
                        Row(
                          children: [
                            ShimmerWidget(height: 18, width: 18), // time icon
                            4.width,
                            ShimmerWidget(height: 14, width: 100),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              16.height,
              Divider(color: context.dividerColor),
              8.height,

              // Service list header
              ShimmerWidget(height: 16, width: 80),
              12.height,

              // Services chips
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(3, (i) {
                  return ShimmerWidget(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: boxDecorationWithRoundedCorners(
                        borderRadius: radius(20),
                        backgroundColor: context.cardColor,
                      ),
                      child: ShimmerWidget(height: 13, width: 60 + (i * 15)),
                    ),
                  );
                }),
              ),

              8.height,
              ShimmerWidget(height: 12, width: 70), // "View More" button placeholder
            ],
          ),
        );
      },
    );
  }
}
