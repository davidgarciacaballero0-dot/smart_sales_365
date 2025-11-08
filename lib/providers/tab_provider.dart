// lib/providers/tab_provider.dart
import 'package:flutter/material.dart';

class TabProvider with ChangeNotifier {
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  void changeTab(int index) {
    _selectedIndex = index;
    notifyListeners();
  }
}
