import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../constants/api_keys.dart';

class AssistenteService {
  static const String _model = 'gemini-2.5-flash';
  static const String _baseUrl = 
    'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';
  
  final List<Map<String, dynamic>> _historico = [];
  
  static const String _systemPrompt = '''
    INSTRUÇÃO DE SISTEMA: Você é um assistente clínico especializado em 
    Práticas Integrativas e Complementares em Saúde (PICS) do NUPICS-UERN.
    Responda sempre em português brasileiro de forma clara e baseada em evidências.
    Nunca substitua consulta médica. Mantenha respostas concisas.
  ''';

  Future<String> enviarMensagem(String mensagem) async {
    // Se o histórico estiver vazio, adicionamos o prompt de sistema como a primeira mensagem
    if (_historico.isEmpty) {
      _historico.add({
        'role': 'user',
        'parts': [{'text': _systemPrompt}]
      });
      _historico.add({
        'role': 'model',
        'parts': [{'text': 'Entendido. Sou o assistente do NUPICS-UERN. Como posso ajudar?'}]
      });
    }

    _historico.add({
      'role': 'user',
      'parts': [{'text': mensagem}]
    });

    final body = {
      'contents': _historico,
      'generationConfig': {
        'maxOutputTokens': 2048,
        'temperature': 0.7,
      }
    };

    try {
      final url = '$_baseUrl?key=$geminiApiKey';
      
      final response = await http.post(
        Uri.parse(url),
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
        debugPrint('!!! [ASSISTENTE] Erro API (Status ${response.statusCode}) !!!');
        debugPrint('Resposta: ${response.body}');
        
        try {
          final errorData = jsonDecode(response.body);
          return 'Erro na API (${response.statusCode}): ${errorData['error']['message']}';
        } catch (_) {
          return 'Erro na API (${response.statusCode}). Verifique se sua chave é válida.';
        }
      }
    } catch (e) {
      debugPrint('!!! [ASSISTENTE] Erro de Conexão: $e !!!');
      return 'Erro de conexão: Verifique sua internet.';
    }
  }

  void limparHistorico() {
    _historico.clear();
  }
}
