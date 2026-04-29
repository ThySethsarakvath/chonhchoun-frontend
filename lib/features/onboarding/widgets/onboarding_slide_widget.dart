import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/onboarding_model.dart';

class OnboardingSlideWidget extends StatelessWidget {
  final OnboardingSlide slide;

  const OnboardingSlideWidget({super.key, required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // ── Image area ─────────────────────────────────────────────────────
          Expanded(
            flex: 6,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: slide.imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF4A8DDB),
                    strokeWidth: 2,
                  ),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.broken_image_rounded,
                  size: 80,
                  color: Color(0xFF8BA4C8),
                ),
              ),
            ),
          ),

          // ── Text area ──────────────────────────────────────────────────────
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  slide.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E2D3D),
                    height: 1.35,
                  ),
                ),
                if (slide.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    slide.subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF8BA4C8),
                      height: 1.55,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}