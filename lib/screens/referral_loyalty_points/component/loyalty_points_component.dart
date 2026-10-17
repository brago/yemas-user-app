import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../component/empty_error_state_widget.dart';
import '../../../component/loader_widget.dart';
import '../../../component/view_all_label_component.dart';
import '../../../network/rest_apis.dart';
import '../../../utils/colors.dart';
import '../model/loyalty_history_model.dart';
import '../shimmer/shimmer_referral.dart';
import '../view_all_history.dart';
import 'history_card.dart';

class LoyaltyPointsComponent extends StatefulWidget {
  final int? availableLoyaltyPoints;
  const LoyaltyPointsComponent({Key? key,  this.availableLoyaltyPoints}) : super(key: key);

  @override
  State<LoyaltyPointsComponent> createState() => _LoyaltyPointsComponentState();
}

class _LoyaltyPointsComponentState extends State<LoyaltyPointsComponent> {
  Future<List<LoyaltyHistoryItem>>? future;


  List<LoyaltyHistoryItem> loyaltyHistoryList = [];
  int page = 1;
  bool isLastPage = false;

  @override
  void initState() {
    super.initState();
    init();
    cachedLoyaltyPoints = widget.availableLoyaltyPoints;

  }


  void init({bool fromRefresh = false, bool forceUpdate = false}) {
    future = getLoyaltyHistory(
      loyaltyHistoryList: loyaltyHistoryList,
      page: page,
      lastPageCallBack: (p) {
        isLastPage = p;
      },
    ).then((list) async {

      cachedLoyaltyHistoryList = loyaltyHistoryList;
      if (mounted) setState(() {});

      return list;
    });

  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SnapHelperWidget<List<LoyaltyHistoryItem>>(
          initialData: cachedLoyaltyHistoryList,
          future: future,
          loadingWidget: ReferralLoyaltyShimmer(),
          onSuccess: (snap) {
            return AnimatedScrollView(
              children: [
                Container(
                  width: context.width(),
                  height: context.height() * 0.08,
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
                            Text(
                              language.lblAvailableLoyaltyPoints,
                              style: primaryTextStyle(color: whiteColor),
                            ),
                            4.height,
                            Row(
                              children: [
                                Image.asset(
                                  ic_coins,
                                  width: 24,
                                  height: 24,
                                ),
                                6.width,
                                Text(
                                 widget.availableLoyaltyPoints.toString(),
                                  style: boldTextStyle(
                                    size: 18,
                                    color: whiteColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: -20,
                        top:0,
                        bottom: -10,
                        child: Image.asset(ic_big_coins),
                      ),
                    ],
                  ),
                ),
                ViewAllLabel(
                  label: language.lblHistory,
                  onTap: () => ViewAllHistory().launch(context),
                ),
                AnimatedListView(
                  physics: const NeverScrollableScrollPhysics(),
                  listAnimationType: ListAnimationType.FadeIn,
                  fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
                  itemCount: snap.length,
                  emptyWidget: const NoDataWidget(
                    title: 'No History Found',
                    imageWidget: EmptyStateWidget(),
                  ),
                  shrinkWrap: true,
                  disposeScrollController: true,
                  itemBuilder: (BuildContext context, int index) {
                    LoyaltyHistoryItem data = snap[index];
                    return HistoryCard(data: data);
                  },
                ),
              ],
              onNextPage: () {
                if (!isLastPage) {
                  page++;
                  init(fromRefresh: true);
                  setState(() {});
                }
              },
              onSwipeRefresh: () async {
                page = 1;
                loyaltyHistoryList.clear();
                init(fromRefresh: true);
                await Future.wait([
                  future ?? Future.value([]),
                ]);
                if (mounted) setState(() {});
                return await 2.seconds.delay;
              },
            );
          },
          errorBuilder: (error) {
            return NoDataWidget(
              title: error,
              imageWidget: const ErrorStateWidget(),
              retryText: language.reload,
              onRetry: () {
                page = 1;
                appStore.setLoading(true);
                init(fromRefresh: true);
                setState(() {});
              },
            );
          },
        ),
        Observer(builder: (_) => LoaderWidget().visible(appStore.isLoading && page != 1),
        ),
      ],
    );
  }
}
