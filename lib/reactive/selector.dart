import 'package:flutter/widgets.dart';

typedef SelectorFn<T extends Listenable, S> = S Function(T notifier);
typedef Eq<S> = bool Function(S a, S b);

typedef InteractState = ({bool isEditing, bool tap, bool longPress, bool drag});
typedef SelHoverState = ({bool isActive, bool isHovered});

class ListenableSelector<T extends Listenable, S> extends StatefulWidget {
  const ListenableSelector({
    super.key,
    required this.listenable,
    required this.select,
    required this.builder,
    this.equals,
  });
  final T listenable;
  final SelectorFn<T, S> select;
  final Eq<S>? equals;
  final Widget Function(BuildContext, S) builder;

  @override
  State<ListenableSelector<T, S>> createState() =>
      _ListenableSelectorState<T, S>();
}

class _ListenableSelectorState<T extends Listenable, S>
    extends State<ListenableSelector<T, S>> {
  late S _value;

  @override
  void initState() {
    super.initState();
    _value = widget.select(widget.listenable);
    widget.listenable.addListener(_onNotify);
  }

  @override
  void didUpdateWidget(covariant ListenableSelector<T, S> old) {
    super.didUpdateWidget(old);
    if (old.listenable != widget.listenable) {
      old.listenable.removeListener(_onNotify);
      _value = widget.select(widget.listenable);
      widget.listenable.addListener(_onNotify);
    }
  }

  @override
  void dispose() {
    widget.listenable.removeListener(_onNotify);
    super.dispose();
  }

  void _onNotify() {
    if (!mounted) return;
    final next = widget.select(widget.listenable);
    final eq = widget.equals ?? (S a, S b) => a == b;
    if (!eq(_value, next)) {
      setState(() => _value = next);
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _value);
}

class CombinedSelector<S> extends StatefulWidget {
  const CombinedSelector({
    super.key,
    required this.listenables,
    required this.select,
    required this.builder,
    this.equals,
  });
  final Iterable<Listenable> listenables;
  final S Function(Iterable<Listenable>) select;
  final Eq<S>? equals;
  final Widget Function(BuildContext, S) builder;

  @override
  State<CombinedSelector<S>> createState() => _CombinedSelectorState<S>();
}

class _CombinedSelectorState<S> extends State<CombinedSelector<S>> {
  late S _value;

  @override
  void initState() {
    super.initState();
    _value = widget.select(widget.listenables);
    for (final n in widget.listenables) {
      n.addListener(_onNotify);
    }
  }

  @override
  void didUpdateWidget(covariant CombinedSelector<S> old) {
    super.didUpdateWidget(old);
    if (!_sameNotifiers(old.listenables, widget.listenables)) {
      for (final n in old.listenables) {
        n.removeListener(_onNotify);
      }
      for (final n in widget.listenables) {
        n.addListener(_onNotify);
      }
      final next = widget.select(widget.listenables);
      final eq = widget.equals ?? (S a, S b) => a == b;
      if (!eq(_value, next)) _value = next;
    }
  }

  @override
  void dispose() {
    for (final n in widget.listenables) {
      n.removeListener(_onNotify);
    }
    super.dispose();
  }

  void _onNotify() {
    if (!mounted) return;
    final next = widget.select(widget.listenables);
    final eq = widget.equals ?? (S a, S b) => a == b;
    if (!eq(_value, next)) {
      setState(() => _value = next);
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _value);

  bool _sameNotifiers(Iterable<Listenable> a, Iterable<Listenable> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!identical(a.elementAt(i), b.elementAt(i))) return false;
    }
    return true;
  }
}
