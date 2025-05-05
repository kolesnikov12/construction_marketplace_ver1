import 'package:flutter/material.dart';
import '../models/tender.dart';
import '../bloc/bloc_provider.dart';
import '../bloc/tender_bloc.dart';
import '../bloc/base/bloc_states.dart';

class TenderItemBuilder extends StatelessWidget {
  final Widget Function(BuildContext, Tender) builder;
  final String tenderId;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  const TenderItemBuilder({
    Key? key,
    required this.builder,
    required this.tenderId,
    this.loadingWidget,
    this.errorWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tenderBloc = BlocProvider.of<TenderBloc>(context);

    return StreamBuilder(
      stream: tenderBloc.state,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data is LoadingState) {
          return loadingWidget ?? Center(child: CircularProgressIndicator());
        }

        if (snapshot.data is ErrorState) {
          final errorState = snapshot.data as ErrorState;
          return errorWidget ?? Center(child: Text(errorState.message));
        }

        if (snapshot.data is TenderDetailsLoadedState) {
          final tenderState = snapshot.data as TenderDetailsLoadedState;
          final tender = tenderState.tender;

          return builder(context, tender);
        }

        return Center(child: Text('Tender not found'));
      },
    );
  }
}