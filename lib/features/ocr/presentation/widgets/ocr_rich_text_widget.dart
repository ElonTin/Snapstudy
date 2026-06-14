import 'package:flutter/material.dart';
import 'package:snapstudy/core/widgets/latex_text_widget.dart';

class OcrSegment {
  const OcrSegment({
    required this.text,
    this.isLatex = false,
    this.isBlock = false,
  });

  final String text;
  final bool isLatex;
  final bool isBlock;
}

/// Hiển thị văn bản OCR hỗn hợp plain text + LaTeX ($...$ / $$...$$).
class OcrRichTextWidget extends StatelessWidget {
  const OcrRichTextWidget({super.key, required this.text, this.style});

  final String text;
  final TextStyle? style;

  static final _blockPattern = RegExp(r'\$\$([\s\S]+?)\$\$', multiLine: true);
  static final _inlinePattern = RegExp(r'\$([^$\n]+?)\$');

  static List<OcrSegment> parse(String input) {
    if (input.trim().isEmpty) return const [];

    final segments = <OcrSegment>[];
    var remaining = input;

    while (remaining.isNotEmpty) {
      final block = _blockPattern.firstMatch(remaining);
      final inline = _inlinePattern.firstMatch(remaining);

      Match? next;
      var isBlock = false;
      if (block != null && (inline == null || block.start <= inline.start)) {
        next = block;
        isBlock = true;
      } else {
        next = inline;
      }

      if (next == null) {
        segments.add(OcrSegment(text: remaining));
        break;
      }

      if (next.start > 0) {
        segments.add(OcrSegment(text: remaining.substring(0, next.start)));
      }

      segments.add(
        OcrSegment(
          text: next.group(1)!.trim(),
          isLatex: true,
          isBlock: isBlock,
        ),
      );

      remaining = remaining.substring(next.end);
    }

    return segments;
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? Theme.of(context).textTheme.bodyMedium;
    final segments = parse(text);

    if (segments.every((s) => !s.isLatex)) {
      return Text(text, style: baseStyle?.copyWith(height: 1.5));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: segments.map((seg) {
        if (!seg.isLatex) {
          if (seg.text.trim().isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(seg.text, style: baseStyle?.copyWith(height: 1.5)),
          );
        }

        return Padding(
          padding: EdgeInsets.only(
            top: seg.isBlock ? 8 : 2,
            bottom: seg.isBlock ? 8 : 4,
          ),
          child: seg.isBlock
              ? Center(
                  child: LatexTextWidget(latex: seg.text, style: baseStyle),
                )
              : LatexTextWidget(latex: seg.text, style: baseStyle),
        );
      }).toList(),
    );
  }
}
