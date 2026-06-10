enum DeliveryStatus {
  pending,
  inTransit,
  arrived,
  delivered,
}

extension DeliveryStatusLabel on DeliveryStatus {
  String get label {
    switch (this) {
      case DeliveryStatus.pending:
        return 'កំពុងរង់ចាំ';
      case DeliveryStatus.inTransit:
        return 'កំពុងដឹកជញ្ជូន';
      case DeliveryStatus.arrived:
        return 'បានមកដល់';
      case DeliveryStatus.delivered:
        return 'បានដឹកជញ្ជូន';
    }
  }
}

class TrackingPoint {
  final String label;
  final bool completed;

  const TrackingPoint({required this.label, required this.completed});
}

class DeliveryItem {
  final String id;
  final String trackingNumber;
  final DeliveryStatus status;
  final String date;        // e.g. "24 មករា"
  final String origin;      // e.g. "ភ្នំពេញ, ទឹកថ្លា"
  final String destination; // e.g. "បាត់ដំបង, វត្តលៀប"
  final List<TrackingPoint> checkpoints;

  const DeliveryItem({
    required this.id,
    required this.trackingNumber,
    required this.status,
    required this.date,
    required this.origin,
    required this.destination,
    required this.checkpoints,
  });
}

class PromoBanner {
  final String title;
  final String subtitle;
  final String imagePath;   // local asset path
  final String backgroundColor; // hex string for parsing
  
  const PromoBanner({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.backgroundColor,
  });
}

class HomeData {
  static const List<PromoBanner> banners = [
    PromoBanner(
      title: 'Buy GPS',
      subtitle: 'Liveasy GPS system allows you to track your vehicles from the app.',
      imagePath: 'assets/images/banner_gps.png',
      backgroundColor: '#2C5F8A',
    ),
    PromoBanner(
      title: 'Refer and earn',
      subtitle: 'Refer Liveasy to earn money on account',
      imagePath: 'assets/images/banner_refer.png',
      backgroundColor: '#1A7A4A',
    ),
    PromoBanner(
      title: 'Bonus',
      subtitle: 'Keep booking Liveasy to earn rewards',
      imagePath: 'assets/images/banner_bonus.png',
      backgroundColor: '#D4780A',
    ),
  ];

  static const List<DeliveryItem> recentDeliveries = [
    DeliveryItem(
      id: '1',
      trackingNumber: '#HWDSF776567DS',
      status: DeliveryStatus.inTransit,
      date: '24 មករា',
      origin: 'ភ្នំពេញ, ទឹកថ្លា',
      destination: 'បាត់ដំបង, វត្តលៀប',
      checkpoints: [
        TrackingPoint(label: 'ទទួល', completed: true),
        TrackingPoint(label: 'ចាកចេញ', completed: true),
        TrackingPoint(label: 'កំពុង', completed: true),
        TrackingPoint(label: 'ទៅដល់', completed: false),
      ],
    ),
  ];

  static const List<DeliveryItem> deliveryHistory = [
    DeliveryItem(
      id: '2',
      trackingNumber: '#HWDSF776567DS',
      status: DeliveryStatus.delivered,
      date: '24 ធ្នូ',
      origin: 'ភ្នំពេញ, ទឹកថ្លា',
      destination: 'សៀមរាប, ក្រុង',
      checkpoints: [],
    ),
    DeliveryItem(
      id: '3',
      trackingNumber: '#ABCDE123456FG',
      status: DeliveryStatus.delivered,
      date: '18 ធ្នូ',
      origin: 'កំពត, ក្រុង',
      destination: 'ភ្នំពេញ, ខណ្ឌចំការមន',
      checkpoints: [],
    ),
    DeliveryItem(
      id: '4',
      trackingNumber: '#ZXQRT987654KL',
      status: DeliveryStatus.delivered,
      date: '5 ធ្នូ',
      origin: 'បាត់ដំបង, ក្រុង',
      destination: 'ភ្នំពេញ, ខណ្ឌដូនពេញ',
      checkpoints: [],
    ),
  ];
}