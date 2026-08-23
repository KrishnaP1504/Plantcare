import 'package:flutter/foundation.dart';

/// Manages the current bottom navigation tab index.
class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void setIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void resetToHome() {
    _currentIndex = 0;
    notifyListeners();
  }
}
