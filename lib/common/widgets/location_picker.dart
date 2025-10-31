import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
// Import the animation package
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:locally/common/extensions/content_extensions.dart';

// Your showLocationPicker function remains the same
Future<Map<String, dynamic>?> showLocationPicker(
  BuildContext context,
) async {
  return await showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _ModernLocationPicker(),
  );
}

class _ModernLocationPicker extends StatefulWidget {
  const _ModernLocationPicker();

  @override
  // Add TickerProviderStateMixin via the State class
  State<_ModernLocationPicker> createState() => _ModernLocationPickerState();
}

class _ModernLocationPickerState extends State<_ModernLocationPicker>
    with TickerProviderStateMixin {
  // <-- ADDED TickerProviderStateMixin

  // 1. Controllers
  // Use both the base controller and the animated wrapper
  late final MapController _mapController;
  late final AnimatedMapController _animatedMapController;

  // 2. State Variables
  // Default center (India)
  final LatLng _defaultCenter = LatLng(20.5937, 78.9629);
  LatLng? _selected;
  String? _address;
  bool _loading = false;

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];

  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    // Initialize both controllers, linking them
    _mapController = MapController();
    _animatedMapController = AnimatedMapController(
      vsync: this,
      mapController: _mapController,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
    );

    // Set default selected position to prevent LateInitializationError
    // before the map is ready.
    _selected = _defaultCenter;

    // Geocoding the default center is now handled in onMapReady.

    _searchController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    // Dispose both controllers
    _animatedMapController.dispose();
    _mapController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final theme = Theme.of(context);

    return Container(
      height: mq.size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Drag Handle
          Container(
            height: 5,
            width: 60,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Stack(
              children: [
                // Map Layer
                FlutterMap(
                  // Use the base MapController here
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter:
                        _defaultCenter, // Use default center for initial view
                    initialZoom: 4,
                    onPositionChanged: _onMapMoved,
                    // 🌟 FIX: Call geocoding safely after map initialization
                    onMapReady: () {
                      _reverseGeocode(_mapController.camera.center);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=${dotenv.env["MAPTILER_API_KEY"]}",
                      userAgentPackageName: "com.example.app",
                    ),
                  ],
                ),

                // Central Pin Icon
                Center(
                  child: Transform.translate(
                    offset: const Offset(0.0, -20.0),
                    child: Icon(
                      Icons.location_on,
                      color: theme.colorScheme.error,
                      size: 40,
                    ),
                  ),
                ),

                // My Location Button
                Positioned(
                  bottom: 20,
                  right: 10,
                  child: FloatingActionButton.small(
                    onPressed: _useCurrentLocation,
                    child: const Icon(Icons.my_location),
                  ),
                ),

                // Search Bar and Results Overlay
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(12),
                    clipBehavior: Clip.antiAlias,
                    color: theme.colorScheme.surface,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSearchBar(),
                        if (_searchResults.isNotEmpty) ...[
                          const Divider(height: 1, thickness: 1),
                          _buildSearchResultsList(),
                        ],
                      ],
                    ),
                  ),
                ),

                // Loading Indicator
                if (_loading) const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
          // Selected Address Display
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              _address ?? "Loading address...",
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Confirm Button
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton.icon(
                onPressed: _selected == null
                    ? null
                    : () => Navigator.pop(context, {
                        "latitude": _selected!.latitude,
                        "longitude": _selected!.longitude,
                        "address": _address,
                      }),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text("Confirm Location"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🌟 FIX: Corrected debounce logic
  void _onMapMoved(MapPosition position, bool hasGesture) {
    final newCenter = position.center;

    setState(() {
      _selected = newCenter;
      _address = "Loading address...";
    });

    // Always cancel any existing timer
    _debounce?.cancel();

    // Set a new timer to call geocode after user stops moving the map
    if (newCenter != null) {
      _debounce = Timer(const Duration(milliseconds: 500), () {
        // Use the controller's latest center when the timer fires
        _reverseGeocode(_mapController.camera.center);
      });
    }
  }

  Widget _buildSearchBar() {
    const OutlineInputBorder roundedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide.none,
    );

    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: "Search for a place...",
        prefixIcon: const Icon(Icons.search),
        border: roundedBorder,
        enabledBorder: roundedBorder,
        focusedBorder: roundedBorder.copyWith(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _clearSearch,
              )
            : null,
      ),
      onChanged: (value) {
        if (value.length > 2) {
          _searchLocation(value);
        } else if (value.isEmpty) {
          setState(() {
            _searchResults = [];
          });
        }
      },
    );
  }

  Widget _buildSearchResultsList() {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.3,
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final place = _searchResults[index];
          final name = place['display_name'] ?? 'Unknown place';
          final lat = double.tryParse(place['lat'] ?? '0.0');
          final lon = double.tryParse(place['lon'] ?? '0.0');

          if (lat == null || lon == null) return const SizedBox.shrink();

          return ListTile(
            title: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis),
            dense: true,
            onTap: () {
              final latLng = LatLng(lat, lon);
              // Use the animated controller for smooth jump
              _animatedMapController.animateTo(dest: latLng, zoom: 14);
              setState(() {
                _selected = latLng;
                _address = name;
              });
              _clearSearch();
            },
          );
        },
      ),
    );
  }

  Future<void> _searchLocation(String query) async {
    // Search logic remains the same
    setState(() => _loading = true);

    final url = Uri.parse(
      "https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=5",
    );
    try {
      final res = await http.get(
        url,
        headers: {'User-Agent': 'flutter-map-app'},
      );
      if (res.statusCode == 200 && mounted) {
        final List data = jsonDecode(res.body);
        setState(() => _searchResults = List<Map<String, dynamic>>.from(data));
      }
    } catch (e) {
      debugPrint("Search error: $e");
    }

    setState(() => _loading = false);
  }

  void _clearSearch() {
    // Clear search logic remains the same
    _searchController.clear();
    setState(() {
      _searchResults = [];
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _loading = true);
    _clearSearch();

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled && mounted) {
      // ... (Error handling for disabled services)
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enable GPS or location services."),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      // ... (Error handling for denied permissions)
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              permission == LocationPermission.deniedForever
                  ? "Location permission permanently denied. Please enable it in Settings."
                  : "Location permission denied by user.",
            ),
            action: permission == LocationPermission.deniedForever
                ? SnackBarAction(
                    label: "Settings",
                    onPressed: Geolocator.openAppSettings,
                  )
                : null,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition();
      final latLng = LatLng(pos.latitude, pos.longitude);

      // 🌟 FIX: Use the animated controller for smooth movement
      await _animatedMapController.animateTo(
        dest: latLng,
        zoom: 15,
      );

      // Trigger geocoding for the new location
      _reverseGeocode(latLng);
    } catch (e) {
      debugPrint("Error getting location: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching location: $e")),
        );
      }
      setState(() => _loading = false);
    }
  }

  Future<void> _reverseGeocode(LatLng latLng) async {
    setState(() {
      _loading = true;
      _selected = latLng;
    });

    try {
      final placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        final addressParts = [
          p.name,
          p.street,
          p.locality,
          p.administrativeArea,
          p.postalCode,
          p.country,
        ];
        setState(() {
          _address = addressParts
              .where((part) => part != null && part.isNotEmpty)
              .join(', ');
        });
      }
    } catch (e) {
      debugPrint("Reverse geocode error: $e");
      if (mounted) {
        setState(() {
          _address = "Could not find address";
        });
      }
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }
}

