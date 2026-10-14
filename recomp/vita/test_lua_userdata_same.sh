#!/usr/bin/env bash
# Host test for the ISAAC_VITA_LUA_NATIVE_INDEX_VERIFY userdata comparison
# (recomp/runtime/host_vita_lua_userdata_same.h): two LuaBridge by-value boxes
# of the same Vector compare equal despite their self-relative m_p word, and
# every real difference is still caught.  Needs only a host C compiler.
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
work=$(mktemp -d "${TMPDIR:-/tmp}/isaac-lua-userdata-same.XXXXXX")
host_cc=${CC:-cc}

for opt in -O0 -O2; do
    "$host_cc" -std=gnu11 $opt -Wall -Wextra -Werror \
        -I"$root/runtime" \
        "$root/vita/host_tests/vita_lua_userdata_same_test.c" \
        -o "$work/userdata-same$opt"
    "$work/userdata-same$opt"
done
rm -rf "$work"
