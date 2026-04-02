import 'package:flutter/material.dart';
// 1. Import the new onboarding screen (we will create it next)
import 'onboarding_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ជញ្ជូន',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2C5F8A)),
        useMaterial3: true,
      ),
      home: const LandingPage(),
    );
  }
}

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _fadeInController;

  late Animation<double> _carPositionAnim;
  late Animation<double> _speedLineOpacity;
  late Animation<double> _bgFadeAnim;

  final GlobalKey _textKey = GlobalKey();
  double _textWidth = 0;
  double _textLeft = 0;

  // REMOVED: _showButtons state variable is gone

  static const double _carSize = 64.0;
  static const double _gap = 10.0;

  @override
  void initState() {
    super.initState();

    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _bgFadeAnim = CurvedAnimation(
      parent: _fadeInController,
      curve: Curves.easeIn,
    );

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _carPositionAnim = Tween<double>(begin: -1.7, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: Curves.easeOutCubic,
      ),
    );

    _speedLineOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 65),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 25),
    ]).animate(_mainController);

    _fadeInController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureText();
      
      // 2. MODIFIED: The callback no longer shows buttons.
      // It automatically navigates when the animation finishes.
      _mainController.forward().then((_) {
        if (mounted) {
          // Navigates to the Onboarding Flow and clears the back stack.
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          );
        }
      });
    });
  }

  void _measureText() {
    final RenderBox? box =
        _textKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      final Offset position = box.localToGlobal(Offset.zero);
      setState(() {
        _textWidth = box.size.width;
        _textLeft = position.dx;
      });
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _fadeInController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF2C5F8A),
      body: FadeTransition(
        opacity: _bgFadeAnim,
        child: Stack(
          children: [
            // ── Background gradient ──────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1E4D73),
                    Color(0xFF2C6B9E),
                    Color(0xFF1A4A6B),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // ── Center row (Your Animation) ──────────────────────────────
            Center(
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (context, _) {
                  final double carOffset =
                      _carPositionAnim.value * screenWidth;
                  final double rowWidth = _textWidth + _gap + _carSize;
                  final double rowLeft = screenWidth / 2 - rowWidth / 2;
                  final double carLeftOnScreen =
                      rowLeft + _textWidth + _gap + carOffset;
                  final double carRightOnScreen = carLeftOnScreen + _carSize;
                  final double revealedPx =
                      (carRightOnScreen - _textLeft).clamp(0.0, _textWidth);
                  final double widthFactor =
                      _textWidth > 0 ? revealedPx / _textWidth : 0.0;

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipRect(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          widthFactor: widthFactor,
                          child: Text(
                            'ជញ្ជូន',
                            key: _textKey,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: _gap),
                      Transform.translate(
                        offset: Offset(carOffset, 0),
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              left: -54,
                              child: Opacity(
                                opacity: _speedLineOpacity.value,
                                child: _buildSpeedLines(),
                              ),
                            ),
                            Image.asset(
                              'assets/images/logo.png',
                              width: _carSize,
                              height: _carSize,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // REMOVED: NEW: Unified Auth Navigation Button block is gone

            // ── City footer ──────────────────────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Image.asset(
                'assets/images/footer.png',
                width: screenWidth,
                fit: BoxFit.fitWidth,
                alignment: Alignment.bottomCenter,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedLines() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        _speedLine(38),
        const SizedBox(height: 5),
        _speedLine(26),
        const SizedBox(height: 5),
        _speedLine(34),
      ],
    );
  }

  Widget _speedLine(double width) {
    return Container(
      width: width,
      height: 2.5,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}