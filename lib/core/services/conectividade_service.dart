import 'package:connectivity_plus/connectivity_plus.dart';

class ConectividadeService {
  final Connectivity _connectivity = Connectivity();

  Stream<bool> monitorarConexao() {
    return _connectivity.onConnectivityChanged.map((results) {
      // results is a List<ConnectivityResult> in newer versions
      return results.any((result) => result != ConnectivityResult.none);
    });
  }

  Future<bool> temConexao() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }
}
