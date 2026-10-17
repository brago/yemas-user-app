import 'package:booking_system_flutter/utils/images.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../utils/colors.dart';

class PointsEarnedCard extends StatelessWidget {
  final int? points;
   PointsEarnedCard({Key? key, required this.points}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 410,
      height: 70,
      decoration: boxDecorationDefault(
        color: primaryColor,
      ),
      child: Stack(
        children: [
          Positioned(
            left: 20,
            top: 0,
            bottom: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Earn Points', style: secondaryTextStyle(color: white)),
                4.height,
                Row(
                  children: [
                    Image.asset(
                      ic_coins,
                      width: 24,
                      height: 24,
                    ),
                    Text(
                      '+${points}',
                      style: primaryTextStyle(),
                    )
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: -40,
            top: -10,
            bottom: -10,
            child: Image.asset(ic_big_coins),
          ),
        ],
      ),
    );
  }
}
