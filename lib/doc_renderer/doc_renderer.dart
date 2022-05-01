import 'dart:math';

import 'package:googleapis/docs/v1.dart' as docs;
import 'package:googleapis_auth/googleapis_auth.dart';

import 'pair.dart';
import 'paragraph_text_style.dart';
import 'table_renderer.dart' as table;

class DocRenderer {
  final String title;

  int location = 1;
  Map<String, Pair<int, int>> objects = {}; // Map<Tag, [start index, end index]>
  List<docs.Request> unprocessedRequests = [];
  List<docs.Request> requests = [];

  late docs.DocsApi docsApi;
  late docs.Document document;

  DocRenderer({required this.title});

  Future<void> create({required AuthClient authClient}) async {
    docsApi = docs.DocsApi(authClient);

    print("Creating a new document...");
    docs.Document d = docs.Document(title: title);
    document = await docsApi.documents.create(d);
    print("New document created");

    print(document.toJson());
  }

  void addTextLine({
    required String text,
    ParagraphTextStyle? textStyle,
    bool newLine = true,
  }) {
    unprocessedRequests.add(
      docs.Request(
        insertText: docs.InsertTextRequest(
          location: docs.Location(index: location),
          text: text + (newLine ? "\n" : ""),
        ),
      ),
    );
    print("[${currentRequest()}] Adding a [$text] text at location: $location");
    print("[${currentRequest()}] Text has new line at the end: $newLine");
    var newLocation = location + text.length + (newLine ? 1 : 0);
    objects[text] = Pair(location, newLocation);
    print("[${currentRequest()}] Adding an object with indices: $location - $newLocation");
    location = newLocation;
    print("[${currentRequest()}] Updating location to: $location");
    if (textStyle?.style != null) {
      setParagraphStyle(textStyle: textStyle!.style, tag: text);
    }
    if (textStyle != null) {
      setTextStyle(textStyle: textStyle, tag: text);
    }
  }

  void addList({
    required List<String> lines,
    ParagraphTextStyle? textStyle,
  }) {
    print("[${currentRequest()}] Adding $lines to the document");
    for (String line in lines) {
      addTextLine(text: line, textStyle: textStyle);
      unprocessedRequests.add(
        docs.Request(
          createParagraphBullets: docs.CreateParagraphBulletsRequest(
            range: docs.Range(
              startIndex: objects[line]!.left,
              endIndex: objects[line]!.right,
            ),
            bulletPreset: "BULLET_DISC_CIRCLE_SQUARE",
          ),
        ),
      );
    }
    print("[${currentRequest()}] Setting a bullet style to the $lines");
  }

  void setTextStyle({
    required ParagraphTextStyle textStyle,
    required String tag,
  }) {
    List<String> fields = [
      "bold",
      "italic",
      "underline",
    ];

    print("[${currentRequest()}] Setting the ${textStyle.decorations} decorations to the [$tag] text");

    docs.TextStyle style = docs.TextStyle(
      bold: textStyle.decorations.contains(ParagraphTextDecorationEnum.BOLD),
      italic: textStyle.decorations.contains(ParagraphTextDecorationEnum.ITALIC),
      underline: textStyle.decorations.contains(ParagraphTextDecorationEnum.UNDERLINED),
    );

    if (textStyle.fontSize != null) {
      print("[${currentRequest()}] Setting the [${textStyle.fontSize}] font size to the [$tag] text");
      fields.add("fontSize");
      style.fontSize = docs.Dimension(
        magnitude: textStyle.fontSize!.toDouble(),
        unit: "PT",
      );
    }

    if (textStyle.fontColor != null) {
      print("[${currentRequest()}] Setting the [${textStyle.fontColor}] color to the [$tag] text");
      fields.add("foregroundColor");
      style.foregroundColor = docs.OptionalColor(
        color: docs.Color(
          rgbColor: docs.RgbColor(
            red: textStyle.fontColor!.red / 255,
            green: textStyle.fontColor!.green / 255,
            blue: textStyle.fontColor!.blue / 255,
          ),
        ),
      );
    }

    if (textStyle.backgroundColor != null) {
      print("[${currentRequest()}] Setting the [${textStyle.backgroundColor}] color to the [$tag] text");
      fields.add("backgroundColor");
      style.backgroundColor = docs.OptionalColor(
        color: docs.Color(
          rgbColor: docs.RgbColor(
            red: textStyle.backgroundColor!.red / 255,
            green: textStyle.backgroundColor!.green / 255,
            blue: textStyle.backgroundColor!.blue / 255,
          ),
        ),
      );
    }

    unprocessedRequests.add(
      docs.Request(
        updateTextStyle: docs.UpdateTextStyleRequest(
          range: docs.Range(
            startIndex: objects[tag]!.left,
            endIndex: objects[tag]!.right,
          ),
          fields: fields.join(","),
          textStyle: style,
        ),
      ),
    );
    print(
        "[${currentRequest()}] Setting text style $textStyle to locations: ${objects[tag]!.left} - ${objects[tag]!.right}");
  }

