import 'package:intl/intl.dart';

String indianRupeeFormat(num amount) {
  final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  return formatter.format(amount);
}
