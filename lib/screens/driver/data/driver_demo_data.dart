import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/driver_request.dart';

const driverDisplayName = 'ភ័ក្ត្រ';
const driverAvailableBalance = '168';
const driverOverviewRange = 'Dec 14 - Dec 21';
const driverTotalTime = '42 Hours 32 Minutes';
const driverTotalDeliveries = '38';

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
