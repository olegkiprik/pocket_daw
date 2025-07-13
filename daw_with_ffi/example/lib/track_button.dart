import 'package:flutter/material.dart';

class TrackButton extends StatefulWidget {
  final Function callback;
  final String text;

  // is the note played
  final bool active;

  // is the note in current step
  final bool isCurrentStep;

  const TrackButton({
    super.key,
    required this.text,
    required this.active,
    required this.callback,
    required this.isCurrentStep,
  });

  @override
  State<StatefulWidget> createState() => TrackButtonState();
}

class TrackButtonState extends State<TrackButton> {
  bool active = false;

  @override
  TextButton build(BuildContext context) {
    active = widget.active;
    Color buttonColor = widget.isCurrentStep ? Colors.deepPurple : 
      (active ? Colors.teal : Colors.white);
    return TextButton(
      child: Text(
              textHeightBehavior: TextHeightBehavior(
                applyHeightToFirstAscent: false,
                applyHeightToLastDescent: false
              ),
              widget.text,
              style: TextStyle(
                  backgroundColor: buttonColor,
              ),
      ),
      onPressed: () {
        setState(() {
          active = !active;
          widget.callback();
        });
      },
    );
  }
}