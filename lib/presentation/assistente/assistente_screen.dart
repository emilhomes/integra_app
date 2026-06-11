import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../core/services/assistente_service.dart';
import '../../core/constants/api_keys.dart';

class AssistenteScreen extends StatefulWidget {
  const AssistenteScreen({super.key});

  @override
  State<AssistenteScreen> createState() => _AssistenteScreenState();
}

class _AssistenteScreenState extends State<AssistenteScreen> {
  final _assistenteService = AssistenteService();
  final _mensagemController = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, String>> _mensagens = [
    {
      'role': 'ia',
      'text': 'Olá! Sou o assistente do ÍNTEGRA. Posso ajudar com dúvidas sobre práticas integrativas, técnicas terapêuticas e protocolos clínicos. Como posso te ajudar hoje?'
    }
  ];
  bool _estaDigitando = false;

  @override
  void dispose() {
    _mensagemController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _enviarMensagem() async {
    final texto = _mensagemController.text.trim();
    if (texto.isEmpty) return;

    setState(() {
      _mensagens.add({'role': 'user', 'text': texto});
      _mensagemController.clear();
      _estaDigitando = true;
    });
    _scrollToBottom();

    final resposta = await _assistenteService.enviarMensagem(texto);

    if (mounted) {
      setState(() {
        _mensagens.add({'role': 'ia', 'text': resposta});
        _estaDigitando = false;
      });
      _scrollToBottom();
    }
  }

  void _limparChat() {
    setState(() {
      _mensagens.clear();
      _mensagens.add({
        'role': 'ia',
        'text': 'Olá! Sou o assistente do ÍNTEGRA. Posso ajudar com dúvidas sobre práticas integrativas, técnicas terapêuticas e protocolos clínicos. Como posso te ajudar hoje?'
      });
      _assistenteService.limparHistorico();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Assistente ÍNTEGRA',
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                final response = await http.get(
                  Uri.parse(
                    'https://generativelanguage.googleapis.com/v1beta/models?key=$geminiApiKey'
                  ),
                );
                debugPrint('Modelos disponíveis: ${response.body}');
              } catch (e) {
                debugPrint('Erro: $e');
              }
            },
            child: const Text('Listar Modelos', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white),
            onPressed: _limparChat,
            tooltip: 'Limpar conversa',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _mensagens.length,
              itemBuilder: (context, index) {
                final msg = _mensagens[index];
                final isUser = msg['role'] == 'user';
                return _buildChatBubble(msg['text'] ?? '', isUser);
              },
            ),
          ),
          if (_estaDigitando) _buildTypingIndicator(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isUser) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.eco_rounded, color: Colors.green, size: 20),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF7C3AED) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 0),
                  bottomRight: Radius.circular(isUser ? 0 : 16),
                ),
                boxShadow: [
                  if (!isUser)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Text(
                text,
                style: GoogleFonts.outfit(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 32), // Espaço para não encostar na esquerda
          if (!isUser) const SizedBox(width: 32), // Espaço para não encostar na direita
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          const Icon(Icons.eco_rounded, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Text(
            'IA digitando...',
            style: GoogleFonts.outfit(
              color: Colors.grey[600],
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
          const _AnimatedDots(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _mensagemController,
              decoration: InputDecoration(
                hintText: 'Digite sua dúvida...',
                hintStyle: GoogleFonts.outfit(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onSubmitted: (_) => _enviarMensagem(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: const Color(0xFF7C3AED),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white),
              onPressed: _enviarMensagem,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedDots extends StatefulWidget {
  const _AnimatedDots();

  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _dotCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _controller.addListener(() {
      final newCount = (_controller.value * 4).floor();
      if (newCount != _dotCount) {
        setState(() => _dotCount = newCount);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text('.' * _dotCount, style: const TextStyle(fontWeight: FontWeight.bold));
  }
}
