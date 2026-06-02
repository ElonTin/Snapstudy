import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/features/home/presentation/utils/dashboard_formatters.dart';

void main() {
  test('relativeTime returns minutes ago', () {
    final result = DashboardFormatters.relativeTime(
      DateTime.now().subtract(const Duration(minutes: 5)),
    );
    expect(result, '5 phút trước');
  });

  test('dueLabel shows overdue', () {
    final result = DashboardFormatters.dueLabel(
      DateTime.now().subtract(const Duration(minutes: 15)),
    );
    expect(result, contains('Quá'));
  });
}
