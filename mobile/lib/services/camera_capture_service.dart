import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// The four possible outcomes of a runtime permission request, per the
/// Week 14 rubric: granted, denied, permanently denied, or restricted
/// (parental controls / device policy on iOS).
enum CameraPermissionState { granted, denied, permanentlyDenied, restricted }

class CameraCaptureResult {
  const CameraCaptureResult._(this.state, {this.filePath});

  final CameraPermissionState state;
  final String? filePath;

  bool get isGranted => state == CameraPermissionState.granted;
}

/// Wraps camera permission handling and photo capture for attaching a
/// receipt photo to an expense. The permission is requested only when the
/// user taps the capture action, never at app startup.
class CameraCaptureService {
  CameraCaptureService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<CameraPermissionState> checkStatus() async {
    return _map(await Permission.camera.status);
  }

  Future<CameraCaptureResult> captureReceiptPhoto() async {
    var status = await Permission.camera.status;
    if (status.isDenied) {
      status = await Permission.camera.request();
    }
    final state = _map(status);
    if (state != CameraPermissionState.granted) {
      return CameraCaptureResult._(state);
    }
    final photo = await _picker.pickImage(source: ImageSource.camera, maxWidth: 1600, imageQuality: 85);
    return CameraCaptureResult._(CameraPermissionState.granted, filePath: photo?.path);
  }

  Future<bool> openSettings() => openAppSettings();

  CameraPermissionState _map(PermissionStatus status) {
    if (status.isGranted) return CameraPermissionState.granted;
    if (status.isPermanentlyDenied) return CameraPermissionState.permanentlyDenied;
    if (status.isRestricted || status.isLimited) return CameraPermissionState.restricted;
    return CameraPermissionState.denied;
  }
}
