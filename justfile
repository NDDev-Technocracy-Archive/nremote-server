set shell := ["bash", "-euo", "pipefail", "-c"]
set positional-arguments

# List the maintained commands.
default:
    @just --list

# Check workflow and command source offline.
check:
    just --fmt --check
    bash -n scripts/ci/security.sh
    shellcheck scripts/ci/security.sh
    actionlint
    zizmor --offline --no-progress .github

# Apply formatting to the command source.
fix:
    just --fmt

# Run the locked native Rust tests.
test:
    cargo test --locked --all-targets

# Build every native Rust target from the lockfile.
build:
    cargo build --locked --all-targets

# Run the complete Linux verification, including the reference image build.
verify scope="--all":
    just check
    just test-format
    just lint-rust
    just build
    just test
    just test-contracts
    just audit-dependencies
    just scan-dependencies
    just scan-secrets "$1"
    just build-image

# Check native formatting with the same generated version placeholder as CI.
test-format:
    bash scripts/ci/security.sh format

# Run the build-dependent Rust lint without changing the lockfile.
lint-rust:
    cargo clippy --locked --all-targets -- -D warnings

# Exercise the existing commit-message exemption controls.
test-contracts:
    node scripts/check_commitlint_config.mjs

# Audit the complete locked dependency graph with the existing policy.
audit-dependencies:
    cargo audit

# Scan root and vendor lockfiles recursively with the existing policy.
scan-dependencies:
    osv-scanner scan source --recursive .

# Scan exact new commits, or complete history by default.
scan-secrets scope="--all":
    bash scripts/ci/security.sh secrets "$1"

# Build the reference image without publishing it.
build-image:
    docker build --platform linux/amd64 -f Dockerfile .
