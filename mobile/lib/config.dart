import 'dart:io';

/// Core Engine base URL. Override with --dart-define=CADASTRA_API_URL=http://host:8000.
/// The Android emulator reaches the host machine at 10.0.2.2.
final String apiBaseUrl = const String.fromEnvironment('CADASTRA_API_URL').isNotEmpty
    ? const String.fromEnvironment('CADASTRA_API_URL')
    : (Platform.isAndroid ? 'http://10.0.2.2:8000' : 'http://localhost:8000');

/// Basemap raster tiles. The public OpenStreetMap servers are for development only;
/// set a commercial or self-hosted source for deployment, e.g.
/// --dart-define=BASEMAP_URL=https://tiles.example.com/{z}/{x}/{y}.png
/// --dart-define=BASEMAP_ATTRIBUTION='© Example, © OpenStreetMap contributors'
const String basemapUrl = String.fromEnvironment('BASEMAP_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png');
const String basemapAttribution =
    String.fromEnvironment('BASEMAP_ATTRIBUTION', defaultValue: '© OpenStreetMap contributors');
