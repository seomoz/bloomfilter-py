'''Simple and fast implementation of Bloom filter'''

import base64
import hashlib
import random
import zlib

cimport cython.math as math
from math import ceil, exp, log
cimport cbloomfilter


__version__ = (0, 1, 0)


cdef class BloomFilter:
    '''Simple and fast implementation of Bloom filter'''
    cdef cbloomfilter.CBloomFilter* cbf

    def __cinit__(self, capacity=0, error_rate=0, _build=True):
        cdef long hash_count
        cdef long bit_count
        cdef double log2 = log(2.0)
        cdef double log_error_rate
        cdef cbloomfilter.CBloomFilter* cbf
        cdef char* seeds

        self.cbf = NULL

        if not _build:
            return

        if capacity <= 0:
            raise ValueError("BloomFilter capacity must be a positive number (%s passed)", capacity)

        if error_rate <= 0 or error_rate >= 1:
            raise ValueError("BloomFilter error rate must be in the range 0 < error rate < 1 (%s passed)", error_rate)

        log_error_rate = log(error_rate)
        hash_count = max(round(- log_error_rate / log2), 1)
        bit_count = ceil(- hash_count / log(1 - exp(log_error_rate / hash_count)) * capacity)
        # Since we are using very simplistic re-hash algorithm, we have a pathological
        # case when `bit_count` is power of 2. We alleviate it by making `bit_count` always
        # an odd number.
        bit_count |= 1
        acc = ''
        for i in xrange(hash_count):
            random_string = "".join(chr(random.randrange(256)) for j in xrange(8))
            # we are using simplistic rehasher, so we better have pretty good seeds.
            hasher = hashlib.new('md5')
            hasher.update(random_string)
            acc += hasher.digest()
        seeds = acc
        cbf = cbloomfilter.CBloomFilter_Create(hash_count, bit_count, seeds)
        if cbf == NULL:
            raise ValueError("BloomFilter cannot allocate memory for capacity=%s and error_rate=%s", capacity, error_rate)
        self.cbf = cbf

    def __dealloc__(self):
        '''Free up filter's data'''
        cbloomfilter.CBloomFilter_Destroy(self.cbf)
        self.cbf = NULL

    @property
    def byte_size(self):
        '''Size of the filter in bytes'''
        return cbloomfilter.CBloomFilter_ByteSize(self.cbf)

    @property
    def hash_count(self):
        '''Number of hashes in the filter'''
        return self.cbf.hash_count

    @property
    def bit_count(self):
        '''Number of bits in the filter'''
        return self.cbf.bit_count

    def add_hash(self, x):
        '''Add item's hash to the filter'''
        return cbloomfilter.CBloomFilter_AddHash(self.cbf, hash(x))

    def test_hash(self, x):
        '''Test whether item hash is in the filter'''
        return bool(cbloomfilter.CBloomFilter_TestHash(self.cbf, hash(x)))

    def serialize(self):
        '''Serialize the filter'''
        return base64.b64encode(zlib.compress((<char*>self.cbf)[:self.byte_size], 9))

    @classmethod
    def deserialize(self, serialized_filter):
        '''Create a filter from previously serialized data'''
        data = zlib.decompress(base64.b64decode(serialized_filter))

        cbf = BloomFilter(_build=False)
        cbf.cbf = cbloomfilter.CBloomFilter_FromData(<char*> data, len(data))
        if cbf.cbf == NULL:
            raise ValueError("BloomFilter: serialized data are corrupted, or cannot allocate memory")
        return cbf


    def raw_data(self):
        '''Raw filter data, primary for debug purpose'''
        return (<char*>self.cbf)[:self.byte_size]

