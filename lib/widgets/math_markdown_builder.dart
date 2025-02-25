import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;

class MathMarkdownBuilder extends MarkdownElementBuilder {
  final TextStyle? textStyle;

  MathMarkdownBuilder({this.textStyle});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    // 处理行内数学公式
    if (element.tag == 'math-inline') {
      return Math.tex(
        element.textContent,
        textStyle: textStyle,
        mathStyle: MathStyle.text,
      );
    }
    
    // 处理块级数学公式
    if (element.tag == 'math-block') {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        width: double.infinity,
        child: Math.tex(
          element.textContent,
          textStyle: textStyle,
          mathStyle: MathStyle.display,
        ),
      );
    }
    return null;
  }
}

// 自定义语法解析器
class MathSyntax extends md.InlineSyntax {
  MathSyntax() : super(r'\$\$(.*?)\$\$|\$(.*?)\$');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final isBlock = match[1] != null;
    final content = isBlock ? match[1]! : match[2]!;
    final element = md.Element(
      isBlock ? 'math-block' : 'math-inline',
      [md.Text(content)],
    );
    parser.addNode(element);
    return true;
  }
}
