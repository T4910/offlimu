import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offlimu/infrastructure/db/app_database.dart';

void main() {
  test('runHealthCheck returns true for healthy in-memory database', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final healthy = await db.runHealthCheck();

    expect(healthy, isTrue);
  });

  test('runVacuum completes and database remains healthy', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await db.runVacuum();
    final healthy = await db.runHealthCheck();

    expect(healthy, isTrue);
  });
}
