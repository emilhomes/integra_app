import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../../data/models/agendamento_model.dart';

class NotificacaoService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> inicializar() async {
    tz_data.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
    );
  }

  static Future<void> agendarNotificacao(AgendamentoModel agendamento) async {
    final scheduledDate = agendamento.dataHora.subtract(const Duration(minutes: 30));
    
    if (scheduledDate.isBefore(DateTime.now())) return;

    await _notificationsPlugin.zonedSchedule(
      agendamento.id.hashCode,
      'Atendimento em 30 minutos',
      'Paciente: ${agendamento.pacienteNome} - ${agendamento.tipoTerapia}',
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'atendimentos_channel',
          'Lembretes de Atendimento',
          channelDescription: 'Notifica 30 minutos antes do atendimento',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexact,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelarNotificacao(String agendamentoId) async {
    await _notificationsPlugin.cancel(agendamentoId.hashCode);
  }
}
