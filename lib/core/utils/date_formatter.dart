import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final _dateFormat = DateFormat('dd MMM yyyy');
  static final _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final _shortFormat = DateFormat('dd/MM/yyyy');
  static final _monthYear = DateFormat('MMM yyyy');

  static String formatDate(DateTime date) => _dateFormat.format(date);
  static String formatDateTime(DateTime date) => _dateTimeFormat.format(date);
  static String formatShort(DateTime date) => _shortFormat.format(date);
  static String formatMonthYear(DateTime date) => _monthYear.format(date);

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return _dateFormat.format(date);
  }

  static String formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final diff = dueDate.difference(now);
    if (diff.isNegative) return 'Overdue by ${(-diff.inDays)} days';
    if (diff.inDays == 0) return 'Due today';
    if (diff.inDays <= 7) return 'Due in ${diff.inDays} days';
    return 'Due ${_dateFormat.format(dueDate)}';
  }

  static List<DateTime> last30Days() {
    final now = DateTime.now();
    return List.generate(
        30, (i) => DateTime(now.year, now.month, now.day - (29 - i)));
  }
}
