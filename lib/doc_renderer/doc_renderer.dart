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
    print("[${unprocessedRequests.length - 1}] Adding a [$text] text at location: $location");
    print("[${unprocessedRequests.length - 1}] Text has new line at the end: $newLine");
    var newLocation = location + text.length + (newLine ? 1 : 0);
    objects[text] = Pair(location, newLocation);
    print("[${unprocessedRequests.length - 1}] Adding an object with indices: $location - $newLocation");
    location = newLocation;
    print("[${unprocessedRequests.length - 1}] Updating location to: $location");
    if (textStyle != null) {
      setParagraphStyle(textStyle: textStyle, tag: text);
    }
  }

  void addList({
    required List<String> lines,
    ParagraphTextStyle? textStyle,
  }) {
    print("Adding $lines to the document");
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
    print("[${unprocessedRequests.length - 1}] Setting a bullet style to the $lines");
  }

  void setParagraphStyle({
    required ParagraphTextStyle textStyle,
    required String tag,
  }) {
    String paragraphStyle;
    switch (textStyle) {
      case ParagraphTextStyle.HEADER_1:
        paragraphStyle = "HEADING_1";
        break;
      case ParagraphTextStyle.HEADER_2:
        paragraphStyle = "HEADING_2";
        break;
      case ParagraphTextStyle.HEADER_3:
        paragraphStyle = "HEADING_3";
        break;
      case ParagraphTextStyle.HEADER_4:
        paragraphStyle = "HEADING_4";
        break;
      case ParagraphTextStyle.HEADER_5:
        paragraphStyle = "HEADING_5";
        break;
      case ParagraphTextStyle.HEADER_6:
        paragraphStyle = "HEADING_6";
        break;
      case ParagraphTextStyle.NORMAL_TEXT:
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
        "[${unprocessedRequests.length - 1}] Setting style $paragraphStyle to locations: ${objects[tag]!.left} - ${objects[tag]!.right}");
  }

  void addImage({
    required String uri,
    required double height,
    required double width,
    bool newLine = true,
  }) {
    print("Adding an image $uri to the document at $location location");
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
    print("Updating location to: $location");
    if (newLine) {
      print("Adding an additional new line");
      addTextLine(text: "", textStyle: ParagraphTextStyle.NORMAL_TEXT);
    }
  }

  void addTable({required List<table.Row> rows}) {
    int rowsCount = rows.length;
    int columnsCount = rows.map((e) => e.cells.length).reduce(max);
    // location++;
    print("Adding a new table to the document at $location location");
    print("Table has $rowsCount rows and $columnsCount columns");
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
          if (cell.mergeRight > 1 || cell.mergeDown > 1) {
            var rowIndex = rows.indexOf(row);
            var columnIndex = cells.indexOf(cell);
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

    print("Current location is: $location");
    location--;
    print("Updating location to: $location");
  }

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
