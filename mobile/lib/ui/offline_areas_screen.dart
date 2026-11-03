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
import 'theme.dart';
import 'widgets.dart';

/// Areas saved on the device for fieldwork without signal.
class OfflineAreasScreen extends StatelessWidget {
  const OfflineAreasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = Services.of(context);
    final offline = services.offlineMaps;
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<List<OfflineArea>>(
          stream: services.db.watchOfflineAreas(),
          builder: (context, snapshot) {
            final areas = snapshot.data ?? [];
            final bytes = areas.fold<int>(0, (sum, a) => sum + a.bytes);
            return ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 96), children: [
              const Text('Offline maps', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                offline.savesTiles
                    ? 'Save the areas you will survey before leaving signal. Map, registered parcels and overlap '
                        'warnings then work offline.'
                    : 'Save the areas you will survey before leaving signal. Registered parcels and overlap warnings '
                        'then work offline. Map imagery cannot be saved with the current basemap provider.',
                style: const TextStyle(color: Palette.muted, height: 1.45),
              ),
              const SizedBox(height: 14),
              if (areas.isNotEmpty)
                Panel(
                  child: Row(children: [
                    const Text('Saved on this device', style: TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('${areas.length} area${areas.length == 1 ? '' : 's'}${bytes > 0 ? ' · ${formatBytes(bytes)}' : ''}',
                        style: const TextStyle(color: Palette.muted)),
                  ]),
                ),
              const SizedBox(height: 10),
              ListenableBuilder(listenable: offline, builder: (context, _) => _Saving(offline)),
              if (snapshot.hasData && areas.isEmpty && !offline.downloading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No saved areas yet.', textAlign: TextAlign.center, style: TextStyle(color: Palette.muted)),
                ),
              for (final a in areas)
                if (!(offline.downloading && !a.complete && a.name == offline.savingName))
                  Padding(padding: const EdgeInsets.only(bottom: 10), child: _AreaCard(a)),
            ]);
          },
        ),
      ),
      floatingActionButton: ListenableBuilder(
        listenable: offline,
        builder: (context, _) => FloatingActionButton.extended(
          heroTag: 'save-area',
          onPressed: offline.downloading
              ? null
              : () async {
                  final message = await Navigator.of(context)
                      .push<String>(MaterialPageRoute(builder: (_) => const SaveAreaScreen()));
                  if (message != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                  }
                },
          icon: const Icon(Icons.add_location_alt_outlined),
          label: Text(offline.downloading ? 'Saving…' : 'Save an area'),
        ),
      ),
    );
  }
}

/// The area being saved right now, with progress and Cancel.
class _Saving extends StatelessWidget {
  final OfflineMaps offline;

  const _Saving(this.offline);

  @override
  Widget build(BuildContext context) {
    final progress = offline.progress;
    if (progress == null) return const SizedBox.shrink();
    final fraction = progress.total == 0 ? null : progress.done / progress.total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Panel(
        borderColor: Palette.green,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const _AreaIcon(Icons.downloading, Tone.green),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(offline.savingName ?? 'Saving', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(progress.total == 0 ? 'Saving registered parcels…' : 'Saving map tiles',
                    style: const TextStyle(fontSize: 13, color: Palette.muted)),
              ]),
            ),
            OutlinedButton(onPressed: offline.cancel, child: const Text('Cancel')),
          ]),
          const SizedBox(height: 10),
          ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: fraction, minHeight: 8)),
          if (progress.total > 0) ...[
            const SizedBox(height: 6),
            Text('${formatCount(progress.done)} of ${formatCount(progress.total)} tiles',
                style: const TextStyle(fontSize: 13, color: Palette.ink2)),
          ],
        ]),
      ),
    );
  }
}

class _AreaIcon extends StatelessWidget {
  final IconData icon;
  final Tone tone;

  const _AreaIcon(this.icon, this.tone);

  @override
  Widget build(BuildContext context) => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: tone.tint, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: tone.text),
      );
}

class _AreaCard extends StatelessWidget {
  final OfflineArea area;

  const _AreaCard(this.area);

  @override
  Widget build(BuildContext context) {
    final b = area.bounds;
    final width = PolygonMath.distance(LatLng(b.centre.latitude, b.west), LatLng(b.centre.latitude, b.east));
    final details = [
      formatDistance(width),
      '${formatCount(area.parcelCount)} parcels',
      if (area.tileSource != null) '${formatCount(area.tileCount)} tiles (${formatBytes(area.bytes)})',
    ].join(' · ');
    return Panel(
      borderColor: area.complete ? Palette.line : Palette.amberLine,
      padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
      child: Row(children: [
        area.complete ? const _AreaIcon(Icons.check, Tone.green) : const _AreaIcon(Icons.error_outline, Tone.amber),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(area.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(details, style: const TextStyle(fontSize: 13, color: Palette.muted)),
            Text(
              area.complete ? 'Updated ${formatDate(area.updatedAt)}' : 'Incomplete · save it again to fill the gaps',
              style: TextStyle(
                fontSize: 12,
                color: area.complete ? Palette.muted : Palette.amberInk,
                fontWeight: area.complete ? FontWeight.w400 : FontWeight.w600,
              ),
            ),
          ]),
        ),
        PopupMenuButton<String>(
          tooltip: 'More actions for ${area.name}',
          onSelected: (action) => action == 'refresh' ? _refresh(context) : _delete(context),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'refresh', child: Text('Update registered parcels')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ]),
    );
  }

  Future<void> _refresh(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final n = await Services.read(context).offlineMaps.refreshParcels(area);
    messenger.showSnackBar(SnackBar(
      content: Text(n == null ? 'Could not reach the registry. Try again when online.' : 'Updated: $n registered parcels.'),
    ));
  }

  Future<void> _delete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${area.name}?'),
        content: const Text('Its saved map imagery is removed from this device. Registered parcels stay cached '
            'until they are next refreshed.'),
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
