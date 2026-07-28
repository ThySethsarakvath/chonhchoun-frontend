import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/driver_earnings.dart';
import '../../../shared/models/driver_request.dart';

const driverDisplayName = 'ភ័ក្ត្រ';
const driverAvailableBalance = '168';
const driverOverviewRange = 'Dec 14 - Dec 21';
const driverTotalTime = '42 Hours 32 Minutes';
const driverTotalDeliveries = '38';

const driverWeeklyEarnings = <DriverDayEarning>[
  DriverDayEarning(label: 'Mon', amount: 18.40, deliveries: 6),
  DriverDayEarning(label: 'Tue', amount: 24.10, deliveries: 8),
  DriverDayEarning(label: 'Wed', amount: 12.75, deliveries: 4),
  DriverDayEarning(label: 'Thu', amount: 31.60, deliveries: 11),
  DriverDayEarning(label: 'Fri', amount: 27.30, deliveries: 9),
  DriverDayEarning(label: 'Sat', amount: 38.95, deliveries: 13),
  DriverDayEarning(label: 'Sun', amount: 14.50, deliveries: 5),
];

const driverRecentTransactions = <DriverTransaction>[
  DriverTransaction(
    title: 'Cash out to wallet',
    subtitle: 'ABA · **** 4417',
    amount: -60.00,
    time: 'Today, 09:12',
    icon: Icons.account_balance_wallet_rounded,
    isPayout: true,
  ),
  DriverTransaction(
    title: 'Documents / Parcel',
    subtitle: 'Russian Market → Olympic',
    amount: 4.10,
    time: 'Today, 08:40',
    icon: Icons.inventory_2_rounded,
    isPayout: false,
  ),
  DriverTransaction(
    title: 'Food Items / Groceries',
    subtitle: 'Toul Kork → Boeung Kak 1',
    amount: 2.80,
    time: 'Yesterday, 19:05',
    icon: Icons.lunch_dining_rounded,
    isPayout: false,
  ),
  DriverTransaction(
    title: 'Electronics / Gadgets',
    subtitle: 'Stueng Mean Chey → Sen Sok',
    amount: 3.50,
    time: 'Yesterday, 17:22',
    icon: Icons.devices_other_rounded,
    isPayout: false,
  ),
  DriverTransaction(
    title: 'Weekend bonus',
    subtitle: '10+ deliveries on Saturday',
    amount: 5.00,
    time: 'Sat, 21:00',
    icon: Icons.bolt_rounded,
    isPayout: false,
  ),
];

const driverRequests = <DriverRequest>[
  DriverRequest(
    title: 'Electronics / Gadgets',
    recipient: 'Paul Pogba',
    pickup: 'Stueng Mean Chey',
    dropOff: 'Tuek Thla, Sen Sok',
    pickupLatLng: LatLng(11.5437, 104.9302),
    dropOffLatLng: LatLng(11.5870, 104.8930),
    payment: 'Card',
    fee: '\$3.50',
    phone: '012321287',
    eta: '42 mins',
    deliveries: 20,
    rating: 4.1,
    accent: Color(0xFF2B6D9B),
    itemSummary: 'Phone accessories and small gadgets',
    senderInitials: 'DR',
  ),
  DriverRequest(
    title: 'Food Items / Groceries',
    recipient: 'Sita',
    pickup: 'Toul Kork',
    dropOff: 'Boeung Kak 1',
    pickupLatLng: LatLng(11.5749, 104.9109),
    dropOffLatLng: LatLng(11.5791, 104.9103),
    payment: 'Cash',
    fee: '\$2.80',
    phone: '093882210',
    eta: '31 mins',
    deliveries: 14,
    rating: 4.6,
    accent: Color(0xFF2F8D76),
    itemSummary: 'Cake, fruit box, and bottled drinks',
    senderInitials: 'ST',
  ),
  DriverRequest(
    title: 'Documents / Parcel',
    recipient: 'Dara',
    pickup: 'Russian Market',
    dropOff: 'Olympic',
    pickupLatLng: LatLng(11.5462, 104.9214),
    dropOffLatLng: LatLng(11.5596, 104.9180),
    payment: 'Card',
    fee: '\$4.10',
    phone: '070552183',
    eta: '26 mins',
    deliveries: 38,
    rating: 4.8,
    accent: Color(0xFF5F7AE8),
    itemSummary: 'Office envelope and signed paperwork',
    senderInitials: 'DA',
  ),
];
