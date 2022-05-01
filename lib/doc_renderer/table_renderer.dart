import 'package:flutter/material.dart';

import 'paragraph_text_style.dart';

class Row {
  List<Cell?> cells;

  Row({required this.cells});
}

class Cell {
  final String text;
  final int mergeRight;
  final int mergeDown;
  final ParagraphTextStyle textStyle;
  final Color? backgroundColor;

  Cell({
    required this.text,
    this.mergeRight = 1,
    this.mergeDown = 1,
    this.textStyle = const ParagraphTextStyle(),
    this.backgroundColor,
  });
}