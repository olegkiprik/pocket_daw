import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// List all source files and select one
class TrackRoute extends StatefulWidget {
  const TrackRoute({super.key});

  @override
  State<TrackRoute> createState() => _TrackRouteState();
}

class _TrackRouteState extends State<TrackRoute> {
  @override
  Widget build(BuildContext context) {
    final args = (ModalRoute.of(context)?.settings.arguments ??
        <String, dynamic>{}) as Map;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(AppLocalizations.of(context)!.tracksTitle),
      ),
      body: ListView.separated(
          itemBuilder: (context, index) => TextButton(
                onPressed: () {
                  // select the track
                  Navigator.pop(context, index);
                },
                child: Text("${index + 1}. ${(args['srcPaths'] as List<String>)[index]}"),
              ),
          separatorBuilder: (context, _) => const SizedBox(width: 2),
          itemCount: args['nrSources']),
    );
  }
}