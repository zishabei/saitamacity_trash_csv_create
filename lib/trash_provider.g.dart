// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trash_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$selectExcelHash() => r'201adffe8842be3464e19278e5b4265bf844d768';

/// See also [SelectExcel].
@ProviderFor(SelectExcel)
final selectExcelProvider =
    AutoDisposeAsyncNotifierProvider<SelectExcel, FilePickerResult?>.internal(
  SelectExcel.new,
  name: r'selectExcelProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$selectExcelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectExcel = AutoDisposeAsyncNotifier<FilePickerResult?>;
String _$parseExcelHash() => r'e8ec4071da33fca4278b764d183c25c556e2a0b2';

/// See also [ParseExcel].
@ProviderFor(ParseExcel)
final parseExcelProvider =
    AutoDisposeAsyncNotifierProvider<ParseExcel, Excel?>.internal(
  ParseExcel.new,
  name: r'parseExcelProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$parseExcelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ParseExcel = AutoDisposeAsyncNotifier<Excel?>;
String _$buildTrashDataHash() => r'217c29a079fb4d73c53d749fd72159f89a3884c1';

/// See also [BuildTrashData].
@ProviderFor(BuildTrashData)
final buildTrashDataProvider =
    AutoDisposeNotifierProvider<BuildTrashData, List<List<dynamic>>>.internal(
  BuildTrashData.new,
  name: r'buildTrashDataProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$buildTrashDataHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$BuildTrashData = AutoDisposeNotifier<List<List<dynamic>>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
