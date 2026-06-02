import 'package:intl/intl.dart';

abstract final class DashboardFormatters {
  static String relativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return DateFormat('dd/MM').format(dateTime);
  }

  static String dueLabel(DateTime dueAt) {
    final diff = dueAt.difference(DateTime.now());
    if (diff.isNegative) {
      final overdue = diff.abs();
      if (overdue.inMinutes < 60) return 'Quá ${overdue.inMinutes} phút';
      if (overdue.inHours < 24) return 'Quá ${overdue.inHours} giờ';
      return 'Quá hạn';
    }
    if (diff.inMinutes < 60) return 'Còn ${diff.inMinutes} phút';
    if (diff.inHours < 24) return 'Còn ${diff.inHours} giờ';
    return DateFormat('HH:mm · dd/MM').format(dueAt);
  }
}
