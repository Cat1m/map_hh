import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter map'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

//todo: sử dụng nominatim
Future<String> getAddressFromNominatim(
    double latitude, double longitude) async {
  final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    var data = jsonDecode(response.body);
    return data['display_name'];
  } else {
    throw Exception('Failed to load location data');
  }
}

class _MyHomePageState extends State<MyHomePage> {
  void getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Kiểm tra xem dịch vụ vị trí có bật không
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // Lấy vị trí hiện tại
    Position position = await Geolocator.getCurrentPosition();
    print(
        "Vị trí hiện tại: Kinh độ: ${position.longitude}, Vĩ độ: ${position.latitude}");

    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        print(
            "Địa điểm hiện tại: ${place.street}, ${place.subLocality}, ${place.locality}, ${place.country}");
      }
    } catch (e) {
      print("Lỗi định vị ngược: $e");
    }

    controller.changeLocation(
      GeoPoint(latitude: position.latitude, longitude: position.longitude),
    );
    await Future.delayed(const Duration(milliseconds: 2000));
    controller.setZoom(zoomLevel: 10);
  }

  MapController controller = MapController(
    initPosition: GeoPoint(latitude: 10.776889, longitude: 106.700806),
    areaLimit: BoundingBox(
      east: 10.4922941,
      north: 47.8084648,
      south: 45.817995,
      west: 5.9559113,
    ),
  );

  void goToHoChiMinhCityCenter() async {
    GeoPoint hcmCenter = GeoPoint(latitude: 10.776889, longitude: 106.700806);
    controller.changeLocation(hcmCenter);

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        hcmCenter.latitude,
        hcmCenter.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        print(place);
        print(
            "Địa chỉ: ${place.street}, ${place.subAdministrativeArea}, ${place.country}");
      }
    } catch (e) {
      print("Lỗi khi lấy địa chỉ: $e");
    }
    print(
        "Đã điều hướng đến trung tâm Hồ Chí Minh: Kinh độ: ${hcmCenter.longitude}, Vĩ độ: ${hcmCenter.latitude}");
  }

  void goToHisHongHung() async {
    GeoPoint hongHungCenter =
        GeoPoint(latitude: 11.28999, longitude: 106.11920); //11.29294,106.12451
    controller.changeLocation(hongHungCenter);
    await Future.delayed(const Duration(milliseconds: 2000));
    controller.setZoom(zoomLevel: 18);

    //sử dụng Nominatim
    try {
      String address = await getAddressFromNominatim(
          hongHungCenter.latitude, hongHungCenter.longitude);
      print("Nominatim API: Địa chỉ: $address");
    } catch (e) {
      print("Lỗi khi lấy địa chỉ từ Nominatim API: $e");
    }

    //sử dụng geocoding
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        hongHungCenter.latitude,
        hongHungCenter.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        print(place);
        print(
            "Địa chỉ: ${place.street}, ${place.subAdministrativeArea}, ${place.country}");
      }
    } catch (e) {
      print("Lỗi khi lấy địa chỉ: $e");
    }
    print(
        "Đã điều hướng đến trung tâm Hồ Chí Minh: Kinh độ: ${hongHungCenter.longitude}, Vĩ độ: ${hongHungCenter.latitude}");
  }

  @override
  void initState() {
    super.initState();
  }

  // default constructor

  @override
  Widget build(BuildContext context) {
    print(controller);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: OSMFlutter(
        controller: controller,
        osmOption: OSMOption(
          userTrackingOption: const UserTrackingOption(
            enableTracking: true,
            unFollowUser: false,
          ),
          zoomOption: const ZoomOption(
            initZoom: 8,
            minZoomLevel: 3,
            maxZoomLevel: 19,
            stepZoom: 1.0,
          ),
          userLocationMarker: UserLocationMaker(
            personMarker: const MarkerIcon(
              icon: Icon(
                Icons.location_history_rounded,
                color: Colors.red,
                size: 48,
              ),
            ),
            directionArrowMarker: const MarkerIcon(
              icon: Icon(
                Icons.double_arrow,
                size: 48,
              ),
            ),
          ),
          roadConfiguration: const RoadOption(roadColor: Colors.yellowAccent),
          markerOption: MarkerOption(
            defaultMarker: const MarkerIcon(
              icon: Icon(
                Icons.person_pin_circle,
                color: Colors.blue,
                size: 56,
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: getCurrentLocation, // Gọi hàm getCurrentLocation ở đây
            tooltip: 'Go to my location',
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 10), // Khoảng cách giữa các nút
          FloatingActionButton(
            onPressed: goToHoChiMinhCityCenter,
            tooltip: 'Go to Ho Chi Minh City Center',
            child: const Icon(Icons.location_city),
          ),
          const SizedBox(height: 10), // Khoảng cách giữa các nút
          FloatingActionButton(
            onPressed: goToHisHongHung,
            tooltip: 'Go to Ho Chi Minh City Center',
            child: const Icon(Icons.history_edu),
          ),
        ],
      ),
    );
  }
}
