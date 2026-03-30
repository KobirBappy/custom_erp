class IdFormatter {
  IdFormatter._();

  static String numericCode(String raw, {int digits = 8}) {
    if (raw.trim().isEmpty) return ''.padLeft(digits, '0');

    var hash = 0;
    for (final code in raw.codeUnits) {
      hash = ((hash * 31) + code) & 0x7fffffff;
    }

    final mod = _pow10(digits);
    return (hash % mod).toString().padLeft(digits, '0');
  }

  static int _pow10(int n) {
    var value = 1;
    for (var i = 0; i < n; i++) {
      value *= 10;
    }
    return value;
  }
}
