import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:html' as html;
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

import 'constants.dart';

void main() async {
  Intl.defaultLocale = 'ja_JP';
  await initializeDateFormatting("ja_JP");
  runApp(const MyApp());
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

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<List<dynamic>> _trashCsvData = [];
  bool _showProgress = false;
  FilePickerResult? _pickedFile;

  @override
  Widget build(BuildContext context) {
    final fileName = _pickedFile?.files.single.name;
    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (fileName != null)
                  Text(
                    "Selected file name: $fileName",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ElevatedButton(
                  onPressed: _selectExcel,
                  child: const Text('Select File'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _pickedFile == null
                      ? null
                      : () async {
                          _generateTrashData();
                        },
                  child: const Text('Generate Trash Data'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed:
                      _trashCsvData.isEmpty ? null : _generateCsvAndDownload,
                  child: const Text('Download CSV'),
                ),
              ],
            ),
          ),
          if (_showProgress)
            Container(
                color: Colors.transparent,
                width: double.infinity,
                height: double.infinity,
                alignment: Alignment.center,
                child: const CircularProgressIndicator())
        ],
      ),
    );
  }

  Future<void> _selectExcel() async {
    setState(() {
      _showProgress = true;
    });
    _trashCsvData.clear();

    /// Use FilePicker to pick files in Flutter Web
    _pickedFile = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      allowMultiple: false,
    );

    setState(() {
      _showProgress = false;
    });
  }

  Future<void> _generateTrashData() async {
    setState(() {
      _showProgress = true;
    });

    /// file might be picked
    final bytes = _pickedFile?.files.single.bytes;
    if (bytes == null) {
      return;
    }
    List<List<dynamic>> trashCsvData = await _parsingExcel(bytes);
    _trashCsvData.addAll(_transpose(trashCsvData));
    setState(() {
      _showProgress = false;
    });
  }

  Future<List<List<dynamic>>> _parsingExcel(Uint8List bytes) async {
    final selectedExcel = Excel.decodeBytes(bytes);
    final Map<String, List> tempData = {};
    final List<List<String>> dateColumn = [];
    for (var table in selectedExcel.tables.keys) {
      final chomeCell = CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0);
      final chome =
          (selectedExcel.tables[table]!.cell(chomeCell).value ?? "").toString();
      Logger().d(table); //sheet Name
      Logger().d(selectedExcel.tables[table]?.maxColumns);
      Logger().d(selectedExcel.tables[table]?.maxRows);
      final sheetTempData = _generateSheetTrashData(selectedExcel, table);
      if (dateColumn.isEmpty) {
        dateColumn.addAll(_generateHeaderColumnData(selectedExcel, table));
      }
      tempData[chome] = sheetTempData;
    }
    final List<List<dynamic>> trashCsvData = [];
    trashCsvData.addAll(dateColumn);
    for (var chome in sortedChomeList) {
      tempData.forEach((key, value) {
        List<String> chomeDetail = chome.split(" ");
        if (key.contains(chomeDetail[0]) && key.contains(chomeDetail[1])) {
          final tempValue = List.from(value);
          tempValue.insert(0, chomeDetail[2]);
          trashCsvData.add(tempValue);
        }
      });
    }
    return trashCsvData;
  }

  List<dynamic> _generateSheetTrashData(Excel excel, String table) {
    final sheetTempData = [];
    for (var row in excel.tables[table]!.rows) {
      for (var cell in row) {
        final cellValue = cell?.value;
        if (numberRegExp.hasMatch(cellValue.toString())) {
          final trashData = (excel.tables[table]!
                      .cell(CellIndex.indexByColumnRow(
                          columnIndex: cell!.columnIndex,
                          rowIndex: cell.rowIndex + 1))
                      .value ??
                  "")
              .toString();
          sheetTempData.add(trashValueToIntMap[trashData] ?? "");
        }
      }
    }
    return sheetTempData;
  }

  List<List<String>> _generateHeaderColumnData(Excel excel, String table) {
    List<String> firstColumnTempData = ["日付"];
    List<String> secondColumnTempData = ["曜"];
    for (var row in excel.tables[table]!.rows) {
      for (var cell in row) {
        final cellValue = cell?.value;
        if (dateRegExp.hasMatch(cellValue.toString())) {
          final dateStr = cellValue.toString();
          DateTime trashDate = DateFormat('yyyy年MM月').parse(dateStr);
          final days =
              DateUtils.getDaysInMonth(trashDate.year, trashDate.month);
          for (int day = 1; day <= days; day++) {
            DateTime date = DateTime(trashDate.year, trashDate.month, day);
            String formattedDate = DateFormat('yyyy/MM/dd').format(date);
            firstColumnTempData.add(formattedDate);
            secondColumnTempData.add(DateFormat.E('ja').format(date));
          }
        }
      }
    }
    return [firstColumnTempData, secondColumnTempData];
  }

  void _generateCsvAndDownload() {
    String csv = const ListToCsvConverter().convert(_trashCsvData);

    final blob = html.Blob([csv], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: url)
      ..setAttribute("download", "1_埼玉県_さいたま市.csv")
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  List<List<dynamic>> _transpose(List<List<dynamic>> data) {
    if (data.isEmpty) return [];
    int rowCount = data.length;
    int colCount = data[0].length;
    List<List<dynamic>> transposed = List.generate(
      colCount,
      (index) => List.generate(rowCount, (subIndex) => null),
    );

    for (int i = 0; i < rowCount; i++) {
      for (int j = 0; j < colCount; j++) {
        transposed[j][i] = data[i][j];
      }
    }
    return transposed;
  }
}
