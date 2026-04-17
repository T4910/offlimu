# CI/CD Pipeline

## What Runs Automatically

- `.github/workflows/ci.yml` validates pull requests and pushes with `flutter pub get`, `scripts/verify_codegen.sh`, `flutter analyze`, and `flutter test`.
- `.github/workflows/build-artifacts.yml` builds release artifacts for Android, Windows, macOS, Linux, and an iOS simulator bundle.

## How To Publish Artifacts

1. Create a version tag and push it:

   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. GitHub Actions will run the release workflow and attach the build outputs to a GitHub Release for that tag.

## What Gets Built

- Android APK and AAB
- Windows release zip
- macOS release app zip
- Linux release tarball
- iOS simulator build zip for compile validation

## Notes

- GitHub Packages is not a good fit for Flutter app binaries. GitHub Releases is the right place for these artifacts, and the workflow also keeps per-run artifacts in Actions for download.
- Android, macOS, and iOS builds are configured for the current demo/runtime setup. For signed iOS or Mac App Store distribution, add Apple code-signing secrets later.