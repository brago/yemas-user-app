import 'package:booking_system_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class HistoryHeaderComponent extends StatefulWidget {
  final Function(String)? onFilterChanged;
  final String initialFilterKey;

  const HistoryHeaderComponent({super.key, this.onFilterChanged, this.initialFilterKey = 'last_week'});

  @override
  State<HistoryHeaderComponent> createState() => _HistoryHeaderComponentState();
}

class _HistoryHeaderComponentState extends State<HistoryHeaderComponent> {
  static const Map<String, String> _filterLabels = {
    'last_week': 'Last Week',
    'last_month': 'Last Month',
    'last_year': 'Last Year',
  };

  late String selectedFilterKey;

  @override
  void initState() {
    super.initState();
    selectedFilterKey = _filterLabels.keys.contains(widget.initialFilterKey) ? widget.initialFilterKey : 'last_week';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          language.lblHistory,
          style: boldTextStyle(size: 18),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: boxDecorationDefault(color: context.cardColor),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedFilterKey,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
              style: primaryTextStyle(),
              borderRadius: radius(12),
              dropdownColor: context.cardColor,
              items: _filterLabels.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value, style: primaryTextStyle(size: 14)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => selectedFilterKey = value);
                  widget.onFilterChanged?.call(value);
                }
              },
            ),
          ),
        ),
      ],
    ).paddingOnly(right: 16, left: 16, top: 8);
  }
}
