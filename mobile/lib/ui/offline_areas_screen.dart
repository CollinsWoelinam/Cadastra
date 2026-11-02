import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../app.dart';
import '../data/db.dart';
import '../geo/polygon_math.dart';
import '../geo/tiles.dart';
import '../services/offline_maps.dart';
import 'format.dart';
import 'survey_map.dart';

/// Areas saved on the device for fieldwork without signal.
class OfflineAreasScreen extends StatelessWidget {
  const OfflineAreasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = Services.of(context);
    final offline = services.offlineMaps;
    return Scaffold(
      appBar: AppBar(title: const Text('Offline maps')),
      body: Column(
        children: [
          ListenableBuilder(
            listenable: offline,
            builder: (context, _) => offline.progress == null
                ? const SizedBox.shrink()
                : LinearProgressIndicator(
                    value: offline.progress!.total == 0 ? null : offline.progress!.done / offline.progress!.total,
                  ),
          ),
          Expanded(
            child: StreamBuilder<List<OfflineArea>>(
              stream: services.db.watchOfflineAreas(),
              builder: (context, snapshot) {
                final areas = snapshot.data ?? [];
                return ListView(
                  padding: const EdgeInsets.only(bottom: 96),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        offline.savesTiles
                            ? 'Save the areas you will work in before leaving signal. Each saved area keeps the map '
                                  'and the registered parcels on this device, so boundaries and overlap warnings work offline.'
                            : 'Save the areas you will work in before leaving signal. Registered parcels are kept on this '
                                  'device so overlap warnings work offline. Map imagery cannot be saved with the current '
                                  'basemap provider; parcels and your boundary still show without it.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                      ),
                    ),
                    if (snapshot.hasData && areas.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No saved areas yet.', textAlign: TextAlign.center),
                      ),
                    for (final a in areas) _AreaTile(a),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: ListenableBuilder(
        listenable: offline,
        builder: (context, _) => FloatingActionButton.extended(
          onPressed: offline.downloading
              ? null
              : () async {
                  final message = await Navigator.of(
                    context,
                  ).push<String>(MaterialPageRoute(builder: (_) => const SaveAreaScreen()));
                  if (message != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                  }
                },
          icon: const Icon(Icons.download_for_offline),
          label: Text(offline.downloading ? 'Saving…' : 'Save an area'),
        ),
      ),
    );
  }
}

class _AreaTile extends StatelessWidget {
  final OfflineArea area;

  const _AreaTile(this.area);

  @override
  Widget build(BuildContext context) {
    final b = area.bounds;
    final width = PolygonMath.distance(LatLng(b.centre.latitude, b.west), LatLng(b.centre.latitude, b.east));
    final height = PolygonMath.distance(LatLng(b.south, b.west), LatLng(b.north, b.west));
    final details = [
      '${formatDistance(width)} × ${formatDistance(height)}',
      '${formatCount(area.parcelCount)} parcels',
      if (area.tileSource != null) '${formatCount(area.tileCount)} map tiles (${formatBytes(area.bytes)})',
      'updated ${formatDate(area.updatedAt)}',
    ].join(' · ');
    return ListTile(
      leading: Icon(
        area.complete ? Icons.offline_pin : Icons.error_outline,
        color: area.complete ? Colors.green.shade700 : Colors.orange.shade800,
      ),
      title: Text(area.name),
      subtitle: Text(area.complete ? details : '$details\nIncomplete — save this area again to fill the gaps.'),
      isThreeLine: !area.complete,
      trailing: PopupMenuButton<String>(
        onSelected: (action) => action == 'refresh' ? _refresh(context) : _delete(context),
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'refresh', child: Text('Update registered parcels')),
          PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
    );
  }

  Future<void> _refresh(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final n = await Services.read(context).offlineMaps.refreshParcels(area);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          n == null ? 'Could not reach the registry. Try again when online.' : 'Updated: $n registered parcels.',
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${area.name}?'),
        content: const Text(
          'Its saved map imagery is removed from this device. Registered parcels stay cached '
          'until they are next refreshed.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true && context.mounted) await Services.read(context).offlineMaps.delete(area);
  }
}

/// Picks an area on the map and saves it; pops with a summary message.
class SaveAreaScreen extends StatefulWidget {
  const SaveAreaScreen({super.key});

  @override
  State<SaveAreaScreen> createState() => _SaveAreaScreenState();
}

class _SaveAreaScreenState extends State<SaveAreaScreen> {
  static const _radii = [500.0, 1000.0, 2000.0];
  final _map = MapController();
  final _name = TextEditingController();
  LatLng _centre = const LatLng(5.6037, -0.1870);
  double _radiusM = 1000;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _centreOnDevice();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// Starts on the surveyor's position when a fix arrives quickly.
  Future<void> _centreOnDevice() async {
    final source = Services.read(context).positionSource();
    if (await source.prepare() != null) return;
    try {
      final fix = await source.fixes.first.timeout(const Duration(seconds: 8));
      if (!mounted) return;
      setState(() => _centre = fix.position);
      if (_mapReady) _fit();
    } on TimeoutException {
      // Stay where the map is; the surveyor can pan.
    }
  }

  GeoBounds get _bounds => GeoBounds.around(_centre, _radiusM);

  void _fit() {
    final b = _bounds;
    _map.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(LatLng(b.south, b.west), LatLng(b.north, b.east)),
        padding: const EdgeInsets.all(32),
      ),
    );
  }

  Future<void> _save() async {
    final offline = Services.read(context).offlineMaps;
    final name = _name.text.trim().isEmpty
        ? 'Area near ${_centre.latitude.toStringAsFixed(4)}, ${_centre.longitude.toStringAsFixed(4)}'
        : _name.text.trim();
    final message = await offline.download(name, _bounds);
    if (mounted) Navigator.of(context).pop(message);
  }

  @override
  Widget build(BuildContext context) {
    final services = Services.of(context);
    final offline = services.offlineMaps;
    final b = _bounds;
    return Scaffold(
      appBar: AppBar(title: const Text('Save an area')),
      // The panel is part of the body (not bottomNavigationBar) so it rises above the keyboard.
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _map,
                  options: MapOptions(
                    initialCenter: _centre,
                    initialZoom: 14,
                    maxZoom: 19,
                    onMapReady: () {
                      _mapReady = true;
                      _fit();
                    },
                    onPositionChanged: (camera, hasGesture) {
                      if (hasGesture) setState(() => _centre = camera.center);
                    },
                  ),
                  children: [
                    if (services.showBasemap) const BasemapLayer(),
                    PolygonLayer(
                      polygons: [
                        Polygon(
                          points: [
                            LatLng(b.south, b.west),
                            LatLng(b.south, b.east),
                            LatLng(b.north, b.east),
                            LatLng(b.north, b.west),
                          ],
                          color: Colors.blue.withValues(alpha: 0.08),
                          borderColor: Colors.blue.shade700,
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                    if (services.showBasemap) const BasemapAttribution(),
                  ],
                ),
                const IgnorePointer(
                  child: Center(child: Icon(Icons.add, size: 32, color: Colors.black87)),
                ),
              ],
            ),
          ),
          ListenableBuilder(listenable: offline, builder: (context, _) => _panel(offline)),
        ],
      ),
    );
  }

