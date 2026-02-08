import 'package:flutter/foundation.dart';

import 'app_session.dart';

class LifeInfo {
  const LifeInfo({
    required this.current,
    required this.max,
    this.updatedAt,
  });

  final int current;
  final int max;
  final DateTime? updatedAt;

  bool get isFull => current >= max;

  factory LifeInfo.fromJson(Map<String, dynamic> json) {
    final updatedRaw = json['updated_at'];
    DateTime? updatedAt;
    if (updatedRaw is String) {
      updatedAt = DateTime.tryParse(updatedRaw);
    }
    final current = (json['current_life'] as num?)?.toInt() ?? 0;
    final max = (json['max_life'] as num?)?.toInt() ?? 0;
    return LifeInfo(
      current: current,
      max: max,
      updatedAt: updatedAt,
    );
  }
}

class LifeState {
  LifeState._();

  static final LifeState instance = LifeState._();

  final ValueNotifier<LifeInfo?> life = ValueNotifier<LifeInfo?>(null);

  Future<LifeInfo> refresh() async {
    final response = await AppSession.instance.api.getJson('/life');
    final info = LifeInfo.fromJson(response);
    life.value = info;
    return info;
  }

  void clear() {
    life.value = null;
  }
}
