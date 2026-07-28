import 'package:latlong2/latlong.dart';
import '../models/warehouse.dart';

class WarehouseData {
  static const List<Warehouse> allWarehouses = [
    // Phnom Penh Hubs
    Warehouse(name: "PP Central Warehouse (ITC)", location: LatLng(11.5710, 104.8990)),
    Warehouse(name: "Sen Sok Warehouse", location: LatLng(11.5834, 104.8805)),
    Warehouse(name: "Chbar Ampov Warehouse", location: LatLng(11.5312, 104.9455)),
    
    // Provincial Warehouses
    Warehouse(name: "Siem Reap Warehouse", location: LatLng(13.3640, 103.8603)),
    Warehouse(name: "Battambang Warehouse", location: LatLng(13.0957, 103.2022)),
    Warehouse(name: "Sihanoukville Warehouse", location: LatLng(10.6275, 103.5221)),
    Warehouse(name: "Kampong Cham Warehouse", location: LatLng(11.9934, 105.4645)),
    Warehouse(name: "Kampong Speu Warehouse", location: LatLng(11.4542, 104.5213)),
    Warehouse(name: "Kampong Chhnang Warehouse", location: LatLng(12.1384, 104.3394)),
    Warehouse(name: "Kampong Thom Warehouse", location: LatLng(12.7121, 104.8887)),
    Warehouse(name: "Kampot Warehouse", location: LatLng(10.5942, 104.1648)),
    Warehouse(name: "Kep Warehouse", location: LatLng(10.4825, 104.3167)),
    Warehouse(name: "Koh Kong Warehouse", location: LatLng(11.6153, 102.9838)),
    Warehouse(name: "Kratie Warehouse", location: LatLng(12.4883, 106.0167)),
    Warehouse(name: "Mondulkiri Warehouse", location: LatLng(12.4561, 107.1881)),
    Warehouse(name: "Oddar Meanchey Warehouse", location: LatLng(14.1817, 103.5176)),
    Warehouse(name: "Pailin Warehouse", location: LatLng(12.8489, 102.6092)),
    Warehouse(name: "Preah Vihear Warehouse", location: LatLng(13.8073, 104.9804)),
    Warehouse(name: "Prey Veng Warehouse", location: LatLng(11.4883, 105.3253)),
    Warehouse(name: "Pursat Warehouse", location: LatLng(12.5383, 103.9192)),
    Warehouse(name: "Ratanakiri Warehouse", location: LatLng(13.7350, 106.9872)),
    Warehouse(name: "Stung Treng Warehouse", location: LatLng(13.5259, 105.9683)),
    Warehouse(name: "Svay Rieng Warehouse", location: LatLng(11.0878, 105.7994)),
    Warehouse(name: "Takeo Warehouse", location: LatLng(10.9908, 104.7847)),
    Warehouse(name: "Tboung Khmum Warehouse", location: LatLng(11.8891, 105.8760)),
    Warehouse(name: "Banteay Meanchey Warehouse", location: LatLng(13.5859, 102.9737)),
    Warehouse(name: "Kandal Warehouse", location: LatLng(11.4842, 104.9472)),
  ];
}
