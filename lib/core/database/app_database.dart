import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_database.g.dart';

/// The app's SQLite database. Everything the app stores lives here, on the
/// device.
///
/// It has no tables yet: they arrive with the data layer (milestone 2), whose
/// first schema is version 1.
@DriftDatabase()
class AppDatabase extends _$AppDatabase {
  /// Opens the database file on the device, or [executor] if given (tests
  /// pass an in-memory database).
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'bah_francais'));

  @override
  int get schemaVersion => 1;
}

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
}
