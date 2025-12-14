import 'package:intl/intl.dart';

// Small helper to keep formatting consistent across UI
class DateFormatters {
  static final _mdy = DateFormat('MMM d, yyyy');

  static String mdy(DateTime d) => _mdy.format(d);
}
