import 'package:flutter/material.dart';
import 'base/bloc_base.dart';

class BlocProvider<T extends Bloc> extends StatefulWidget {
  final Widget child;
  final T Function() create;

  const BlocProvider({
    Key? key,
    required this.child,
    required this.create,
  }) : super(key: key);

  @override
  _BlocProviderState<T> createState() => _BlocProviderState<T>();

  static T of<T extends Bloc>(BuildContext context) {
    final BlocProvider<T>? provider = context.findAncestorWidgetOfExactType<BlocProvider<T>>();
    if (provider == null) {
      throw Exception('BlocProvider of type $T not found in context');
    }
    return provider._bloc;
  }

  final T _bloc = create();
}

class _BlocProviderState<T extends Bloc> extends State<BlocProvider<T>> {
  @override
  void dispose() {
    widget._bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}