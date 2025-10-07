import 'package:flutter/foundation.dart';

class AppState extends ChangeNotifier {
  bool pregnant = true;
  int weeksPregnant = 12;

  int? get trimester {
    if (!pregnant) return null;
    if (weeksPregnant >= 1 && weeksPregnant <= 13) return 1;
    if (weeksPregnant >= 14 && weeksPregnant <= 27) return 2;
    if (weeksPregnant >= 28 && weeksPregnant <= 41) return 3;
    return null;
  }

  void setPregnant(bool v) {
    pregnant = v;
    notifyListeners();
  }

  void setWeeks(int w) {
    weeksPregnant = w.clamp(1, 41);
    notifyListeners();
  }
}
