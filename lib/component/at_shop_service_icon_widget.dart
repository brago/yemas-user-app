import 'package:booking_system_flutter/generated/assets.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class ShopServiceIconWidget extends StatelessWidget {
  final bool isShowText;

  const ShopServiceIconWidget({super.key, this.isShowText = true});

  @override
  Widget build(BuildContext context) {
    if (isShowText) {
      return Container(
        decoration: boxDecorationDefault(
          color: appStore.isDarkMode ? Colors.black : lightPrimaryColor,
          borderRadius: radius(20),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6),
              child: Image.asset(
                Assets.iconsIcDefaultShop,
                height: 12,
                color: Colors.white,
              ),
              decoration: boxDecorationDefault(
                shape: BoxShape.circle,
                color: shopColor,
              ),
            ),
            4.width,
            Text(language.lblAtShop, style: boldTextStyle(size: 12)).paddingSymmetric(vertical: 4, horizontal: 2),
            8.width,
          ],
        ),
      );
    } else {
      // Show only the shop icon
      return Container(
        padding: EdgeInsets.all(6),
        child: Image.asset(
          Assets.iconsIcDefaultShop,
          height: 12,
          color: Colors.white,
        ),
        decoration: boxDecorationDefault(
          shape: BoxShape.circle,
          color: shopColor,
        ),
      );
    }
  }
}