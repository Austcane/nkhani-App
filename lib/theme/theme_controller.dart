import 'package:flutter/material.dart';

class ThemeController extends ChangeNotifier {
  ThemeMode _mode;

  ThemeController({ThemeMode initialMode = ThemeMode.light})
      : _mode = initialMode;

  ThemeMode get mode => _mode;

  bool get isDark => _mode == ThemeMode.dark;

  void setDarkMode(bool enabled) {
    final next = enabled ? ThemeMode.dark : ThemeMode.light;
    if (_mode == next) return;
    _mode = next;
    notifyListeners();
  }
}

class ThemeControllerScope extends InheritedNotifier<ThemeController> {
  const ThemeControllerScope({
    super.key,
    required ThemeController controller,
    required Widget child,
  }) : super(notifier: controller, child: child);

  static ThemeController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<ThemeControllerScope>();
    assert(scope != null, 'ThemeControllerScope not found in context.');
    return scope!.notifier!;
  }
}
