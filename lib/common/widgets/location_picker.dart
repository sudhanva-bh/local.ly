import 'dart:async';
import 'dart:convert';
import 'dart:ui'; // Required for ImageFilter and BackdropFilter
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:locally/common/extensions/content_extensions.dart';

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
  State<_ModernLocationPicker> createState() => _ModernLocationPickerState();
}

class _ModernLocationPickerState extends State<_ModernLocationPicker>
    with TickerProviderStateMixin {
  late final MapController _mapController;
  late final AnimatedMapController _animatedMapController;

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
    _mapController = MapController();
    _animatedMapController = AnimatedMapController(
      vsync: this,
      mapController: _mapController,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
    );
    _selected = _defaultCenter;
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
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

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: mq.size.height * 0.85,
          decoration: BoxDecoration(
            // Slightly opaque white background for the modal base
            color: Colors.white.withOpacity(0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.5), width: 1),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Drag Handle
              Container(
                height: 5,
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Stack(
                  children: [
                    // Map Layer
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _defaultCenter,
                        initialZoom: 4,
                        onPositionChanged: _onMapMoved,
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
                        backgroundColor: Colors.white,
                        foregroundColor: theme.colorScheme.primary,
                        child: const Icon(Icons.my_location),
                      ),
                    ),

                    // Search Bar and Results Overlay
                    Positioned(
                      top: 10,
                      left: 10,
                      right: 10,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildSearchBar(),
                          if (_searchResults.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            // Results Container
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 10,
                                  sigmaY: 10,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.85),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                  ),
                                  child: _buildSearchResultsList(),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Loading Indicator
                    if (_loading)
                      Container(
                        color: Colors.black.withOpacity(0.1),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
              ),
              // Selected Address Display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  border: Border(
                    top: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      "Selected Location",
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _address ?? "Loading address...",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
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
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onMapMoved(MapPosition position, bool hasGesture) {
    final newCenter = position.center;
    setState(() {
      _selected = newCenter;
      _address = "Loading address...";
    });
    _debounce?.cancel();
    if (newCenter != null) {
      _debounce = Timer(const Duration(milliseconds: 500), () {
        _reverseGeocode(_mapController.camera.center);
      });
    }
  }

  Widget _buildSearchBar() {
    // Glass Search Bar Style
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            hintText: "Search for a place...",
            hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.black.withOpacity(0.6),
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(
              0.7,
            ), // High opacity for readability
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white, width: 2),
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.black54),
                    onPressed: _clearSearch,
                  )
                : null,
          ),
          onChanged: (value) {
            if (value.length > 2) {
              _searchLocation(value);
            } else if (value.isEmpty) {
              setState(() => _searchResults = []);
            }
          },
        ),
      ),
    );
  }

  Widget _buildSearchResultsList() {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.3,
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _searchResults.length,
        separatorBuilder: (ctx, i) => Divider(
          height: 1,
          thickness: 1,
          color: Colors.grey.withOpacity(0.2),
        ),
        itemBuilder: (context, index) {
          final place = _searchResults[index];
          final name = place['display_name'] ?? 'Unknown place';
          final lat = double.tryParse(place['lat'] ?? '0.0');
          final lon = double.tryParse(place['lon'] ?? '0.0');

          if (lat == null || lon == null) return const SizedBox.shrink();

          return ListTile(
            title: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
            dense: true,
            onTap: () {
              final latLng = LatLng(lat, lon);
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

  // ... _searchLocation, _clearSearch, _useCurrentLocation, _reverseGeocode methods remain same ...
  Future<void> _searchLocation(String query) async {
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
    _searchController.clear();
    setState(() => _searchResults = []);
    FocusScope.of(context).unfocus();
  }

  Future<bool> _requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, handle appropriately
      return Future.error('Location services are disabled.');
    }

    // Check current permission status
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Permissions are denied, request them
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are still denied, handle appropriately
        return Future.error('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are permanently denied, direct user to settings
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    // Permissions are granted, proceed with location retrieval
    return true;
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _loading = true);
    _clearSearch();
    // ... (Previous Geolocator logic here, abbreviated for brevity)
    // Assuming permission logic is same as before
    try {
      if (await _requestLocationPermission()) {
        final pos = await Geolocator.getCurrentPosition();
        final latLng = LatLng(pos.latitude, pos.longitude);
        await _animatedMapController.animateTo(dest: latLng, zoom: 16.5);
        _reverseGeocode(latLng);
      }
    } catch (e) {
      
    }
    setState(() => _loading = false);
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
      // ... error handling
    }
    if (mounted) setState(() => _loading = false);
  }
}

// --- GLASSMORPHISM PREVIEW FIELD ---
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

    final updateAddressField = shouldUpdate ?? false;

    setState(() {
      _position = LatLng(lat, lon);
      _address = address;
    });

    widget.onLocationPicked(
      latitude: lat,
      longitude: lon,
      address: address,
      updateAddressField: updateAddressField,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _openPicker,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(23),
            child: BackdropFilter(
              // Apply blur to background behind this card
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 180,
                decoration: BoxDecoration(
                  // Glassmorphism Fill
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(23),
                  // Glassmorphism Border
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_position != null)
                      FlutterMap(
                        options: MapOptions(
                          initialCenter: _position!,
                          initialZoom: 15,
                          interactionOptions: const InteractionOptions(
                            flags: 0,
                          ),
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
                      )
                    else
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.map_outlined,
                              size: 50,
                              color: Colors.white.withOpacity(0.5),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Tap to select location",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Address overlay - darker glass gradient for readability
                    if (_position != null)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.8),
                                Colors.black.withOpacity(0.0),
                              ],
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.place_outlined,
                                color: Colors.white.withOpacity(0.9),
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _address ?? "Tap to select location on map",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
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
        ),
      ],
    );
  }
}
