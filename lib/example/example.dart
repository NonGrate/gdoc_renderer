import 'package:flutter/material.dart';
import 'package:gdoc_renderer/doc_renderer/doc_renderer.dart';
import 'package:gdoc_renderer/doc_renderer/file_uploader.dart';
import 'package:gdoc_renderer/doc_renderer/paragraph_text_style.dart';
import 'package:gdoc_renderer/doc_renderer/table_renderer.dart' as table;
import 'package:googleapis_auth/googleapis_auth.dart';

Future<void> exampleDocRender(BuildContext context) async {
  DocRenderer docRenderer = DocRenderer(title: "Example document");

  docRenderer.addTextLine(text: "PlainText0");

  docRenderer.addTextLine(
    text: "StyledPlainText",
    textStyle: const ParagraphTextStyle(
      fontSize: 8,
      fontColor: Color(0xFFFF6600),
      backgroundColor: Colors.green,
      decorations: [
        ParagraphTextDecorationEnum.UNDERLINED,
      ],
    ),
  );

  docRenderer.addTextLine(
    text: "StyledHeaderText",
    textStyle: const ParagraphTextStyle(
      style: ParagraphTextStyleEnum.HEADER_5,
      fontSize: 36,
      fontColor: Color(0xFF66FF66),
      decorations: [
        ParagraphTextDecorationEnum.ITALIC,
        ParagraphTextDecorationEnum.BOLD,
      ],
    ),
  );

  docRenderer.addTextLine(
    text: "Header1",
    textStyle: const ParagraphTextStyle(style: ParagraphTextStyleEnum.HEADER_2),
  );
  docRenderer.addTextLine(text: "PlainText1");

  docRenderer.addTextLine(
    text: "Header2",
    textStyle: const ParagraphTextStyle(style: ParagraphTextStyleEnum.HEADER_2),
  );
  docRenderer.addTextLine(
    text: "SubHeader2",
    textStyle: const ParagraphTextStyle(style: ParagraphTextStyleEnum.HEADER_3),
  );
  docRenderer.addTextLine(text: "PlainText2");

  docRenderer.addList(lines: ["aaa", "bbb", "ccc"]);

  docRenderer.addTextLine(
    text: "SubHeader3",
    textStyle: const ParagraphTextStyle(style: ParagraphTextStyleEnum.HEADER_3),
  );

  docRenderer.addList(lines: ["aaa", "bbb", "ccc"]);

  docRenderer.addImage(
    uri: "https://picsum.photos/300/200",
    height: 300,
    width: 200,
  );

  docRenderer.addTextLine(
    text: "SubHeader4",
    textStyle: const ParagraphTextStyle(style: ParagraphTextStyleEnum.HEADER_3),
  );

  docRenderer.addTable(
    rows: [
      table.Row(
        cells: [
          table.Cell(
            text: "111",
            textStyle: const ParagraphTextStyle(style: ParagraphTextStyleEnum.HEADER_3),
          ),
          table.Cell(
            text: "222",
            textStyle: const ParagraphTextStyle(fontSize: 6, backgroundColor: Colors.pinkAccent),
            backgroundColor: Colors.green,
          ),
        ],
      ),
      table.Row(
        cells: [
          table.Cell(
            text: "aaa",
            mergeRight: 4,
            mergeDown: 5,
          ),
        ],
      ),
      table.Row(
        cells: [
          table.Cell(text: "bbb"),
          table.Cell(
            text: "ccc",
            textStyle: const ParagraphTextStyle(style: ParagraphTextStyleEnum.HEADER_5),
          ),
        ],
      ),
      table.Row(
        cells: [
          table.Cell(text: "ddd"),
          table.Cell(text: "eee"),
        ],
      ),
      table.Row(
        cells: [
          null,
          table.Cell(text: "fff"),
        ],
      ),
    ],
  );

  docRenderer.addTextLine(text: "PlainText111");
  docRenderer.addTextLine(
    text: "SubHeader222",
    textStyle: const ParagraphTextStyle(style: ParagraphTextStyleEnum.HEADER_3),
  );

  await docRenderer.save();
}

Future<void> uploadImage(AuthClient authClient, DocRenderer docRenderer) async {
  var fileUploader = FileUploader(authClient: authClient);
  String? uploadedFileUrl = await fileUploader.uploadFile("local_file_path");

  if (uploadedFileUrl == null) {
    print("Failed to upload file");
    return;
  }

  print("Upload successful: $uploadedFileUrl");
  docRenderer.addImage(
    uri: uploadedFileUrl,
    height: 300,
    width: 200,
  );
}