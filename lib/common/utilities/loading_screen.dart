import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:locally/common/utilities/spotlight_painter.dart';

class SpotlightLoadingWidget extends StatefulWidget {
  const SpotlightLoadingWidget({
    super.key,
    this.highlightColor = Colors.deepOrange,
    this.faintColor = Colors.grey,
  });

  final Color highlightColor; // Color for the highlighted icon
  final Color faintColor; // Color for non-highlighted icons

  @override
  _SpotlightLoadingWidgetState createState() => _SpotlightLoadingWidgetState();
}

class _SpotlightLoadingWidgetState extends State<SpotlightLoadingWidget> {
  final List<IconData> _groceryIcons = [
    Icons.shopping_basket,
    Icons.egg,
    Icons.cake,
    Icons.bakery_dining,
    Icons.local_drink,
    Icons.delivery_dining,
    Icons.local_pizza_outlined,
    Icons.local_grocery_store,
  ];

  late PageController _pageController;
  late Timer _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(
      viewportFraction: 0.4,
      initialPage: _currentPage,
    );

    _timer = Timer.periodic(const Duration(milliseconds: 500), (Timer timer) {
      if (!mounted) return;

      if (_currentPage < _groceryIcons.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _groceryIcons.length,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double page = 0;
                  if (_pageController.hasClients &&
                      _pageController.position.haveDimensions) {
                    page = _pageController.page ?? 0;
                  }
                  double distance = (page - index).abs().clamp(0.0, 1.0);
                  // Blend between highlight and faint color based on distance
                  Color iconColor = Color.lerp(
                    widget.highlightColor,
                    widget.faintColor,
                    distance,
                  )!;

                  double scale = (1 - (distance * 0.3)).clamp(0.7, 1.3);
                  double opacity = (1 - (distance * 0.6)).clamp(0.3, 1.0);

                  return Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: opacity,
                      child: Icon(
                        _groceryIcons[index],
                        size: 80,
                        color: iconColor,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        // --- Torch / Spotlight ---
        IgnorePointer(
          child: Align(
            alignment: Alignment.topCenter,
            child: ShaderMask(
              shaderCallback: (rect) {
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Colors.transparent,
                  ],
                  stops: const [0.0, 1.0],
                ).createShader(rect);
              },
              blendMode: BlendMode.dstIn,
              child: CustomPaint(
                size: Size(
                  double.infinity,
                  MediaQuery.of(context).size.height,
                ),
                painter: SpotlightPainter(),
              ),
            ),
          ),
        ),

        // --- Loading Text ---
        Positioned(
          bottom: 150,
          child: Column(
            children: [
              const CircularProgressIndicator(color: Colors.green),
              const SizedBox(height: 20),
              Text(
                "Loading fresh items...",
                style: GoogleFonts.manrope(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                  letterSpacing: 1.2,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
