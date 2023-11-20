import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';

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
  double currentLatitude = 10.776889; // Giá trị mặc định
  double currentLongitude = 106.700806; // Giá trị mặc định
  late WebViewController webController;

  String nominatimAddress = "Chưa có địa chỉ";
  String geocodingAddress = "Chưa có địa chỉ";

  MapController controller = MapController(
    initPosition: GeoPoint(latitude: 10.776889, longitude: 106.700806),
    areaLimit: BoundingBox(
      east: 10.4922941,
      north: 47.8084648,
      south: 45.817995,
      west: 5.9559113,
    ),
  );

  @override
  void initState() {
    super.initState();
    // Khởi tạo WebViewController ở đây
    webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith(
                'https://www.openstreetmap.org/?mlat=$currentLatitude&mlon=$currentLongitude&zoom=16')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(
        Uri.parse(
            'https://www.openstreetmap.org/?mlat=$currentLatitude&mlon=$currentLongitude&zoom=16'),
      );
  }

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
    setState(() {
      currentLatitude = position.latitude;
      currentLongitude = position.longitude;
    });

    // Cập nhật URL cho WebView
    String osmUrl =
        'https://www.openstreetmap.org/?mlat=$currentLatitude&mlon=$currentLongitude&zoom=16';
    webController.loadRequest(Uri.parse(osmUrl));

    await Future.delayed(const Duration(milliseconds: 2000));
    controller.setZoom(zoomLevel: 10);
  }

  void goToHoChiMinhCityCenter() async {
    GeoPoint hcmCenter = GeoPoint(latitude: 10.776889, longitude: 106.700806);
    controller.changeLocation(hcmCenter);
    setState(() {
      currentLatitude = hcmCenter.latitude;
      currentLongitude = hcmCenter.longitude;
    });

    // Cập nhật URL cho WebView
    String osmUrl =
        'https://www.openstreetmap.org/?mlat=$currentLatitude&mlon=$currentLongitude&zoom=16';
    webController.loadRequest(Uri.parse(osmUrl));

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
    setState(() {
      currentLatitude = hongHungCenter.latitude;
      currentLongitude = hongHungCenter.longitude;
    });

    String osmUrl =
        'https://www.openstreetmap.org/?mlat=$currentLatitude&mlon=$currentLongitude&zoom=16';
    webController.loadRequest(Uri.parse(osmUrl));

    await Future.delayed(const Duration(milliseconds: 2000));
    controller.setZoom(zoomLevel: 18);

    //sử dụng Nominatim
    try {
      String address = await getAddressFromNominatim(
          hongHungCenter.latitude, hongHungCenter.longitude);
      setState(() {
        nominatimAddress = address;
      });
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
        setState(() {
          geocodingAddress =
              "${place.street}, ${place.subAdministrativeArea}, ${place.country}, ${place.country}";
        });
      }
    } catch (e) {
      print("Lỗi khi lấy địa chỉ: $e");
    }
    print(
        "Đã điều hướng đến trung tâm Hồ Chí Minh: Kinh độ: ${hongHungCenter.longitude}, Vĩ độ: ${hongHungCenter.latitude}");
  }

  @override
  Widget build(BuildContext context) {
    print(controller);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: OSMFlutter(
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
                roadConfiguration:
                    const RoadOption(roadColor: Colors.yellowAccent),
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
          ),
          ElevatedButton(
            onPressed: () => showWebViewDialog(context),
            child: const Text("đi đến xác nhận check in"),
          ),
          Text("Địa chỉ Nominatim: $nominatimAddress"),
          const SizedBox(height: 10),
          Text("Địa chỉ Geocoding: $geocodingAddress"),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "uniqueTag1",
            onPressed: getCurrentLocation, // Gọi hàm getCurrentLocation ở đây
            tooltip: 'Go to my location',
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 10), // Khoảng cách giữa các nút
          FloatingActionButton(
            heroTag: "uniqueTag2",
            onPressed: goToHoChiMinhCityCenter,
            tooltip: 'Go to Ho Chi Minh City Center',
            child: const Icon(Icons.location_city),
          ),
          const SizedBox(height: 10), // Khoảng cách giữa các nút
          FloatingActionButton(
            heroTag: "uniqueTag3",
            onPressed: goToHisHongHung,
            tooltip: 'Go to Ho Chi Minh City Center',
            child: const Icon(Icons.history_edu),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  void showWebViewDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Xác nhận địa điểm"),
          content: SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            width: MediaQuery.of(context).size.width,
            child: WebViewWidget(
              controller: webController,
            ),
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("đóng"),
                ),
                const SizedBox(width: 5),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Xác Nhận"),
                ),
              ],
            )
          ],
        );
      },
    );
  }
}
