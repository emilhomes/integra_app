import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:intl/intl.dart';
import '../../data/models/agendamento_model.dart';

class NotificacaoService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> inicializar() async {
    tz_data.initializeTimeZones();
    
    // Usa offset fixo para Brasil (UTC-3) para evitar dependência de plugins nativos problemáticos
    final brasilLocation = tz.getLocation('America/Sao_Paulo');
    tz.setLocalLocation(brasilLocation);
    debugPrint('Fuso horário configurado: America/Sao_Paulo (UTC-3)');

    // Solicita permissão explícita no Android 13+
    await Permission.notification.request();

    if (Platform.isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      final canScheduleExact = await androidPlugin?.canScheduleExactNotifications() ?? false;
      debugPrint('Permissão para alarmes exatos: $canScheduleExact');
      
      if (!canScheduleExact) {
        await androidPlugin?.requestExactAlarmsPermission();
      }
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notifications.initialize(
      initializationSettings,
    );
  }

  static Future<void> agendarNotificacao(AgendamentoModel agendamento) async {
    final agoraSistema = DateTime.now();
    
    // Calcula quanto tempo falta entre AGORA e o horário escolhido
    final diferenca = agendamento.dataHora.difference(agoraSistema);
    
    // Subtrai 10 segundos para o teste imediato
    final tempoParaDisparar = diferenca - const Duration(seconds: 10);
    
    debugPrint('--- [INFO AGENDAMENTO] ---');
    debugPrint('Relógio do Celular: $agoraSistema');
    debugPrint('Horário Escolhido: ${agendamento.dataHora}');
    
    if (tempoParaDisparar.isNegative) {
      debugPrint('AVISO: O horário já passou no relógio do celular. Notificação não agendada.');
      return;
    }

    // Criamos o ponto de disparo baseado no AGORA do timezone local configurado (America/Sao_Paulo)
    final dataDisparo = tz.TZDateTime.now(tz.local).add(tempoParaDisparar);

    debugPrint('Disparará em: ${tempoParaDisparar.inMinutes}m e ${tempoParaDisparar.inSeconds % 60}s');
    debugPrint('Instante exato (TimeZone Brasil): $dataDisparo');

    await _notifications.zonedSchedule(
      agendamento.id.hashCode,
      'ÍNTEGRA — Lembrete de Atendimento',
      'Paciente: ${agendamento.pacienteNome} · ${agendamento.tipoTerapia}',
      dataDisparo,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'integra_agendamentos_v4',
          'Agendamentos ÍNTEGRA',
          channelDescription: 'Lembretes críticos de atendimentos',
          importance: Importance.max,
          priority: Priority.max,
          showWhen: true,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    
    debugPrint('SUCESSO: Programado no Android.');
    debugPrint('--------------------------');
  }

  static Future<void> cancelarNotificacao(String agendamentoId) async {
    await _notifications.cancel(agendamentoId.hashCode);
  }

  static Future<void> notificarConfirmacao(AgendamentoModel agendamento) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'integra_confirmacoes',
      'Confirmações ÍNTEGRA',
      channelDescription: 'Notifica quando um agendamento é realizado',
      importance: Importance.max,
      priority: Priority.max,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notifications.show(
      agendamento.id.hashCode,
      'Agendamento Confirmado!',
      'Paciente: ${agendamento.pacienteNome} \nData: ${DateFormat('dd/MM HH:mm').format(agendamento.dataHora)}',
      platformChannelSpecifics,
    );
    
    debugPrint('Notificação de confirmação disparada para: ${agendamento.id}');
  }

  static Future<void> testarNotificacao() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'test_channel',
      'Canal de Teste',
      channelDescription: 'Canal para testar notificações',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notifications.show(
      0,
      'ÍNTEGRA - Teste',
      'Sistema de notificações funcionando!',
      platformChannelSpecifics,
    );
  }
}
