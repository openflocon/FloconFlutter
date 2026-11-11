# Publishing to pub.dev: TODO

Checklist to publish the Flocon packages on [pub.dev](https://pub.dev). Publishing itself is done by a GitHub Action, triggered by a git tag. Tick the boxes as the steps are done, and delete this file once the first release is out.

Packages (publish order matters, everything depends on `flocon`):

1. `flocon`
2. `flocon_dio`, `flocon_http`, `flocon_shared_preferences`, `flocon_files`, `flocon_crash_reporter`, `flocon_database`, `flocon_qr_scanner`

## 1. pub.dev account and ownership (manual, one time)

- [ ] Create or choose a [verified publisher](https://pub.dev/create-publisher) for the `openflocon` organization (verified domain), so that the packages are owned by it and not by a person.
- [ ] Check that the names are free on pub.dev: `flocon`, `flocon_dio`, `flocon_http`, `flocon_shared_preferences`, `flocon_files`, `flocon_crash_reporter`, `flocon_database`, `flocon_qr_scanner`. Rename now if one is taken (renaming after publication is impossible).
- [ ] Decide on the versioning: all packages share the same version number, or each one has its own. Recommended: independent versions, `flocon_*` plugins constrain `flocon: ^x.y.z`.

## 2. Prepare the packages (PR)

For each package in `packages/`:

- [ ] Remove `publish_to: none` from the `pubspec.yaml` (all packages except `flocon`).
- [ ] Replace the `flocon: path: ../flocon` dependency by a version constraint (`flocon: ^0.1.0`). Keep working locally with a pub workspace (`workspace:` in a root `pubspec.yaml`, `resolution: workspace` in each package) or with a `pubspec_overrides.yaml` that is not published.
- [ ] Pick the first version (`0.1.0` instead of `0.0.1` is suggested), and write the matching entry in `CHANGELOG.md` (pub.dev shows it, and the release check below reads it).
- [ ] `pubspec.yaml` has `description` (60 to 180 characters), `repository`, `issue_tracker`, `topics` (5 max), and no `homepage` pointing to a dead link.
- [ ] `LICENSE`, `README.md` (with an installation snippet using the pub.dev version, not the git one) and `example/` are present and up to date.
- [ ] `lib/` exposes a single public entry point per package, and the public API has `///` doc comments (pana scores them).
- [ ] `dart pub publish --dry-run` (or `flutter pub publish --dry-run`) passes with no warning, in every package.
- [ ] `flutter analyze` and `flutter test` pass in every package (`tool/check.sh`).
- [ ] Update the root `README.md`: replace the "There is no release on pub.dev yet, depend on the repository" section by the pub.dev installation (`flutter pub add flocon flocon_dio ...`).
- [ ] Check `flocon` native code (Android, iOS, macOS) builds from the published archive: the `.pubignore` / `.gitignore` must not exclude files the plugin needs, and `ios/flocon.podspec`, `macos/flocon.podspec` have the right version and metadata.
- [ ] Check the `false_secrets` entry of `flocon` (TLS test key) still makes `pub publish` pass the secret scan.

## 3. First release (manual, one time)

pub.dev lets you enable automated publishing only on a package that already exists, so the first version of each package is published by hand:

- [ ] From a clean checkout of `main`, with the verified publisher account: `dart pub publish` (or `flutter pub publish`) in `packages/flocon`, then in each other package. `--dry-run` first.
- [ ] Transfer each package to the verified publisher if it was not published under it (Admin tab > Publisher).
- [ ] Check the page of each package: score (pana), platforms, license, example, changelog, topics.

## 4. Automated publishing from GitHub Actions (PR)

Uses [OIDC automated publishing](https://dart.dev/tools/pub/automated-publishing), no long-lived secret is stored.

- [ ] On pub.dev, for **each package**: Admin tab > Automated publishing > Enable publishing from GitHub Actions. Repository: `openflocon/FloconFlutter`. Tag pattern: `{{package}}-v{{version}}` (example tag: `flocon-v0.1.0`). Enable "Require GitHub Actions environment" and set it to `pub.dev`.
- [ ] On GitHub: create the environment `pub.dev` (Settings > Environments), with required reviewers, so that nobody can publish without an approval.
- [ ] Add `.github/workflows/publish.yml`:
  - triggers on tags matching `[a-z_]+-v[0-9]+.[0-9]+.[0-9]+*`;
  - `permissions: id-token: write`, `environment: pub.dev`;
  - sets up Flutter (pinned stable version) with `subosito/flutter-action`;
  - derives the package directory and the version from the tag name (`flocon_dio-v0.1.0` -> `packages/flocon_dio`, `0.1.0`);
  - checks that the version in the package `pubspec.yaml` and its `CHANGELOG.md` match the tag, and fails otherwise;
  - runs `flutter pub get`, `flutter analyze`, `flutter test` in the package;
  - runs `dart pub publish --dry-run`, then `dart pub publish --force`.
- [ ] Add `.github/workflows/check.yml` (on pull requests): runs `tool/check.sh` and `dart pub publish --dry-run` for every package, so a PR cannot break publication.
- [ ] Test the workflow with a pre-release tag first (`flocon-v0.1.1-dev.1`), then remove it from pub.dev if needed (a published version can only be retracted within 7 days).

## 5. Release procedure (document it, then follow it for every release)

- [ ] Add a "Releasing" section to the root `README.md` (or `CONTRIBUTING.md`) with the steps below.
- [ ] Bump `version` and write the `CHANGELOG.md` entry in the package(s) to release, through a PR merged into `main`.
- [ ] If `flocon` changes in a breaking way, bump the constraint in the `flocon_*` packages that depend on it, and release `flocon` first.
- [ ] Tag `main` and push the tag: `git tag flocon-v0.1.0 && git push origin flocon-v0.1.0`, one tag per package, `flocon` first.
- [ ] Approve the deployment in the GitHub `pub.dev` environment, check that the run is green and that the version appears on pub.dev.
- [ ] Create the GitHub release from the tag, with the changelog entry as notes.

## 6. After the first release

- [ ] Remove the git-based installation snippet from the docs of the Flocon desktop app and from the `Flocon` repository docs (`docs2/setup.md`, root `README.md`), and point to pub.dev.
- [ ] Add pub.dev badges (version, points) to the README of each package.
- [ ] Switch the `sample/` app to the pub.dev versions (optional, keep `path:` if it is used to test local changes).
- [ ] Delete this file.