  void setParagraphStyle({
    required ParagraphTextStyleEnum textStyle,
    required String tag,
  }) {
    String paragraphStyle;
    switch (textStyle) {
      case ParagraphTextStyleEnum.HEADER_1:
        paragraphStyle = "HEADING_1";
        break;
      case ParagraphTextStyleEnum.HEADER_2:
        paragraphStyle = "HEADING_2";
        break;
      case ParagraphTextStyleEnum.HEADER_3:
        paragraphStyle = "HEADING_3";
        break;
      case ParagraphTextStyleEnum.HEADER_4:
        paragraphStyle = "HEADING_4";
        break;
      case ParagraphTextStyleEnum.HEADER_5:
        paragraphStyle = "HEADING_5";
        break;
      case ParagraphTextStyleEnum.HEADER_6:
        paragraphStyle = "HEADING_6";
        break;
      case ParagraphTextStyleEnum.NORMAL_TEXT:
        paragraphStyle = "NORMAL_TEXT";
        break;
    }
    unprocessedRequests.add(
      docs.Request(
        updateParagraphStyle: docs.UpdateParagraphStyleRequest(
          range: docs.Range(
            startIndex: objects[tag]!.left,
            endIndex: objects[tag]!.right,
          ),
          fields: 'namedStyleType',
          paragraphStyle: docs.ParagraphStyle(
            namedStyleType: paragraphStyle,
          ),
        ),
      ),
    );
    print(
        "[${currentRequest()}] Setting style $paragraphStyle to locations: ${objects[tag]!.left} - ${objects[tag]!.right}");
  }

  void addImage({
    required String uri,
    required double height,
    required double width,
    bool newLine = true,
  }) {
    print("[${currentRequest()}] Adding an image $uri to the document at $location location");
    unprocessedRequests.add(
      docs.Request(
        insertInlineImage: docs.InsertInlineImageRequest(
          uri: uri,
          location: docs.Location(index: location),
          objectSize: docs.Size(
            height: docs.Dimension(
              magnitude: height,
              unit: "PT",
            ),
            width: docs.Dimension(
              magnitude: width,
              unit: "PT",
            ),
          ),
        ),
      ),
    );
    var newLocation = location + 1;
    objects[uri] = Pair(location, newLocation);
    location = newLocation;
    print("[${currentRequest()}] Updating location to: $location");
    if (newLine) {
      print("[${currentRequest()}] Adding an additional new line");
      addTextLine(text: "");
    }
  }

  void addTable({required List<table.Row> rows}) {
    int rowsCount = rows.length;
    int columnsCount = rows.map((e) => e.cells.length).reduce(max);
    // location++;
    print("[${currentRequest()}] Adding a new table to the document at $location location");
    print("[${currentRequest()}] Table has $rowsCount rows and $columnsCount columns");
    unprocessedRequests.add(
      docs.Request(
        insertTable: docs.InsertTableRequest(
          // location: docs.Location(index: location),
          endOfSegmentLocation: docs.EndOfSegmentLocation(),
          rows: rowsCount,
          columns: columnsCount,
        ),
      ),
    );

    int tableStartLocation = location + 1;
    location += 4; // skip table+row+cell+paragraph indices

    for (table.Row row in rows) {
      List<table.Cell?> cells = row.cells;
      // if cells length is smaller than columns count - fill the rest with empty text
      if (cells.length < columnsCount) {
        cells = List<table.Cell?>.generate(
          columnsCount,
          (index) => index < row.cells.length ? row.cells[index] : null,
        );
      }

      for (table.Cell? cell in cells) {
        if (cell != null) {
          addTextLine(
            text: cell.text,
            newLine: false,
            textStyle: cell.textStyle,
          );

          var rowIndex = rows.indexOf(row);
          var columnIndex = cells.indexOf(cell);

          if (cell.backgroundColor != null) {
            print("[${currentRequest()}] Setting the [${cell.backgroundColor}] color to the [${cell.text}] cell");
            unprocessedRequests.add(
              docs.Request(
                updateTableCellStyle: docs.UpdateTableCellStyleRequest(
                  tableRange: docs.TableRange(
                    rowSpan: 1,
                    columnSpan: 1,
                    tableCellLocation: docs.TableCellLocation(
                      rowIndex: rowIndex,
                      columnIndex: columnIndex,
                      tableStartLocation: docs.Location(index: tableStartLocation),
                    ),
                  ),
                  tableCellStyle: docs.TableCellStyle(
                    backgroundColor: docs.OptionalColor(
                      color: docs.Color(
                        rgbColor: docs.RgbColor(
                          red: cell.backgroundColor!.red / 255,
                          green: cell.backgroundColor!.green / 255,
                          blue: cell.backgroundColor!.blue / 255,
                        ),
                      ),
                    ),
                  ),
                  fields: "backgroundColor",
                ),
              ),
            );
          }

          if (cell.mergeRight > 1 || cell.mergeDown > 1) {
            unprocessedRequests.add(
              docs.Request(
                mergeTableCells: docs.MergeTableCellsRequest(
                  tableRange: docs.TableRange(
                    rowSpan: min(cell.mergeDown, rowsCount - rowIndex),
                    columnSpan: min(cell.mergeRight, columnsCount - columnIndex),
                    tableCellLocation: docs.TableCellLocation(
                      rowIndex: rowIndex,
                      columnIndex: columnIndex,
                      tableStartLocation: docs.Location(index: tableStartLocation),
                    ),
                  ),
                ),
              ),
            );
          }
        }
        location += 2; // cell end + next cell start index
      }
      location += 1; // row change index
    }

    print("[${currentRequest()}] Current location is: $location");
    location--;
    print("[${currentRequest()}] Updating location to: $location");
  }

  int currentRequest() => unprocessedRequests.length - 1;

  Future<void> save() async {
    print("Unprocessed requests count: ${unprocessedRequests.length}");
    docs.BatchUpdateDocumentRequest bodyRequest = docs.BatchUpdateDocumentRequest(requests: unprocessedRequests);
    docs.BatchUpdateDocumentResponse response = await docsApi.documents.batchUpdate(
      bodyRequest,
      document.documentId!,
    );

    print("processed requests: $unprocessedRequests");
    requests.addAll(unprocessedRequests.toList());
    unprocessedRequests.clear();

    print(response.toJson());
  }
}
