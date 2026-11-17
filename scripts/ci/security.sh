#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
  secrets)
    scope=${2:---all}
    if [[ "$scope" != --all && ! "$scope" =~ ^[0-9a-f]{40}\.\.[0-9a-f]{40}$ ]]; then
      printf 'secret scope must be --all or two full commit identifiers\n' >&2
      exit 2
    fi
    # Preserve the existing commit-specific imported-example policy.
    betterleaks git --config .gitleaks.toml --no-banner --redact "--log-opts=$scope" .
    ;;
  format)
    # build.rs creates this untracked module during a native build.
    printf 'pub const VERSION: &str = "0.0.0";\n' > src/version.rs
    cargo fmt --all --check
    ;;
  *)
    printf 'usage: %s secrets [--all|BASE..HEAD] | format\n' "$0" >&2
    exit 2
    ;;
esac
