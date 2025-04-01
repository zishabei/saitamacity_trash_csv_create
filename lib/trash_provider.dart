import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'constants.dart';

part 'trash_provider.g.dart';

@riverpod
class SelectExcel extends _$SelectExcel {
  @override
  FutureOr<FilePickerResult?> build() async {
    return null;
  }

  void selectExcel() async {
    state = const AsyncValue.loading();
    ref.invalidate(parseExcelProvider);
    ref.invalidate(buildTrashDataProvider);
    state = AsyncData(
      await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        allowMultiple: false,
      ),
    );
  }
}

@riverpod
class ParseExcel extends _$ParseExcel {
  @override
  FutureOr<Excel?> build() async {
    return null;
  }

  void parse() async {
    state = const AsyncValue.loading();
    await Future.delayed(const Duration(seconds: 1));
    final pickedFile = ref.read(selectExcelProvider).value;
    final bytes = pickedFile?.files.single.bytes;
    if (bytes == null) {
      state = const AsyncValue.data(null);
      return;
    }
    state = AsyncData(Excel.decodeBytes(bytes));
  }
}

@riverpod
class BuildTrashData extends _$BuildTrashData {
  @override
  List<List<dynamic>> build() {
    return [];
  }

  void buildTrashData() async {
    final selectedExcel = ref.read(parseExcelProvider).value;
    if (selectedExcel == null) {
      return;
    }
    await Future.delayed(const Duration(milliseconds: 400));
    final Map<String, List> tempData = {};
    final List<List<String>> dateColumn = [];
    for (var table in selectedExcel.tables.keys) {
      final chomeCell = CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0);
      final chome =
          (selectedExcel.tables[table]!.cell(chomeCell).value ?? "").toString();
      Logger().d(
        'sheet Name: $table \ncolumns:${selectedExcel.tables[table]?.maxColumns} \nrows:${selectedExcel.tables[table]?.maxRows}',
      ); //sheet Name
      final sheetTempData = _generateSheetTrashData(selectedExcel, table);
      if (dateColumn.isEmpty) {
        dateColumn.addAll(_generateHeaderColumnData(selectedExcel, table));
      }
      tempData[chome] = sheetTempData;
    }
    final List<List<dynamic>> trashCsvData = [];
    trashCsvData.addAll(dateColumn);
    Logger().d('tempData: $tempData');
    for (var chome in sortedChomeList) {
      tempData.forEach((areaChomes, value) {
        // areaChomes　例:
        //【大宮区】::東町１・２丁目、天沼町１・２丁目、★吉敷町１丁目、★吉敷町２丁目（線路より東）、吉敷町３・４丁目、北袋町１・２丁目、★下町１～３丁目、浅間町１・２丁目、★大門町１～３丁目、★仲町１～３丁目、★宮町１～５丁目
        final areaName = areaChomes.split("::")[0];
        final chomes =
            areaChomes
                .split("::")[1]
                .split("、")
                .map((e) => e.replaceAll("★", ""))
                .toList();
        List<String> chomeDetail = chome.split(" ");
        if (areaName.contains(chomeDetail[0]) &&
            chomes.contains(chomeDetail[1])) {
          final tempValue = List.from(value);
          tempValue.insert(0, chomeDetail[2]);
          trashCsvData.add(tempValue);
        }
      });
    }
    state = _transpose(trashCsvData);
  }

  List<dynamic> _generateSheetTrashData(Excel excel, String table) {
    final sheetTempData = [];
    for (var row in excel.tables[table]!.rows) {
      for (var cell in row) {
        final cellValue = cell?.value;
        if (numberRegExp.hasMatch(cellValue.toString())) {
          final trashData =
              (excel.tables[table]!
                          .cell(
                            CellIndex.indexByColumnRow(
                              columnIndex: cell!.columnIndex,
                              rowIndex: cell.rowIndex + 1,
                            ),
                          )
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
          final days = DateUtils.getDaysInMonth(
            trashDate.year,
            trashDate.month,
          );
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
