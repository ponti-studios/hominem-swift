default: build test

# Build every product from the root manifest.
build:
    swift build

# Run every package test suite. No network calls by default.
test:
    swift test

# Normalize formatting across the root manifest and packages.
fmt:
    swift-format format --recursive --in-place Package.swift packages/*/Sources packages/*/Tests

# Fail if any file drifts from the committed formatting.
lint:
    swift-format lint --recursive Package.swift packages/*/Sources packages/*/Tests

# Print the resolved products, targets, and platforms.
package-describe:
    swift package describe

# Report toolchain and repository state. Never prints secrets.
doctor:
    @swift-format --version
    @just --version
    @swift --version 2>&1 | head -1
    @xcodebuild -version 2>&1 | head -1
    @git status --short | head -20 && test -z "$(git status --short)" && echo "tree clean" || echo "tree dirty"

# Gate every release must pass before tagging.
release-check: build test lint
    git diff --check
    @test -z "$(git status --short)" || (echo "ERROR: dirty tree, commit first" && exit 1)
    @echo "release checks passed"
