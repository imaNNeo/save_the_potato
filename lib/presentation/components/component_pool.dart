import 'package:flame/components.dart';

class ComponentPool<T extends Component> {
  final List<T> _pool = [];
  final T Function() _componentFactory;

  ComponentPool(
      this._componentFactory, {
        int initialSize = 0,
      }) {
    for (int i = 0; i < initialSize; i++) {
      _pool.add(_componentFactory());
    }
  }

  T get() {
    if (_pool.isNotEmpty) {
      return _pool.removeLast();
    }
    print('Component pool is empty, creating a new component');
    return _componentFactory();
  }

  void release(T component) {
    component.removeFromParent();
    _pool.add(component);
  }
}