import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:local_auth/local_auth.dart';
import '../services/notification_service.dart'; // Integration

class MuraSecurityController extends ChangeNotifier {
  static final MuraSecurityController _instance =
      MuraSecurityController._internal();
  factory MuraSecurityController() => _instance;
  MuraSecurityController._internal();

  final LocalAuthentication auth = LocalAuthentication();

  bool _isTwoFactor = true;
  bool _isBiometric = false;
  bool _isEncrypted = false;

  bool get isTwoFactor => _isTwoFactor;
  bool get isBiometric => _isBiometric;
  bool get isEncrypted => _isEncrypted;

  void toggleTwoFactor(bool value) {
    _isTwoFactor = value;
    notifyListeners();
  }

  Future<void> toggleBiometric(bool value) async {
    if (value == true) {
      bool didAuthenticate = await _authenticateUser();
      if (didAuthenticate) {
        _isBiometric = true;
        MuraNotificationService().showInstantAlert(
          title: "ENCLAVE_ACTIVATED",
          body: "Biometric shield is now securing your registry.",
        );
      } else {
        _isBiometric = false;
      }
    } else {
      bool didAuthenticate = await _authenticateUser();
      if (didAuthenticate) {
        _isBiometric = false;
      }
    }
    notifyListeners();
  }

  Future<bool> _authenticateUser() async {
    try {
      final bool canAuth =
          await auth.canCheckBiometrics || await auth.isDeviceSupported();
      if (!canAuth) return false;

      return await auth.authenticate(
        localizedReason: 'AUTHENTICATE_TO_MODIFY_SECURE_ENCLAVE',
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: !kIsWeb,
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      debugPrint("Auth Error: $e");
      return false;
    }
  }

  void toggleEncryption(bool value) {
    _isEncrypted = value;
    notifyListeners();
  }

  void wipeAllSessions() {
    _isTwoFactor = false;
    _isBiometric = false;
    _isEncrypted = false;
    MuraNotificationService().showInstantAlert(
      title: "PROTOCOL_WIPE",
      body: "All remote sessions have been terminated.",
    );
    notifyListeners();
  }
}
