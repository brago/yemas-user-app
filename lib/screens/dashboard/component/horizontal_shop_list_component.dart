import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import 'package:booking_system_flutter/component/view_all_label_component.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/shop_model.dart';
import 'package:booking_system_flutter/screens/shop/shop_list_screen.dart';
import 'package:booking_system_flutter/screens/shop/component/shop_component.dart';

class HorizontalShopListComponent extends StatelessWidget {
  final List<ShopModel> shopList;
  final String? listTitle;
  final double? cardWidth;
  final int providerId;
  final String providerName;
  final int serviceId;
  final String serviceName;

  final bool showServices;

  HorizontalShopListComponent({
    required this.shopList,
    this.listTitle,
    this.cardWidth,
    this.providerId = 0,
    this.providerName = '',
    this.serviceId = 0,
    this.serviceName = '',
    this.showServices = true,
  });

  @override
  Widget build(BuildContext context) {
    if (shopList.isEmpty) return Offstage();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ViewAllLabel(
          label: listTitle ?? language.lblShop,
          list: shopList,
          alwaysShowViewAll: true,
          onTap: () {
            ShopListScreen(
              providerId: providerId,
              providerName: providerName,
              serviceId: serviceId,
              serviceName: serviceName,
            ).launch(context).then((value) {
              setStatusBarColor(
                Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
              );
            });
          },
        ).paddingDirectional(start: 16, end: 16),
        HorizontalList(
          spacing: 16,
          runSpacing: 16,
          itemCount: shopList.length,
          padding: EdgeInsets.symmetric(horizontal: 16),
          itemBuilder: (context, index) {
            return ShopComponent(
              shop: shopList[index],
              showServices: showServices,
              width: context.width() - 32,
            );
          },
        ),
      ],
    );
  }
}