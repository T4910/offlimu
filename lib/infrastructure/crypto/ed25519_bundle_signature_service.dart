import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/services/bundle_signature_service.dart';
import 'package:offlimu/domain/services/crypto_service.dart';
import 'package:offlimu/domain/services/node_identity_store.dart';

class Ed25519BundleSignatureService implements BundleSignatureService {
  Ed25519BundleSignatureService({
    required CryptoService cryptoService,
    required NodeIdentityStore nodeIdentityStore,
    String displayName = 'OffLiMU Node',
  }) : _cryptoService = cryptoService,
       _nodeIdentityStore = nodeIdentityStore,
       _displayName = displayName;

  final CryptoService _cryptoService;
  final NodeIdentityStore _nodeIdentityStore;
  final String _displayName;

  @override
  Future<Bundle> sign({required Bundle bundle, required String nodeId}) async {
    final identity = await _nodeIdentityStore.loadOrCreate(
      nodeId: nodeId,
      displayName: _displayName,
    );
    final signedPayload = bundle.copyWith(
      sourcePublicKey: identity.publicKeyBase64,
    );
    final signature = await _cryptoService.sign(signedPayload.signaturePayload);
    return signedPayload.copyWith(signature: signature);
  }

  @override
  Future<bool> verify(Bundle bundle) async {
    final signature = bundle.signature;
    final publicKey = bundle.sourcePublicKey;
    if (signature == null || publicKey == null) {
      return false;
    }

    return _cryptoService.verify(
      payload: bundle.signaturePayload,
      signature: signature,
      publicKey: publicKey,
    );
  }
}
