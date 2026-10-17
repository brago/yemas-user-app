import 'package:booking_system_flutter/screens/booking/booking_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../model/loyalty_history_model.dart';

class HistoryCard extends StatelessWidget {
  final LoyaltyHistoryItem data;

  const HistoryCard({super.key, required this.data});


  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: boxDecorationWithRoundedCorners(
        backgroundColor: context.cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              data.type == 'referral'
                  ? const Text("Refferal Bonus")
                  : Text(
                      "${data.description}"
                      "${data.type == 'referral' ? '' : ' #${data.bookingId}'}",
                      style: primaryTextStyle(),
                    ).expand(),
              Row(
                children: [
                  Text(
                    data.status == "credit" ? "+" : "-",
                    style: boldTextStyle(
                      color: data.status == "credit" ? Colors.green : Colors.red,
                      size: 15,
                    ),
                  ),
                  Text(
                    "${data.points}",
                    style: boldTextStyle(
                      color: data.status == "credit" ? Colors.green : Colors.red,
                      size: 15,
                    ),
                  ),
                ],
              ),
            ],
          ),
          6.height,
          Text(
            "${data.createdAt}",
            // formatBookingDate(data.createdAt, format: DATE_FORMAT_1),
            style: secondaryTextStyle(size: 12),
          ),
        ],
      ),
    ).onTap(() async {
      if (data.bookingId != -1 && data.type != "referral") {
        await BookingDetailScreen(bookingId: data.bookingId).launch(context);
      }
    },);
  }
}
