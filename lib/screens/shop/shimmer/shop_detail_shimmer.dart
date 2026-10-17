import 'package:booking_system_flutter/component/shimmer_widget.dart';
import 'package:flutter/material.dart';

class ShopDetailsShimmer extends StatelessWidget {
  const ShopDetailsShimmer({super.key});

  Widget shimmerBox({double? height, double? width, double radius = 8}) {
    return ShimmerWidget(
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Shop Image
          shimmerBox(height: 200, width: double.infinity, radius: 16),
          const SizedBox(height: 16),

          // Shop Name
          shimmerBox(height: 20, width: 150),
          const SizedBox(height: 12),

          // Address Row
          Row(
            children: [
              shimmerBox(height: 16, width: 16, radius: 4),
              const SizedBox(width: 8),
              shimmerBox(height: 14, width: 200),
            ],
          ),
          const SizedBox(height: 10),

          // Email Row
          Row(
            children: [
              shimmerBox(height: 16, width: 16, radius: 4),
              const SizedBox(width: 8),
              shimmerBox(height: 14, width: 180),
            ],
          ),
          const SizedBox(height: 10),

          // Phone Row
          Row(
            children: [
              shimmerBox(height: 16, width: 16, radius: 4),
              const SizedBox(width: 8),
              shimmerBox(height: 14, width: 140),
            ],
          ),
          const SizedBox(height: 10),

          // Time Row
          Row(
            children: [
              shimmerBox(height: 16, width: 16, radius: 4),
              const SizedBox(width: 8),
              shimmerBox(height: 14, width: 160),
            ],
          ),
          const SizedBox(height: 20),

          // Services Title
          shimmerBox(height: 18, width: 100),
          const SizedBox(height: 16),

          // Horizontal service list
          SizedBox(
            height: 250,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, __) {
                return SizedBox(
                  width: 180,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Service Image
                      shimmerBox(height: 140, width: 180, radius: 16),
                      const SizedBox(height: 8),

                      // Price Tag
                      shimmerBox(height: 20, width: 50, radius: 12),
                      const SizedBox(height: 8),

                      // Rating Stars
                      shimmerBox(height: 14, width: 80),
                      const SizedBox(height: 8),

                      // Service Title
                      shimmerBox(height: 16, width: 120),
                      const SizedBox(height: 8),

                      // Provider Row
                      Row(
                        children: [
                          shimmerBox(height: 24, width: 24, radius: 12),
                          const SizedBox(width: 8),
                          shimmerBox(height: 14, width: 80),
                        ],
                      ),
                    ],
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemCount: 2,
            ),
          ),
        ],
      ),
    );
  }
}
