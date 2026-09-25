#!/usr/bin/env bash
set -euo pipefail

bazel aquery 'mnemonic("CppCompile|CppLink", ":single_binary")' | grep -E '^action|Inputs' | sed 's#, external/[^],]*##g'
