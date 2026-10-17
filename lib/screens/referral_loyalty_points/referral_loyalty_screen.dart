import 'package:booking_system_flutter/component/base_scaffold_widget.dart';
import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../model/user_data_model.dart';
import '../../network/rest_apis.dart';
import 'component/loyalty_points_component.dart';
import 'component/referral_component.dart';

class ReferralAndLoyaltyScreen extends StatefulWidget {
  const ReferralAndLoyaltyScreen({Key? key}) : super(key: key);

  @override
  State<ReferralAndLoyaltyScreen> createState() => _ReferralAndLoyaltyScreenState();
}

class _ReferralAndLoyaltyScreenState extends State<ReferralAndLoyaltyScreen> {
  static const String loyaltyKey = 'loyalty';
  static const String referralKey = 'referral';

  final TextEditingController codeConte = TextEditingController(text: "");
  int? availableLoyaltyPoints = cachedUserDetail?.loyalty_points ?? cachedLoyaltyPoints;

  String selectedTabKey = loyaltyKey;

  bool isTabLoading = false;
  bool showReferralTab = cachedUserDetail == null ? true : _hasValidReferralPoints(cachedUserDetail);

  @override
  void initState() {
    super.initState();
    _applyUserSnapshot(cachedUserDetail);
    init();
  }

  void init() {
    getUserDetail(appStore.userId).then((value) {
      cachedUserDetail = value;
      _applyUserSnapshot(value, shouldSetState: true);
    }).catchError((e) {
      log(e.toString());
    });
  }

  final List<Map<String, String>> tabs = const [
    {'key': loyaltyKey, 'label': 'Loyalty'},
    {'key': referralKey, 'label': 'Referral'},
  ];

  List<Map<String, String>> get visibleTabs {
    if (showReferralTab) return tabs;
    return tabs.where((tab) => tab['key'] == loyaltyKey).toList();
  }

  @override
  void dispose() {
    codeConte.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: language.lblReferralAndLoyalty,
      showLoader: false,
      child: Stack(
        children: [
          Column(
            children: [
              16.height,
              buildTabFilters(),
              16.height,
              Flexible(
                fit: FlexFit.loose,
                child: buildTabBody(),
              ),
            ],
          ),
          Observer(builder: (_) => LoaderWidget().visible(appStore.isLoading)),
        ],
      ),
    );
  }

  Widget buildTabFilters() {
    return Row(
      children: [
        HorizontalList(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          spacing: 16,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visibleTabs.length,
          itemBuilder: (ctx, index) {
            final tab = visibleTabs[index];
            final String key = tab['key']!;
            final String label = tab['label']!;
            final bool isSelected = selectedTabKey == key;

            return FilterChip(
              shape: RoundedRectangleBorder(
                borderRadius: radius(18),
                side: BorderSide(
                  color: isSelected ? primaryColor : Colors.transparent,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              label: Text(
                label,
                style: boldTextStyle(
                  size: 12,
                  color: isSelected
                      ? primaryColor
                      : appStore.isDarkMode
                          ? Colors.white
                          : appTextPrimaryColor,
                ),
              ),
              selected: false,
              showCheckmark: false,
              backgroundColor: isSelected ? lightPrimaryColor : context.cardColor,
              onSelected: (bool selected) {
                _onTabSelected(key);
              },
            );
          },
        ),
      ],
    ).paddingOnly(right: 16);
  }

  void _onTabSelected(String key) {
    if (!visibleTabs.any((tab) => tab['key'] == key)) return;
    if (selectedTabKey == key) return;

    setState(() {
      selectedTabKey = key;
      isTabLoading = true;
    });

    1.seconds.delay.then((_) {
      if (!mounted) return;
      if (selectedTabKey == key) {
        setState(() {
          isTabLoading = false;
        });
      }
    });
  }

  Widget buildTabBody() {
    Widget child;

    if (isTabLoading) {
      child = LoaderWidget();
    } else {
      if (selectedTabKey == loyaltyKey) {
        child = LoyaltyPointsComponent(
          availableLoyaltyPoints: availableLoyaltyPoints ?? cachedLoyaltyPoints ?? 0,
        );
      } else {
        child = ReferralComponent(codeConte: codeConte);
      }
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: Container(
        key: ValueKey('${selectedTabKey}_${isTabLoading ? "loading" : "content"}'),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: child,
      ),
    );
  }

  void _applyUserSnapshot(UserData? value, {bool shouldSetState = false}) {
    if (value == null) return;

    void updateState() {
      availableLoyaltyPoints = value.loyalty_points ?? cachedLoyaltyPoints;
      showReferralTab = _hasValidReferralPoints(value);

      if (!showReferralTab && selectedTabKey == referralKey) {
        selectedTabKey = loyaltyKey;
      }
    }

    if (shouldSetState) {
      if (!mounted) return;
      setState(updateState);
    } else {
      updateState();
    }
  }
}

bool _hasValidReferralPoints(UserData? data) {
  if (data == null) return false;
  final int referrer = data.referrer_points.validate();
  final int referred = data.referred_user_points.validate();
  return referrer > 0 || referred > 0;
}
