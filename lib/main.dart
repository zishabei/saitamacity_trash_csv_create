import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:html' as html;
import 'package:intl/intl.dart';
import 'package:saitama_trash_data_tool/trash_provider.dart';

void main() async {
  Intl.defaultLocale = 'ja_JP';
  await initializeDateFormatting("ja_JP");
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Saitama Trash Data Tool',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key});

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    final selectedFile = ref.watch(selectExcelProvider);
    final selectedFileName = selectedFile.value?.files.single.name;
    final parseExcel = ref.watch(parseExcelProvider);
    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (selectedFileName != null)
                  Text(
                    "選択したファイル: $selectedFileName",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ElevatedButton(
                  onPressed: ref.read(selectExcelProvider.notifier).selectExcel,
                  child: const Text('Select File'),
                ),
                const SizedBox(height: 12),
                parseExcelWarning,
                ElevatedButton(
                  onPressed:
                      selectedFile.value == null
                          ? null
                          : ref.read(parseExcelProvider.notifier).parse,
                  child: const Text('Parse Excel'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed:
                      parseExcel.value == null
                          ? null
                          : ref
                              .read(buildTrashDataProvider.notifier)
                              .buildTrashData,
                  child: const Text('Generate Trash Data'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed:
                      ref.watch(buildTrashDataProvider).isEmpty
                          ? null
                          : _downloadCsv,
                  child: const Text('Download CSV'),
                ),
              ],
            ),
          ),
          if (ref.watch(selectExcelProvider).isLoading)
            Container(
              color: Colors.transparent,
              width: double.infinity,
              height: double.infinity,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            ),
          if (parseExcel.isLoading)
            Container(
              color: Colors.transparent,
              width: double.infinity,
              height: double.infinity,
              alignment: Alignment.center,
              child: Text(
                "ごみExcel解析中...",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
        ],
      ),
    );
  }

  void _downloadCsv() {
    String csv = const ListToCsvConverter().convert(
      ref.read(buildTrashDataProvider),
    );
    final blob = html.Blob([csv], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "1_埼玉県_さいたま市.csv")
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  Widget get parseExcelWarning {
    final parseExcel = ref.watch(parseExcelProvider);
    Widget widget(String message) {
      return Text(
        message,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      );
    }

    if (parseExcel.value != null) {
      return widget("ごみExcel解析完了。");
    }
    if (parseExcel.isLoading) {
      return widget("ごみExcel解析中...");
    }
    return const SizedBox.shrink();
  }
}
