import 'dart:io';
import 'package:flutter/foundation.dart';
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

    // Retorna a posição atual com alta precisão e timeout para evitar travamentos
    try {
      LocationSettings locationSettings;

      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
          timeLimit: const Duration(seconds: 5), // Limite de 5 segundos
        );
      } else {
        locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
          timeLimit: const Duration(seconds: 5),
        );
      }

      // Tenta pegar a posição atual com timeout
      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: locationSettings,
        ).timeout(const Duration(seconds: 5));
      } catch (_) {
        // Se der timeout ou erro, tenta a última posição conhecida
        return await Geolocator.getLastKnownPosition();
      }
    } catch (e) {
      // Em caso de erro, tenta ao menos a última conhecida
      return await Geolocator.getLastKnownPosition();
    }
  }
}
