import 'package:booking_system_flutter/utils/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'dart:async';

class ShopImageSlider extends StatefulWidget {
  final List<String> imageList;

  const ShopImageSlider({Key? key, required this.imageList}) : super(key: key);

  @override
  State<ShopImageSlider> createState() => _ShopImageSliderState();
}

class _ShopImageSliderState extends State<ShopImageSlider> {
  PageController sliderPageController = PageController(initialPage: 0);
  int _currentPage = 0;
  bool _isForward = true;

  @override
  void initState() {
    super.initState();
    if (widget.imageList.length >= 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        autoScrollImages();
      });
    }
  }

  Future<void> autoScrollImages() async {
    int totalPages = widget.imageList.length;
    // Fixed 10 seconds duration for complete cycle
    int delaySeconds = (10 / totalPages).floor();

    while (mounted) {
      await Future.delayed(Duration(seconds: delaySeconds));

      if (!mounted || !sliderPageController.hasClients) return;

      if (_isForward) {
        if (_currentPage < totalPages - 1) {
          _currentPage++;
        } else {
          _isForward = false;
          _currentPage--;
        }
      } else {
        if (_currentPage > 0) {
          _currentPage--;
        } else {
          _isForward = true;
          _currentPage++;
        }
      }

      sliderPageController.animateToPage(
        _currentPage,
        duration: Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );

      setState(() {}); // Update DotIndicator
    }
  }

  @override
  void dispose() {
    sliderPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 205,
      width: context.width(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          PageView(
            controller: sliderPageController,
            children: widget.imageList.map((url) {
              return CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                width: context.width(),
                placeholder: (context, url) => Container(
                  color: grey300Color,
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: grey300Color,
                  child: Icon(Icons.image_not_supported, size: 50, color: greyColor),
                ),
              ).cornerRadiusWithClipRRect(16).paddingSymmetric(horizontal: 0);
            }).toList(),
            onPageChanged: (i) => setState(() => _currentPage = i),
          ),
          if (widget.imageList.length > 1)
            Positioned(
              bottom: -25,
              left: 0,
              right: 0,
              child: DotIndicator(
                pageController: sliderPageController,
                pages: widget.imageList,
                indicatorColor: primaryColor,
                unselectedIndicatorColor: primaryLightColor,
                currentBoxShape: BoxShape.rectangle,
                boxShape: BoxShape.rectangle,
                borderRadius: radius(2),
                currentBorderRadius: radius(3),
                currentDotSize: 18,
                currentDotWidth: 6,
                dotSize: 6,
              ),
            ),
          25.height,
        ],
      ),
    );
  }
}
