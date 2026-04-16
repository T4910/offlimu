import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lib imports respect architecture boundaries', () {
    final libDir = Directory('lib');
    expect(
      libDir.existsSync(),
      isTrue,
      reason: 'Expected to run from project root where lib/ exists.',
    );

    final violations = <String>[];

    for (final entity in libDir.listSync(recursive: true).whereType<File>()) {
      if (!entity.path.endsWith('.dart')) {
        continue;
      }
      if (_isGeneratedFile(entity.path)) {
        continue;
      }

      final sourceRelPath = _toPosixPath(entity.path, libDir.path);
      final sourceLayer = _topLevelLayer(sourceRelPath);
      if (sourceLayer == null) {
        continue;
      }

      final lines = entity.readAsLinesSync();
      for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
        final importTarget = _parseImportTarget(lines[lineIndex]);
        if (importTarget == null) {
          continue;
        }

        final targetRelPath = _resolveLibImportTarget(
          sourceFile: entity,
          sourceRelPath: sourceRelPath,
          importTarget: importTarget,
          libDir: libDir,
        );
        if (targetRelPath == null) {
          continue;
        }

        final targetLayer = _topLevelLayer(targetRelPath);
        if (targetLayer == null) {
          continue;
        }

        if (_isAllowedImport(sourceLayer, targetLayer)) {
          continue;
        }

        violations.add(
          '$sourceRelPath:${lineIndex + 1} imports $targetRelPath '
          '(rule: $sourceLayer -> $targetLayer is forbidden)',
        );
      }
    }

    expect(
      violations,
      isEmpty,
      reason: violations.isEmpty
          ? null
          : 'Architecture import boundary violations:\n${violations.join('\n')}',
    );
  });
}

bool _isGeneratedFile(String path) {
  return path.endsWith('.g.dart') ||
      path.endsWith('.freezed.dart') ||
      path.endsWith('.mocks.dart') ||
      path.endsWith('.gr.dart');
}

String _toPosixPath(String fullPath, String basePath) {
  final normalizedFull = fullPath.replaceAll('\\', '/');
  final normalizedBase = basePath.replaceAll('\\', '/');
  final prefix = normalizedBase.endsWith('/')
      ? normalizedBase
      : '$normalizedBase/';
  if (!normalizedFull.startsWith(prefix)) {
    return normalizedFull;
  }
  return normalizedFull.substring(prefix.length);
}

String? _topLevelLayer(String relativePath) {
  final separatorIndex = relativePath.indexOf('/');
  if (separatorIndex <= 0) {
    return null;
  }
  return relativePath.substring(0, separatorIndex);
}

String? _parseImportTarget(String line) {
  final singleQuote = RegExp(r"^\s*import\s+'([^']+)'");
  final doubleQuote = RegExp(r'^\s*import\s+"([^"]+)"');
  final singleMatch = singleQuote.firstMatch(line);
  if (singleMatch != null) {
    return singleMatch.group(1);
  }
  final doubleMatch = doubleQuote.firstMatch(line);
  if (doubleMatch != null) {
    return doubleMatch.group(1);
  }
  return null;
}

String? _resolveLibImportTarget({
  required File sourceFile,
  required String sourceRelPath,
  required String importTarget,
  required Directory libDir,
}) {
  const packagePrefix = 'package:offlimu/';
  if (importTarget.startsWith(packagePrefix)) {
    return importTarget.substring(packagePrefix.length);
  }

  if (importTarget.startsWith('dart:') ||
      importTarget.startsWith('package:flutter/') ||
      importTarget.startsWith('package:flutter_test/') ||
      importTarget.startsWith('package:')) {
    return null;
  }

  if (!importTarget.startsWith('./') && !importTarget.startsWith('../')) {
    return null;
  }

  final resolvedUri = sourceFile.parent.uri.resolve(importTarget);
  final resolvedPath = File.fromUri(resolvedUri).absolute.path;
  final libPath = libDir.absolute.path;
  final normalizedResolved = resolvedPath.replaceAll('\\', '/');
  final normalizedLib = libPath.replaceAll('\\', '/');
  final prefix = normalizedLib.endsWith('/')
      ? normalizedLib
      : '$normalizedLib/';
  if (!normalizedResolved.startsWith(prefix)) {
    return null;
  }

  final resolvedRelPath = normalizedResolved.substring(prefix.length);
  if (_topLevelLayer(sourceRelPath) == 'app' &&
      !resolvedRelPath.contains('/')) {
    return null;
  }
  return resolvedRelPath;
}

bool _isAllowedImport(String sourceLayer, String targetLayer) {
  switch (sourceLayer) {
    case 'domain':
      return targetLayer == 'domain';
    case 'infrastructure':
      return targetLayer == 'infrastructure' ||
          targetLayer == 'domain' ||
          targetLayer == 'core' ||
          targetLayer == 'node_runtime';
    case 'node_runtime':
      return targetLayer == 'node_runtime' ||
          targetLayer == 'domain' ||
          targetLayer == 'core';
    case 'core':
      return targetLayer == 'core' ||
          targetLayer == 'domain' ||
          targetLayer == 'infrastructure' ||
          targetLayer == 'node_runtime';
    case 'features':
      return targetLayer == 'features' ||
          targetLayer == 'domain' ||
          targetLayer == 'core';
    case 'app':
      return targetLayer == 'app' ||
          targetLayer == 'core' ||
          targetLayer == 'features';
    default:
      return true;
  }
}
