import 'package:flutter/material.dart';
import 'package:twemoji/twemoji.dart';

class TwemojiText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const TwemojiText({super.key, required this.text, this.style});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TwemojiTextSpan(
        text: text,
        style: style ?? DefaultTextStyle.of(context).style,
      ),
    );
  }
}
