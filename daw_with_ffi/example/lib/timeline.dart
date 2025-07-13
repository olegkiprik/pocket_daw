import 'package:flutter/material.dart';
import 'constants.dart';
import 'track_button.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Show and edit played notes
class TimelineRoute extends StatefulWidget {
  const TimelineRoute({super.key});

  @override
  State<TimelineRoute> createState() => _TimelineRouteState();
}

class _TimelineRouteState extends State<TimelineRoute> {
  @override
  Widget build(BuildContext context) {
    final args = (ModalRoute.of(context)?.settings.arguments ??
        <String, dynamic>{}) as Map;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(AppLocalizations.of(context)!.timelineTitle),
      ),
      body: GridView.count(
        crossAxisCount: nrNotes,
        mainAxisSpacing: 0,
        children: List.generate(nrNotes * args['nrSteps'] as int, (index) {
          int noteIndex = index % nrNotes;
          int stepIndex = index ~/ nrNotes;
          return Center(
            child: TrackButton(
                text: '${noteIndex % 10}',
                active: (args['track'] as List<List<bool>>)[stepIndex][noteIndex],
                callback: () {
                  bool tmp = (args['track'] as List<List<bool>>)[stepIndex][noteIndex];
                  (args['track'] as List<List<bool>>)[stepIndex][noteIndex] = !tmp;
                },
                isCurrentStep: args['isCurrentStep'] == stepIndex),
          );
        }),
      ),
    );
  }
}