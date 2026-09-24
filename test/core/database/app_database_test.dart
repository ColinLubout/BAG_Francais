import 'package:bah_francais/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('opens and runs a query', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    expect(database.schemaVersion, 1);
    final row = await database.customSelect('SELECT 1 AS one').getSingle();
    expect(row.read<int>('one'), 1);
  });
}
