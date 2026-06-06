import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/use_cases/resend_bundle_use_case.dart';
import 'package:offlimu/infrastructure/db/app_database.dart';
import 'package:offlimu/infrastructure/db/drift_bundle_repository.dart';

void main() {
  test(
    'resendFileTransfer requeues metadata and chunk bundles for a file',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final repository = DriftBundleRepository(db, localNodeId: 'node-a');
      final useCase = ResendBundleUseCase(bundles: repository);
      final now = DateTime.now();

      await repository.save(
        Bundle(
          bundleId: 'file-meta',
          type: Bundle.typeFileShareMetadata,
          sourceNodeId: 'node-a',
          destinationNodeId: 'node-b',
          payloadReference: 'sha256:file',
          payload: jsonEncode(<String, Object?>{'contentHash': 'sha256:file'}),
          appId: 'offlimu.files',
          createdAt: now,
          ttlSeconds: 3600,
          acknowledged: true,
          failedAttempts: 1,
          lastError: 'expired',
        ),
      );
      await repository.save(
        Bundle(
          bundleId: 'file-chunk-0',
          type: Bundle.typeFileShareChunk,
          sourceNodeId: 'node-a',
          destinationNodeId: 'node-b',
          payloadReference: 'sha256:file',
          appId: 'offlimu.files',
          createdAt: now,
          ttlSeconds: 3600,
          acknowledged: true,
          failedAttempts: 1,
          lastError: 'expired',
        ),
      );

      final result = await useCase.resendFileTransfer('sha256:file');
      final pending = await repository.getPendingBundles();

      expect(result.requeuedCount, 2);
      expect(pending.map((bundle) => bundle.bundleId), contains('file-meta'));
      expect(
        pending.map((bundle) => bundle.bundleId),
        contains('file-chunk-0'),
      );
    },
  );
}
