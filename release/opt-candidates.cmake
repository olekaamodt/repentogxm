# repentogxm optimization candidates on top of v0.1.1-alpha.
#
# The v0.1.1-alpha option set plus three optimizations that are implemented,
# host-tested and fall back to the original code, but have never been
# measured on a Vita (STATUS.md "What is in the tree", recomp/vita/README.md).
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

# 3. Door transitions, "45-50 % of a room entry was PNG sprite-sheet reload"
#    (STATUS.md problem 2): keep recently released sprite sheets uploaded on a
#    byte-budgeted LRU so re-entering a room skips fopen/inflate/glTexImage2D.
#    48 MiB holds one room's miss set; the headroom rule evicts whenever
#    vitaGL free memory drops below 64 MiB, so it cannot cause a texture
#    allocation failure the release build would not have. The release file
#    carries a budget of 8; 48 is the option's own default.
set(ISAAC_VITA_IMAGE_RETAIN ON CACHE BOOL "" FORCE)
set(ISAAC_VITA_IMAGE_RETAIN_BUDGET_MB 48 CACHE STRING "" FORCE)
set(ISAAC_VITA_IMAGE_RETAIN_HEADROOM_MB 64 CACHE STRING "" FORCE)
