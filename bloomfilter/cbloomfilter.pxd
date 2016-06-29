
cdef extern from "cbloomfilter.h" nogil:
    ctypedef struct CBloomFilter:
        long  hash_count
        long  bit_count
        long* data

    CBloomFilter* CBloomFilter_Create(long hash_count, long bit_count, void* seeds);
    CBloomFilter* CBloomFilter_FromData(void* address, size_t length);
    void CBloomFilter_Destroy(CBloomFilter* filter);
    void CBloomFilter_AddHash(CBloomFilter* filter, long hash64);
    int  CBloomFilter_TestHash(CBloomFilter* filter, long hash64);
    size_t CBloomFilter_ByteSize(CBloomFilter* filter);
