String ordinalSuffix(int number) {
  final units = number % 10;
  final tens = number ~/ 10 % 10;

  if (tens != 1) {
    if (units == 1) return '${number}st';
    if (units == 2) return '${number}nd';
    if (units == 3) return '${number}rd';
  }

  return '${number}th';
}
