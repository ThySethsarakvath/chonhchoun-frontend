import '../../shared/models/order.dart';

String customerOrderStatusKhmer(CustomerOrder order) {
  if (order.serviceType == DeliveryServiceType.warehouse) {
    return switch (order.status) {
      OrderStatus.searching => 'កំពុងរង់ចាំការប្រគល់ទំនិញនៅឃ្លាំង',
      OrderStatus.accepted => 'រួចរាល់សម្រាប់ការប្រគល់ទំនិញ',
      OrderStatus.arrivedAtPickup => 'អ្នកបើកបរកំពុងរង់ចាំទទួលកញ្ចប់',
      OrderStatus.inTransit => 'កញ្ចប់កំពុងដឹកជញ្ជូនរវាងឃ្លាំង',
      OrderStatus.arrivedAtDropoff => 'កំពុងរង់ចាំការបញ្ជាក់ពីអ្នកទទួល',
      OrderStatus.delivered => 'រួចរាល់សម្រាប់ការទទួលនៅឃ្លាំងគោលដៅ',
      OrderStatus.canceled => 'បានបោះបង់ការដឹកជញ្ជូន',
      OrderStatus.failed => 'ការដឹកជញ្ជូនមិនបានសម្រេច',
    };
  }

  return switch (order.status) {
    OrderStatus.searching => 'កំពុងរង់ចាំអ្នកបើកបរ',
    OrderStatus.accepted => 'អ្នកបើកបរកំពុងមកទទួលកញ្ចប់',
    OrderStatus.arrivedAtPickup =>
      'អ្នកបើកបរបានមកដល់ — សូមបង្ហាញ QR សម្រាប់ទទួលកញ្ចប់',
    OrderStatus.inTransit => 'កំពុងធ្វើដំណើរទៅទីតាំងគោលដៅ',
    OrderStatus.arrivedAtDropoff =>
      'អ្នកបើកបរបានមកដល់ — ត្រូវការការបញ្ជាក់ពីអ្នកទទួល',
    OrderStatus.delivered => 'ដឹកជញ្ជូនបានជោគជ័យ',
    OrderStatus.canceled => 'បានបោះបង់ការដឹកជញ្ជូន',
    OrderStatus.failed => 'ការដឹកជញ្ជូនមិនបានសម្រេច',
  };
}

String customerItemTypeKhmer(ItemType type) {
  return switch (type) {
    ItemType.document => 'ឯកសារ',
    ItemType.food => 'អាហារ',
    ItemType.clothing => 'សម្លៀកបំពាក់',
    ItemType.electronics => 'គ្រឿងអេឡិចត្រូនិក',
    ItemType.others => 'ផ្សេងៗ',
  };
}

String customerVehicleKhmer(VehicleType type) {
  return switch (type) {
    VehicleType.bike => 'ម៉ូតូ',
    VehicleType.tuktuk => 'ម៉ូតូកង់បី',
  };
}

String customerServiceKhmer(DeliveryServiceType type) {
  return switch (type) {
    DeliveryServiceType.express => 'ដឹកជញ្ជូនរហ័ស',
    DeliveryServiceType.warehouse => 'ដឹកជញ្ជូនរវាងឃ្លាំង',
  };
}

String customerStatusCodeKhmer(String status) {
  return switch (status.toUpperCase()) {
    'PENDING' || 'SEARCHING' => 'កំពុងរង់ចាំអ្នកបើកបរ',
    'ACCEPTED' => 'អ្នកបើកបរបានទទួលយក',
    'ARRIVED_AT_PICKUP' => 'អ្នកបើកបរបានមកដល់ទីតាំងទទួលកញ្ចប់',
    'IN_TRANSIT' => 'កំពុងដឹកជញ្ជូន',
    'ARRIVED_AT_DROPOFF' => 'អ្នកបើកបរបានមកដល់ទីតាំងប្រគល់',
    'DELIVERED' || 'COMPLETED' => 'ដឹកជញ្ជូនបានជោគជ័យ',
    'CANCELLED' || 'CANCELED' => 'បានបោះបង់ការដឹកជញ្ជូន',
    'FAILED' => 'ការដឹកជញ្ជូនមិនបានសម្រេច',
    _ => 'កំពុងដំណើរការ',
  };
}
