import 'package:booking_system_flutter/component/base_scaffold_widget.dart';
import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/store/filter_store.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../component/cached_image_widget.dart';
import '../../component/empty_error_state_widget.dart';
import '../../main.dart';
import '../../model/category_model.dart';
import '../../model/service_data_model.dart';
import '../../network/rest_apis.dart';
import '../../utils/common.dart';
import '../../utils/constant.dart';
import '../../utils/images.dart';
import '../../utils/search_intent.dart';
import '../booking/component/provider_service_component.dart';
import '../dashboard/component/category_widget.dart';
import '../filter/filter_screen.dart';
import 'view_all_service_screen.dart';

/// Service search: speak or type what you need at the top, or pick a category
/// from the catalogue at the bottom. Results are limited to the user's area
/// when their location is on.
class SearchServiceScreen extends StatefulWidget {
  final List<ServiceData>? featuredList;
  final String search;

  /// Opens the screen with the microphone already listening.
  final bool startListening;

  SearchServiceScreen({Key? key, this.featuredList, this.search = "", this.startListening = false}) : super(key: key);

  @override
  State<SearchServiceScreen> createState() => _SearchServiceScreenState();
}

class _SearchServiceScreenState extends State<SearchServiceScreen> {
  // The app's audience is French-speaking; these texts are French only.
  static const _title = 'Que recherchez-vous ?';
  static const _hint = "Ex. : j'ai besoin d'un plombier";
  static const _tapToSpeak = 'Touchez le micro et dites ce dont vous avez besoin';
  static const _listening = 'Je vous écoute…';
  static const _typeInstead = 'Écrivez simplement ce que vous cherchez';
  static const _pickCategory = 'Ou choisissez directement';
  static const _locationOn = 'Prestataires près de : ';
  static const _locationOff = 'Activer ma position pour voir les prestataires proches';
  static const _resultsFor = 'Résultats pour';
  static const _noResultTitle = 'Aucun service trouvé';
  static const _noResultHint = 'Essayez avec un autre mot, ou choisissez une catégorie ci-dessous.';

  final SpeechToText speech = SpeechToText();
  bool speechAvailable = false;
  bool isListening = false;
  String? frenchLocaleId;

  final TextEditingController searchCont = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  List<CategoryData> categories = [];
  Future<List<CategoryData>>? futureCategories;

  Future<List<ServiceData>>? futureService;
  List<ServiceData> serviceList = [];
  int page = 1;
  bool isLastPage = false;

  /// What the last search was understood as.
  String lastQuery = '';
  SearchIntent intent = const SearchIntent();

  bool get hasSearch => lastQuery.isNotEmpty || isFilterApplied;

  bool get isFilterApplied {
    return filterStore.providerId.isNotEmpty || filterStore.handymanId.isNotEmpty || filterStore.ratingId.isNotEmpty || filterStore.categoryId.isNotEmpty || filterStore.isPriceMax.isNotEmpty || filterStore.isPriceMin.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    filterStore = FilterStore();
    futureCategories = loadCategories();
    initSpeech();

    if (widget.search.isNotEmpty) {
      searchCont.text = widget.search;
      runSearch(widget.search);
    }
  }

  Future<List<CategoryData>> loadCategories() async {
    final res = await getCategoryList('1');
    categories = res.categoryList.validate();
    setState(() {});
    return categories;
  }

  //region Voice
  Future<void> initSpeech() async {
    try {
      speechAvailable = await speech.initialize(onError: onSpeechError, onStatus: onSpeechStatus);
      if (speechAvailable) {
        final locales = await speech.locales();
        frenchLocaleId = locales.firstWhere((l) => l.localeId.toLowerCase().startsWith('fr'), orElse: () => locales.isNotEmpty ? locales.first : LocaleName('', '')).localeId;
      }
    } catch (e) {
      speechAvailable = false;
    }
    setState(() {});

    if (speechAvailable && widget.startListening) startListening();
  }

  void startListening() {
    if (!speechAvailable) return;
    hideKeyboard(context);
    isListening = true;
    setState(() {});

    speech.listen(
      onResult: onSpeechResult,
      localeId: frenchLocaleId.validate().isEmpty ? null : frenchLocaleId,
      listenFor: const Duration(seconds: 20),
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(partialResults: true, cancelOnError: true, listenMode: ListenMode.search),
    );
  }

