import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// Renders LaTeX with plain-text fallback.
class LatexTextWidget extends StatelessWidget {
  const LatexTextWidget({
    super.key,
    required this.latex,
    this.style,
    this.onCopy,
  });

  final String latex;
  final TextStyle? style;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final textStyle = style ?? Theme.of(context).textTheme.bodyMedium;

    Widget content;
    try {
      content = Math.tex(
        latex,
        textStyle: textStyle,
        onErrorFallback: (err) => Text(latex, style: textStyle),
      );
    } catch (_) {
      content = Text(latex, style: textStyle?.copyWith(fontFamily: 'monospace'));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: content)),
        if (onCopy != null)
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            tooltip: 'Sao chép LaTeX',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: latex));
              onCopy?.call();
            },
          ),
      ],
    );
  }
}
