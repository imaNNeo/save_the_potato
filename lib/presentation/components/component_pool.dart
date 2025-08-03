import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

class ComponentPool<T extends Component> {
  final List<T> _pool = [];
  final T Function() _componentFactory;

  String? _debugName;
  late bool _debugPrint;

  ComponentPool(
    this._componentFactory, {
    int initialSize = 0,
    bool debugPrint = false,
    String? debugName,
  }) {
    for (int i = 0; i < initialSize; i++) {
      _pool.add(_componentFactory());
    }
    _debugName = debugName;
    _debugPrint = debugPrint;
  }

  T get() {
    if (_pool.isNotEmpty) {
      if (_debugPrint) {
        debugPrint(
          'Reusing component from pool ($_debugName), size: ${_pool.length}',
        );
      }
      return _pool.removeLast();
    }
    if (_debugPrint) {
      debugPrint(
        'Component pool ($_debugName) is empty, creating a new component',
      );
    }
    return _componentFactory();
  }

  void release(T component) {
    component.removeFromParent();
    _pool.add(component);
  }
}
