#!/usr/bin/env bash
#
# Fails when the public API breaks compared with the latest release, such as a renamed method or a
# removed type, so a break can't happen by accident.
#
# When a break is intended, copy the reported line, the text after 💔, into
# api-breakage-allowlist.txt, one per line, in the same change. Delete the file when releasing.

set -euo pipefail

cd "$(dirname "$0")/.."

release=$(git describe --tags --abbrev=0)
echo "Comparing the public API with $release"

if [ -f api-breakage-allowlist.txt ]; then
  swift package diagnose-api-breaking-changes "$release" \
    --breakage-allowlist-path api-breakage-allowlist.txt
else
  swift package diagnose-api-breaking-changes "$release"
fi
