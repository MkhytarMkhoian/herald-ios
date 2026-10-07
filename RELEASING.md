# Releasing

Herald for iOS is six Swift packages, one per repository: `herald-ios`, and one per vendor. They
share one version. Swift Package Manager installs a package straight from its git tags, so a
release is a `vX.Y.Z` tag in each repository; there is nothing to upload.

`herald-ios` is released first, because the vendor packages depend on it. Pushing its tag also
runs the **Release** workflow, which asks [herald-docs](https://github.com/MkhytarMkhoian/herald-docs)
to redeploy the website with the new samples and change log.

## Steps

1. **Update `CHANGELOG.md`** in `herald-ios`. It covers all six packages.
    - Under `## Version X.Y.Z`, replace `_Unreleased_` with the release date, `_YYYY-MM-DD_`.
    - Check that every change a user would notice is listed, each starting with `New:`, `Fix:`,
      `Upgrade:` or `Breaking:`.
2. **Update the version shown to readers,** in the install snippets of every `README.md`.
3. **Check that everything passes,** with the vendor repositories cloned next to `herald-ios`:

    ```bash
    swift format lint --strict -r Sources Tests Samples/Sources Samples/Tests Example Package.swift
    swift test
    scripts/check-api.sh
    (cd Samples && xcodebuild test -scheme herald-ios-samples-Package \
        -destination "id=$(../scripts/simulator.sh)")
    xcodebuild test -project Example/HeraldExample.xcodeproj -scheme HeraldExample \
        -destination "id=$(scripts/simulator.sh)"
    ```

    If a repository has an `api-breakage-allowlist.txt`, check that each break in it has a
    `Breaking:` line in the change log, then delete the file: the new release is what the next
    changes are compared with.

4. **Release `herald-ios`:**

    ```bash
    git commit -am "Release X.Y.Z"
    git tag vX.Y.Z
    git push origin main vX.Y.Z
    ```

5. **Release each vendor package,** with the same version. If it needs the new `herald-ios`, raise
   the version in its `Package.swift` first (`from: "X.Y.Z"`). Then, in each one:

    ```bash
    git commit -am "Release X.Y.Z"
    git tag vX.Y.Z
    git push origin main vX.Y.Z
    ```

6. **Verify:**
    - CI is green in all six repositories.
    - A new app resolves the packages at `X.Y.Z` in Xcode, through File → Add Package Dependencies.
    - The [website](https://mkhytarmkhoian.github.io/herald-docs/) shows the release in its change
      log.

A tag must never move once pushed: apps may already have resolved it. When a release is wrong,
fix it forward with the next version.

## Pre-releases

A version like `1.0.0-beta.1` is a pre-release. Apps get it only when they ask for it, such as
`from: "1.0.0-beta.1"`; `from: "1.0.0"` never picks it up.

## The first release

Until `herald-ios` has a tag on GitHub, the vendor packages find it on disk, at `../herald-ios`.
For the first release:

1. Release `herald-ios` as in steps 1 to 4.
2. In each vendor package, replace `.package(path: "../herald-ios")` with
   `.package(url: "https://github.com/MkhytarMkhoian/herald-ios", from: "X.Y.Z")`, check that
   it builds, and release it as in step 5.

## One-time setup

- **`DOCS_DISPATCH_TOKEN`**, a repository secret in `herald-ios`: a fine-grained personal access
  token with repository access to herald-docs only and the Contents permission set to read and
  write. It's the same token as in herald and herald-flutter. It expires, so renew it in time.
- **[Swift Package Index](https://swiftpackageindex.com/add-a-package):** add all six packages
  once. It then lists every new release by itself, and builds the API reference that each
  repository's `.spi.yml` asks for.
