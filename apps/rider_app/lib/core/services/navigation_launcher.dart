import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../map/geo_point.dart';

/// Signature for a function that checks whether a [Uri] can be handled.
///
/// Mirrors `url_launcher`'s `canLaunchUrl` and is injectable so the launch
/// behavior can be exercised in tests without a platform channel.
typedef CanLaunch = Future<bool> Function(Uri uri);

/// Signature for a function that launches a [Uri] in an external application.
///
/// Mirrors `url_launcher`'s `launchUrl` (with [LaunchMode.externalApplication])
/// and is injectable for testing.
typedef Launch = Future<bool> Function(Uri uri);

Future<bool> _defaultCanLaunch(Uri uri) => canLaunchUrl(uri);

Future<bool> _defaultLaunch(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

/// Hands off device-level actions (turn-by-turn navigation and phone dialing)
/// to external apps.
///
/// The URI builders ([buildGeoUri], [buildGoogleMapsUri], [buildWazeUri], and
/// [buildTelUri]) are pure, static functions so they can be unit- and
/// property-tested independently of any platform channel. The instance methods
/// ([openExternalNavigation] and [dial]) use `url_launcher` to attempt the
/// launch and report success as a boolean rather than throwing.
class NavigationLauncher {
  /// Creates a launcher.
  ///
  /// [canLaunch] and [launch] default to `url_launcher`'s `canLaunchUrl` and
  /// `launchUrl` respectively; they can be overridden in tests.
  const NavigationLauncher({
    CanLaunch canLaunch = _defaultCanLaunch,
    Launch launch = _defaultLaunch,
  })  : _canLaunch = canLaunch,
        _launch = launch;

  final CanLaunch _canLaunch;
  final Launch _launch;

  /// Builds a `geo:` URI for [destination] that encodes both its latitude and
  /// longitude (e.g. `geo:23.78,90.41?q=23.78,90.41`).
  ///
  /// Pure and independently testable (Property 10).
  static Uri buildGeoUri(GeoPoint destination) {
    final coords = '${destination.latitude},${destination.longitude}';
    return Uri(scheme: 'geo', path: coords, queryParameters: {'q': coords});
  }

  /// Builds a Google Maps directions URL that encodes [destination]'s latitude
  /// and longitude. Used as a cross-platform fallback when the `geo:` scheme is
  /// not handled by any installed app.
  static Uri buildGoogleMapsUri(GeoPoint destination) {
    return Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${destination.latitude},${destination.longitude}',
    });
  }

  /// Builds a Waze deep link that encodes [destination]'s latitude and
  /// longitude and requests immediate navigation.
  static Uri buildWazeUri(GeoPoint destination) {
    return Uri.https('waze.com', '/ul', {
      'll': '${destination.latitude},${destination.longitude}',
      'navigate': 'yes',
    });
  }

  /// Android Google Maps turn-by-turn (`google.navigation:` intent).
  static Uri buildGoogleNavigationUri(GeoPoint destination) {
    final coords = '${destination.latitude},${destination.longitude}';
    return Uri(
      scheme: 'google.navigation',
      queryParameters: {'q': coords, 'mode': 'd'},
    );
  }

  /// iOS Google Maps app deep link.
  static Uri buildGoogleMapsAppUri(GeoPoint destination) {
    final coords = '${destination.latitude},${destination.longitude}';
    return Uri(
      scheme: 'comgooglemaps',
      queryParameters: {
        'daddr': coords,
        'directionsmode': 'driving',
      },
    );
  }

  /// iOS Apple Maps directions.
  static Uri buildAppleMapsUri(GeoPoint destination) {
    final coords = '${destination.latitude},${destination.longitude}';
    return Uri.https('maps.apple.com', '/', {
      'daddr': coords,
      'dirflg': 'd',
    });
  }

  /// Platform-ordered URIs for external turn-by-turn navigation.
  static List<Uri> navigationUriCandidates(GeoPoint destination) {
    final candidates = <Uri>[];

    if (!kIsWeb) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          candidates.add(buildGoogleNavigationUri(destination));
          break;
        case TargetPlatform.iOS:
          candidates.add(buildGoogleMapsAppUri(destination));
          candidates.add(buildAppleMapsUri(destination));
          break;
        default:
          break;
      }
    }

    candidates.addAll([
      buildGeoUri(destination),
      buildGoogleMapsUri(destination),
      buildWazeUri(destination),
    ]);

    return candidates;
  }

  /// Builds a `tel:` URI that encodes [phoneNumber].
  ///
  /// Pure and independently testable (Property 12). The scheme is always `tel`
  /// and the (decoded) path is the supplied number.
  static Uri buildTelUri(String phoneNumber) {
    return Uri(scheme: 'tel', path: phoneNumber);
  }

  /// Attempts to open [destination] in an external navigation app, trying the
  /// `geo:` scheme first, then Google Maps, then Waze.
  ///
  /// Returns `true` as soon as one handler successfully launches; returns
  /// `false` if no handler is available or every launch attempt fails
  /// (Requirements 4.4, 4.5).
  Future<bool> openExternalNavigation(GeoPoint destination) async {
    for (final uri in navigationUriCandidates(destination)) {
      if (await _tryLaunch(uri)) return true;
    }
    return false;
  }

  /// Launches the device dialer for [phoneNumber] via a `tel:` URI.
  ///
  /// Returns `false` if the dialer cannot be launched (Requirements 5.2, 5.6).
  Future<bool> dial(String phoneNumber) {
    return _tryLaunch(buildTelUri(phoneNumber));
  }

  /// Launches [uri] in an external app. On Android 11+, [canLaunchUrl] often
  /// returns false even when Google Maps is installed, so we try [launch] first.
  Future<bool> _tryLaunch(Uri uri) async {
    try {
      if (await _launch(uri)) return true;
      if (await _canLaunch(uri)) {
        return await _launch(uri);
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
