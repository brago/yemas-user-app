import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/component/view_all_label_component.dart';
import 'package:booking_system_flutter/generated/assets.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/model/shop_model.dart';
import 'package:booking_system_flutter/screens/service/service_detail_screen.dart';
import 'package:booking_system_flutter/screens/service/view_all_service_screen.dart';
import 'package:booking_system_flutter/screens/shop/shop_detail_screen.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class ShopComponent extends StatelessWidget {
  final ShopModel shop;
  final double imageSize;
  final bool showServices;
  final bool isSelected;
  final double? width;
  final VoidCallback? onTap;

  const ShopComponent({
    Key? key,
    required this.shop,
    this.imageSize = 56,
    this.showServices = true,
    this.isSelected = false,
    this.width,
    this.onTap,
  }) : super(key: key);

  Widget _buildFallbackImage() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Image.asset(
        Assets.iconsIcDefaultShop,
        height: 14,
        width: 14,
        color: primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ??
          () {
            ShopDetailScreen(shopId: shop.id).launch(context);
          },
      child: Container(
        width: width ?? context.width(),
        padding: EdgeInsets.all(16),
        decoration: boxDecorationDefault(
          color: context.cardColor,
          border: isSelected ? Border.all(color: primaryColor) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: [
                Container(
                  width: imageSize,
                  height: imageSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: shop.shopFirstImage.isNotEmpty
                        ? CachedImageWidget(
                            url: shop.shopFirstImage,
                            fit: BoxFit.cover,
                            width: imageSize,
                            height: imageSize,
                            usePlaceholderIfUrlEmpty: true,
                          )
                        : _buildFallbackImage(),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 6,
                  children: [
                    Text(
                      shop.name,
                      style: boldTextStyle(size: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ic_location.iconImage(size: 14, color: context.iconColor),
                        4.width,
                        Expanded(
                          child: SizedBox(
                            height: 20, // required for Marquee to know its height
                            child: Marquee(
                              child: Text(
                                "${shop.buildFullAddress()}",
                                style: secondaryTextStyle(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    TextIcon(
                      edgeInsets: EdgeInsets.zero,
                      text: shop.shopStartTime.validate().isNotEmpty && shop.shopEndTime.isNotEmpty ? '${shop.shopStartTime} - ${shop.shopEndTime}' : '---',
                      expandedText: true,
                      prefix: ic_clock.iconImage(size: 14, color: context.iconColor),
                      textStyle: secondaryTextStyle(),
                      spacing: 4,
                    ),
                  ],
                ).expand(),
              ],
            ),
            if (showServices && shop.services.isNotEmpty)
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  8.height,
                  Divider(color: context.dividerColor),
                  ViewAllLabel(
                    label: '${language.lblServicesList}',
                    maxViewAllLength: 3,
                    onTap: () {
                      ViewAllServiceScreen(
                        shopId: shop.id,
                        screenTitle: language.shopsService(shop.name),
                      ).launch(context);
                    },
                  ),
                  AnimatedWrap(
                    spacing: 6,
                    runSpacing: 6,
                    direction: Axis.horizontal,
                    itemCount: shop.services.take(3).length,
                    itemBuilder: (context, index) {
                      ServiceData service = shop.services[index];
                      return InkWell(
                        onTap: () {
                          ServiceDetailScreen(serviceId: service.id.validate()).launch(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.08),
                            borderRadius: radius(16),
                          ),
                          child: Text(
                            service.name.validate(),
                            style: secondaryTextStyle(color: primaryColor),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
