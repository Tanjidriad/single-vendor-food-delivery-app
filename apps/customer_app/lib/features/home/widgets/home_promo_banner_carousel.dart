import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/home_promo_banner_layout.dart';

import '../../../core/utils/responsive/app_responsive.dart';
import '../../../core/widgets/feedback/app_smooth_page_indicator.dart';
import 'home_promo_slide_card.dart';

/// Uber Eats–style promo carousel: peeking rounded cards, autoplay, worm dots.
class HomePromoBannerCarousel extends StatefulWidget {
  const HomePromoBannerCarousel({
    super.key,
    required this.banners,
    this.onBannerTap,
    this.onDefaultTap,
  });

  final List<Map<String, dynamic>> banners;
  final void Function(Map<String, dynamic> banner)? onBannerTap;
  final VoidCallback? onDefaultTap;

  @override
  State<HomePromoBannerCarousel> createState() => _HomePromoBannerCarouselState();
}

class _HomePromoBannerCarouselState extends State<HomePromoBannerCarousel> {
  final _carouselController = CarouselSliderController();
  int _index = 0;

  List<Map<String, dynamic>> get _slides {
    if (widget.banners.isEmpty) return const [];
    return widget.banners.cast<Map<String, dynamic>>();
  }

  void _onSlideTap(Map<String, dynamic> slide, bool fromApi) {
    if (fromApi && widget.onBannerTap != null) {
      widget.onBannerTap!(slide);
    } else {
      widget.onDefaultTap?.call();
    }
  }

  _SlideData _parseSlide(Map<String, dynamic> slide, int index) {
    final fromApi = index < widget.banners.length;
    final bg = slide['backgroundColor'];
    const fallbackColor = 0xFFE8E4F8;

    return _SlideData(
      title: slide['title'] as String? ??
          slide['headline'] as String? ??
          'Special offer just for you',
      ctaLabel: slide['ctaLabel'] as String? ?? 'Browse offer',
      backgroundColor: Color(bg is int ? bg : fallbackColor),
      imageUrl: _imageUrlFor(slide, index),
      raw: slide,
      fromApi: fromApi,
    );
  }

  String? _imageUrlFor(Map<String, dynamic> slide, int index) {
    final url = slide['imageUrl'] as String?;
    if (url != null && url.trim().isNotEmpty) return url.trim();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final slides = _slides;
    if (slides.isEmpty) return const SizedBox.shrink();

    final multiple = slides.length > 1;
    final pagePadding = AppResponsive.pagePadding(context);
    final height = HomePromoBannerLayout.cardHeight;

    return Column(
      children: [
        CarouselSlider.builder(
          carouselController: _carouselController,
          itemCount: slides.length,
          options: CarouselOptions(
            height: height,
            viewportFraction: HomePromoBannerLayout.viewportFraction,
            padEnds: false,
            enableInfiniteScroll: multiple,
            autoPlay: multiple,
            autoPlayInterval: const Duration(seconds: 4),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.easeInOutCubic,
            scrollPhysics: const BouncingScrollPhysics(),
            onPageChanged: (index, _) => setState(() => _index = index),
          ),
          itemBuilder: (context, index, _) {
            final slide = _parseSlide(slides[index], index);
            final isFirst = index == 0;
            final isLast = index == slides.length - 1;

            return Padding(
              padding: EdgeInsets.only(
                left: isFirst ? pagePadding : HomePromoBannerLayout.slideGap / 2,
                right: isLast ? pagePadding : HomePromoBannerLayout.slideGap / 2,
              ),
              child: HomePromoSlideCard(
                title: slide.title,
                imageUrl: slide.imageUrl,
                backgroundColor: slide.backgroundColor,
                ctaLabel: slide.ctaLabel,
                onTap: () => _onSlideTap(slide.raw, slide.fromApi),
                onCtaTap: () => _onSlideTap(slide.raw, slide.fromApi),
              ),
            );
          },
        ),
        if (multiple) ...[
          const SizedBox(height: AppSpacing.md),
          AppSmoothPageIndicator(
            activeIndex: _index,
            count: slides.length,
            onDotClicked: (i) => _carouselController.animateToPage(i),
          ),
        ],
      ],
    );
  }
}

class _SlideData {
  const _SlideData({
    required this.title,
    required this.ctaLabel,
    required this.backgroundColor,
    required this.imageUrl,
    required this.raw,
    required this.fromApi,
  });

  final String title;
  final String ctaLabel;
  final Color backgroundColor;
  final String? imageUrl;
  final Map<String, dynamic> raw;
  final bool fromApi;
}
