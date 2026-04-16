import 'package:offlimu/domain/entities/bundle.dart';

abstract interface class BundleSignatureService {
  Future<Bundle> sign({required Bundle bundle, required String nodeId});

  Future<bool> verify(Bundle bundle);
}
