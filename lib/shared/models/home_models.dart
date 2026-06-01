enum DeliveryStatus {
  pending,
  inTransit,
  arrived,
  delivered,
  canceled,
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
      case DeliveryStatus.canceled:
        return 'បានបោះបង់';
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
  final String itemName;
  final DeliveryStatus status;
  final String date;        
  final String origin;      
  final String destination; 
  final List<TrackingPoint> checkpoints;
  final String? dropoffContactName;
  final String? dropoffContactNumber;
  final String? noteToDriver;

  const DeliveryItem({
    required this.id,
    required this.trackingNumber,
    required this.itemName,
    required this.status,
    required this.date,
    required this.origin,
    required this.destination,
    required this.checkpoints,
    this.dropoffContactName,
    this.dropoffContactNumber,
    this.noteToDriver,
  });

  factory DeliveryItem.fromJson(Map<String, dynamic> json) {
    final status = _parseStatus(json['status']);
    final name = json['itemName'] ?? 'Package';
    final id = json['_id'] ?? json['id'] ?? '';
    final shortId = id.toString().length > 8 ? id.toString().substring(0, 8) : id.toString();
    
    // Generate default checkpoints based on status if backend doesn't provide them
    List<TrackingPoint> checkpoints = (json['checkpoints'] as List?)
        ?.map((e) => TrackingPoint(label: e['label'], completed: e['completed']))
        .toList() ?? [];

    if (checkpoints.isEmpty) {
      checkpoints = [
        TrackingPoint(label: 'ទទួល', completed: true), 
        TrackingPoint(label: 'ចាកចេញ', completed: status == DeliveryStatus.inTransit || status == DeliveryStatus.arrived || status == DeliveryStatus.delivered),
        TrackingPoint(label: 'កំពុង', completed: status == DeliveryStatus.arrived || status == DeliveryStatus.delivered),
        TrackingPoint(label: 'ទៅដល់', completed: status == DeliveryStatus.delivered),
      ];
    }

    return DeliveryItem(
      id: id,
      itemName: name,
      trackingNumber: "$name - #${shortId.toUpperCase()}",
      status: status,
      date: json['date'] ?? (json['createdAt'] != null ? _formatDate(json['createdAt']) : 'Just now'),
      origin: json['origin'] ?? json['pickupAddress'] ?? '',
      destination: json['destination'] ?? json['dropoffAddress'] ?? '',
      checkpoints: checkpoints,
      dropoffContactName: json['dropoffContactName'],
      dropoffContactNumber: json['dropoffContactNumber'],
      noteToDriver: json['noteToDriver'],
    );
  }

  static DeliveryStatus _parseStatus(String? status) {
    switch (status) {
      case 'searching': return DeliveryStatus.pending;
      case 'accepted': return DeliveryStatus.inTransit;
      case 'pickedUp': return DeliveryStatus.inTransit;
      case 'delivered': return DeliveryStatus.delivered;
      case 'canceled': return DeliveryStatus.canceled;
      default: return DeliveryStatus.pending;
    }
  }

  static String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return "${dt.day}/${dt.month}";
    } catch (_) { return "Just now"; }
  }
}

class PromoBanner {
  final String title;
  final String subtitle;
  final String imagePath;   
  final String backgroundColor; 
  
  const PromoBanner({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.backgroundColor,
  });

  factory PromoBanner.fromJson(Map<String, dynamic> json) {
    return PromoBanner(
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      imagePath: json['imagePath'] ?? '',
      backgroundColor: json['backgroundColor'] ?? '#2C5F8A',
    );
  }
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

  static const List<DeliveryItem> recentDeliveries = [];

  static const List<DeliveryItem> deliveryHistory = [];
}