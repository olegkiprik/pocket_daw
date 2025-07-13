export 'stub.dart' if (dart.library.permission_handler) 'import_android.dart';
import 'dart:io' as io;
import 'package:daw_with_ffi_example/import_android.dart';
import 'package:file_manager/file_manager.dart' as fm;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Select a file or a directory
class StorageRoute extends StatefulWidget {
  const StorageRoute({super.key});

  @override
  State<StorageRoute> createState() => _StorageRouteState();
}

class _StorageRouteState extends State<StorageRoute> {
  final fm.FileManagerController controller = fm.FileManagerController();

  @override
  Widget build(BuildContext context) {
    final args = (ModalRoute.of(context)?.settings.arguments ??
        <String, dynamic>{}) as Map;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(args['title'] as String),
      ),

      // https://pub.dev/packages/file_manager
      body: fm.FileManager(
        controller: controller,
        builder: (context, snapshot) {
          final List<io.FileSystemEntity> entities = snapshot;
          return ListView.builder(
            itemCount: entities.length,
            itemBuilder: (context, index) {
              return Card(
                child: ListTile(
                  leading: fm.FileManager.isFile(entities[index])
                      ? Icon(Icons.feed_outlined)
                      : Icon(Icons.folder),
                  title: Text(fm.FileManager.basename(entities[index])),
                  onTap: () {
                    if (fm.FileManager.isDirectory(entities[index])) {
                      controller.openDirectory(entities[index]);
                    } else {
                      // file selected
                      final path = entities[index].path;
                      debugPrint('PATH TO FILE: $path');
                      Navigator.pop(context, entities[index]);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: IconButton(
        tooltip: AppLocalizations.of(context)!.requestPermissionsTooltip,
        onPressed: () async {
          await requestPermissions();
        },
        icon: const Icon(Icons.sd_storage)),
    );
  }
}
