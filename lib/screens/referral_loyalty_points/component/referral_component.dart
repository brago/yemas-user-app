import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:share_plus/share_plus.dart';

import '../../../network/rest_apis.dart';
import '../../../utils/colors.dart';
import '../../../utils/common.dart';
import '../../../utils/configs.dart';
import '../../../utils/dashed_rect.dart';
import '../../../utils/images.dart';

class ReferralComponent extends StatefulWidget {
  TextEditingController codeConte = TextEditingController();

  ReferralComponent({super.key, required this.codeConte}) {
    codeConte.text = appStore.referralCode.isNotEmpty ? appStore.referralCode : "";
  }

  @override
  State<ReferralComponent> createState() => _ReferralComponentState();
}

class _ReferralComponentState extends State<ReferralComponent> {
  int? referrer_points;
  int? referred_points;

  // Generate share message with deep link
  String _getShareMessage(String referralCode) {
    final referralUrl = '$DOMAIN_URL/register-page?ref=${Uri.encodeComponent(referralCode)}';
    return language.referralShareMessage(referralCode, referralUrl);
  }

  Future<void> _shareReferralCode(BuildContext context) async {
    try {
      final result = await Share.share(
        _getShareMessage(widget.codeConte.text),
        subject: 'Join and Get Rewards! 🎁',
      );

      if (result.status == ShareResultStatus.success) {
        toast('Shared successfully!');
      }
    } catch (e) {
      toast('Error sharing: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    final user = await getUserDetail(appStore.userId);
    setState(() {
      referrer_points = user.referrer_points.validate();
      referred_points = user.referred_user_points.validate();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          language.shareYourPromoCode("${referrer_points}", "${referred_points}"),
          style: primaryTextStyle(size: 15),
        ),
        8.height,
        Text(
          language.copyYourCodeAndShare,
          style: secondaryTextStyle(size: 13),
        ),
        16.height,
        Container(
          padding: const EdgeInsets.all(12),
          decoration: boxDecorationDefault(color: context.cardColor),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(language.lblYourReferralCode, style: secondaryTextStyle(size: 13)),
              Row(
                children: [
                  AppTextField(
                    textFieldType: TextFieldType.NAME,
                    controller: widget.codeConte,
                    readOnly: true,
                    decoration: inputDecoration(
                      context,
                    ),
                    suffix: ic_copy.iconImage(size: 12).onTap(() async {
                      await Clipboard.setData(ClipboardData(text: widget.codeConte.text));
                      toast(language.referralCodeIsCopied);
                    }).paddingAll(16),
                  ).expand(),
                  8.width,
                  AppButton(
                    text: language.lblShare,
                    textStyle: boldTextStyle(color: Colors.white),
                    color: primaryColor,
                    width: 80,
                    onTap: () {
                      _shareReferralCode(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        24.height,
        Text(language.howItWorks, style: boldTextStyle(size: 16)),
        16.height,
        _buildHowItWorksStep(1, language.lblShareYourCode, language.lblInviteFriends),
        _buildHowItWorksStep(2, language.lblEarnPoints, language.lblGetRewarded),
        _buildHowItWorksStep(3, language.lblRedeemRewards, language.unlockBenefits(referrer_points.validate().toString())),
      ],
    );
  }

  Widget _buildHowItWorksStep(int index, String title, String description) {
    Color color;
    switch (index) {
      case 1:
        color = const Color(0xFFFF9500);
        break;
      case 2:
        color = const Color(0xFF34C759);
        break;
      default:
        color = const Color(0xFFAF52DE);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(index.toString(), style: boldTextStyle(color: color, size: 14)),
            ),
            if (index != 3)
              SizedBox(
                height: 65,
                child: DashedRect(
                  gap: 2.5,
                  strokeWidth: 0.8,
                  color: primaryColor,
                ),
              )
          ],
        ),
        12.width,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: boldTextStyle(size: 14)),
              4.height,
              Text(description, style: secondaryTextStyle(size: 13)),
            ],
          ),
        ),
      ],
    ).paddingBottom(8);
  }
}
