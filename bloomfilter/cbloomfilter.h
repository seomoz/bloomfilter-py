#ifndef CBLOOMFILTER__H
#define CBLOOMFILTER__H

#include <stdint.h>
#include <stdlib.h>


#define SIGNATURE 0x6D6F6F6C427A6F4Dul  // 'MozBloom'

#define BITS_PER_WORD (sizeof(uint64_t) * 8)


typedef struct {
    uint64_t signature;  // the value should be SIGNATURE
    int32_t  version_major;
    int32_t  version_minor;
    uint64_t hash_count; // number of hashes in the filter
    uint64_t bit_count;  // number of bits in the filter (exact)
    uint64_t data[0];    // first `hash_count` words is hash seeds,
                         // the rest is filter bit masks
} CBloomFilter;


static inline size_t byte_size(uint64_t hash_count, uint64_t bit_count)
{
    uint64_t word_count = (bit_count + BITS_PER_WORD - 1) / BITS_PER_WORD ;
    return sizeof(CBloomFilter) + (hash_count + word_count) * sizeof(uint64_t);
}

static inline uint64_t rehash(uint64_t seed, uint64_t hash64)
{
    return seed ^ hash64;
}

CBloomFilter* CBloomFilter_Create(uint64_t hash_count, uint64_t bit_count, void* seeds)
{
    errno = 0;
    CBloomFilter* filter = (CBloomFilter*) calloc(byte_size(hash_count, bit_count), 1);
    if (filter == NULL || errno) {
        return NULL;
    }
    filter->signature = SIGNATURE;
    filter->version_major = 1;
    filter->version_minor = 0;
    filter->hash_count = hash_count;
    filter->bit_count = bit_count;
    memcpy(filter->data, seeds, hash_count * sizeof(uint64_t));
    return filter;
}

void CBloomFilter_Destroy(CBloomFilter* filter)
{
    if (filter != NULL) {
        free(filter);
    }
}

void CBloomFilter_AddHash(CBloomFilter* filter, uint64_t hash64)
{
    uint64_t hash_count = filter->hash_count;
    uint64_t bit_count = filter->bit_count;
    uint64_t* bits = &filter->data[hash_count];
    int ix;

    for (ix = 0; ix < hash_count; ++ix) {
        uint64_t hash = rehash(filter->data[ix], hash64) % bit_count;
        bits[hash / BITS_PER_WORD] |= ((uint64_t)1) << (hash % BITS_PER_WORD);
    }
}

int  CBloomFilter_TestHash(CBloomFilter* filter, uint64_t hash64)
{
    uint64_t hash_count = filter->hash_count;
    uint64_t bit_count = filter->bit_count;
    uint64_t* bits = &filter->data[hash_count];
    int ix;

    for (ix = 0; ix < hash_count; ++ix) {
        uint64_t hash = rehash(filter->data[ix], hash64) % bit_count;
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
        old->version_major != 1 || CBloomFilter_ByteSize(old) != length) {
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
