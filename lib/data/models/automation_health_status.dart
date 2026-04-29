
import 'package:leastprice/core/utils/helpers.dart';

class AutomationHealthStatus {
  const AutomationHealthStatus({
    required this.service,
    required this.status,
    required this.lastRunAt,
    required this.lastSuccessAt,
    required this.summary,
  });

  final String service;
  final String status;
  final DateTime? lastRunAt;
  final DateTime? lastSuccessAt;
  final String summary;

  factory AutomationHealthStatus.initial() {
    return const AutomationHealthStatus(
      service: 'daily_price_bot',
      status: 'unknown',
      lastRunAt: null,
      lastSuccessAt: null,
      summary: '',
    );
  }

  factory AutomationHealthStatus.fromJson(Map<String, dynamic> json) {
    return AutomationHealthStatus(
      service: stringValue(json['service']) ?? 'daily_price_bot',
      status: stringValue(json['status']) ?? 'unknown',
      lastRunAt: dateTimeValue(json['lastRunAt'] ?? json['lastAttemptAt']),
      lastSuccessAt: dateTimeValue(json['lastSuccessAt']),
      summary: stringValue(json['message']) ?? '',
    );
  }

  String get statusLabel {
    if (lastSuccessAt == null) {
      return tr(
        'الروبوت: بانتظار أول تشغيل',
        'Bot: waiting for first run',
      );
    }
    return tr(
      'آخر تحديث ${formatHealthTimestamp(lastSuccessAt)}',
      'Last update ${formatHealthTimestamp(lastSuccessAt)}',
    );
  }
}
