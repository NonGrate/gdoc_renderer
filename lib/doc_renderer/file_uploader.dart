import 'dart:io';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart';

class FileUploader {
  final AuthClient authClient;

  FileUploader({required this.authClient});

  Future<String?> uploadFile(String uri) async {
    final driveApi = drive.DriveApi(authClient);
    final folderId = await _getFolderId(driveApi);
    if (folderId == null) {
      print("Folder id is null aborting.");
      return null;
    }

    print("FileUploader: Creating a file with URI: $uri");

    var file = File.fromUri(Uri.parse(uri));
    final Stream<List<int>> mediaStream = file.openRead().asBroadcastStream();
    var fileLength = file.lengthSync();
    print("FileUploader: Creating a Media with $mediaStream with $fileLength length");
    var media = new drive.Media(mediaStream, fileLength);

    drive.File driveFile = drive.File();

    driveFile.name = uri.split("/").last;
    print("FileUploader: Creating a Drive file with the name: ${driveFile.name}");
    driveFile.modifiedTime = DateTime.now().toUtc();
    driveFile.parents = [folderId];
    print("FileUploader: Creating a Drive file with the name: ${driveFile.name} and parent folder id: $folderId");

    drive.File response = await driveApi.files.create(driveFile, uploadMedia: media);
    print("FileUploader: driveApi.files.create response: ${response.toJson()}");

    String fileId = response.id!;

    var permissions = await driveApi.permissions.create(drive.Permission(type: "anyone", role: "reader"), fileId);
    print("FileUploader: driveApi.permissions.create response: ${permissions.toJson()}");

    drive.File fileInfo = await driveApi.files.get(fileId, $fields: "webContentLink") as drive.File;
    print("FileUploader: driveApi.files.get response: ${fileInfo.toJson()}");

    return fileInfo.webContentLink;
  }

  Future<String?> _getFolderId(drive.DriveApi driveApi) async {
    final mimeType = "application/vnd.google-apps.folder";
    String folderName = "GDocRenderer";

    try {
      final found = await driveApi.files.list(
        q: "mimeType = '$mimeType' and name = '$folderName'",
        $fields: "files(id, name)",
      );
      final files = found.files;
      if (files == null) {
        print("FileUploader: Cannot get the list of drive files");
        return null;
      }

      if (files.isNotEmpty) {
        return files.first.id;
      }

      // Create a folder
      var folder = new drive.File();
      folder.name = folderName;
      folder.mimeType = mimeType;
      final folderCreation = await driveApi.files.create(folder);
      print("FileUploader: Folder ID is ${folderCreation.id}");

      return folderCreation.id;
    } catch (e) {
      print(e);
      return null;
    }
  }
}