class LocationPickerField extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final String? address;
  final void Function({
    required double latitude,
    required double longitude,
    required String address,
    required bool updateAddressField,
  })
  onLocationPicked;

  const LocationPickerField({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.onLocationPicked,
  });

  @override
  State<LocationPickerField> createState() => _LocationPickerFieldState();
}

class _LocationPickerFieldState extends State<LocationPickerField> {
  late LatLng? _position;
  late String? _address;

  @override
  void initState() {
    super.initState();
    _position = (widget.latitude != null && widget.longitude != null)
        ? LatLng(widget.latitude!, widget.longitude!)
        : null;
    _address = widget.address;
  }

  Future<void> _openPicker() async {
    final result = await showLocationPicker(context);
    if (result == null) return;

    final lat = result["latitude"] as double;
    final lon = result["longitude"] as double;
    final address = result["address"] as String? ?? "Unknown address";

    // ✅ Ask confirmation before updating the address field
    final shouldUpdate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update Address?"),
        content: Text(
          "Would you like to replace your current address with:\n\n$address",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes, update"),
          ),
        ],
      ),
    );

    // Default to false if dialog dismissed
    final updateAddressField = shouldUpdate ?? false;

    setState(() {
      _position = LatLng(lat, lon);
      _address = address;
    });

    // Pass the chosen data + user preference to parent
    widget.onLocationPicked(
      latitude: lat,
      longitude: lon,
      address: address,
      updateAddressField: updateAddressField,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Shop Location",
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _openPicker,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.colors.outline),
                color: context.colors.surfaceDim,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_position != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: _position!,
                          initialZoom: 15,
                          interactionOptions: const InteractionOptions(
                            flags: 0,
                          ), // disable pan/zoom
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                "https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=${dotenv.env["MAPTILER_API_KEY"]}",
                            userAgentPackageName: "com.example.app",
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _position!,
                                width: 40,
                                height: 40,
                                child: Icon(
                                  Icons.location_on,
                                  color: context.colors.primary,
                                  size: 38,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  else
                    const Center(
                      child: Icon(
                        Icons.map_outlined,
                        size: 60,
                        color: Colors.grey,
                      ),
                    ),
                  // Overlay
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      color: Colors.black.withOpacity(0.5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.open_in_full,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _address ?? "Tap to select location on map",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
