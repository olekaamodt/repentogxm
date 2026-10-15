# repentogxm optimization round 1: whole-corpus code generation settings.
#
# release/opt-candidates.cmake (the measured shader-attribute options) plus
# two switches that change how every translated function compiles. Neither
# changes the generated C corpus, so the v0.1.1-alpha corpus is reused; every
# generated unit is recompiled.
#
# Chosen from a guest-sampler profile (2026-10-15, normal rooms, EID closed):
# translated code is a flat profile with no dominant function, so per-function
# rewrites alone cannot close the 3-6 ms the full 30 Hz tick (update + full
# render, ~30 ms) is over the 27 ms that leaves room for the interpolated
# 60 Hz frame. These two act on all of it at once.
#
# Measure with -DISAAC_VITA_PHASE_PROFILE=ON -DISAAC_VITA_LOG_PRINTF_TO_FILE=ON
# against the same options on release/opt-candidates.cmake.

include("${CMAKE_CURRENT_LIST_DIR}/opt-candidates.cmake")

# 1. Raw synthetic stack: push/pop/esp adjust become plain arithmetic on the
#    function-local esp (guest.h "Raw stack (the production corpus)") instead
#    of an out-of-line range check that publishes and reloads esp around every
#    stack operation. Trade-off: a guest stack overflow is no longer caught as
#    a controlled fault. The release ran without a stack fault on record.
set(ISAAC_VITA_GUEST_STACK_GUARD OFF CACHE BOOL "" FORCE)

# 2. Scalar float guest loads/stores as VFP vldr/vstr behind a word-alignment
#    test instead of the memcpy pun (core<->VFP transfers). Header-only; the
#    option's own description says to turn it on in perf builds.
set(ISAAC_VITA_TRANSLATED_CPU_F32_VFP ON CACHE BOOL "" FORCE)
