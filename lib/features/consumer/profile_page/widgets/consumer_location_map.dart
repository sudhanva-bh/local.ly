// lib/features/consumer/profile/widgets/consumer_location_map.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/models/users/consumer_model.dart';

class ConsumerLocationMap extends StatelessWidget {
  final ConsumerModel consumer;

  const ConsumerLocationMap({super.key, required this.consumer});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    
    if (consumer.latitude == null || consumer.longitude == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.outlineVariant),
              color: colors.surfaceDim,
            ),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(
                  consumer.latitude!,
                  consumer.longitude!,
                ),
                initialZoom: 16,
                interactionOptions: const InteractionOptions(flags: 0),
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
                      point: LatLng(consumer.latitude!, consumer.longitude!),
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.location_on,
                        color: colors.primary,
                        size: 38,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          consumer.address ?? '',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}