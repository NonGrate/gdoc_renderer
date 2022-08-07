import 'dart:ui';

class ParagraphTextStyle {
  final ParagraphTextStyleEnum style;
  final List<ParagraphTextDecorationEnum> decorations;
  final int? fontSize;
  final Color? fontColor;
  final Color? backgroundColor;
  final String? fontFamily;

  const ParagraphTextStyle({
    this.style = ParagraphTextStyleEnum.NORMAL_TEXT,
    this.decorations = const [],
    this.fontSize,
    this.fontColor,
    this.backgroundColor,
    this.fontFamily,
  });

  @override
  String toString() {
    return 'ParagraphTextStyle{style: $style, decorations: $decorations, fontSize: $fontSize, fontColor: $fontColor, backgroundColor: $backgroundColor, fontFamily: $fontFamily}';
  }
}

enum ParagraphTextStyleEnum {
  HEADER_1,
  HEADER_2,
  HEADER_3,
  HEADER_4,
  HEADER_5,
  HEADER_6,
  NORMAL_TEXT,
}

enum ParagraphTextDecorationEnum {
  BOLD,
  ITALIC,
  UNDERLINED,
}
