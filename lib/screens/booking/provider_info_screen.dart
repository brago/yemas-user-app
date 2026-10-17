import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/component/user_info_widget.dart';
import 'package:booking_system_flutter/component/view_all_label_component.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/provider_info_response.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/dashboard/component/horizontal_shop_list_component.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../component/base_scaffold_widget.dart';
import '../../component/empty_error_state_widget.dart';
import '../../utils/colors.dart';
import '../../utils/common.dart';
import '../../utils/images.dart';
import '../service/view_all_service_screen.dart';
import 'component/handyman_staff_members_component.dart';
import 'component/provider_service_component.dart';

class ProviderInfoScreen extends StatefulWidget {
  final int? providerId;
  final bool canCustomerContact;
  final VoidCallback? onUpdate;
  final ServiceData? serviceData;

  ProviderInfoScreen({this.providerId, this.canCustomerContact = false, this.onUpdate, this.serviceData});

  @override
  ProviderInfoScreenState createState() => ProviderInfoScreenState();
}

class ProviderInfoScreenState extends State<ProviderInfoScreen> {
  Future<ProviderInfoResponse>? future;
  int page = 1;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    future = getProviderDetail(widget.providerId.validate(), userId: appStore.userId.validate());
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  Widget servicesWidget({required List<ServiceData> list, int? providerId}) {
    int totalServices = list.length;
    return Column(
      children: [
        ViewAllLabel(
          label: '${language.service} (${totalServices})',
          list: list,
          onTap: () {
            ViewAllServiceScreen(providerId: providerId).launch(context, pageRouteAnimation: PageRouteAnimation.Fade);
          },
        ),
        if (list.isEmpty) NoDataWidget(title: language.lblNoServicesFound, imageWidget: const EmptyStateWidget()),
        if (list.isNotEmpty)
          AnimatedWrap(
            spacing: 16,
            runSpacing: 16,
            itemCount: list.length,
            listAnimationType: ListAnimationType.FadeIn,
            fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
            scaleConfiguration: ScaleConfiguration(duration: 300.milliseconds, delay: 50.milliseconds),
            itemBuilder: (_, index) => ProviderServiceComponent(serviceData: list[index], isFromProviderInfo: true),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: language.lblAboutProvider,
      showLoader: false,
      child: SafeArea(
        top: false,
        child: Scaffold(
          body: SnapHelperWidget<ProviderInfoResponse>(
            future: future,
            initialData: cachedProviderList.firstWhere((element) => element?.$1 == widget.providerId.validate(), orElse: () => null)?.$2,
            onSuccess: (data) {
              return Stack(
                children: [
                  AnimatedScrollView(
                    padding: EdgeInsets.only(bottom: 60),
                    listAnimationType: ListAnimationType.FadeIn,
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      UserInfoWidget(
                        data: data.userData!,
                        isOnTapEnabled: true,
                        onUpdate: () {
                          widget.onUpdate?.call();
                        },
                      ),
                      16.height,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (data.userData!.knownLanguagesArray.isNotEmpty) ...[
                            16.height,
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(language.knownLanguages, style: boldTextStyle()).paddingSymmetric(horizontal: 16),
                                8.height,
                                Wrap(
                                  children: data.userData!.knownLanguagesArray.map((e) {
                                    return Container(
                                      decoration: boxDecorationWithRoundedCorners(
                                        borderRadius: const BorderRadius.all(Radius.circular(20)),
                                        backgroundColor: appStore.isDarkMode ? cardDarkColor : primaryColor.withValues(alpha: 0.1),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      margin: const EdgeInsets.only(right: 8, bottom: 8),
                                      child: Text(e, style: secondaryTextStyle(weight: FontWeight.bold)),
                                    );
                                  }).toList(),
                                ).paddingSymmetric(
                                  horizontal: 16,
                                ),
                              ],
                            ),
                            16.height,
                          ],
                          if (data.userData!.skillsArray.isNotEmpty) ...[
                            16.height,
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(language.essentialSkills, style: boldTextStyle()).paddingSymmetric(horizontal: 16),
                                8.height,
                                Wrap(
                                  children: data.userData!.skillsArray.map((e) {
                                    return Container(
                                      decoration: boxDecorationWithRoundedCorners(
                                        borderRadius: const BorderRadius.all(Radius.circular(20)),
                                        backgroundColor: appStore.isDarkMode ? cardDarkColor : primaryColor.withValues(alpha: 0.1),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      margin: const EdgeInsets.only(right: 8),
                                      child: Text(e, style: secondaryTextStyle(weight: FontWeight.bold)),
                                    );
                                  }).toList(),
                                ).paddingSymmetric(horizontal: 16),
                                16.height,
                              ],
                            ),
                            16.height,
                          ],
                          if (widget.canCustomerContact) ...[
                            16.height,
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(language.personalInfo, style: boldTextStyle()).paddingSymmetric(horizontal: 16),
                                8.height,
                                TextIcon(
                                  spacing: 10,
                                  onTap: () {
                                    launchMail("${data.userData!.email.validate()}");
                                  },
                                  prefix: Image.asset(ic_message, width: 16, height: 16, color: appStore.isDarkMode ? Colors.white : context.primaryColor),
                                  text: data.userData!.email.validate(),
                                  textStyle: secondaryTextStyle(size: 14),
                                  expandedText: true,
                                ).paddingSymmetric(horizontal: 16),
                                4.height,
                                TextIcon(
                                  spacing: 10,
                                  onTap: () {
                                    launchCall("${data.userData!.contactNumber.validate()}");
                                  },
                                  prefix: Image.asset(ic_calling, width: 16, height: 16, color: appStore.isDarkMode ? Colors.white : context.primaryColor),
                                  text: data.userData!.contactNumber.validate(),
                                  textStyle: secondaryTextStyle(size: 14),
                                  expandedText: true,
                                ).paddingSymmetric(horizontal: 16),
                                24.height,
                              ],
                            ),
                            16.height,
                          ],
                          HandymanStaffMembersComponent(
                            handymanList: data.handymanStaffList.validate(),
                          ),
                          if (data.shops != null && data.shops!.isNotEmpty) ...[
                            16.height,
                            HorizontalShopListComponent(
                              shopList: data.shops!.take(5).toList(),
                              listTitle: '${language.lblShop} (${data.shops!.length})',
                              providerId: widget.providerId.validate(),
                              providerName: data.userData!.displayName.validate(),
                            ),
                          ],
                          servicesWidget(
                            list: data.serviceList!.take(6).toList(),
                            providerId: widget.providerId.validate(),
                          ).paddingSymmetric(horizontal: 16),
                        ],
                      ),
                    ],
                    onSwipeRefresh: () async {
                      page = 1;

                      init();
                      setState(() {});

                      return await 2.seconds.delay;
                    },
                  ),
                  Observer(builder: (context) => LoaderWidget().visible(appStore.isLoading)),
                ],
              );
            },
            loadingWidget: LoaderWidget(),
            errorBuilder: (error) {
              return NoDataWidget(
                title: error,
                imageWidget: const ErrorStateWidget(),
                retryText: language.reload,
                onRetry: () {
                  page = 1;
                  appStore.setLoading(true);

                  init();
                  setState(() {});
                },
              );
            },
          ),
        ),
      ),
    );
  }
}