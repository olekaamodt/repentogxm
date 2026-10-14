/* Host test for isaac_vita_lua_userdata_bytes_same
 * (recomp/runtime/host_vita_lua_userdata_same.h), the userdata comparison
 * behind ISAAC_VITA_LUA_NATIVE_INDEX_VERIFY.
 *
 * Models LuaBridge's UserdataValue<Vector>: { vtable, m_p, float x, float y }
 * where m_p points at x inside the same block.  Two boxes of the same value
 * must compare equal (STATUS.md problem 6: the Position getter's false
 * mismatch); any real difference must still be caught.
 *
 * Pointers are stored as 32-bit words, as on the Vita.  On a 64-bit host the
 * comparison truncates the block address the same way, so the model holds. */
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "host_vita_lua_userdata_same.h"

typedef struct box {
    uint32_t vtable;
    uint32_t self_payload;
    float x;
    float y;
} box;

static int failures;

static void expect(int got, int want, const char *what)
{
    if (got != want) {
        fprintf(stderr, "FAIL: %s (got %d, want %d)\n", what, got, want);
        ++failures;
    }
}

static box *make(float x, float y, uint32_t vtable)
{
    /* Over-allocate and offset so the two boxes never share an address. */
    box *b = (box *)calloc(1, sizeof(box));
    if (!b) {
        perror("calloc");
        exit(2);
    }
    b->vtable = vtable;
    b->self_payload = (uint32_t)(uintptr_t)&b->x;
    b->x = x;
    b->y = y;
    return b;
}

int main(void)
{
    box *a = make(1.5f, -2.0f, 0x00a1b2c4U);
    box *b = make(1.5f, -2.0f, 0x00a1b2c4U);
    box *c;
    unsigned char raw_a[13];
    unsigned char raw_b[13];

    expect(isaac_vita_lua_userdata_bytes_same(a, b, sizeof(box)), 1,
           "two boxes of the same Vector are the same value");
    expect(isaac_vita_lua_userdata_bytes_same(a, a, sizeof(box)), 1,
           "a box equals itself");

    b->x = 1.25f;
    expect(isaac_vita_lua_userdata_bytes_same(a, b, sizeof(box)), 0,
           "a different payload is caught");
    b->x = 1.5f;

    b->vtable = 0x00a1b2c8U;
    expect(isaac_vita_lua_userdata_bytes_same(a, b, sizeof(box)), 0,
           "a different vtable word is caught");
    b->vtable = 0x00a1b2c4U;

    /* Self-relative in both blocks but to different offsets. */
    b->self_payload = (uint32_t)(uintptr_t)&b->y;
    expect(isaac_vita_lua_userdata_bytes_same(a, b, sizeof(box)), 0,
           "self pointers to different offsets are caught");

    /* One side points into a third block at the same offset. */
    c = make(0.0f, 0.0f, 0x1U);
    b->self_payload = (uint32_t)(uintptr_t)&c->x;
    expect(isaac_vita_lua_userdata_bytes_same(a, b, sizeof(box)), 0,
           "a pointer outside its own block is caught");

    /* An external pointer equal on both sides compares as plain bytes. */
    a->self_payload = (uint32_t)(uintptr_t)c;
    b->self_payload = (uint32_t)(uintptr_t)c;
    expect(isaac_vita_lua_userdata_bytes_same(a, b, sizeof(box)), 1,
           "equal external pointers are equal bytes");

    /* A difference in a trailing partial word is never forgiven. */
    memset(raw_a, 0, sizeof(raw_a));
    memset(raw_b, 0, sizeof(raw_b));
    raw_b[12] = 1;
    expect(isaac_vita_lua_userdata_bytes_same(raw_a, raw_b, sizeof(raw_a)), 0,
           "a trailing byte difference is caught");
    expect(isaac_vita_lua_userdata_bytes_same(raw_a, raw_b, 0), 1,
           "empty userdata compares equal");

    free(a);
    free(b);
    free(c);
    if (failures) {
        fprintf(stderr, "%d failure(s)\n", failures);
        return 1;
    }
    puts("vita_lua_userdata_same_test: ok");
    return 0;
}
