import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signature/signature.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/app_colors.dart';

class AssinaturaScreen extends StatefulWidget {
  final String atendimentoId;
  const AssinaturaScreen({super.key, required this.atendimentoId});

  @override
  State<AssinaturaScreen> createState() => _AssinaturaScreenState();
}

class _AssinaturaScreenState extends State<AssinaturaScreen> {
  late SignatureController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
    // Força orientação paisagem
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
  }

  @override
  void dispose() {
    // Volta para retrato ao sair
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    if (_controller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, assine antes de confirmar.')),
      );
      return;
    }

    final Uint8List? data = await _controller.toPngBytes();
    if (data != null) {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/assinatura_${widget.atendimentoId}.png';
      final file = File(path);
      await file.writeAsBytes(data);
      if (mounted) {
        Navigator.pop(context, path);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Por favor, assine abaixo para confirmar o atendimento',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => _controller.clear(),
                        child: const Text('Limpar'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _confirmar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Confirmar Assinatura'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Signature(
                  controller: _controller,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
