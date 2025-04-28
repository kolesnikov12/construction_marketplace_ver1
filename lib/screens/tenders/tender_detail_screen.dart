import 'package:flutter/material.dart';
import 'package:construction_marketplace/utils/l10n/app_localizations.dart';

class TenderDetailScreen extends StatelessWidget {
  static const routeName = '/tenders/detail';

  @override
  Widget build(BuildContext context) {
    final tenderId = ModalRoute.of(context)!.settings.arguments as String;
    final localization = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localization.translate('tender_details')),
      ),
      body: Center(
        child: Text('Tender ID: $tenderId'),
      ),
    );
  }
}