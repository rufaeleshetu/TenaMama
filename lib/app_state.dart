import 'package:flutter/foundation.dart';

class AppState extends ChangeNotifier {
  bool pregnant = true;        // default
  int weeksPregnant = 12;      // default

  void setPregnant(bool v) {
    pregnant = v;
    notifyListeners();
  }

  void setWeeks(int w) {
    weeksPregnant = w.clamp(0, 42);
    notifyListeners();
  }

  int? get trimester {
    if (!pregnant) return null;
    final w = weeksPregnant;
    if (w < 13) return 1;
    if (w < 27) return 2;
    return 3;
  }
}
