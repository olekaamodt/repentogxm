# repentogxm optimization candidates on top of v0.1.1-alpha.
#
# The v0.1.1-alpha option set plus two optimizations that are implemented,
# host-tested and fall back to the original code. Measured on one Vita
# 2026-10-15: attribute location lookups per draw 13.4 -> 1.7, room render
# median about 1-1.3 ms lower in the busier scenes, no faults or fallbacks
# (STATUS.md "What is in the tree", recomp/vita/README.md).
# Configure exactly like the release, swapping the -C file:
#
#   cmake -S recomp/vita -B <build> -G Ninja -C release/opt-candidates.cmake \
#     -DCMAKE_TOOLCHAIN_FILE="$VITASDK/share/vita.toolchain.cmake" \
#     -DISAAC_PE_PATH=<isaac-ng.exe.unpacked.exe> \
#     -DISAAC_GENERATED_DIR=<generated> \
#     -DISAAC_LUA53_SOURCE_DIR=<pristine lua-5.3.3 source tree>
#   ninja -C <build> eboot.bin the-binding-of-isaac-repentance.vpk
#
# Use the corpus generated for v0.1.1-alpha (same GUEST_* switches): none of
# the options below changes generated code.
#
# Measure it against a twin: configure a second build directory from
# release/v0.1.1-alpha.cmake and add -DISAAC_VITA_PHASE_PROFILE=ON to both, so
# the only difference is the three candidates. Play the same rooms on both and
# compare render median / p95 per window class and door-transition wall time
# (STATUS.md "How the numbers are measured"). Each candidate can be switched
# back off with -D...=OFF on the command line to isolate it.

include("${CMAKE_CURRENT_LIST_DIR}/v0.1.1-alpha.cmake")

# 1. Room render, "sprite attribute state about 0.7 ms" per frame (STATUS.md):
#    remember glGetAttribLocation answers inside the Shader::EnableAttribs /
#    DisableAttribs replays, keyed on the program-state generation, the shader
#    object and every attribute name; any change takes the unmemoized path.
set(ISAAC_VITA_SHADER_ATTRIB_LOCATION_MEMO ON CACHE BOOL "" FORCE)

# 2. Same phase: hand each replay's whole attribute set to the typed backend in
#    one native call instead of one GL wrapper call per attribute. Rejected by
#    CMake together with GL_WRAPPER_TIME or STALL_PROBE (both OFF here).
set(ISAAC_VITA_SHADER_ATTRIB_DIRECT_STATE ON CACHE BOOL "" FORCE)

# Sprite-sheet retention (ISAAC_VITA_IMAGE_RETAIN) was measured on device
# 2026-10-15 and dropped: vitaGL free memory sits at the 64 MiB headroom
# floor during play, so 1 of 1,856 offered sheets was reused and door-
# transition stalls were unchanged (median 0.90 s vs 0.94 s). It stays OFF,
# as in the release.
