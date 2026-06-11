import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app/app.dart';
import 'firebase_options.dart';
import 'core/services/notificacao_service.dart';

void main() async {
  try {
    debugPrint('--- [ÍNTEGRA] INICIANDO INICIALIZAÇÃO ---');
    WidgetsFlutterBinding.ensureInitialized();
    
    debugPrint('--- [ÍNTEGRA] INICIALIZANDO FIREBASE ---');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    debugPrint('--- [ÍNTEGRA] CONFIGURANDO FIRESTORE ---');
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    debugPrint('--- [ÍNTEGRA] INICIALIZANDO NOTIFICAÇÕES ---');
    await NotificacaoService.inicializar();

    debugPrint('--- [ÍNTEGRA] EXECUTANDO RUNAPP ---');
    runApp(const IntegraApp());
  } catch (e, stack) {
    debugPrint('!!! [ÍNTEGRA] ERRO CRÍTICO NA INICIALIZAÇÃO !!!');
    debugPrint('Erro: $e');
    debugPrint('Stacktrace: $stack');
    
    runApp(MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.red, size: 64),
                  const SizedBox(height: 24),
                  const Text(
                    'Erro ao Iniciar Aplicativo',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SelectableText(
                    e.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                  const SizedBox(height: 24),
                  const Text('Por favor, reinicie o aplicativo ou verifique sua conexão.'),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
  }
}
