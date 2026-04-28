import 'package:flutter/material.dart';
import '../models/onboarding_model.dart';
import '../services/onboarding_service.dart';
import '../widgets/onboarding_slide_widget.dart';
import '../widgets/dot_indicator.dart';

class OnboardingPage extends StatefulWidget {
  final VoidCallback onFinished;

  const OnboardingPage({super.key, required this.onFinished});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final OnboardingService _service = OnboardingService();
  final PageController _pageController = PageController();

  List<OnboardingSlide> _slides = [];
  int _currentIndex = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSlides();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadSlides() async {
    try {
      final slides = await _service.fetchSlides();
      if (mounted) {
        setState(() {
          _slides = slides;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }

  void _goNext() {
    if (_currentIndex < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onFinished();
    }
  }

  bool get _isLastSlide => _currentIndex == _slides.length - 1;

  @override
  Widget build(BuildContext context) {
    // ── Loading ───────────────────────────────────────────────────────────────
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFEEF3FB),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ── Error ─────────────────────────────────────────────────────────────────
    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFEEF3FB),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 64, color: Color(0xFF8BA4C8)),
                const SizedBox(height: 16),
                const Text(
                  'Could not load content',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3A4E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF8BA4C8)),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _loading = true;
                      _error = null;
                    });
                    _loadSlides();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A8DDB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Retry', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ── Empty state ───────────────────────────────────────────────────────────
    if (_slides.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFEEF3FB),
        body: Center(
          child: ElevatedButton(
            onPressed: widget.onFinished,
            child: const Text('Continue'),
          ),
        ),
      );
    }

    // ── Main onboarding UI ────────────────────────────────────────────────────
    return Scaffold(
      backgroundColor: const Color(0xFFEEF3FB),
      body: SafeArea(
        child: Column(
          children: [
            // Top spacer — shifts slide content toward vertical center
            const SizedBox(height: 48),

            // Slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  return OnboardingSlideWidget(slide: _slides[index]);
                },
              ),
            ),

            // Dot indicators
            DotIndicator(
              count: _slides.length,
              currentIndex: _currentIndex,
            ),

            const SizedBox(height: 32),

            // CTA Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _goNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A8DDB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _isLastSlide ? 'ចាប់ផ្តើម' : 'បន្ទាប់',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}