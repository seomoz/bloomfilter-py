#ifndef CBLOOMFILTER__H
#define CBLOOMFILTER__H

#include <stdint.h>
#include <stdlib.h>


#define SIGNATURE 0x6D6F6F6C427A6F4Dul  // 'MozBloom'
#define VERSION_MAJOR 1
#define VERSION_MINOR 0

#define BITS_PER_WORD (sizeof(uint64_t) * 8)


typedef struct {
    uint64_t signature;  // the value should be SIGNATURE
    int32_t  version_major;
    int32_t  version_minor;
    uint64_t hash_count; // number of hashes in the filter
    uint64_t bit_count;  // number of bits in the filter (exact)

    // We are trying to make the object serializable, and avoid storing pointers.
    // To that end, we storing both seeds and bits in the same data array.
    // The first `hash_count` words are hash seeds, the rest is filter bit masks.
    //
    // Please do not use `data` directly. `seed_array()` and `bits_array()`
    // functions provide convenient and explicit access.
    uint64_t data[0];
} CBloomFilter;


static inline size_t byte_size(uint64_t hash_count, uint64_t bit_count)
    __attribute__((always_inline));
static inline size_t byte_size(uint64_t hash_count, uint64_t bit_count)
{
    uint64_t word_count = (bit_count + BITS_PER_WORD - 1) / BITS_PER_WORD ;
    return sizeof(CBloomFilter) + (hash_count + word_count) * sizeof(uint64_t);
}


static inline uint64_t rehash(uint64_t seed, uint64_t hash64)
    __attribute__((always_inline));
static inline uint64_t rehash(uint64_t seed, uint64_t hash64)
{
    return seed ^ hash64;
}

static inline uint64_t* bits_array(CBloomFilter* filter)
    __attribute__((always_inline));
static inline uint64_t* bits_array(CBloomFilter* filter)
{
    return &filter->data[filter->hash_count];
}

static inline uint64_t* seeds_array(CBloomFilter* filter)
    __attribute__((always_inline));
static inline uint64_t* seeds_array(CBloomFilter* filter)
{
    return filter->data;
}

CBloomFilter* CBloomFilter_Create(uint64_t hash_count, uint64_t bit_count, void* seeds)
{
    errno = 0;
    CBloomFilter* filter = (CBloomFilter*) calloc(byte_size(hash_count, bit_count), 1);
    if (filter == NULL || errno) {
        return NULL;
    }
    filter->signature = SIGNATURE;
    filter->version_major = VERSION_MAJOR;
    filter->version_minor = VERSION_MINOR;
    filter->hash_count = hash_count;
    filter->bit_count = bit_count;
    memcpy(seeds_array(filter), seeds, hash_count * sizeof(uint64_t));
    return filter;
}

void CBloomFilter_Destroy(CBloomFilter* filter)
{
    free(filter);
}

int  CBloomFilter_AddHash(CBloomFilter* filter, uint64_t hash64)
{
    uint64_t hash_count = filter->hash_count;
    uint64_t bit_count = filter->bit_count;
    uint64_t* bits = bits_array(filter);
    uint64_t* seeds = seeds_array(filter);
    int ix;
    uint64_t added = 0;

    for (ix = 0; ix < hash_count; ++ix) {
        uint64_t hash = rehash(seeds[ix], hash64) % bit_count;
        uint64_t mask = ((uint64_t)1) << (hash % BITS_PER_WORD);
        uint64_t bit = (bits[hash / BITS_PER_WORD] & mask) >> (hash % BITS_PER_WORD);
        added = bit ? added : 1;
        bits[hash / BITS_PER_WORD] |= mask;
    }

    return added ? 1 : 0;
}

int  CBloomFilter_TestHash(CBloomFilter* filter, uint64_t hash64)
{
    uint64_t hash_count = filter->hash_count;
    uint64_t bit_count = filter->bit_count;
    uint64_t* bits = bits_array(filter);
    uint64_t* seeds = seeds_array(filter);
    int ix;

    for (ix = 0; ix < hash_count; ++ix) {
        uint64_t hash = rehash(seeds[ix], hash64) % bit_count;
        if (bits[hash / BITS_PER_WORD] & ((uint64_t)1) << (hash % BITS_PER_WORD)) {
            continue;
        }
        else {
            return 0;
        }

    }
    return 1;
}

size_t CBloomFilter_ByteSize(CBloomFilter* filter)
{
    return byte_size(filter->hash_count, filter->bit_count);
}

CBloomFilter* CBloomFilter_FromData(void* address, size_t length)
{
    CBloomFilter* old = address;
    if (length < sizeof(CBloomFilter) || old->signature != SIGNATURE ||
        old->version_major != VERSION_MAJOR ||
        CBloomFilter_ByteSize(old) != length) {
        return NULL;
    }

    errno = 0;
    CBloomFilter* filter = (CBloomFilter*) malloc(length);
    if (filter == NULL || errno) {
        return NULL;
    }

    memcpy(filter, old, length);

    return filter;
}
#endif
