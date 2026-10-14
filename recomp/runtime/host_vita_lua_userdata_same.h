/* Userdata comparison for the ISAAC_VITA_LUA_NATIVE_INDEX_VERIFY comparator
 * (host_vita_lua.c).  Header-only so the host test can include it without
 * Lua. */
#ifndef HOST_VITA_LUA_USERDATA_SAME_H
#define HOST_VITA_LUA_USERDATA_SAME_H

#include <stddef.h>
#include <stdint.h>
#include <string.h>

/* LuaBridge's UserdataValue<T> stores a pointer to its own payload inside the
 * block (Userdata::m_p), so two by-value boxes of the same Vector differ in
 * exactly that word.  Guest addresses are host addresses here (the image is
 * identity-mapped and Lua allocates through the guest allocator), so a word
 * that points into its own block at the same offset as its counterpart in
 * the other block is the same value.  Everything else must match byte for
 * byte.  Kept free of Lua so recomp/vita/host_tests/vita_lua_userdata_same_test.c can
 * exercise it directly. */
static inline int isaac_vita_lua_userdata_bytes_same(const void *a, const void *b,
                                       size_t length)
{
    const unsigned char *pa = (const unsigned char *)a;
    const unsigned char *pb = (const unsigned char *)b;
    const uint32_t base_a = (uint32_t)(uintptr_t)pa;
    const uint32_t base_b = (uint32_t)(uintptr_t)pb;
    size_t i = 0;

    while (i < length) {
        if (pa[i] == pb[i]) {
            ++i;
            continue;
        }
        /* A differing byte must sit in an aligned word that is a
         * self-relative pointer in both blocks. */
        {
            size_t word = i & ~(size_t)3U;
            uint32_t wa;
            uint32_t wb;
            if (word + 4U > length)
                return 0;
            memcpy(&wa, pa + word, 4U);
            memcpy(&wb, pb + word, 4U);
            if (wa - base_a >= (uint32_t)length ||
                wa - base_a != wb - base_b)
                return 0;
            i = word + 4U;
        }
    }
    return 1;
}

#endif /* HOST_VITA_LUA_USERDATA_SAME_H */
