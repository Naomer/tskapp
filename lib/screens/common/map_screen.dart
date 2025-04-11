import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final Function(LatLng)? onLocationSelected;

  const MapScreen({
    super.key,
    this.initialLocation,
    this.onLocationSelected,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  bool _isLoading = true;
  String? _error;
  final _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _checkLocationServicesAndPermissions();
  }

  Future<void> _checkLocationServicesAndPermissions() async {
    try {
      // First check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Location Services Disabled'),
                content: const Text(
                  'Please enable location services to use this feature. '
                  'Would you like to enable it now?',
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('CANCEL'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() {
                        _error = 'Location services are disabled';
                        _isLoading = false;
                      });
                    },
                  ),
                  TextButton(
                    child: const Text('SETTINGS'),
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await Geolocator.openLocationSettings();
                      if (mounted) {
                        _checkLocationServicesAndPermissions();
                      }
                    },
                  ),
                ],
              );
            },
          );
          return;
        }
      }

      // Then check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _error = 'Location permission denied';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Location Permission Required'),
                content: const Text(
                  'Location permission is required to use this feature. '
                  'Please enable it in settings.',
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('CANCEL'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() {
                        _error = 'Location permission denied forever';
                        _isLoading = false;
                      });
                    },
                  ),
                  TextButton(
                    child: const Text('SETTINGS'),
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await openAppSettings();
                      if (mounted) {
                        _checkLocationServicesAndPermissions();
                      }
                    },
                  ),
                ],
              );
            },
          );
          return;
        }
      }

      // If we get here, we have permission and services are enabled
      await _initializeMap();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error checking location services: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _initializeMap() async {
    try {
      Position? position;

      // First attempt: Try high accuracy with longer timeout
      try {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Getting your location...'),
              duration: Duration(seconds: 2),
            ),
          );
        }

        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          forceAndroidLocationManager: true,
          timeLimit: const Duration(seconds: 20),
        );
      } catch (e) {
        print('First location attempt failed: $e');
        // Second attempt: Try low accuracy with shorter timeout
        try {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Retrying with lower accuracy...'),
                duration: Duration(seconds: 2),
              ),
            );
          }

          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            forceAndroidLocationManager: true,
            timeLimit: const Duration(seconds: 15),
          );
        } catch (e) {
          print('Second location attempt failed: $e');
          // Third attempt: Try to get last known position
          position = await Geolocator.getLastKnownPosition();
          print('Last known position: $position');

          if (position == null) {
            print('No last known position available');
            // Final fallback: Use default location (center of India)
            position = Position(
              latitude: 20.5937,
              longitude: 78.9629,
              timestamp: DateTime.now(),
              accuracy: 0,
              altitude: 0,
              heading: 0,
              speed: 0,
              speedAccuracy: 0,
              altitudeAccuracy: 0,
              headingAccuracy: 0,
            );

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                      'Could not get your location. Using default location.'),
                  duration: const Duration(seconds: 4),
                  action: SnackBarAction(
                    label: 'RETRY',
                    onPressed: _initializeMap,
                  ),
                ),
              );
            }
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Using last known location'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }

      if (mounted) {
        final location = LatLng(position.latitude, position.longitude);
        print('Setting location to: $location');
        setState(() {
          _selectedLocation = widget.initialLocation ?? location;
          _isLoading = false;
        });

        // Add a small delay to ensure the map is properly initialized
        await Future.delayed(const Duration(milliseconds: 500));

        if (_mapController != null) {
          print('Moving camera to location: $location');
          await _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(location, 15),
          );
        }
      }
    } catch (e, stackTrace) {
      print('Error in _initializeMap: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _error = 'Failed to get location: $e';
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location error: $e'),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'RETRY',
              onPressed: _initializeMap,
            ),
          ),
        );
      }
    }
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json'
          '?input=$query'
          '&key=AIzaSyBPzc7TGvM4eT5AalOR4gG2EdMY3DF7JoY'
          '&components=country:in',
        ),
      );

      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        setState(() {
          _searchResults = data['predictions'];
          _isSearching = false;
        });
      } else {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  Future<void> _getPlaceDetails(String placeId) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/place/details/json'
          '?place_id=$placeId'
          '&key=AIzaSyBPzc7TGvM4eT5AalOR4gG2EdMY3DF7JoY'
          '&fields=geometry',
        ),
      );

      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final location = data['result']['geometry']['location'];
        final latLng = LatLng(location['lat'], location['lng']);

        setState(() {
          _selectedLocation = latLng;
          _searchResults = [];
          _searchController.clear();
        });

        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(latLng, 15),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to get location details'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // Set map style to default style with better visibility
    _mapController?.setMapStyle('''
      [
        {
          "featureType": "poi",
          "elementType": "labels",
          "stylers": [
            {
              "visibility": "off"
            }
          ]
        },
        {
          "featureType": "road",
          "elementType": "geometry",
          "stylers": [
            {
              "color": "#ffffff"
            }
          ]
        }
      ]
    ''');

    // If we have a selected location, move to it
    if (_selectedLocation != null) {
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedLocation!, 15),
      );
    }
  }

  void _onMapTapped(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
    widget.onLocationSelected?.call(location);
  }

  Future<void> _goToCurrentLocation() async {
    try {
      Position? position;

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Getting your location...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // First try high accuracy
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
        );
      } catch (e) {
        // Then try low accuracy
        try {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Retrying with lower accuracy...'),
                duration: Duration(seconds: 2),
              ),
            );
          }

          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.reduced,
            timeLimit: const Duration(seconds: 10),
          );
        } catch (e) {
          // Finally try last known position
          position = await Geolocator.getLastKnownPosition();

          if (position == null) {
            throw Exception('Could not get current location');
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Using last known location'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }

      final location = LatLng(position.latitude, position.longitude);

      if (_mapController != null && mounted) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(location, 15),
        );
        setState(() {
          _selectedLocation = location;
        });
        widget.onLocationSelected?.call(location);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to get current location'),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'RETRY',
              onPressed: _goToCurrentLocation,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Getting your location...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off,
                          size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(color: Colors.red[300], fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _checkLocationServicesAndPermissions,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    GoogleMap(
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: CameraPosition(
                        target:
                            _selectedLocation ?? const LatLng(20.5937, 78.9629),
                        zoom: 15,
                      ),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      mapToolbarEnabled: false,
                      zoomControlsEnabled: false,
                      compassEnabled: true,
                      tiltGesturesEnabled: true,
                      rotateGesturesEnabled: true,
                      zoomGesturesEnabled: true,
                      mapType: MapType.normal,
                      onTap: _onMapTapped,
                      markers: _selectedLocation != null
                          ? {
                              Marker(
                                markerId: const MarkerId('selected_location'),
                                position: _selectedLocation!,
                                draggable: true,
                                icon: BitmapDescriptor.defaultMarkerWithHue(
                                    BitmapDescriptor.hueBlue),
                                onDragEnd: (newPosition) {
                                  setState(() {
                                    _selectedLocation = newPosition;
                                  });
                                  widget.onLocationSelected?.call(newPosition);
                                },
                              ),
                            }
                          : {},
                    ),
                    // Search Bar
                    SafeArea(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: const InputDecoration(
                                      hintText: 'Search location...',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                    ),
                                    onChanged: _searchPlaces,
                                  ),
                                ),
                                if (_isSearching)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 16),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.blue,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (_searchResults.isNotEmpty)
                              Container(
                                constraints: BoxConstraints(
                                  maxHeight:
                                      MediaQuery.of(context).size.height * 0.3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _searchResults.length,
                                  itemBuilder: (context, index) {
                                    final result = _searchResults[index];
                                    return ListTile(
                                      leading: const Icon(Icons.location_on),
                                      title: Text(result['description']),
                                      onTap: () {
                                        _getPlaceDetails(result['place_id']);
                                      },
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    // Current Location Button
                    Positioned(
                      right: 16,
                      bottom: 90,
                      child: FloatingActionButton(
                        heroTag: 'current_location',
                        onPressed: _goToCurrentLocation,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.my_location,
                          color: Colors.blue[600],
                        ),
                      ),
                    ),
                    // Confirm Button
                    if (_selectedLocation != null)
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context, _selectedLocation);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Confirm Location',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
