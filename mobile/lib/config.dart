import 'dart:io';

/// Core Engine base URL. Override with --dart-define=CADASTRA_API_URL=http://host:8000.
/// The Android emulator reaches the host machine at 10.0.2.2.
final String apiBaseUrl = const String.fromEnvironment('CADASTRA_API_URL').isNotEmpty
    ? const String.fromEnvironment('CADASTRA_API_URL')
    : (Platform.isAndroid ? 'http://10.0.2.2:8000' : 'http://localhost:8000');
