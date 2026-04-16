#!/usr/bin/env bash
set -euo pipefail

echo "Running build_runner to verify generated code is up to date..."
flutter pub run build_runner build --delete-conflicting-outputs

if ! command -v git >/dev/null 2>&1; then
  echo "git is not available; skipping generated diff check."
  exit 0
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Not inside a git work tree; skipping generated diff check."
  exit 0
fi

if ! git diff --quiet -- '**/*.g.dart' '**/*.freezed.dart' '**/*.mocks.dart'; then
  echo "Generated files are stale. Please run build_runner and commit the results."
  git --no-pager diff -- '**/*.g.dart' '**/*.freezed.dart' '**/*.mocks.dart' | cat
  exit 1
fi

echo "Generated code is up to date."
