import 'package:booking_system_flutter/component/base_scaffold_widget.dart';
import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../component/empty_error_state_widget.dart';
import '../../network/rest_apis.dart';
import 'component/history_card.dart';
import 'component/history_header_component.dart';
import 'model/loyalty_history_model.dart';

class ViewAllHistory extends StatefulWidget {
  const ViewAllHistory({super.key});

  @override
  State<ViewAllHistory> createState() => _ViewAllHistoryState();
}

class _ViewAllHistoryState extends State<ViewAllHistory> {
  Future<List<LoyaltyHistoryItem>>? future;
  List<LoyaltyHistoryItem> historyList = [];

  int page = 1;
  bool isLastPage = false;
  String selectedFilter = 'last_week';

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() {
    future = getLoyaltyHistory(
      page: page,
      filter: selectedFilter,
      loyaltyHistoryList: historyList,
      lastPageCallBack: (p) {
        isLastPage = p;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: language.lblHistory,
      child: Column(
        children: [
          HistoryHeaderComponent(
            initialFilterKey: selectedFilter,
            onFilterChanged: (filterKey) {
              page = 1;
              selectedFilter = filterKey;
              init();
              setState(() {});
            },
          ),
          SnapHelperWidget<List<LoyaltyHistoryItem>>(
            future: future,
            loadingWidget: LoaderWidget(),
            onSuccess: (list) {
              return AnimatedScrollView(
                onSwipeRefresh: () async {
                  page = 1;
                  init();
                  setState(() {});
                  return await 2.seconds.delay;
                },
                onNextPage: () {
                  if (!isLastPage) {
                    page++;
                    init();
                    setState(() {});
                  }
                },
                children: [
                  AnimatedListView(
                    itemCount: list.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    listAnimationType: ListAnimationType.FadeIn,
                    fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
                    emptyWidget: NoDataWidget(
                      title: 'No History Found',
                      imageWidget: const EmptyStateWidget(),
                    ),
                    itemBuilder: (context, index) {
                      LoyaltyHistoryItem value = list[index];
                      return HistoryCard(data: value);
                    },
                  ),
                ],
              );
            },
          ).paddingOnly(right: 16, left: 16, top: 16).expand(),
        ],
      ),
    );
  }
}
