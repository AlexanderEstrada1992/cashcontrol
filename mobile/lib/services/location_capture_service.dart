import 'package:geolocator/geolocator.dart';

/// Location availability is split in two independent conditions, as required
/// by the Week 14 guide: the runtime permission state, and the device's
/// location service (GPS) being turned on or off.
enum LocationAvailability { granted, denied, permanentlyDenied, restricted, serviceDisabled }

class LocationCaptureResult {
  const LocationCaptureResult._(this.state, {this.latitude, this.longitude});

  final LocationAvailability state;
  final double? latitude;
  final double? longitude;

  bool get isGranted => state == LocationAvailability.granted && latitude != null;
}

/// Wraps location permission handling and coordinate capture for tagging an
/// expense with the place where it happened. The permission is requested
/// only when the user taps the "attach location" action.
class LocationCaptureService {
  Future<LocationCaptureResult> captureCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationCaptureResult._(LocationAvailability.serviceDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    switch (permission) {
      case LocationPermission.deniedForever:
        return const LocationCaptureResult._(LocationAvailability.permanentlyDenied);
      case LocationPermission.denied:
        return const LocationCaptureResult._(LocationAvailability.denied);
      case LocationPermission.unableToDetermine:
        return const LocationCaptureResult._(LocationAvailability.restricted);
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        break;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 10)),
    );
    return LocationCaptureResult._(LocationAvailability.granted, latitude: position.latitude, longitude: position.longitude);
  }

  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
