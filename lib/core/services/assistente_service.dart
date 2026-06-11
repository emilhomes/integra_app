import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../constants/api_keys.dart';

class AssistenteService {
  static const String _model = 'gemini-2.0-flash';
  static const String _baseUrl = 
    'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';
  
  final List<Map<String, dynamic>> _historico = [];
  
  static const String _systemPrompt = '''
    Você é um assistente clínico especializado em 
    Práticas Integrativas e Complementares em Saúde (PICS).
    Você auxilia profissionais e estagiários do NUPICS-UERN.
    Responda sempre em português brasileiro.
    Seja objetivo, claro e baseado em evidências.
    Áreas de conhecimento: acupuntura auricular, aromaterapia, 
    massoterapia, reiki, ventosaterapia e outras PICS.
    Importante: nunca substitua consulta médica profissional.
    Mantenha respostas concisas (máximo 3 parágrafos).
  ''';

  Future<String> enviarMensagem(String mensagem) async {
    _historico.add({
      'role': 'user',
      'parts': [{'text': mensagem}]
    });

    final body = {
      'system_instruction': {
        'parts': [{'text': _systemPrompt}]
      },
      'contents': _historico,
      'generationConfig': {
        'maxOutputTokens': 1024,
        'temperature': 0.7,
      }
    };

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$geminiApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final resposta = data['candidates'][0]['content']
            ['parts'][0]['text'] as String;
        
        _historico.add({
          'role': 'model',
          'parts': [{'text': resposta}]
        });
        
        return resposta;
      } else {
        debugPrint('Erro API: ${response.body}');
        return 'Erro ao processar sua pergunta. Tente novamente.';
      }
    } catch (e) {
      debugPrint('Erro: $e');
      return 'Erro de conexão. Verifique sua internet.';
    }
  }

  void limparHistorico() {
    _historico.clear();
  }
}
