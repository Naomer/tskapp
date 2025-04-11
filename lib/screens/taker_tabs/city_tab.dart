import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/env.dart';

class CityTab extends StatefulWidget {
  const CityTab({super.key});

  @override
  State<CityTab> createState() => _CityTabState();
}

class _CityTabState extends State<CityTab> {
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      _removeOverlay();
      return;
    }

    setState(() => _isSearching = true);

    try {
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json'
          '?input=$query'
          '&key=${Env.googleMapsAndroidApiKey}'
          '&components=country:in',
        ),
      );

      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        setState(() {
          _searchResults = data['predictions'];
          _isSearching = false;
        });
        _showSearchResults();
      } else {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('Error searching places: $e');
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  void _showSearchResults() {
    _removeOverlay();

    if (_searchResults.isEmpty) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: offset.dy + 100, // Position below search bar
        left: 40,
        right: 40,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.3,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final result = _searchResults[index];
                return ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.blue),
                  title: Text(
                    result['description'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    _getPlaceDetails(result['place_id']);
                    _removeOverlay();
                    _searchController.clear();
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Future<void> _getPlaceDetails(String placeId) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/place/details/json'
          '?place_id=$placeId'
          '&key=${Env.googleMapsAndroidApiKey}'
          '&fields=geometry,formatted_address',
        ),
      );

      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final location = data['result']['geometry']['location'];
        final latLng = LatLng(location['lat'], location['lng']);
        final address = data['result']['formatted_address'];

        if (mapController != null) {
          await mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(latLng, 15),
          );

          setState(() {
            markers.clear();
            markers.add(
              Marker(
                markerId: const MarkerId('selected_location'),
                position: latLng,
                infoWindow: InfoWindow(title: address),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueBlue),
              ),
            );
          });
        }
      }
    } catch (e) {
      debugPrint('Error getting place details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to get location details'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _requestLocationPermission() async {
    try {
      // Just request the permission - this will show the standard Android prompt
      await Permission.location.request();

      // Initialize map after permission request
      _initializeMap();
    } catch (e) {
      debugPrint('Error requesting permission: $e');
    }
  }

  Future<void> _initializeMap() async {
    try {
      setState(() => isLoading = true);

      if (mapController != null) {
        await _getCurrentLocation();
      }

      setState(() => isLoading = false);
    } catch (e) {
      debugPrint('Error initializing map: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Only try to get location if permission is granted
      if (!await Permission.location.isGranted) {
        return;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } catch (e) {
        debugPrint('Location error: $e');
        return;
      }

      if (position != null && mounted && mapController != null) {
        final LatLng location = LatLng(position.latitude, position.longitude);
        await mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: location,
              zoom: 15,
            ),
          ),
        );

        setState(() {
          markers.clear();
          markers.add(
            Marker(
              markerId: const MarkerId('currentLocation'),
              position: location,
              infoWindow: const InfoWindow(title: 'Your Location'),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue),
            ),
          );
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titleSpacing: 16,
        title: Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search for location',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    prefixIcon:
                        Icon(IconlyLight.search, color: Colors.grey[500]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    suffixIcon: _isSearching
                        ? Container(
                            width: 20,
                            height: 20,
                            margin: const EdgeInsets.all(12),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.blue),
                            ),
                          )
                        : null,
                  ),
                  onChanged: _searchPlaces,
                ),
              ),
              IconButton(
                onPressed: () {
                  _getCurrentLocation();
                  _removeOverlay();
                  _searchController.clear();
                },
                icon: const Icon(Icons.my_location, color: Colors.blue),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Stack(
                  children: [
                    Container(
                      height: MediaQuery.of(context).size.height * 0.67,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: GoogleMap(
                          initialCameraPosition: const CameraPosition(
                            target: LatLng(20.5937, 78.9629),
                            zoom: 12,
                          ),
                          onMapCreated: (GoogleMapController controller) async {
                            debugPrint('Map controller created');
                            setState(() {
                              mapController = controller;
                              isLoading = false;
                            });
                            await controller.setMapStyle(null);
                            await _getCurrentLocation();
                          },
                          markers: markers,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          zoomControlsEnabled: true,
                          mapToolbarEnabled: false,
                          compassEnabled: true,
                          mapType: MapType.normal,
                          buildingsEnabled: true,
                          indoorViewEnabled: true,
                          trafficEnabled: false,
                          tiltGesturesEnabled: true,
                          rotateGesturesEnabled: true,
                          scrollGesturesEnabled: true,
                          zoomGesturesEnabled: true,
                          liteModeEnabled: false,
                        ),
                      ),
                    ),
                    if (isLoading)
                      const Positioned.fill(
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