  Widget _panel(OfflineMaps offline) {
    final tiles = offline.tileCount(_bounds);
    final tooBig = tiles > OfflineMaps.maxTiles;
    final progress = offline.progress;
    return Material(
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (progress == null) ...[
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'e.g. East Legon block C',
                    isDense: true,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                SegmentedButton<double>(
                  segments: [
                    for (final r in _radii) ButtonSegment(value: r, label: Text('${(r * 2 / 1000).round()} km')),
                  ],
                  selected: {_radiusM},
                  onSelectionChanged: (s) {
                    setState(() => _radiusM = s.single);
                    if (_mapReady) _fit();
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  key: const Key('estimate'),
                  !offline.savesTiles
                      ? 'Registered parcels only — the current basemap provider does not allow saving map imagery.'
                      : tooBig
                      ? 'Too large to save at once. Choose a smaller area.'
                      : 'About ${formatCount(tiles)} map tiles (≈ ${formatBytes(tiles * OfflineMaps.avgTileBytes)}) '
                            'plus registered parcels.',
                  style: TextStyle(color: tooBig ? Colors.red.shade700 : Colors.black54),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  key: const Key('save-area'),
                  onPressed: tooBig ? null : _save,
                  icon: const Icon(Icons.download),
                  label: const Text('Save for offline use'),
                ),
              ] else ...[
                Text(
                  progress.total == 0
                      ? 'Saving registered parcels…'
                      : 'Saving map tiles: ${formatCount(progress.done)} of ${formatCount(progress.total)}',
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: progress.total == 0 ? null : progress.done / progress.total),
                const SizedBox(height: 8),
                OutlinedButton(onPressed: offline.cancel, child: const Text('Cancel')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
