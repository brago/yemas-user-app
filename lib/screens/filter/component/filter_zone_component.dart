import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/zone_model.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../../component/empty_error_state_widget.dart';

class FilterServiceZoneComponent extends StatefulWidget {
  final List<ZoneModel> providerList;
  final bool showLoader;
  final Function(int? zoneId)? onZoneSelected;
  final int? initialSelectedZoneId;

  const FilterServiceZoneComponent({
    required this.providerList,
    this.showLoader = false,
    this.onZoneSelected,
    this.initialSelectedZoneId,
  });

  @override
  State<FilterServiceZoneComponent> createState() => _FilterServiceZoneComponentState();
}

class _FilterServiceZoneComponentState extends State<FilterServiceZoneComponent> {
  int? selectedZoneId;

  @override
  void initState() {
    super.initState();
    selectedZoneId = widget.initialSelectedZoneId;
  }

  @override
  void didUpdateWidget(FilterServiceZoneComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSelectedZoneId != widget.initialSelectedZoneId) {
      selectedZoneId = widget.initialSelectedZoneId;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.providerList.isEmpty && !appStore.isLoading) {
      return NoDataWidget(
        title: language.noProviderFound,
        imageWidget: const EmptyStateWidget(),
      );
    } else if (widget.showLoader) {
      return Observer(builder: (_) => LoaderWidget().visible(appStore.isLoading));
    }

    return AnimatedListView(
      slideConfiguration: sliderConfigurationGlobal,
      itemCount: widget.providerList.length,
      listAnimationType: ListAnimationType.FadeIn,
      fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
      itemBuilder: (context, index) {
        ZoneModel data = widget.providerList[index];

        return Container(
          padding: const EdgeInsets.all(8),
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: selectedZoneId == data.id ? context.cardColor : context.scaffoldBackgroundColor,
            borderRadius: radius(8),
            border: Border.all(
              color: selectedZoneId == data.id ? context.primaryColor : Colors.grey.withValues(alpha:0.3),
            ),
          ),
          child: Row(
            children: [
              Radio<int>(
                value: data.id.validate(),
                groupValue: selectedZoneId,
                activeColor: context.primaryColor,
                onChanged: (value) {
                  setState(() {
                    if (selectedZoneId == value) {
                      selectedZoneId = null;
                    } else {
                      selectedZoneId = value;
                    }
                  });
                  if (widget.onZoneSelected != null) {
                    widget.onZoneSelected!(selectedZoneId);
                  }
                },
              ),
              8.width,
              Text(
                data.name.validate(),
                style: primaryTextStyle(),
              ).expand(),
            ],
          ),
        ).onTap(() {
          setState(() {
            if (selectedZoneId == data.id) {
              selectedZoneId = null;
            } else {
              selectedZoneId = data.id.validate();
            }
          });
          if (widget.onZoneSelected != null) {
            widget.onZoneSelected!(selectedZoneId);
          }
        });
      },
    );
  }
}
