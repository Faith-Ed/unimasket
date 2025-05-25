import 'package:flutter/foundation.dart';

// Use ValueNotifier so widgets can listen for changes
class AiChatbotState {
  static final AiChatbotState _instance = AiChatbotState._internal();

  factory AiChatbotState() => _instance;

  AiChatbotState._internal();

  // ValueNotifier for the enabled state, default true
  ValueNotifier<bool> isEnabled = ValueNotifier<bool>(true);

  void setEnabled(bool enabled) {
    isEnabled.value = enabled;
  }
}
