import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class ViewAllLabel extends StatelessWidget {
  final String label;
  final List? list;
  final VoidCallback? onTap;
  final int? labelSize;
  final TextStyle? trailingTextStyle;
  final bool? alwaysShowViewAll; // New parameter to always show View All button
  final int maxViewAllLength;

  ViewAllLabel({
    required this.label,
    this.onTap,
    this.labelSize,
    this.list,
    this.trailingTextStyle,
    this.alwaysShowViewAll,
    this.maxViewAllLength = 4,
  });

  bool isViewAllVisible(List list) => list.length >= maxViewAllLength;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: boldTextStyle(size: labelSize ?? LABEL_TEXT_SIZE)),
        TextButton(
          onPressed: (list == null ? true : (alwaysShowViewAll == true ? true : isViewAllVisible(list!)))
              ? () {
                  onTap?.call();
                }
              : null,
          child: (list == null ? true : (alwaysShowViewAll == true ? true : isViewAllVisible(list!))) ? Text(language.lblViewAll, style: trailingTextStyle ?? secondaryTextStyle()) : SizedBox(),
        )
      ],
    );
  }
}