  void stopListening() {
    speech.stop();
    isListening = false;
    setState(() {});
  }

  void onSpeechResult(SpeechRecognitionResult result) {
    searchCont.text = result.recognizedWords;
    if (result.finalResult) {
      isListening = false;
      runSearch(result.recognizedWords);
    }
    setState(() {});
  }

  void onSpeechStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      isListening = false;
      setState(() {});
    }
  }

  void onSpeechError(SpeechRecognitionError error) {
    isListening = false;
    setState(() {});
  }
  //endregion

  //region Search
  Future<void> runSearch(String text) async {
    hideKeyboard(context);
    if (categories.isEmpty) await futureCategories?.catchError((_) => <CategoryData>[]);

    lastQuery = text.trim();
    intent = understandSearch(lastQuery, categories);
    page = 1;
    serviceList = [];

    if (lastQuery.isEmpty && !isFilterApplied) {
      futureService = null;
      setState(() {});
      return;
    }

    appStore.setLoading(true);
    fetchServices();
    setState(() {});
  }

  void fetchServices() {
    final category = intent.category;
    futureService = searchServiceAPI(
      page: page,
      list: serviceList,
      // A recognised category shows all its services; otherwise search the useful words.
      categoryId: category != null ? category.id.toString() : filterStore.categoryId.join(','),
      search: category != null ? '' : (intent.keywords.isNotEmpty ? intent.keywords : lastQuery),
      providerId: filterStore.providerId.join(','),
      isPriceMin: filterStore.isPriceMin,
      isPriceMax: filterStore.isPriceMax,
      ratingId: filterStore.ratingId.join(','),
      latitude: filterStore.latitude,
      longitude: filterStore.longitude,
      lastPageCallBack: (p0) => isLastPage = p0,
    );
  }

  void clearSearch() {
    searchCont.clear();
    lastQuery = '';
    intent = const SearchIntent();
    futureService = null;
    serviceList = [];
    setState(() {});
  }
  //endregion

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    speech.cancel();
    filterStore.clearFilters();
    searchFocusNode.dispose();
    filterStore.setSelectedSubCategory(catId: 0);
    super.dispose();
  }

  //region Widgets
  Widget micButton() {
    return GestureDetector(
      onTap: isListening ? stopListening : startListening,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.all(isListening ? 10 : 0),
        decoration: BoxDecoration(shape: BoxShape.circle, color: context.primaryColor.withValues(alpha: isListening ? 0.18 : 0)),
        child: Container(
          height: 84,
          width: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.primaryColor,
            boxShadow: [BoxShadow(color: context.primaryColor.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 6))],
          ),
          child: Icon(isListening ? Icons.stop_rounded : Icons.mic_rounded, color: Colors.white, size: 42),
        ),
      ),
    );
  }

  Widget locationChip() {
    return Observer(builder: (context) {
      final bool on = appStore.isCurrentLocation;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(on ? Icons.location_on : Icons.location_off_outlined, size: 18, color: on ? context.primaryColor : context.iconColor),
          6.width,
          Text(
            on ? '$_locationOn${getStringAsync(CURRENT_ADDRESS)}' : _locationOff,
            style: secondaryTextStyle(size: 12, color: on ? null : context.primaryColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ).flexible(),
        ],
      ).paddingSymmetric(horizontal: 12, vertical: 8).onTap(() {
        locationWiseService(context, () {
          if (hasSearch) runSearch(lastQuery);
        });
      }, borderRadius: radius());
    });
  }

  Widget topPanel() {
    return Container(
      width: context.width(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: 0.06),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        children: [
          if (speechAvailable) ...[
            micButton(),
            12.height,
            Text(isListening ? _listening : _tapToSpeak, style: secondaryTextStyle(), textAlign: TextAlign.center),
            16.height,
          ] else ...[
            Text(_typeInstead, style: secondaryTextStyle(), textAlign: TextAlign.center),
            12.height,
          ],
          Row(
            children: [
              AppTextField(
                textFieldType: TextFieldType.OTHER,
                controller: searchCont,
                focus: searchFocusNode,
                textInputAction: TextInputAction.search,
                onChanged: (_) => setState(() {}),
                onFieldSubmitted: runSearch,
                decoration: inputDecoration(context).copyWith(
                  hintText: _hint,
                  hintStyle: secondaryTextStyle(),
                  prefixIcon: ic_search.iconImage(size: 10).paddingAll(14),
                  suffixIcon: searchCont.text.isNotEmpty ? CloseButton(onPressed: clearSearch) : null,
                ),
              ).expand(),
              12.width,
              Container(
                padding: const EdgeInsets.all(10),
                decoration: boxDecorationDefault(color: context.primaryColor),
                child: const CachedImageWidget(url: ic_filter, height: 26, width: 26, color: Colors.white),
              ).onTap(() {
                hideKeyboard(context);
                FilterScreen(isFromProvider: true, isFromCategory: false).launch(context).then((value) {
                  if (value != null) runSearch(searchCont.text);
                });
              }, borderRadius: radius()),
            ],
          ),
          4.height,
          locationChip(),
        ],
      ),
    );
  }

  Widget categoryCatalogue() {
    return SnapHelperWidget<List<CategoryData>>(
      future: futureCategories,
      loadingWidget: LoaderWidget(),
      errorBuilder: (error) => NoDataWidget(title: error, imageWidget: const ErrorStateWidget(), retryText: language.reload, onRetry: () {
        futureCategories = loadCategories();
        setState(() {});
      }),
      onSuccess: (list) {
        final double itemWidth = (context.width() - 32 - 2 * 12) / 3;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_pickCategory, style: boldTextStyle(size: LABEL_TEXT_SIZE)),
            16.height,
            Wrap(
              spacing: 12,
              runSpacing: 16,
              children: list.map((category) {
                return GestureDetector(
                  onTap: () => ViewAllServiceScreen(categoryId: category.id.validate(), categoryName: category.name, isFromCategory: true).launch(context),
                  child: CategoryWidget(categoryData: category, width: itemWidth),
                );
              }).toList(),
            ),
          ],
        ).paddingAll(16);
      },
    );
  }

  Widget resultsHeader() {
    return Row(
      children: [
        Text('$_resultsFor « $lastQuery »', style: boldTextStyle(size: LABEL_TEXT_SIZE), maxLines: 2, overflow: TextOverflow.ellipsis).expand(),
        if (intent.category != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: boxDecorationDefault(color: context.primaryColor.withValues(alpha: 0.12), borderRadius: radius(20)),
            child: Text(intent.category!.name.validate(), style: boldTextStyle(size: 12, color: context.primaryColor)),
          ),
      ],
    ).paddingSymmetric(horizontal: 16, vertical: 12);
  }

  Widget results() {
    return SnapHelperWidget<List<ServiceData>>(
      future: futureService,
      loadingWidget: appStore.isLoading ? const Offstage() : LoaderWidget(),
      errorBuilder: (error) => NoDataWidget(title: error, retryText: language.reload, imageWidget: const ErrorStateWidget(), onRetry: () => runSearch(lastQuery)),
      onSuccess: (data) {
        if (serviceList.isEmpty) {
          return Column(
            children: [
              NoDataWidget(title: _noResultTitle, subTitle: _noResultHint, imageWidget: const EmptyStateWidget()).paddingSymmetric(vertical: 16),
              categoryCatalogue(),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (lastQuery.isNotEmpty) resultsHeader(),
            AnimatedListView(
              itemCount: serviceList.length,
              listAnimationType: ListAnimationType.FadeIn,
              fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemBuilder: (_, index) => ProviderServiceComponent(serviceData: serviceList[index]).paddingAll(8),
            ).paddingSymmetric(horizontal: 8),
          ],
        );
      },
    );
  }
  //endregion

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => hideKeyboard(context),
      child: AppScaffold(
        appBarTitle: _title,
        child: Column(
          children: [
            topPanel(),
            AnimatedScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              onSwipeRefresh: () {
                if (hasSearch) runSearch(lastQuery);
                return Future.value(false);
              },
              onNextPage: () {
                if (hasSearch && !isLastPage) {
                  page++;
                  appStore.setLoading(true);
                  fetchServices();
                  setState(() {});
                }
              },
              children: [
                hasSearch && futureService != null ? results() : categoryCatalogue(),
              ],
            ).expand(),
          ],
        ),
      ),
    );
  }
}
