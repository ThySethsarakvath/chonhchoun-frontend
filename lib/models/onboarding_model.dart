class OnboardingSlide {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final int order;
  final bool isActive;

  const OnboardingSlide({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.order,
    required this.isActive,
  });

  factory OnboardingSlide.fromJson(Map<String, dynamic> json) {
    return OnboardingSlide(
      id: json['_id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String? ?? '',
      imageUrl: json['imageUrl'] as String,
      order: json['order'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}