import 'dart:io';
import 'package:geolocator/geolocator.dart';

class GpsService {
  /// Captura a localização atual do dispositivo.
  /// Retorna null se as permissões forem negadas ou o serviço estiver desativado.
  Future<Position?> capturarLocalizacao() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verifica se os serviços de localização estão ativos
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissões negadas
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissões negadas permanentemente
      return null;
    }

    // Retorna a posição atual com alta precisão
    try {
      LocationSettings locationSettings;

      if (Platform.isAndroid) {
        locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        );
      } else {
        locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        );
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
    } catch (e) {
      return null;
    }
  }
}
