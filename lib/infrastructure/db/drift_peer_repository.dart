import 'package:drift/drift.dart';
import 'package:offlimu/domain/entities/peer_contact.dart' as domain;
import 'package:offlimu/domain/repositories/peer_repository.dart';
import 'package:offlimu/infrastructure/db/app_database.dart' hide PeerContact;

class DriftPeerRepository implements PeerRepository {
  DriftPeerRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> upsertPeer(domain.PeerContact peer) async {
    final existing = await (_db.select(_db.peerContacts)
          ..where((tbl) => tbl.nodeId.equals(peer.nodeId)))
        .getSingleOrNull();

    final int seenCount = existing == null ? peer.seenCount : existing.seenCount + 1;

    await _db.into(_db.peerContacts).insertOnConflictUpdate(
          PeerContactsCompanion(
            nodeId: Value<String>(peer.nodeId),
            host: Value<String>(peer.host),
            port: Value<int>(peer.port),
            lastSeenMs: Value<int>(peer.lastSeen.millisecondsSinceEpoch),
            seenCount: Value<int>(seenCount),
          ),
        );
  }

  @override
  Stream<List<domain.PeerContact>> watchPeers() {
    final query = (_db.select(_db.peerContacts)
      ..orderBy(
        <OrderingTerm Function($PeerContactsTable)>[
          (tbl) => OrderingTerm.desc(tbl.lastSeenMs),
        ],
      ));

    return query.watch().map(
          (rows) => rows
              .map(
                (row) => domain.PeerContact(
                  nodeId: row.nodeId,
                  host: row.host,
                  port: row.port,
                  lastSeen: DateTime.fromMillisecondsSinceEpoch(row.lastSeenMs),
                  seenCount: row.seenCount,
                ),
              )
              .toList(growable: false),
        );
  }
}
