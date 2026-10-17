import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../utils/configs.dart';
import '../../../../utils/images.dart';

class DashboardReferralComponent extends StatefulWidget {
  const DashboardReferralComponent({Key? key}) : super(key: key);

  @override
  State<DashboardReferralComponent> createState() => _DashboardReferralComponentState();
}

class _DashboardReferralComponentState extends State<DashboardReferralComponent> {

  // Get user referral code (using username as referral code)
  String get referralCode => appStore.referralCode.isNotEmpty ? appStore.referralCode : "";

  // Generate share message with deep link
  String get shareMessage {
    final referralUrl = '$DOMAIN_URL/register-page?ref=${Uri.encodeComponent(referralCode)}';
    return language.referralShareMessage(referralCode, referralUrl);
  }

  Future<void> _shareReferralCode() async {
    try {
      final result = await Share.share(
        shareMessage,
        subject: 'Join and Get Rewards! 🎁',
      );

      if (result.status == ShareResultStatus.success) {
        _showSnackBar('Shared successfully!');
      }
    } catch (e) {
      _showSnackBar('Error sharing: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final imgSize = w * 0.45;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: 170,
          width: context.width(),
          decoration: boxDecorationWithRoundedCorners(
            backgroundColor: primaryColor,
            borderRadius: radius(14),
          ),
          clipBehavior: Clip.none,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // content (left column)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      language.referFriendsAndEarnLoyaltyPoints,
                      style: boldTextStyle(color: Colors.white, size: 16),
                    ),
                    8.height,
                    Text(
                      language.inviteYourFriendsToTryServices,
                      style: secondaryTextStyle(color: Colors.white70),
                    ),
                    14.height,
                    AppButton(
                      text: language.inviteNow,
                      textStyle: boldTextStyle(color: primaryColor),
                      color: Colors.white,
                      width: 120,
                      shapeBorder: RoundedRectangleBorder(borderRadius: radius(8)),
                      onTap: () {
                        _shareReferralCode();
                      },
                    ),
                  ],
                ),
              ),
              Positioned(
                right: -6,
                bottom: -12,
                child: Image.asset(
                  ic_piggy,
                  width: imgSize,
                  height: imgSize,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
